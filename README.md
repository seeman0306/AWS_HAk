# 💧 AquaGuard AI
### AI-Powered Water Contamination Reporting & Smart Complaint Routing System
**AWS Environmental Hacks Hackathon Solution**

---

## 📌 Executive Summary

**AquaGuard AI** transforms civic water quality monitoring by empowering citizens to instantly report suspected drinking water contamination, sewage infiltration into wells and ponds, and visible wastewater discharge.

Powered by a pre-built **Roboflow Computer Vision AI Model** (`water-pollution-6ekuv-iqw6f/1`), the system inspects uploaded water photographs, detects floating waste and surface pollution signatures, auto-routes grievances to the responsible municipal department (Water Supply, Sanitation, or Environmental Board), and tracks complaints end-to-end on a live GIS hotspot map backed by **PostgreSQL**.

---

## 🌟 Key Features

1. **Citizen Reporting Portal (`citizen.html`)**:
   - 📸 **Camera & Gallery Image Upload**: Capture live photos of contaminated water or upload from device gallery.
   - 📍 **GPS Geotagging & Leaflet Pin Picker**: Automatically requests GPS coordinates with high precision; includes an interactive map with draggable pin for manual corrections.
   - 💧 **5 Core Water Incident Categories**:
     - *Suspected Dirty / Contaminated Drinking Water* (Tap discoloration, odor, turbidity)
     - *Sewage Mixing into Wells* (Open community wells, borewells)
     - *Sewage Entering Ponds & Lakes* (Temple tanks, urban water bodies)
     - *Sewage Pipe Leakage / Burst* (Underground sewer main rupture)
     - *Visible Wastewater Discharge* (Industrial effluent, canal waste)
   - 🤖 **Real Roboflow AI Analysis**: Calls serverless Roboflow computer vision model, displays real predictions, bounding boxes, confidence scores, and mandatory scientific disclaimers (visual observation vs laboratory confirmation).
   - 📋 **Live Grievance Tracking**: Unique complaint ID generation (`AQG-XXXXX`), status progression timeline (*Submitted → Assigned → In Testing → Resolved*), and database history.

2. **Smart Complaint Routing Rules**:
   - Contaminated Drinking Water → **Water Supply & Quality Department**
   - Sewage in Wells / Sewer Pipe Ruptures → **Sanitation & Sewerage Department**
   - Sewage in Ponds / Lakes / Industrial Effluents → **Environmental & Water Resources Board**

3. **Central Governance & Hotspot GIS Map (`admin.html`)**:
   - 📊 **Real-time KPI Dashboard**: Total grievances, open & unresolved incidents, department assignments, and resolution counts computed live from PostgreSQL.
   - 🗺️ **Interactive Incident Hotspot Map**: Color-coded Leaflet OpenStreetMap markers (Deep Blue for drinking water, Amber for wells, Red for pipe leaks, Teal for lakes/ponds) with popups and clustering.
   - 📈 **Department Analytics**: Chart.js visualizations breaking down complaints by department and issue type.
   - 🏛️ **Administrative Triage**: Ability to reassign departments and review audit histories.

4. **Department Officer Consoles**:
   - 🚰 **Water Supply Console (`water-supply-officer.html`)**
   - 🚽 **Sanitation & Sewerage Console (`sanitation-officer.html`)**
   - 🌿 **Environmental Protection Console (`environment-officer.html`)**
   - Features: View department-specific queues, inspect AI predictions, dispatch field teams, record laboratory test notes, and resolve incidents.

5. **Robust Backend & Database Architecture (`backend/`)**:
   - **Express REST API** with parameterized SQL queries.
   - **PostgreSQL 18** database (`aquaguard_db`) with relational schemas for complaints, departments, users, and AI telemetry logs.
   - Resilient multi-tier architecture with automatic memory cache fallback if the database server is offline.

---

## 🔑 Demo Access Credentials

| Role | Email | Password | Assigned Portal |
| :--- | :--- | :--- | :--- |
| **Citizen Reporter** | `citizen@aquaguard.ai` | `123456` | Citizen Reporting (`citizen.html`) |
| **Water Supply Officer** | `water@aquaguard.ai` | `123456` | Water Supply Console (`water-supply-officer.html`) |
| **Sanitation Officer** | `sanitation@aquaguard.ai` | `123456` | Sanitation Console (`sanitation-officer.html`) |
| **Environment Officer** | `environment@aquaguard.ai` | `123456` | Environment Console (`environment-officer.html`) |
| **Overall Administrator** | `admin@aquaguard.ai` | `123456` | Admin Center (`admin.html`) |

*(Quick-fill buttons are provided on the login page `index.html` for single-click access).*

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Node.js** (v18 or v20+)
- **PostgreSQL** (v15 to v18)

### 2. Configure Environment Variables
Copy `.env.example` to `backend/.env` or adjust configuration:
```env
PORT=5000
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/aquaguard_db
ROBOFLOW_API_KEY=tiuCwSKgFd2lAPoP2dlT
ROBOFLOW_MODEL_ID=water-pollution-6ekuv-iqw6f/1
ROBOFLOW_API_URL=https://serverless.roboflow.com
DEMO_MODE=false
```

### 3. Initialize PostgreSQL Database
Execute the schema script in PostgreSQL:
```bash
cd backend
# Database tables and seeds auto-initialize when the server starts,
# or execute manually:
psql -h 127.0.0.1 -p 5433 -U postgres -d aquaguard_db -f schema.sql
```

### 4. Start the Application
```bash
cd backend
npm install
npm start
```
The server will start at:
- **Application Portal**: `http://localhost:5000/`
- **Citizen Portal**: `http://localhost:5000/citizen.html`
- **Admin Center**: `http://localhost:5000/admin.html`
- **Health Check**: `http://localhost:5000/api/health`

### 5. Run Automated Tests
```bash
cd backend
npm test
```

---

## 🤖 Roboflow Model Details

- **Model ID**: `water-pollution-6ekuv-iqw6f/1`
- **Inference Endpoint**: `https://serverless.roboflow.com/water-pollution-6ekuv-iqw6f/1`
- **Task Type**: Object Detection (bounding boxes, class labels, confidence scores)
- **Detected Classes**: `floating waste`, `water pollution`, surface contaminants
- **Scientific Limitation Notice**: Optical detection identifies surface debris and visual turbidity. Visual AI cannot establish microscopic microbiological pathogens (E. coli, cholera) or invisible dissolved heavy metals. AquaGuard AI clearly presents its findings as optical observations and dispatches laboratory sampling.

---

## ☁️ AWS Cloud Integration Blueprint

See [`AWS_DEPLOYMENT.md`](AWS_DEPLOYMENT.md) for full blueprints covering:
- **Amazon RDS for PostgreSQL**: Managed high-availability database.
- **Amazon S3**: Object storage bucket for high-resolution citizen uploads.
- **Amazon SNS**: Instant push notification and SMS alerts to field sanitary inspectors.
- **Amazon ECS (Fargate)**: Containerized serverless deployment.
