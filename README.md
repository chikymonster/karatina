# WSUS Reporting Solution - Single Folder Edition

## 🎯 Problem Solved
WSUS native reports are slow, ugly, and unusable. This solution provides:
- ✨ Beautiful HTML dashboards with charts
- 📊 Power BI integration for drill-down analysis
- 📧 Automated weekly email reports
- 📈 Executive-friendly metrics
- 🔍 Auditor-approved compliance data

## 📁 Simple Deployment - All Files in One Folder!

Everything you need is in this single folder:
```
wsus-reporting/
├── 01_vw_OverallCompliance.sql
├── 02_vw_ComplianceByClassification.sql
├── 03_vw_MissingSecurityUpdates.sql
├── 04_vw_NonReportingSystems.sql
├── 05_vw_ComplianceBySystemType.sql
├── 06_vw_TopNonCompliantSystems.sql
├── Generate-WSUSReports.ps1
├── Export-WSUSDataToCSV.ps1
├── Setup-AutomatedReporting.ps1
├── Test-WSUSReportingHealth.ps1
├── Install-WSUSReporting.ps1
├── README.md (this file)
├── DEPLOYMENT-GUIDE.md
└── QUICK-REFERENCE.md
```

No subdirectories, no complexity. Just copy the folder and run!

## 🚀 Quick Start (5 Minutes)

### Step 1: Copy Files
```powershell
# Copy this entire folder to your WSUS server
# Example: C:\WSUSReporting\
```

### Step 2: Run Installation
```powershell
# Open PowerShell as Administrator
cd C:\WSUSReporting

# Basic install (deploys SQL views + generates first report)
.\Install-WSUSReporting.ps1 -SqlServer "YOUR_SQL_SERVER_NAME"

# That's it! Your browser will open with your first report.
```

### Step 3: Setup Automation (Optional)
```powershell
# Add email delivery and scheduled tasks
.\Install-WSUSReporting.ps1 -SqlServer "YOUR_SQL_SERVER" -SetupAutomation `
    -SmtpServer "smtp.company.com" `
    -EmailTo "audit@company.com,security@company.com" `
    -EmailFrom "wsus-reports@company.com"
```

## 📊 What You Get

### Beautiful HTML Reports with:
- **Overall Compliance Dashboard** - Single-pane view of patch health
- **Server vs Workstation** - Separate metrics for critical systems
- **Missing Security Updates** - What patches are missing, on how many systems
- **Top Non-Compliant Systems** - Worst offenders ranked by risk
- **Non-Reporting Systems** - Stale data requiring investigation
- **Interactive Charts** - Visual compliance trends

### Automated Features:
- ✅ Weekly email reports (Monday 8 AM)
- ✅ Daily local summaries (6 AM)
- ✅ 90-day automatic cleanup
- ✅ Zero manual work

### Auditor Tools:
- CSV exports for Excel analysis
- Complete computer inventory
- Risk scoring
- Historical compliance data

## 📋 Requirements

- Windows Server with WSUS installed
- SQL Server (not Windows Internal Database) with SUSDB
- PowerShell 5.1+ (built into Windows Server 2016+)
- Administrator rights
- SMTP server access (optional, for email)

## 🔧 Daily Usage

### Generate Report Manually
```powershell
cd C:\WSUSReporting
.\Generate-WSUSReports.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Reports"
```

### Export CSV for Auditors
```powershell
.\Export-WSUSDataToCSV.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Audit"
```

### Run Health Check
```powershell
.\Test-WSUSReportingHealth.ps1 -SqlServer "WSUSSQL01"
```

### Test Email Delivery
```powershell
.\Generate-WSUSReports.ps1 -SqlServer "WSUSSQL01" -EmailReport `
    -SmtpServer "smtp.company.com" `
    -EmailTo "test@company.com" `
    -EmailFrom "wsus@company.com"
```

## 🎯 For Auditors

**Common Questions Answered:**

**Q: What's our patch compliance?**  
→ Open HTML report → See "Overall Compliance" card (top left)

**Q: Which systems need critical patches?**  
→ HTML report → "Top Non-Compliant Systems" table

**Q: What critical patches are missing?**  
→ HTML report → "Critical & Security Updates Missing" section

**Q: Which systems aren't reporting?**  
→ HTML report → "Non-Reporting Systems" section

**Q: Give me raw data for analysis**  
→ Run: `.\Export-WSUSDataToCSV.ps1 -SqlServer "WSUSSQL01"`

## 🔧 Manage Scheduled Tasks

### View Tasks
```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like 'WSUS-*'}
```

### Run Task Now
```powershell
Start-ScheduledTask -TaskName "WSUS-WeeklyReport"
```

