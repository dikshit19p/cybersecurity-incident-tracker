# 🛡️ Cybersecurity Incident Tracking System

A professional Security Operations Center (SOC) dashboard for tracking and managing cybersecurity incidents in real-time.

![Dashboard Preview](docs/Screenshots/dashboard.png)

---

## ✨ Features
- ✅ Real-time incident tracking dashboard
- ✅ Complete CRUD operations (Create, Read, Update, Delete)
- ✅ Automated triggers for critical incidents
- ✅ Analyst performance tracking
- ✅ Action timeline & audit trails
- ✅ Professional cybersecurity UI/UX

## 🛠️ Tech Stack
- **Database:** MySQL 8.0
- **Backend:** Python Flask
- **Frontend:** HTML5, CSS3, JavaScript

## 📦 Quick Start
```bash
# Install dependencies
pip install flask mysql-connector-python

# Setup database
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql

# Run application
cd dashboard
python app.py
