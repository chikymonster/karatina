-- =============================================
-- Top Non-Compliant Systems
-- Worst offenders by missing patch count
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_TopNonCompliantSystems')
    DROP VIEW vw_TopNonCompliantSystems
GO

CREATE VIEW vw_TopNonCompliantSystems
AS
SELECT TOP 100
    c.FullDomainName AS ComputerName,
    cs.OSDescription AS OperatingSystem,
    cs.LastSyncTime,
    DATEDIFF(day, cs.LastSyncTime, GETDATE()) AS DaysSinceLastSync,
    
    -- Count of missing updates by severity
    COUNT(CASE WHEN uc.CategoryTitle = 'Critical Updates' AND us.SummarizationState = 2 THEN 1 END) AS MissingCritical,
    COUNT(CASE WHEN uc.CategoryTitle = 'Security Updates' AND us.SummarizationState = 2 THEN 1 END) AS MissingSecurity,
    COUNT(CASE WHEN us.SummarizationState = 2 THEN 1 END) AS TotalMissingUpdates,
    
    -- Failed updates
    COUNT(CASE WHEN us.SummarizationState IN (4,5) THEN 1 END) AS FailedUpdates,
    
    -- Computer group
    COALESCE(tg.Name, 'Unassigned') AS ComputerGroup,
    
    -- Risk score (weighted by severity)
    (COUNT(CASE WHEN uc.CategoryTitle = 'Critical Updates' AND us.SummarizationState = 2 THEN 1 END) * 10) +
    (COUNT(CASE WHEN uc.CategoryTitle = 'Security Updates' AND us.SummarizationState = 2 THEN 1 END) * 5) +
    (COUNT(CASE WHEN us.SummarizationState = 2 THEN 1 END)) AS RiskScore

FROM dbo.tbComputerTarget c
LEFT JOIN dbo.tbComputerTargetDetail cs ON c.ComputerID = cs.TargetID
LEFT JOIN dbo.tbUpdateStatusPerComputer us ON c.ComputerID = us.ComputerID
LEFT JOIN dbo.tbUpdate u ON us.UpdateID = u.UpdateID
LEFT JOIN dbo.tbUpdateCategory uc ON u.UpdateClassificationID = uc.CategoryID
LEFT JOIN dbo.tbComputerTargetInGroup ctg ON c.ComputerID = ctg.ComputerTargetID
LEFT JOIN dbo.tbGroup tg ON ctg.GroupID = tg.GroupID

WHERE c.IsDeleted = 0
    AND (u.IsDeclined = 0 OR u.IsDeclined IS NULL)
    AND (u.IsSuperseded = 0 OR u.IsSuperseded IS NULL)

GROUP BY 
    c.FullDomainName,
    cs.OSDescription,
    cs.LastSyncTime,
    tg.Name

HAVING COUNT(CASE WHEN us.SummarizationState = 2 THEN 1 END) > 0

ORDER BY RiskScore DESC, TotalMissingUpdates DESC
GO

GRANT SELECT ON vw_TopNonCompliantSystems TO PUBLIC
GO
