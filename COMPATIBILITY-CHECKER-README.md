# WSUS Compatibility Checker

A comprehensive PowerShell script to test if your WSUS/SQL Server environment is compatible with the [WSUS Reporting Solution](https://github.com/yourusername/wsus-reporting).

## Features

- **10 Comprehensive Tests** covering all critical compatibility requirements
- **Zero Installation** - just download and run
- **Both Authentication Types** - Windows Auth and SQL Server Auth supported
- **Detailed Results** - clear pass/fail/warning for each test
- **Export Results** - JSON export for documentation
- **Exit Codes** - perfect for CI/CD pipelines

## Quick Start

### Download and Run

```powershell
# Windows Authentication
.\Test-WSUSCompatibility.ps1 -SqlServer "WSUSSQL01"

# SQL Server Authentication
.\Test-WSUSCompatibility.ps1 -SqlServer "WSUSSQL01" `
    -UseSqlAuth `
    -SqlUsername "wsus_reader" `
    -SqlPassword "YourPassword123"
```

## What It Tests

| Test # | Component | What It Checks |
|--------|-----------|----------------|
| 1 | PowerShell Version | Verifies PowerShell 5.1+ |
| 2 | Network Connectivity | Tests port 1433 to SQL Server |
| 3 | SQL Server Connection | Validates credentials and connectivity |
| 4 | SUSDB Database | Confirms SUSDB exists and is accessible |
| 5 | WSUS Version | Detects WSUS 3.0/4.0/6.0 |
| 6 | Required Tables | Checks for 9 critical WSUS tables |
| 7 | Required Columns | Validates schema compatibility |
| 8 | Sample Queries | Tests complex JOIN and aggregation |
| 9 | WSUS Data | Verifies database has actual data |
| 10 | Permissions | Confirms SELECT and CREATE VIEW rights |

## Requirements

- Windows Server 2008 R2 or later
- PowerShell 5.1 or later (built into Server 2016+)
- Network access to SQL Server (port 1433)
- SQL account with `db_datareader` role on SUSDB
  - For installation testing: Also needs `db_ddladmin` role

## Usage Examples

### Basic Test

```powershell
# Test with Windows Authentication
.\Test-WSUSCompatibility.ps1 -SqlServer "WSUSSQL01"
```

### Test with SQL Authentication

```powershell
# Test with SQL Server account
.\Test-WSUSCompatibility.ps1 `
    -SqlServer "WSUSSQL01" `
    -UseSqlAuth `
    -SqlUsername "wsus_reader" `
    -SqlPassword "ReadOnlyPassword123"
```

### Export Results

```powershell
# Export detailed results to JSON
.\Test-WSUSCompatibility.ps1 `
    -SqlServer "WSUSSQL01" `
    -ExportPath "C:\Temp\compatibility-results.json"
```

### Quiet Mode (for Scripts)

```powershell
# Run in quiet mode with exit codes only
.\Test-WSUSCompatibility.ps1 -SqlServer "WSUSSQL01" -Quiet

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "Compatible!"
} else {
    Write-Host "Not compatible - exit code: $LASTEXITCODE"
}
```

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | EXCELLENT / GOOD | All tests passed, ready for installation |
| 1 | MARGINAL | Some failures, address issues before proceeding |
| 2 | INCOMPATIBLE | Critical failures, fix issues first |

## Sample Output

```
==========================================
  WSUS Compatibility Checker
==========================================

[1/10] PowerShell Version...
  [PASS] Version 5.1

[2/10] Network Connectivity...
  [PASS] Port 1433 accessible

[3/10] SQL Server Connection...
  [PASS] Connected successfully
  [PASS] SQL Server 2019

[4/10] SUSDB Database...
  [PASS] Database accessible

[5/10] WSUS Version...
  [PASS] Version 4.0.9200.21732 detected

[6/10] Required Tables...
  [PASS] All 9 tables exist

[7/10] Required Columns...
  [PASS] All critical columns exist

[8/10] Sample Queries...
  [PASS] Complex JOIN works

[9/10] WSUS Data...
  [PASS] Found 247 computers

[10/10] Permissions...
  [PASS] Has SELECT permission
  [PASS] Can create views (for install)

==========================================
  SUMMARY
==========================================
  Passed:  12
  Warnings: 0
  Failed:  0

  Status: EXCELLENT - Ready!
