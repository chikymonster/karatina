-- =============================================
-- Non-Reporting Systems
-- Computers that haven't checked in recently
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NonReportingSystems')
    DROP VIEW vw_NonReportingSystems
GO

CREATE VIEW vw_NonReportingSystems
AS
SELECT 
    c.FullDomainName AS ComputerName,
    cs.LastSyncTime,
    DATEDIFF(day, cs.LastSyncTime, GETDATE()) AS DaysSinceLastSync,
    cs.OSDescription AS OperatingSystem,
    cs.ComputerMake AS Manufacturer,
    cs.ComputerModel AS Model,
    cs.IPAddress,
    
    -- Categorize by how stale the data is
    CASE 
        WHEN cs.LastSyncTime IS NULL THEN 'Never Reported'
        WHEN DATEDIFF(day, cs.LastSyncTime, GETDATE()) >= 90 THEN 'Critical (90+ days)'
        WHEN DATEDIFF(day, cs.LastSyncTime, GETDATE()) >= 60 THEN 'High (60-89 days)'
        WHEN DATEDIFF(day, cs.LastSyncTime, GETDATE()) >= 30 THEN 'Medium (30-59 days)'
        ELSE 'Recent'
    END AS Status,
    
    -- Computer group membership
    COALESCE(tg.Name, 'Unassigned') AS ComputerGroup

FROM dbo.tbComputerTarget c
LEFT JOIN dbo.tbComputerTargetDetail cs ON c.ComputerID = cs.TargetID
LEFT JOIN dbo.tbComputerTargetInGroup ctg ON c.ComputerID = ctg.ComputerTargetID
LEFT JOIN dbo.tbGroup tg ON ctg.GroupID = tg.GroupID

WHERE c.IsDeleted = 0
    AND (cs.LastSyncTime IS NULL OR cs.LastSyncTime < DATEADD(day, -30, GETDATE()))
GO

GRANT SELECT ON vw_NonReportingSystems TO PUBLIC
GO
