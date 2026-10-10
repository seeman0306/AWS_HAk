-- ========================================================
-- AquaGuard AI — PostgreSQL Database Schema & Initial Seed
-- AI-Powered Water Contamination Reporting & Smart Routing
-- AWS Environmental Hacks Hackathon
-- ========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables in order of dependencies if re-initializing
DROP TABLE IF EXISTS ai_detection_logs CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- 1. Departments Table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    officer_name VARCHAR(100),
    officer_email VARCHAR(100),
    contact_phone VARCHAR(20),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users Table
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('CITIZEN', 'WATER_OFFICER', 'SANITATION_OFFICER', 'ENVIRONMENT_OFFICER', 'OVERALL_ADMIN')),
    department_code VARCHAR(30) REFERENCES departments(code) ON DELETE SET NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Complaints Table
CREATE TABLE complaints (
    id VARCHAR(30) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL,
    user_name VARCHAR(100),
    issue_type VARCHAR(60) NOT NULL,
    issue_title VARCHAR(150) NOT NULL,
    confidence NUMERIC(5, 4) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH')),
    department_code VARCHAR(30) NOT NULL REFERENCES departments(code),
    latitude NUMERIC(10, 6) NOT NULL,
    longitude NUMERIC(10, 6) NOT NULL,
    location_str VARCHAR(100) NOT NULL,
    address TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'ASSIGNED', 'IN PROGRESS', 'RESOLVED', 'REJECTED')),
    image_url TEXT,
    water_source_type VARCHAR(50),
    suspected_contaminant VARCHAR(50),
    citizen_description TEXT,
    ai_predictions JSONB,
    officer_notes TEXT,
    resolution_details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. AI Detection Telemetry Logs Table
