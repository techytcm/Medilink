# 🏥 MediLink — AI Healthcare Assistant

A full-stack, AI-inspired healthcare platform designed to connect patients, doctors, and administrators through a modern digital healthcare experience.

MediLink helps users analyze symptoms, assess health risks, receive specialist recommendations, manage appointments, and communicate with an intelligent healthcare chatbot.

Built with **Python (Flask), MySQL, Tailwind CSS, JavaScript, and Inter Font**, MediLink provides a responsive light/dark interface with role-based healthcare management features.

---

## ✨ Features

### 🔐 Authentication & Security

* User registration and login system
* Logout and password reset functionality
* Secure password hashing using **bcrypt**
* Session-based authentication
* Role-based access control
* Protected routes with authorization guards

---

## 👤 Patient Features

* Patient dashboard
* Symptom analysis using healthcare prediction engine
* Risk level assessment
* Specialist recommendations
* Appointment booking and history
* Prediction history tracking
* AI healthcare chatbot (**MediBot**)
* Notifications
* Feedback submission
* Profile management
* Account settings

---

## 👨‍⚕️ Doctor Features

* Doctor dashboard
* Appointment management
* Patient detail viewing
* Consultation notes
* Patient interaction history

---

## 🛡️ Admin Features

* Admin dashboard
* User management
* Doctor management
* System reports
* Audit log monitoring
* Feedback management

---

# 🧠 Medical AI Engine

MediLink includes a lightweight healthcare intelligence engine designed for future machine learning integration.

### Current Implementation:

* Rule-based symptom matching system
* NLP-light text preprocessing
* Symptom alias recognition
* Disease prediction with confidence scores
* Risk-level classification
* Specialist recommendation system
* Healthcare chatbot intent matching

### Future ML Integration:

The architecture is designed so the current prediction engine can be replaced with advanced models such as:

* Scikit-learn classifiers
* NLP models
* Transformer-based healthcare models
* Hugging Face models

without changing the application routes or services.

---

# 🛠️ Tech Stack

| Layer           | Technology                              |
| --------------- | --------------------------------------- |
| Backend         | Python 3.10+, Flask 3                   |
| Database        | MySQL 8.0+                              |
| Database Driver | PyMySQL                                 |
| Security        | bcrypt                                  |
| Frontend        | HTML5, Tailwind CSS, Vanilla JavaScript |
| Template Engine | Jinja2                                  |
| Font            | Inter (Google Fonts)                    |
| Architecture    | Full-stack MVC-inspired Flask structure |

---

# 🚀 Installation & Setup

## 1. Clone Repository

```bash
git clone <your-repository-url>

cd medilink
```

---

## 2. Create Virtual Environment

### Linux / macOS

```bash
python -m venv venv

source venv/bin/activate
```

### Windows

```bash
python -m venv venv

venv\Scripts\activate
```

---

## 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## 4. Configure Environment Variables

Create a `.env` file:

```bash
cp .env.example .env
```

Update the file with your MySQL credentials:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=medilink
DB_PORT=3306

SECRET_KEY=your_secret_key
```

---

## 5. Initialize Database

Run:

```bash
python database/init_db.py
```

This will:

* Create the MediLink database
* Create required tables
* Insert symptom catalog data
* Create default admin account

---

## 6. Run Application

Start Flask server:

```bash
python app.py
```

Application will run at:

```
http://localhost:5000
```

---

# 🔑 Demo Credentials

| Role    | Email                           | Password |
| ------- | ------------------------------- | -------- |
| Patient | Register your own account       | -        |
| Doctor  | Register your own account       | -        |
| Admin   | Configure during database setup | -        |

---

# 📂 Project Structure

```
MediLink/
│
├── backend/
│   ├── routes/
│   ├── services/
│   ├── ml/
│   │   └── symptom_engine.py
│   ├── auth/
│   └── database/
│
├── database/
│   ├── schema.sql
│   └── init_db.py
│
├── templates/
│   ├── auth/
│   ├── patient/
│   ├── doctor/
│   ├── admin/
│   └── errors/
│
├── static/
│   ├── css/
│   ├── js/
│   └── images/
│
├── app.py
├── requirements.txt
├── .env.example
└── README.md
```

---

# 🔒 Security Features

MediLink follows secure development practices:

✅ bcrypt password hashing (cost factor 12)
✅ Parameterized SQL queries to prevent SQL injection
✅ Secure session management
✅ HTTPOnly and SameSite cookies
✅ Role-based route protection
✅ Server-side validation
✅ Audit logging for important actions

---

# 🤖 AI Architecture

The core AI logic is located at:

```
backend/ml/symptom_engine.py
```

It contains:

* Disease knowledge base
* Symptom-weight mapping
* Risk assessment system
* Specialist recommendation logic
* NLP preprocessing pipeline
* Prediction function
* Chatbot response engine

Input:

```
User symptoms → Processing → Prediction
```

Output:

```json
{
  "disease": "Example Disease",
  "confidence": 0.85,
  "risk": "Medium",
  "specialist": "Example Specialist"
}
```

---

# 🎨 UI & Design

MediLink follows a modern healthcare design system:

* Clean medical interface
* Inter typography
* Green & white healthcare theme
* Dark mode support
* Responsive mobile-first layout
* SVG-based hero illustration
* Accessible user experience

---

# ⚠️ Disclaimer

MediLink is an educational/demo healthcare application.

It is **not a certified medical device** and should not replace professional medical advice, diagnosis, or treatment.

Always consult a qualified healthcare professional for medical decisions.

---

# 📜 License

Distributed under the MIT License.

You are free to use, modify, and adapt this project.
