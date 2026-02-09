-- =============================================
-- Compliance by Update Classification
-- Shows patch compliance broken down by type
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ComplianceByClassification')
    DROP VIEW vw_ComplianceByClassification
GO

CREATE VIEW vw_ComplianceByClassification
AS
SELECT 
    uc.CategoryTitle AS Classification,
    COUNT(DISTINCT c.ComputerID) AS TotalComputers,
    COUNT(DISTINCT CASE WHEN us.SummarizationState = 2 THEN c.ComputerID END) AS ComputersNeedingUpdates,
    COUNT(DISTINCT CASE WHEN us.SummarizationState = 3 THEN c.ComputerID END) AS ComputersCompliant,
    COUNT(DISTINCT CASE WHEN us.SummarizationState IN (4,5) THEN c.ComputerID END) AS ComputersWithFailures,
    
    -- Updates statistics
    COUNT(CASE WHEN us.SummarizationState = 2 THEN us.UpdateID END) AS UpdatesNeeded,
    COUNT(CASE WHEN us.SummarizationState = 3 THEN us.UpdateID END) AS UpdatesInstalled,
    
    -- Compliance percentage
    CAST(
        (COUNT(DISTINCT CASE WHEN us.SummarizationState = 3 THEN c.ComputerID END) * 100.0) / 
        NULLIF(COUNT(DISTINCT c.ComputerID), 0)
    AS DECIMAL(5,2)) AS CompliancePercentage

FROM dbo.tbComputerTarget c
INNER JOIN dbo.tbUpdateStatusPerComputer us ON c.ComputerID = us.ComputerID
INNER JOIN dbo.tbUpdate u ON us.UpdateID = u.UpdateID
INNER JOIN dbo.tbUpdateCategory uc ON u.UpdateClassificationID = uc.CategoryID

WHERE c.IsDeleted = 0
    AND u.IsDeclined = 0
    AND uc.CategoryTitle IN ('Critical Updates', 'Security Updates', 'Definition Updates', 'Update Rollups', 'Service Packs', 'Updates')

GROUP BY uc.CategoryTitle
GO

GRANT SELECT ON vw_ComplianceByClassification TO PUBLIC
GO
