-- ============================================
-- PROJECT: Cybersecurity Incident Tracking System
-- FILE: 03_queries.sql
-- DESCRIPTION: Comprehensive SQL queries for reporting and analysis
-- ============================================

USE incident_tracker;

-- ============================================
-- QUERY 1: List All Active Incidents
-- ============================================
-- Shows all incidents that are not yet resolved
SELECT 
    i.incident_id,
    i.title,
    i.severity,
    i.status,
    i.priority,
    u.username AS reported_by,
    a.username AS assigned_to,
    i.detected_at
FROM Incidents i
JOIN Users u ON i.reported_by = u.user_id
LEFT JOIN Users a ON i.assigned_to = a.user_id
WHERE i.status NOT IN ('resolved', 'closed', 'false_positive')
ORDER BY 
    CASE i.severity 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END,
    i.priority;

-- ============================================
-- QUERY 2: Critical Incidents Requiring Immediate Attention
-- ============================================
SELECT 
    i.incident_id,
    i.title,
    i.description,
    i.severity,
    i.status,
    asset.asset_name,
    asset.ip_address,
    TIMESTAMPDIFF(HOUR, i.detected_at, NOW()) AS hours_open
FROM Incidents i
LEFT JOIN Assets asset ON i.asset_id = asset.asset_id
WHERE i.severity = 'critical' 
AND i.status NOT IN ('resolved', 'closed')
ORDER BY i.detected_at ASC;

-- ============================================
-- QUERY 3: Incidents by Category (Summary Report)
-- ============================================
SELECT 
    c.name AS category,
    COUNT(i.incident_id) AS total_incidents,
    SUM(CASE WHEN i.severity = 'critical' THEN 1 ELSE 0 END) AS critical_count,
    SUM(CASE WHEN i.severity = 'high' THEN 1 ELSE 0 END) AS high_count,
    SUM(CASE WHEN i.status = 'resolved' THEN 1 ELSE 0 END) AS resolved_count
FROM Categories c
LEFT JOIN Incidents i ON c.category_id = i.category_id
GROUP BY c.category_id, c.name
ORDER BY total_incidents DESC;

-- ============================================
-- QUERY 4: Analyst Performance Dashboard
-- ============================================
SELECT 
    u.user_id,
    u.username,
    u.department,
    COUNT(i.incident_id) AS total_assigned,
    SUM(CASE WHEN i.status = 'resolved' THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN i.status = 'investigating' THEN 1 ELSE 0 END) AS in_progress,
    ROUND(
        AVG(CASE WHEN i.status = 'resolved' THEN 
            TIMESTAMPDIFF(HOUR, i.detected_at, i.resolved_at) 
        END), 2
    ) AS avg_resolution_hours
FROM Users u
LEFT JOIN Incidents i ON u.user_id = i.assigned_to
WHERE u.role = 'analyst'
GROUP BY u.user_id, u.username, u.department
HAVING total_assigned > 0
ORDER BY resolved DESC;

-- ============================================
-- QUERY 5: Assets Most Targeted by Attacks
-- ============================================
SELECT 
    a.asset_name,
    a.ip_address,
    a.asset_type,
    a.criticality,
    COUNT(i.incident_id) AS incident_count,
    GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS attack_types
FROM Assets a
JOIN Incidents i ON a.asset_id = i.asset_id
JOIN Categories c ON i.category_id = c.category_id
GROUP BY a.asset_id, a.asset_name, a.ip_address, a.asset_type, a.criticality
ORDER BY incident_count DESC;

-- ============================================
-- QUERY 6: Incident Timeline with Actions
-- ============================================
-- Shows complete history of an incident (use incident_id = 1)
SELECT 
    i.title,
    i.severity,
    i.status,
    i.detected_at,
    act.action_type,
    act.action_description,
    u.username AS performed_by,
    act.performed_at,
    act.time_spent_minutes
