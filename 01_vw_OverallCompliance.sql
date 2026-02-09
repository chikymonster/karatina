-- =============================================
-- WSUS Overall Compliance View
-- Provides high-level compliance statistics
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_OverallCompliance')
    DROP VIEW vw_OverallCompliance
GO

CREATE VIEW vw_OverallCompliance
AS
SELECT 
    COUNT(DISTINCT c.ComputerID) AS TotalComputers,
    COUNT(DISTINCT CASE WHEN cs.LastSyncTime >= DATEADD(day, -30, GETDATE()) THEN c.ComputerID END) AS ReportingLast30Days,
    COUNT(DISTINCT CASE WHEN cs.LastSyncTime < DATEADD(day, -30, GETDATE()) THEN c.ComputerID END) AS NotReportingLast30Days,
    COUNT(DISTINCT CASE WHEN cs.LastSyncTime < DATEADD(day, -90, GETDATE()) THEN c.ComputerID END) AS NotReportingLast90Days,
    
    -- Total updates needed across environment
    COUNT(DISTINCT CASE WHEN us.SummarizationState = 2 THEN us.UpdateID END) AS TotalUpdatesNeeded,
    COUNT(DISTINCT CASE WHEN us.SummarizationState = 3 THEN us.UpdateID END) AS TotalUpdatesInstalled,
    
    -- Calculate compliance percentage
    CAST(
        (COUNT(DISTINCT CASE WHEN us.SummarizationState = 3 THEN us.UpdateID END) * 100.0) / 
        NULLIF(COUNT(DISTINCT us.UpdateID), 0)
    AS DECIMAL(5,2)) AS CompliancePercentage

FROM dbo.tbComputerTarget c
LEFT JOIN dbo.tbComputerTargetDetail cs ON c.ComputerID = cs.TargetID
LEFT JOIN dbo.tbUpdateStatusPerComputer us ON c.ComputerID = us.ComputerID
WHERE c.IsDeleted = 0
GO

-- Grant permissions
GRANT SELECT ON vw_OverallCompliance TO PUBLIC
GO
