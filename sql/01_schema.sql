-- ============================================
-- PROJECT: Cybersecurity Incident Tracking System
-- FILE: 01_schema.sql
-- DESCRIPTION: Creates database and all tables
-- ============================================

-- 1. Create the Database
DROP DATABASE IF EXISTS incident_tracker;
CREATE DATABASE incident_tracker;
USE incident_tracker;

-- ============================================
-- 2. Create Tables (Parent Tables First)
-- ============================================

-- Table: Users (Security Team)
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    role ENUM('admin', 'analyst', 'reporter', 'viewer') DEFAULT 'reporter',
    department VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Assets (Servers, Laptops, etc.)
CREATE TABLE Assets (
    asset_id INT PRIMARY KEY AUTO_INCREMENT,
    asset_name VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45) UNIQUE,
    asset_type ENUM('server', 'workstation', 'network', 'database', 'cloud'),
    location VARCHAR(100),
    criticality ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    owner_id INT,
    FOREIGN KEY (owner_id) REFERENCES Users(user_id)
);

-- Table: Categories (Types of Incidents)
CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    default_severity ENUM('low', 'medium', 'high', 'critical')
);

-- ============================================
-- 3. Create Tables (Child Tables)
-- ============================================

-- Table: Incidents (Core Tracking Table)
CREATE TABLE Incidents (
    incident_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    status ENUM('reported', 'investigating', 'contained', 'resolved', 'closed', 'false_positive') DEFAULT 'reported',
    priority INT DEFAULT 3,
    reported_by INT NOT NULL,
    assigned_to INT,
    asset_id INT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    closed_at TIMESTAMP NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (reported_by) REFERENCES Users(user_id),
    FOREIGN KEY (assigned_to) REFERENCES Users(user_id),
    FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

-- Table: Actions (Response Trail)
CREATE TABLE Actions (
    action_id INT PRIMARY KEY AUTO_INCREMENT,
    incident_id INT NOT NULL,
    action_type ENUM('investigation', 'containment', 'eradication', 'recovery', 'communication', 'documentation'),
    action_description TEXT NOT NULL,
    performed_by INT NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    time_spent_minutes INT,
    FOREIGN KEY (incident_id) REFERENCES Incidents(incident_id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES Users(user_id)
);

-- Table: Evidence (Attachments)
CREATE TABLE Evidence (
    evidence_id INT PRIMARY KEY AUTO_INCREMENT,
    incident_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),
    file_size_kb INT,
    uploaded_by INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    FOREIGN KEY (incident_id) REFERENCES Incidents(incident_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES Users(user_id)
);

-- ============================================
-- 4. Create Indexes (For Performance)
-- ============================================
CREATE INDEX idx_incident_status ON Incidents(status);
CREATE INDEX idx_incident_severity ON Incidents(severity);
CREATE INDEX idx_incident_date ON Incidents(detected_at);