### Check Task History
```powershell
Get-ScheduledTask -TaskName "WSUS-WeeklyReport" | Get-ScheduledTaskInfo
```

## 🩺 Troubleshooting

### Reports Show No Data
```powershell
# Verify WSUS has computers
Get-WsusServer | Get-WsusComputer | Measure-Object

# Check last sync
Get-WsusServer | Get-WsusSubscription
```

### SQL Connection Fails
```powershell
# Test connection
Test-NetConnection -ComputerName "SQL_SERVER" -Port 1433

# Verify SQL views exist
# Run in SQL Server Management Studio:
# SELECT TABLE_NAME FROM SUSDB.INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME LIKE 'vw_%'
```

### Email Not Sending
```powershell
# Test SMTP
Send-MailMessage -To "test@company.com" -From "wsus@company.com" `
    -Subject "Test" -Body "Test" -SmtpServer "smtp.company.com"
```

## 📚 Documentation

All in this folder:
- **README.md** (this file) - Quick start
- **DEPLOYMENT-GUIDE.md** - Complete setup guide
- **QUICK-REFERENCE.md** - Command cheat sheet

## 🎨 What the SQL Views Do

1. **01_vw_OverallCompliance.sql** - Summary metrics (compliance %, total systems)
2. **02_vw_ComplianceByClassification.sql** - Breakdown by Critical/Security/Updates
3. **03_vw_MissingSecurityUpdates.sql** - Which patches are missing
4. **04_vw_NonReportingSystems.sql** - Systems not checking in
5. **05_vw_ComplianceBySystemType.sql** - Server vs workstation stats
6. **06_vw_TopNonCompliantSystems.sql** - Worst offenders with risk scores

These views make data extraction fast and enable Power BI integration.

## 🎓 Best Practices

1. ✅ Run health check after installation
2. ✅ Test report generation before automation
3. ✅ Keep 90+ days of reports (audit trail)
4. ✅ Focus on server compliance first (most critical)
5. ✅ Investigate non-reporting systems weekly
6. ✅ Share with management (they love dashboards)
7. ✅ Export CSV monthly for auditors

## 🎯 Target Compliance Levels

- **Excellent (Green)**: >95% compliant
- **Good (Yellow)**: 85-95% compliant
- **Poor (Red)**: <85% compliant

Servers should maintain >95%. Workstations >90% acceptable.

## 🔐 Security

- Scripts need only **read-only** access to SUSDB (`db_datareader`)
- No write operations to database
- Windows Authentication (no passwords in scripts)
- Reports contain: computer names, IPs, OS versions, patch status
- Ensure email recipients authorized for this data

## 💡 Pro Tips

- Schedule reports for Monday morning (start week informed)
- Use Power BI for interactive exploration
- Document exceptions (systems that can't patch)
- Watch trends over time, not just point-in-time
- Keep reports for compliance audit trail

## 🆘 Support

**For Issues:**
1. Run: `.\Test-WSUSReportingHealth.ps1 -SqlServer "WSUSSQL01"`
2. Check DEPLOYMENT-GUIDE.md for detailed troubleshooting
3. Verify all files are in the same folder
4. Ensure running PowerShell as Administrator

## 🚀 Power BI Integration

Want interactive dashboards? Power BI can connect directly to the SQL views:

1. Open Power BI Desktop
2. Get Data → SQL Server
3. Server: YOUR_SQL_SERVER, Database: SUSDB
4. Import these views:
   - vw_OverallCompliance
   - vw_ComplianceByClassification
   - vw_MissingSecurityUpdates
   - vw_ComplianceBySystemType
   - vw_TopNonCompliantSystems
5. Create visualizations and publish

See DEPLOYMENT-GUIDE.md for detailed Power BI setup.

## 📈 Example Use Cases

### Monthly Audit
```powershell
# Export everything for auditors
.\Export-WSUSDataToCSV.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Audit\2026-02"
# Provide folder to auditors
```

### Executive Presentation
```powershell
# Generate fresh report
.\Generate-WSUSReports.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Reports"
# Open HTML in browser, show dashboard
```

### Weekly Review
```powershell
# Automated! Just check your email Monday morning
# Or manually trigger:
Start-ScheduledTask -TaskName "WSUS-WeeklyReport"
```

## 🎉 Summary

You now have:
- ✅ 6 SQL views for efficient data extraction
- ✅ 4 PowerShell scripts for reporting and automation
- ✅ Beautiful HTML reports with charts
- ✅ CSV exports for auditors
- ✅ Scheduled tasks for hands-free operation
- ✅ Complete documentation

**All in one simple folder!**

No more suffering with WSUS's terrible native reports. Your auditors will thank you! 🎊

---

**Questions?** See DEPLOYMENT-GUIDE.md or QUICK-REFERENCE.md for more details.