FROM Incidents i
LEFT JOIN Actions act ON i.incident_id = act.incident_id
LEFT JOIN Users u ON act.performed_by = u.user_id
WHERE i.incident_id = 1
ORDER BY act.performed_at;

-- ============================================
-- QUERY 7: Monthly Incident Trend
-- ============================================
SELECT 
    DATE_FORMAT(detected_at, '%Y-%m') AS month,
    COUNT(*) AS total_incidents,
    SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) AS critical,
    SUM(CASE WHEN severity = 'high' THEN 1 ELSE 0 END) AS high,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) AS resolved
FROM Incidents
GROUP BY DATE_FORMAT(detected_at, '%Y-%m')
ORDER BY month DESC;

-- ============================================
-- QUERY 8: Overdue Incidents (Not Updated in 48 Hours)
-- ============================================
SELECT 
    i.incident_id,
    i.title,
    i.severity,
    i.status,
    u.username AS assigned_to,
    i.detected_at,
    TIMESTAMPDIFF(HOUR, i.detected_at, NOW()) AS hours_since_detection,
    CASE 
        WHEN TIMESTAMPDIFF(HOUR, i.detected_at, NOW()) > 72 THEN 'OVERDUE'
        WHEN TIMESTAMPDIFF(HOUR, i.detected_at, NOW()) > 48 THEN 'WARNING'
        ELSE 'OK'
    END AS status_alert
FROM Incidents i
LEFT JOIN Users u ON i.assigned_to = u.user_id
WHERE i.status NOT IN ('resolved', 'closed', 'false_positive')
AND i.detected_at < DATE_SUB(NOW(), INTERVAL 48 HOUR)
ORDER BY i.detected_at ASC;

-- ============================================
-- QUERY 9: Department-wise Incident Report
-- ============================================
SELECT 
    u.department,
    COUNT(i.incident_id) AS incidents_reported,
    SUM(CASE WHEN i.severity IN ('high', 'critical') THEN 1 ELSE 0 END) AS high_severity_count
FROM Users u
JOIN Incidents i ON u.user_id = i.reported_by
GROUP BY u.department
ORDER BY incidents_reported DESC;

-- ============================================
-- QUERY 10: Top 5 Slowest Resolved Incidents
-- ============================================
SELECT 
    i.incident_id,
    i.title,
    i.severity,
    u.username AS resolved_by,
    TIMESTAMPDIFF(HOUR, i.detected_at, i.resolved_at) AS resolution_hours,
    i.detected_at,
    i.resolved_at
FROM Incidents i
LEFT JOIN Users u ON i.assigned_to = u.user_id
WHERE i.status = 'resolved' 
AND i.resolved_at IS NOT NULL
ORDER BY resolution_hours DESC
LIMIT 5;

-- ============================================
-- QUERY 11: Evidence Summary per Incident
-- ============================================
SELECT 
    i.incident_id,
    i.title,
    COUNT(e.evidence_id) AS evidence_count,
    SUM(e.file_size_kb) AS total_size_kb,
    GROUP_CONCAT(DISTINCT e.file_type SEPARATOR ', ') AS file_types
FROM Incidents i
LEFT JOIN Evidence e ON i.incident_id = e.incident_id
GROUP BY i.incident_id, i.title
HAVING evidence_count > 0
ORDER BY evidence_count DESC;

-- ============================================
-- QUERY 12: Security Team Workload Distribution
-- ============================================
SELECT 
    u.username,
    u.role,
    COUNT(CASE WHEN i.status = 'investigating' THEN 1 END) AS investigating,
    COUNT(CASE WHEN i.status = 'contained' THEN 1 END) AS contained,
    COUNT(CASE WHEN i.status = 'resolved' THEN 1 END) AS resolved,
    COUNT(i.incident_id) AS total_incidents
FROM Users u
LEFT JOIN Incidents i ON u.user_id = i.assigned_to
GROUP BY u.user_id, u.username, u.role
ORDER BY total_incidents DESC;