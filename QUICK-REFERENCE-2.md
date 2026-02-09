# WSUS Reporting - Quick Reference Card

## 🚀 Quick Start (Copy & Paste)

### First-Time Setup
```powershell
# 1. One-line install (run as Administrator)
cd C:\path\to\wsus-reporting
.\Install-WSUSReporting.ps1 -SqlServer "YOUR_SQL_SERVER"

# 2. Setup automation with email
.\Install-WSUSReporting.ps1 -SqlServer "YOUR_SQL_SERVER" -SetupAutomation `
    -SmtpServer "smtp.company.com" `
    -EmailTo "audit@company.com,security@company.com" `
    -EmailFrom "wsus-reports@company.com"
```

## 📊 Generate Reports

### HTML Report (Beautiful Dashboard)
```powershell
.\scripts\Generate-WSUSReports.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Reports"
```

### CSV Export (For Auditors)
```powershell
.\scripts\Export-WSUSDataToCSV.ps1 -SqlServer "WSUSSQL01" -OutputPath "C:\Audit"
```

### Email Report Now
```powershell
.\scripts\Generate-WSUSReports.ps1 -SqlServer "WSUSSQL01" -EmailReport `
    -SmtpServer "smtp.company.com" -EmailTo "audit@company.com" -EmailFrom "wsus@company.com"
```

## 🔧 Manage Scheduled Tasks

### View All WSUS Tasks
```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like 'WSUS-*'}
```

### Run Task Manually
```powershell
Start-ScheduledTask -TaskName "WSUS-WeeklyReport"
```

### Check Task Status
```powershell
Get-ScheduledTask -TaskName "WSUS-WeeklyReport" | Get-ScheduledTaskInfo
```

### Disable/Enable Task
```powershell
Disable-ScheduledTask -TaskName "WSUS-WeeklyReport"
Enable-ScheduledTask -TaskName "WSUS-WeeklyReport"
```

## 🩺 Health Check & Troubleshooting

### Run Health Check
```powershell
.\scripts\Test-WSUSReportingHealth.ps1 -SqlServer "WSUSSQL01"
```

### Test SQL Connection
```powershell
Test-NetConnection -ComputerName "WSUSSQL01" -Port 1433
```

### Verify SQL Views Exist
```sql
USE SUSDB
GO
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME LIKE 'vw_%'
GO
-- Should return 6 views
```

### Test WSUS Sync
```powershell
Get-WsusServer | Invoke-WsusServerSync
```

### Check WSUS Computer Count
```sql
SELECT COUNT(*) FROM SUSDB.dbo.tbComputerTarget WHERE IsDeleted = 0
```

## 📂 File Locations

### Reports
- HTML: `C:\WSUSReports\WSUS_Report_YYYY-MM-DD.html`
- CSV: `C:\WSUSReports\CSV\*.csv`

### Scripts
- All PowerShell: `C:\WSUSReporting\scripts\`
- SQL Views: `C:\WSUSReporting\sql-views\`

### Scheduled Tasks
- Weekly Report: Monday 8:00 AM
- Daily Summary: Daily 6:00 AM  
- Cleanup: Sunday 2:00 AM

## 🎯 Common Queries

### Overall Compliance
```sql
SELECT * FROM SUSDB.dbo.vw_OverallCompliance
```

### Missing Critical Updates
```sql
SELECT TOP 10 * FROM SUSDB.dbo.vw_MissingSecurityUpdates 
WHERE Severity = 'Critical'
ORDER BY ComputersAffected DESC
```

### Non-Reporting Systems
```sql
SELECT * FROM SUSDB.dbo.vw_NonReportingSystems 
WHERE DaysSinceLastSync > 30
ORDER BY DaysSinceLastSync DESC
```

### Server Compliance
```sql
SELECT * FROM SUSDB.dbo.vw_ComplianceBySystemType 
WHERE SystemType = 'Server'
```

### Top Non-Compliant
```sql
SELECT TOP 10 * FROM SUSDB.dbo.vw_TopNonCompliantSystems
```

## ⚙️ Customize Automation

### Change Email Recipients
```powershell
# Re-run setup with new recipients
.\scripts\Setup-AutomatedReporting.ps1 -SqlServer "WSUSSQL01" `
    -EmailTo "new@company.com,list@company.com" `
    -EmailFrom "wsus@company.com" -SmtpServer "smtp.company.com"
