# WSUS Reporting Solution - Deployment Guide

## Overview

This comprehensive WSUS reporting solution replaces the clunky native WSUS reports with auditor-friendly dashboards, automated HTML reports, and Power BI integration.

**What You Get:**
- ✅ Automated weekly HTML reports with charts
- ✅ Daily compliance summaries
- ✅ CSV exports for auditor analysis
- ✅ Power BI templates for interactive dashboards
- ✅ Email delivery to stakeholders
- ✅ Executive-friendly metrics

## Prerequisites

### System Requirements
- Windows Server with WSUS installed
- SQL Server with SUSDB database (not Windows Internal Database)
- PowerShell 5.1 or higher
- SQL Server Management Studio (for view deployment)
- Power BI Desktop (optional, for dashboards)
- SMTP server access (for email reports)

### Permissions Required
- SQL Server: db_datareader on SUSDB
- Windows: Administrator rights (for scheduled tasks)
- SMTP: Ability to send email

## Deployment Steps

### Step 1: Deploy SQL Views (REQUIRED)

These views simplify data extraction and improve performance.

1. Open SQL Server Management Studio
2. Connect to your WSUS SQL Server
3. Open and execute each SQL script in this order:

```sql
-- Run these in SUSDB database
01_vw_OverallCompliance.sql
02_vw_ComplianceByClassification.sql
03_vw_MissingSecurityUpdates.sql
04_vw_NonReportingSystems.sql
05_vw_ComplianceBySystemType.sql
06_vw_TopNonCompliantSystems.sql
```

**Verification:**
```sql
USE SUSDB
GO
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE 'vw_%'
GO
```

You should see 6 views listed.

### Step 2: Test Manual Report Generation

Before automating, test that reports generate correctly.

1. Copy the `scripts` folder to your WSUS server (e.g., `C:\WSUSReporting\scripts`)

2. Open PowerShell as Administrator

3. Run the report generator:

```powershell
cd C:\WSUSReporting\scripts

.\Generate-WSUSReports.ps1 `
    -SqlServer "YOUR_SQL_SERVER" `
    -OutputPath "C:\WSUSReports" `
    -Verbose
```

4. Verify the HTML report was created in `C:\WSUSReports`

5. Open the HTML file in a browser - you should see a beautiful dashboard

### Step 3: Test CSV Export (Optional)

For auditors who want raw data:

```powershell
.\Export-WSUSDataToCSV.ps1 `
    -SqlServer "YOUR_SQL_SERVER" `
    -OutputPath "C:\WSUSReports\CSV"
```

Check `C:\WSUSReports\CSV` for 7 CSV files.

### Step 4: Setup Automated Reporting

This creates scheduled tasks for weekly reports with email delivery.

```powershell
.\Setup-AutomatedReporting.ps1 `
    -SqlServer "YOUR_SQL_SERVER" `
    -ReportPath "C:\WSUSReports" `
    -SmtpServer "smtp.yourcompany.com" `
    -EmailTo "audit@company.com,security@company.com" `
    -EmailFrom "wsus-reports@company.com" `
    -ScheduleDay "Monday" `
    -ScheduleTime "08:00"
```

**This creates 3 scheduled tasks:**

1. **WSUS-WeeklyReport** - Runs every Monday at 8 AM, emails stakeholders
2. **WSUS-DailySummary** - Runs daily at 6 AM, creates local report only
3. **WSUS-ReportCleanup** - Runs weekly, removes reports older than 90 days

**Test the scheduled task immediately:**
```powershell
Start-ScheduledTask -TaskName "WSUS-WeeklyReport"
```

Check your email and the output folder!

### Step 5: Power BI Setup (Optional but Recommended)

For interactive dashboards that auditors can drill into:

1. Install Power BI Desktop (free from Microsoft)
2. Follow the instructions in `templates/PowerBI-Setup-Guide.md`
3. Publish to Power BI Service for web access
4. Share with auditors

## Usage Guide

### For IT Administrators

**Daily Monitoring:**
- Check `C:\WSUSReports` for the daily summary (generated at 6 AM)
- Look for red metrics (compliance <85%)
- Review non-reporting systems