CREATE TABLE ai_detection_logs (
    id SERIAL PRIMARY KEY,
    complaint_id VARCHAR(30) REFERENCES complaints(id) ON DELETE SET NULL,
    issue_detected VARCHAR(60),
    confidence NUMERIC(5, 4),
    raw_response JSONB,
    api_endpoint TEXT,
    latency_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indices for High Performance Querying
CREATE INDEX idx_complaints_dept ON complaints(department_code);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_created ON complaints(created_at DESC);
CREATE INDEX idx_complaints_coords ON complaints(latitude, longitude);
CREATE INDEX idx_complaints_issue ON complaints(issue_type);

-- ========================================================
-- SEED DATA
-- ========================================================

-- Insert Municipal Water Departments
INSERT INTO departments (code, name, officer_name, officer_email, contact_phone, description) VALUES
('WATER_SUPPLY', 'Water Supply & Quality Department', 'Dr. Rajesh Verma', 'water@aquaguard.ai', '+91 94421-22001', 'Responsible for municipal drinking water pipelines, quality tests, chlorination, and overhead reservoirs.'),
('SANITATION', 'Sanitation & Sewerage Department', 'Eng. Meera Nair', 'sanitation@aquaguard.ai', '+91 94421-22002', 'Handles domestic sewage, septic tanks, sewage mixing into open wells, and stormwater drains.'),
('ENVIRONMENT', 'Environmental & Water Resources Board', 'Officer Ananya Sen', 'environment@aquaguard.ai', '+91 94421-22003', 'Oversees lakes, urban ponds, wetlands, industrial effluent dumping, and environmental water conservation.');

-- Insert Users (Officers, Admin, Citizens)
INSERT INTO users (id, email, password_hash, full_name, role, department_code, phone) VALUES
('usr_citizen_01', 'citizen@aquaguard.ai', '123456', 'Kishore Sundar (Citizen)', 'CITIZEN', NULL, '+91 98765-43210'),
('usr_officer_water', 'water@aquaguard.ai', '123456', 'Dr. Rajesh Verma (Water Supply)', 'WATER_OFFICER', 'WATER_SUPPLY', '+91 94421-22001'),
('usr_officer_sanitation', 'sanitation@aquaguard.ai', '123456', 'Eng. Meera Nair (Sanitation)', 'SANITATION_OFFICER', 'SANITATION', '+91 94421-22002'),
('usr_officer_environment', 'environment@aquaguard.ai', '123456', 'Officer Ananya Sen (Environment)', 'ENVIRONMENT_OFFICER', 'ENVIRONMENT', '+91 94421-22003'),
('usr_admin_01', 'admin@aquaguard.ai', '123456', 'Municipal Commissioner (Overall Admin)', 'OVERALL_ADMIN', NULL, '+91 98400-11223');

-- Insert Initial Real Demonstration Complaints
INSERT INTO complaints (
    id, user_id, user_name, issue_type, issue_title, confidence, severity, department_code,
    latitude, longitude, location_str, address, status, image_url, water_source_type,
    suspected_contaminant, citizen_description, officer_notes, created_at
) VALUES
(
    'AQG-7821A', 'usr_citizen_01', 'Kishore Sundar',
    'drinking_water_contamination', 'Suspected Contaminated Drinking Water', 0.8920, 'HIGH', 'WATER_SUPPLY',
    9.524500, 77.638200, '9.524500, 77.638200', '14 North Car Street, Ward 3, Water Supply Sector',
    'IN PROGRESS', 'assets/sample_drinking_water.jpg', 'DRINKING_TAP',
    'TURBIDITY_ODOR', 'Tap water coming with brownish discoloration and sulfur odor for 2 days.',
    'Water quality sample collected for laboratory TDS & microbial assay by field team.',
    NOW() - INTERVAL '4 hours'
),
(
    'AQG-3942B', 'usr_citizen_01', 'Kishore Sundar',
    'sewage_in_well', 'Sewage Infiltration into Community Open Well', 0.9410, 'HIGH', 'SANITATION',
    9.516800, 77.629400, '9.516800, 77.629400', 'Opposite Sivan Temple Well, West Bazaar Ward',
    'NEW', 'assets/sample_well_sewage.jpg', 'OPEN_WELL',
    'SEWAGE', 'Broken municipal underground sewer line overflowing directly into historical open well.',
    'Assigned to field sanitary inspector for emergency isolation.',
    NOW() - INTERVAL '7 hours'
),
(
    'AQG-9104C', 'usr_citizen_01', 'Kishore Sundar',
    'sewage_in_pond_lake', 'Sewage & Waste Discharge into Lotus Pond', 0.8850, 'MEDIUM', 'ENVIRONMENT',
    9.531200, 77.645100, '9.531200, 77.645100', 'East Lake Bund Road, Near Botanical Gardens',
    'ASSIGNED', 'assets/sample_pond_pollution.jpg', 'POND_LAKE',
    'FLOATING_WASTE', 'Discharge of untreated wastewater and floating debris noticed at inlet channel.',
    'Notified Environmental Protection Officer for inlet barricade installation.',
    NOW() - INTERVAL '1 day'
),
(
    'AQG-6238D', 'usr_citizen_01', 'Kishore Sundar',
    'sewage_pipe_leakage', 'Underground Sewage Main Rupture', 0.9230, 'HIGH', 'SANITATION',
    9.508900, 77.621500, '9.508900, 77.621500', 'Railway Feeder Road, Ward 11',
    'RESOLVED', 'assets/sample_pipe_leak.jpg', 'DRAINAGE',
    'SEWAGE', 'Sewage water flooding onto pedestrian walkway near municipal borewell point.',
    'Broken 300mm stoneware pipe repaired and replaced with HDPE conduit. Bleaching powder sanitized.',
    NOW() - INTERVAL '2 days'
),
(
    'AQG-4819E', 'usr_citizen_01', 'Kishore Sundar',
    'visible_water_pollution', 'Industrial Sludge Discharge in Irrigation Canal', 0.8650, 'HIGH', 'ENVIRONMENT',
    9.538000, 77.618000, '9.538000, 77.618000', 'Outer Ring Road Canal Bridge, North Agro Zone',
    'NEW', 'assets/sample_pond_pollution.jpg', 'CANAL_RIVER',
    'CHEMICAL_DISCHARGE', 'Dark foamy chemical effluent seen entering agricultural feeder canal.',
    'Immediate inspection dispatched to trace origin unit.',
    NOW() - INTERVAL '18 hours'
);
