-- =============================================
-- Server vs Workstation Compliance
-- Separate compliance metrics by system type
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ComplianceBySystemType')
    DROP VIEW vw_ComplianceBySystemType
GO

CREATE VIEW vw_ComplianceBySystemType
AS
SELECT 
    CASE 
        WHEN cs.OSDescription LIKE '%Server%' THEN 'Server'
        WHEN cs.OSDescription LIKE '%Windows 10%' THEN 'Windows 10 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 11%' THEN 'Windows 11 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 7%' THEN 'Windows 7 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 8%' THEN 'Windows 8 Workstation'
        ELSE 'Other'
    END AS SystemType,
    
    COUNT(DISTINCT c.ComputerID) AS TotalSystems,
    
    -- Systems needing updates
    COUNT(DISTINCT CASE 
        WHEN EXISTS (
            SELECT 1 FROM dbo.tbUpdateStatusPerComputer us2
            WHERE us2.ComputerID = c.ComputerID 
            AND us2.SummarizationState = 2
        )
        THEN c.ComputerID 
    END) AS SystemsNeedingUpdates,
    
    -- Fully compliant systems
    COUNT(DISTINCT CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM dbo.tbUpdateStatusPerComputer us2
            WHERE us2.ComputerID = c.ComputerID 
            AND us2.SummarizationState = 2
        )
        THEN c.ComputerID 
    END) AS CompliantSystems,
    
    -- Systems with failures
    COUNT(DISTINCT CASE 
        WHEN EXISTS (
            SELECT 1 FROM dbo.tbUpdateStatusPerComputer us2
            WHERE us2.ComputerID = c.ComputerID 
            AND us2.SummarizationState IN (4,5)
        )
        THEN c.ComputerID 
    END) AS SystemsWithFailures,
    
    -- Compliance percentage
    CAST(
        (COUNT(DISTINCT CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM dbo.tbUpdateStatusPerComputer us2
                WHERE us2.ComputerID = c.ComputerID 
                AND us2.SummarizationState = 2
            )
            THEN c.ComputerID 
        END) * 100.0) / 
        NULLIF(COUNT(DISTINCT c.ComputerID), 0)
    AS DECIMAL(5,2)) AS CompliancePercentage,
    
    -- Reporting status
    COUNT(DISTINCT CASE WHEN cs.LastSyncTime >= DATEADD(day, -30, GETDATE()) THEN c.ComputerID END) AS ReportingLast30Days,
    COUNT(DISTINCT CASE WHEN cs.LastSyncTime < DATEADD(day, -30, GETDATE()) OR cs.LastSyncTime IS NULL THEN c.ComputerID END) AS NotReportingLast30Days

FROM dbo.tbComputerTarget c
LEFT JOIN dbo.tbComputerTargetDetail cs ON c.ComputerID = cs.TargetID

WHERE c.IsDeleted = 0

GROUP BY 
    CASE 
        WHEN cs.OSDescription LIKE '%Server%' THEN 'Server'
        WHEN cs.OSDescription LIKE '%Windows 10%' THEN 'Windows 10 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 11%' THEN 'Windows 11 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 7%' THEN 'Windows 7 Workstation'
        WHEN cs.OSDescription LIKE '%Windows 8%' THEN 'Windows 8 Workstation'
        ELSE 'Other'
    END

HAVING COUNT(DISTINCT c.ComputerID) > 0
GO

GRANT SELECT ON vw_ComplianceBySystemType TO PUBLIC
GO
