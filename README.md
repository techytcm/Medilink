MediLink: Healthcare Assistant
A full-stack, AI-inspired healthcare platform built with Python (Flask), MySQL,Tailwind CSS and the Inter font. Features patient/doctor/admin roles, symptomanalysis, risk scoring, specialist recommendations, appointment management, a healthcarechatbot, notifications, audit logs, and a polished light/dark UI.

✨ Features
Authentication — register, login, logout, password reset, bcrypt hashing, session management, role-based redirects
Patients — dashboard, symptom analysis with AI engine, risk level + specialist recommendation, appointment booking & history, prediction history, MediBot chatbot, notifications, feedback, profile, settings
Doctors — dashboard, appointment management, patient detail view, consultation notes
Admins — dashboard, user & doctor management, reports, audit logs, feedback review
Medical Engine — rule-based symptom matching with NLP-light preprocessing, designed for easy ML integration
Design — Inter font, green light/dark theme, responsive mobile-first layout, 2D SVG hero illustration
🛠 Tech Stack
Layer	Technology
Backend	Python 3.10+, Flask 3, PyMySQL, bcrypt
Database	MySQL 8.0+
Frontend	HTML5, Tailwind CSS (CDN), vanilla JS, Jinja2
Font	Inter (Google Fonts)
🚀 Setup
1. Clone & create a virtual environment
git clone <your-repo-url> medilinkcd medilinkpython -m venv venvsource venv/bin/activate   # Windows: venv\Scripts\activate
2. Install dependencies
bash

pip install -r requirements.txt
3. Configure environment
bash

cp .env.example .env
# Edit .env with your MySQL credentials
4. Initialize the database
bash

python database/init_db.py
This creates the medilink database, all tables, seeds the symptom catalog,
and inserts a default admin user.

Note: The default admin password hash in schema.sql is illustrative.
To generate a fresh hash for Admin@123, run:

python

import bcrypt
print(bcrypt.hashpw(b"Admin@123", bcrypt.gensalt(12)).decode())
…and replace the row in schema.sql before running init_db.py.

5. Run the application
bash

python app.py
# → http://localhost:5000
🔑 Sample credentials
Role
Email
Password
Patient	(register your own)	—
Doctor	(register your own)	—

📂 Project structure
See the file tree in the project root. Key folders:

backend/ — services, routes, ML engine, DB helpers, auth
database/ — schema + init script
templates/ — Jinja2 templates (auth, patient, doctor, admin, errors)
static/ — CSS, JS, SVG hero illustration
🔒 Security
Passwords hashed with bcrypt (cost 12)
Parameterized SQL queries (PyMySQL) — SQL-injection safe
Session-based auth with httponly, samesite cookies
Role-based route guards (@role_required)
Server-side input validation
Audit logging on key actions
🧠 AI / ML architecture
backend/ml/symptom_engine.py contains:

A disease knowledge base mapping symptoms → diseases with weights, risk levels, specialists, advice
An NLP-light preprocessor (lowercasing, tokenization, alias resolution, stopword removal)
A predict() function returning ranked candidates with confidence scores
A chatbot_reply() intent matcher with fallback to the prediction engine
The contract is intentionally simple (text in → dict out) so a future
scikit-learn / HuggingFace model can replace the rule-based predict() without
touching routes or services.

📜 Disclaimer
MediLink is a demo/educational product and not a certified medical device.
Always consult a licensed healthcare professional.

📄 License
MIT — free to use and adapt.