```

## Common Issues

### Cannot Connect to SQL Server

```
[FAIL] Cannot reach port 1433
```

**Solutions:**
- Verify SQL Server service is running
- Check firewall allows port 1433
- Confirm SQL Server name/IP is correct
- Test: `Test-NetConnection -ComputerName WSUSSQL01 -Port 1433`

### Login Failed

```
[FAIL] Login failed for user 'wsus_reader'
```

**Solutions:**
- Verify username/password are correct
- Check SQL Server authentication mode (should be Mixed Mode)
- Confirm login is enabled: `ALTER LOGIN [wsus_reader] ENABLE`

### Missing Tables

```
[FAIL] Missing: tbComputerTarget, tbUpdate
```

**Solutions:**
- WSUS database may be corrupted
- Wrong database (should be SUSDB, not WID)
- Very old WSUS version (pre-3.0)

### No Data Found

```
[WARN] No computers in WSUS
```

**Solutions:**
- WSUS hasn't synchronized yet
- No clients have reported in
- Check WSUS synchronization: `Get-WsusServer | Get-WsusSubscription`

### Cannot Create Views

```
[WARN] Cannot create views
```

**Solutions:**
- Use account with `db_ddladmin` role for installation
- Or use sysadmin account for initial setup
- This account can still generate reports (doesn't need CREATE VIEW for that)

## Compatibility Matrix

| WSUS Version | Windows Server | SQL Server | Status |
|--------------|----------------|------------|--------|
| WSUS 6.0 | Server 2022 | 2016-2022 | ✅ Fully Supported |
| WSUS 4.0 | Server 2016/2019 | 2012-2019 | ✅ Fully Supported |
| WSUS 3.0 SP2 | Server 2012/2012 R2 | 2008 R2-2014 | ✅ Should Work |
| WSUS 3.0 | Server 2008 R2 | 2008 R2 | ⚠️ Marginal |
| WSUS 2.0 | Server 2003 | 2005 | ❌ Not Supported |

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Test WSUS Compatibility
  shell: powershell
  run: |
    .\Test-WSUSCompatibility.ps1 `
      -SqlServer "${{ secrets.SQL_SERVER }}" `
      -UseSqlAuth `
      -SqlUsername "${{ secrets.SQL_USERNAME }}" `
      -SqlPassword "${{ secrets.SQL_PASSWORD }}" `
      -ExportPath "compatibility-results.json"
    
- name: Upload Results
  uses: actions/upload-artifact@v2
  with:
    name: compatibility-results
    path: compatibility-results.json
```

### Azure DevOps Pipeline

```yaml
- task: PowerShell@2
  displayName: 'WSUS Compatibility Check'
  inputs:
    filePath: 'Test-WSUSCompatibility.ps1'
    arguments: >
      -SqlServer $(SqlServer)
      -UseSqlAuth
      -SqlUsername $(SqlUsername)
      -SqlPassword $(SqlPassword)
      -ExportPath $(Build.ArtifactStagingDirectory)/compatibility.json
    
- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.ArtifactStagingDirectory)'
    ArtifactName: 'compatibility-results'
```

## Troubleshooting

### Script Won't Run

```powershell
# Check execution policy
Get-ExecutionPolicy

# Allow scripts temporarily
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Or run with bypass
powershell.exe -ExecutionPolicy Bypass -File .\Test-WSUSCompatibility.ps1 -SqlServer "SERVER"
```

### Firewall Blocking

```powershell
# Test SQL Server port manually
Test-NetConnection -ComputerName "WSUSSQL01" -Port 1433

# Check Windows Firewall
Get-NetFirewallRule -DisplayName "*SQL*" | Where-Object {$_.Enabled -eq $true}
```

### Windows Internal Database (WID)

```powershell
# Check if using WID instead of SQL Server
Get-WsusServer | Select-Object DatabaseServerName

# If shows: \\.\pipe\MICROSOFT##WID\...
# Then you're using WID - migrate to SQL Server first
```

## Development

### Running Tests

```powershell
# Test against multiple servers
$servers = @("WSUSSQL01", "WSUSSQL02", "WSUSSQL03")

foreach ($server in $servers) {
    Write-Host "Testing $server..." -ForegroundColor Cyan
    .\Test-WSUSCompatibility.ps1 -SqlServer $server -Quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$server: COMPATIBLE" -ForegroundColor Green
    } else {
        Write-Host "$server: INCOMPATIBLE (code $LASTEXITCODE)" -ForegroundColor Red
    }
}
```

### Extending Tests

To add a new test, follow this pattern:

```powershell
# Add to main execution section
if (-not $Quiet) { Write-Host "[11/11] Your New Test..." -ForegroundColor Cyan }
$result = Test-SqlQuery "YOUR SQL QUERY HERE"
if ($result.Success) {
    Write-TestResult "Your Test" "Pass" "Success message"
} else {
    Write-TestResult "Your Test" "Fail" "Failure message"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-test`)
3. Commit your changes (`git commit -am 'Add new compatibility test'`)
4. Push to the branch (`git push origin feature/new-test`)
5. Create a Pull Request

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/wsus-reporting/issues)
- **Documentation**: [Full Documentation](https://github.com/yourusername/wsus-reporting/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/wsus-reporting/discussions)

## Credits

Created by [Your Name](https://github.com/yourusername)

Part of the [WSUS Reporting Solution](https://github.com/yourusername/wsus-reporting) project.

## Changelog

### v1.0 (2026-02-12)
- Initial release
- 10 comprehensive compatibility tests
- Windows and SQL Server authentication support
- JSON export functionality
- CI/CD integration examples