**Weekly Review:**
- The Monday morning email contains the full report
- Focus on:
  - Overall compliance percentage
  - Server compliance (should be >95%)
  - Critical and security updates missing
  - Top non-compliant systems
  - Non-reporting systems (stale data)

**Monthly Audits:**
- Export CSV files for the audit team:
  ```powershell
  .\Export-WSUSDataToCSV.ps1 -SqlServer "YOUR_SQL_SERVER" -OutputPath "C:\Audit\Month-YYYY-MM"
  ```
- Provide the HTML report
- Give them access to Power BI if available

**Troubleshooting Issues:**

Problem: Report shows 0 computers
- Solution: Verify WSUS synchronization is working
- Check: `Get-WsusServer | Invoke-WsusServerSync`

Problem: Email not sending
- Solution: Test SMTP manually:
  ```powershell
  Send-MailMessage -To "test@company.com" -From "wsus@company.com" -Subject "Test" -Body "Test" -SmtpServer "smtp.company.com"
  ```

Problem: Non-reporting systems list is huge
- Solution: Investigate why clients aren't checking in
- Check: Group Policy settings for Windows Update
- Check: WSUS server health and disk space

### For Auditors

**Quick Answers to Common Questions:**

1. **What's the current patch compliance?**
   - Open latest HTML report → Top left metric card
   - Target: >95% for production, >90% for all systems

2. **How many systems haven't reported in 30+ days?**
   - HTML report → "Non-Reporting Systems" section
   - CSV: Open `04_NonReportingSystems_DATE.csv`

3. **What critical patches are missing?**
   - HTML report → "Critical & Security Updates Missing" table
   - Shows: Update name, KB number, computers affected, age

4. **Are servers more compliant than workstations?**
   - HTML report → "Server vs Workstation Compliance" section
   - Servers should typically be >95% compliant

5. **Which systems are the worst offenders?**
   - HTML report → "Top 10 Non-Compliant Systems"
   - Sorted by risk score (weighted by critical patches)

**Power BI Analysis:**
- Open the published Power BI report
- Use Q&A: "Show me servers with critical updates"
- Filter by date range, department, or system type
- Export any table to Excel for detailed analysis

**Evidence Collection:**
1. Download the HTML report (self-contained, no dependencies)
2. Export CSV files for detailed analysis
3. Take screenshots of Power BI dashboards
4. All data includes timestamps and metadata

### For Management

**Executive Summary Metrics:**

The HTML report executive dashboard shows:
- Overall compliance percentage (target: >95%)
- Total systems under management
- Reporting rate (systems checking in)
- Number of systems needing attention

**KPIs to Track:**
1. **Compliance Percentage** - Should trend upward
2. **Critical Updates Age** - Should be <30 days
3. **Server Compliance** - Should be >95%
4. **Reporting Rate** - Should be >98%

**Red Flags:**
- ⚠️ Compliance drops below 85%
- ⚠️ Critical updates missing >30 days
- ⚠️ >10% of systems not reporting
- ⚠️ Failed updates increasing

## Maintenance

### Weekly Tasks
- Review Monday morning email report
- Investigate any red metrics
- Follow up on non-reporting systems

### Monthly Tasks
- Review trend: Is compliance improving?
- Archive reports for audit trail
- Check scheduled tasks are running:
  ```powershell
  Get-ScheduledTask | Where-Object {$_.TaskName -like 'WSUS-*'} | Get-ScheduledTaskInfo
  ```

### Quarterly Tasks
- Review Power BI dashboard with stakeholders
- Update email distribution list if needed
- Verify SQL views are still performing well

### As Needed
- Re-run setup if email addresses change
- Adjust schedule times if needed
- Export CSV for auditors on request

## Customization

### Change Email Recipients

```powershell
# Get existing task
$task = Get-ScheduledTask -TaskName "WSUS-WeeklyReport"

# Modify and re-create with new email list
.\Setup-AutomatedReporting.ps1 `
    -SqlServer "YOUR_SQL_SERVER" `
    -EmailTo "newlist@company.com" `
    (other parameters)
