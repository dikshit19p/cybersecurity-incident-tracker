-- ============================================
-- PROJECT: Cybersecurity Incident Tracking System
-- FILE: 02_sample_data.sql
-- DESCRIPTION: Inserts sample data into all tables
-- ============================================

USE incident_tracker;

-- ============================================
-- 1. Insert Users (Security Team)
-- ============================================
INSERT INTO Users (username, email, role, department, password_hash) VALUES
('admin', 'admin@company.com', 'admin', 'IT Security', 'hash_admin_123'),
('alice', 'alice@company.com', 'analyst', 'SOC', 'hash_alice_456'),
('bob', 'bob@company.com', 'analyst', 'SOC', 'hash_bob_789'),
('charlie', 'charlie@company.com', 'reporter', 'HR', 'hash_charlie_101'),
('david', 'david@company.com', 'reporter', 'Finance', 'hash_david_202');

-- ============================================
-- 2. Insert Assets (Company Devices)
-- ============================================
INSERT INTO Assets (asset_name, ip_address, asset_type, location, criticality, owner_id) VALUES
('Web Server 01', '192.168.1.10', 'server', 'Data Center A', 'critical', 1),
('Database Server', '192.168.1.20', 'database', 'Data Center A', 'critical', 1),
('HR Laptop 01', '192.168.1.50', 'workstation', 'Office Floor 2', 'medium', 4),
('Firewall Main', '192.168.1.1', 'network', 'Data Center A', 'critical', 1),
('Finance PC 03', '192.168.1.60', 'workstation', 'Office Floor 3', 'high', 5);

-- ============================================
-- 3. Insert Categories (Threat Types)
-- ============================================
INSERT INTO Categories (name, description, default_severity) VALUES
('Malware', 'Virus, trojan, ransomware infections', 'high'),
('Phishing', 'Suspicious emails or social engineering', 'medium'),
('Unauthorized Access', 'Failed login attempts or privilege escalation', 'high'),
('Data Breach', 'Sensitive data exposure or theft', 'critical'),
('DDoS', 'Distributed denial of service attacks', 'high'),
('Policy Violation', 'Internal security policy breaches', 'low');

-- ============================================
-- 4. Insert Incidents (The Core Data)
-- ============================================
INSERT INTO Incidents (title, description, category_id, severity, status, reported_by, assigned_to, asset_id, priority) VALUES
('Suspicious Login Attempts', 'Multiple failed logins from external IP 203.0.113.45 on Web Server', 3, 'high', 'investigating', 4, 2, 1, 2),
('Phishing Email Reported', 'Employee received suspicious email requesting credentials', 2, 'medium', 'resolved', 4, 3, 3, 3),
('Ransomware Detected', 'Encryption activity detected on HR Laptop', 1, 'critical', 'contained', 2, 2, 3, 1),
('Unusual Data Export', 'Large data transfer from Database Server after hours', 4, 'critical', 'reported', 1, 2, 2, 1),
('Firewall Rule Violation', 'Unauthorized port scan detected from internal IP', 6, 'low', 'closed', 1, 3, 4, 4),
('DDoS Attack Attempt', 'High traffic spike detected on Web Server', 5, 'high', 'resolved', 2, 2, 1, 2),
('Lost Company Laptop', 'Employee reported laptop stolen from cafe', 3, 'medium', 'investigating', 5, 3, 5, 3),
('Suspicious Process Running', 'Unknown process running on Finance PC', 1, 'high', 'reported', 5, 2, 5, 2);

-- ============================================
-- 5. Insert Actions (Response Steps)
-- ============================================
-- Actions for Incident #1 (Suspicious Login)
INSERT INTO Actions (incident_id, action_type, action_description, performed_by, time_spent_minutes) VALUES
(1, 'investigation', 'Reviewed firewall logs for source IP 203.0.113.45', 2, 30),
(1, 'containment', 'Blocked suspicious IP at firewall level', 2, 15);

-- Actions for Incident #2 (Phishing)
INSERT INTO Actions (incident_id, action_type, action_description, performed_by, time_spent_minutes) VALUES
(2, 'investigation', 'Analyzed email headers and attachments', 3, 45),
(2, 'eradication', 'Deleted phishing email from all mailboxes', 3, 20),
(2, 'documentation', 'Added sender domain to blocklist', 3, 10);

-- Actions for Incident #3 (Ransomware)
INSERT INTO Actions (incident_id, action_type, action_description, performed_by, time_spent_minutes) VALUES
(3, 'containment', 'Disconnected HR Laptop from network immediately', 2, 10),
(3, 'eradication', 'Reimaged laptop from clean backup', 2, 120);

-- ============================================
-- 6. Insert Evidence (Files/Logs)
-- ============================================
INSERT INTO Evidence (incident_id, file_name, file_type, file_size_kb, uploaded_by, description) VALUES
(1, 'firewall_log_20240320.txt', 'text', 150, 2, 'Firewall logs showing blocked IPs'),
(3, 'ransomware_note.txt', 'text', 5, 2, 'Ransom note found on desktop'),
(3, 'system_scan_report.pdf', 'pdf', 2500, 2, 'Antivirus scan results'),
(4, 'database_audit_log.csv', 'csv', 500, 1, 'Database access logs for suspicious timeframe');