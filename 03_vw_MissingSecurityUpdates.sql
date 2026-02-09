-- =============================================
-- Missing Security Updates Report
-- Shows which critical patches are missing
-- =============================================
USE SUSDB
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_MissingSecurityUpdates')
    DROP VIEW vw_MissingSecurityUpdates
GO

CREATE VIEW vw_MissingSecurityUpdates
AS
SELECT 
    u.UpdateID,
    p.DefaultTitle AS UpdateTitle,
    uc.CategoryTitle AS Classification,
    u.CreationDate AS ReleaseDate,
    DATEDIFF(day, u.CreationDate, GETDATE()) AS DaysSinceRelease,
    COUNT(DISTINCT us.ComputerID) AS ComputersAffected,
    
    -- Severity based on classification
    CASE 
        WHEN uc.CategoryTitle = 'Critical Updates' THEN 'Critical'
        WHEN uc.CategoryTitle = 'Security Updates' THEN 'High'
        ELSE 'Medium'
    END AS Severity,
    
    -- KB Article number
    COALESCE(ka.ArticleID, 'N/A') AS KBArticle

FROM dbo.tbUpdate u
INNER JOIN dbo.tbUpdateCategory uc ON u.UpdateClassificationID = uc.CategoryID
INNER JOIN dbo.tbProperty p ON u.LocalUpdateID = p.LocalUpdateID AND p.PropertyID = 1
LEFT JOIN dbo.tbKBArticleForUpdate ka ON u.LocalUpdateID = ka.LocalUpdateID
INNER JOIN dbo.tbUpdateStatusPerComputer us ON u.UpdateID = us.UpdateID

WHERE us.SummarizationState = 2  -- Needed
    AND u.IsDeclined = 0
    AND u.IsSuperseded = 0
    AND uc.CategoryTitle IN ('Critical Updates', 'Security Updates')

GROUP BY 
    u.UpdateID,
    p.DefaultTitle,
    uc.CategoryTitle,
    u.CreationDate,
    ka.ArticleID

HAVING COUNT(DISTINCT us.ComputerID) > 0
GO

GRANT SELECT ON vw_MissingSecurityUpdates TO PUBLIC
GO