```

### Change Schedule Day/Time
```powershell
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek "Friday" -At "17:00"
Set-ScheduledTask -TaskName "WSUS-WeeklyReport" -Trigger $trigger
```

### Change Report Retention (Default: 90 days)
```powershell
# Edit the cleanup task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument `
    "-Command `"Get-ChildItem 'C:\WSUSReports' -Recurse | Where {`$_.CreationTime -lt (Get-Date).AddDays(-180)} | Remove-Item`""
Set-ScheduledTask -TaskName "WSUS-ReportCleanup" -Action $action
```

## 🎨 Report Customization

### Modify HTML Colors/Style
Edit `scripts\Generate-WSUSReports.ps1` line 200-400 (CSS section)

### Add Custom Metrics
1. Create SQL view in SUSDB
2. Add query to Generate-WSUSReports.ps1
3. Add HTML section to display data

## 📧 SMTP Troubleshooting

### Test SMTP Manually
```powershell
Send-MailMessage -To "test@company.com" -From "wsus@company.com" `
    -Subject "Test" -Body "Test" -SmtpServer "smtp.company.com"
```

### Common SMTP Ports
- Port 25: Standard SMTP
- Port 587: SMTP with STARTTLS
- Port 465: SMTPS (SSL)

## 🔍 Auditor FAQs

**Q: What's our patch compliance?**
A: Open HTML report → See "Overall Compliance" card (top left)

**Q: Which systems need critical patches?**
A: HTML report → "Top Non-Compliant Systems" table

**Q: What critical patches are missing?**
A: HTML report → "Critical & Security Updates Missing" section

**Q: Which systems aren't reporting?**
A: HTML report → "Non-Reporting Systems" section

**Q: Give me raw data**
A: Run: `.\Export-WSUSDataToCSV.ps1 -SqlServer "WSUSSQL01"`

**Q: Show me server compliance specifically**
A: HTML report → "Server vs Workstation Compliance" section

## 🎯 Target Metrics

### Good
- Overall Compliance: >95%
- Server Compliance: >98%
- Reporting Rate: >95%
- Non-Reporting Systems: <5%
- Critical Updates Age: <30 days

### Acceptable
- Overall Compliance: 85-95%
- Server Compliance: 90-98%
- Reporting Rate: 85-95%
- Non-Reporting Systems: 5-10%
- Critical Updates Age: 30-60 days

### Poor (Requires Action)
- Overall Compliance: <85%
- Server Compliance: <90%
- Reporting Rate: <85%
- Non-Reporting Systems: >10%
- Critical Updates Age: >60 days

## 🆘 Emergency Contacts

**WSUS Not Syncing:**
```powershell
Get-WsusServer | Get-WsusSubscription
Get-WsusServer | Invoke-WsusServerSync
```

**Database Connection Issues:**
1. Verify SQL Server service running
2. Check firewall (port 1433)
3. Test Windows authentication
4. Confirm permissions on SUSDB

**Reports Show No Data:**
1. Verify WSUS synchronization recent
2. Check computer group membership
3. Confirm clients reporting to WSUS
4. Run health check script

## 📚 Documentation

- **README.md** - Overview and quick start
- **DEPLOYMENT-GUIDE.md** - Complete setup guide
- **PowerBI-Setup-Guide.md** - Interactive dashboards
- **This file** - Quick reference commands

## 💡 Pro Tips

1. ⏰ Schedule reports for Monday morning - start the week informed
2. 📊 Use Power BI for interactive exploration  
3. 📁 Keep 90+ days of reports for audit trail
4. 🎯 Focus on servers first - they're most critical
5. 📧 Include management in weekly emails
6. 🔍 Investigate non-reporting systems weekly
7. 📈 Watch trends over time, not just snapshots
8. 📝 Document exceptions for systems that can't patch

## 🔐 Security Notes

- Reports contain: Computer names, IPs, OS versions, patch status
- SQL permission needed: db_datareader on SUSDB only
- Store reports securely (NTFS permissions)
- Email only to authorized recipients
- Scheduled tasks run as SYSTEM (or service account)

---

**Print this card and keep it handy!** 📎