```

### Change Schedule

```powershell
# Modify trigger for the weekly report
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek "Friday" -At "17:00"
Set-ScheduledTask -TaskName "WSUS-WeeklyReport" -Trigger $trigger
```

### Modify Report Appearance

Edit `Generate-WSUSReports.ps1`:
- Line 200-400: CSS styling (colors, fonts, layout)
- Line 450-800: HTML structure and sections
- Line 850+: Chart generation JavaScript

### Add Custom SQL Views

Create your own view in SUSDB:
```sql
CREATE VIEW vw_YourCustomView AS
SELECT ...
FROM tbComputerTarget
WHERE ...
```

Then add it to the PowerShell script to include in reports.

## Security Considerations

### SQL Permissions
The service account needs only:
- `db_datareader` on SUSDB
- No write permissions required

### Email Content
Reports may contain:
- Computer names
- IP addresses
- Operating system versions
- Patch status

Ensure email recipients are authorized to view this data.

### Report Storage
- Reports stored locally: `C:\WSUSReports`
- Set NTFS permissions appropriately
- Consider encrypting the folder if highly sensitive

### Scheduled Task Security
- Tasks run as SYSTEM by default
- Consider using a dedicated service account
- Grant only required SQL permissions

## Troubleshooting

### Reports Look Empty

**Cause:** No data in WSUS database

**Solution:**
1. Verify WSUS synchronization is working
2. Check computer group membership
3. Ensure clients are reporting to WSUS server

### SQL Connection Errors

**Cause:** Network or permission issues

**Solution:**
1. Test SQL connection:
   ```powershell
   Test-NetConnection -ComputerName "SQL_SERVER" -Port 1433
   ```
2. Verify SQL login credentials
3. Check firewall rules
4. Ensure SQL Server is set to Mixed Mode authentication

### Email Not Sending

**Cause:** SMTP configuration issues

**Solution:**
1. Test SMTP manually
2. Check SMTP server allows relay from WSUS server
3. Verify port (usually 25 or 587)
4. Check if TLS/SSL is required

### Scheduled Tasks Not Running

**Cause:** Various Windows Task Scheduler issues

**Solution:**
1. Check task history:
   ```powershell
   Get-ScheduledTask -TaskName "WSUS-WeeklyReport" | Get-ScheduledTaskInfo
   ```
2. Verify service account has permissions
3. Check "Run whether user is logged on or not" is selected
4. Ensure "Run with highest privileges" is checked

### Power BI Connection Fails

**Cause:** Firewall or authentication issues

**Solution:**
1. Install Power BI Gateway on SQL Server
2. Use Windows authentication
3. Whitelist Power BI service IP addresses on firewall

## Best Practices

1. **Keep reports for audit trail** - Don't reduce retention below 90 days
2. **Review weekly** - Don't let compliance drift without attention
3. **Prioritize servers** - Server patches should be deployed first
4. **Document exceptions** - If systems can't patch, document why
5. **Test patches** - Use a pilot group before broad deployment
6. **Monitor trends** - Look for patterns, not just point-in-time numbers

## Support and Updates

**This Solution Includes:**
- 6 SQL views for efficient data extraction
- 3 PowerShell scripts for reporting and automation
- 3 scheduled tasks for hands-free operation
- Power BI setup guide and DAX measures
- This comprehensive documentation

**For Issues:**
1. Check the PowerShell script output for errors
2. Review scheduled task history
3. Verify SQL views are returning data
4. Test components individually before blaming the full solution

**Future Enhancements:**
- Add trend analysis (requires historical data collection)
- Integrate with ticketing system for automatic remediation
- Add Slack/Teams notifications for critical alerts
- Create mobile-friendly dashboard

## Summary

You now have a professional WSUS reporting system that:
- ✅ Generates beautiful, auditor-friendly reports automatically
- ✅ Emails stakeholders weekly without manual intervention
- ✅ Provides Power BI dashboards for deep-dive analysis
- ✅ Exports CSV data for custom analysis
- ✅ Maintains an audit trail of compliance over time

**No more excuses for poor WSUS reporting!**

The auditors will thank you, management will be impressed, and you'll save hours every week.
