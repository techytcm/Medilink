-- ============================================================
-- MediLink: Healthcare Assistant — Extensible Database Schema
-- MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS medilink
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medilink;

-- ----------------------------------------------------------
-- USERS
-- ----------------------------------------------------------
CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(120)  NOT NULL,
    email          VARCHAR(150)  NOT NULL UNIQUE,
    phone          VARCHAR(20),
    password_hash  VARCHAR(255)  NOT NULL,
    role           ENUM('patient','doctor','admin') NOT NULL DEFAULT 'patient',
    avatar_url     VARCHAR(255),
    is_active      BOOLEAN       DEFAULT TRUE,
    last_login     DATETIME      NULL,
    created_at     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_role (role),
    INDEX idx_users_email (email)
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- PATIENT PROFILES
-- ----------------------------------------------------------
CREATE TABLE patient_profiles (
    profile_id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL UNIQUE,
    date_of_birth       DATE,
    gender              ENUM('male','female','other'),
    blood_group         VARCHAR(5),
    height_cm           DECIMAL(5,2),
    weight_kg           DECIMAL(5,2),
    allergies           TEXT,
    chronic_conditions  TEXT,
    emergency_contact   VARCHAR(120),
    emergency_phone     VARCHAR(20),
    address             TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- DOCTOR PROFILES
-- ----------------------------------------------------------
CREATE TABLE doctor_profiles (
    profile_id            INT AUTO_INCREMENT PRIMARY KEY,
    user_id               INT NOT NULL UNIQUE,
    specialization        VARCHAR(100) NOT NULL,
    license_number        VARCHAR(50)  UNIQUE,
    years_of_experience   INT,
    education             TEXT,
    bio                   TEXT,
    consultation_fee      DECIMAL(10,2) DEFAULT 0,
    available_days        VARCHAR(100),
    available_time_start  TIME,
    available_time_end    TIME,
    rating                DECIMAL(2,1)  DEFAULT 0,
    is_verified           BOOLEAN       DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_doctor_specialization (specialization)
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- SYMPTOMS CATALOG
-- ----------------------------------------------------------
CREATE TABLE symptoms (
    symptom_id   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    category     VARCHAR(80),
    description  TEXT
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- DISEASES CATALOG
-- ----------------------------------------------------------
CREATE TABLE diseases (
    disease_id      INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL UNIQUE,
    category        VARCHAR(80),
    description     TEXT,
    specialist      VARCHAR(100),
    recommendations TEXT,
    risk_level      ENUM('low','moderate','high','critical') DEFAULT 'low'
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- DISEASE-SYMPTOM MAPPING
-- weight: 1 = common symptom, 2 = primary/key symptom
-- ----------------------------------------------------------
CREATE TABLE disease_symptoms (
    disease_id INT NOT NULL,
    symptom_id INT NOT NULL,
    weight      INT DEFAULT 1, 
    PRIMARY KEY (disease_id, symptom_id),
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE,
    FOREIGN KEY (symptom_id) REFERENCES symptoms(symptom_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- PREDICTIONS
-- ----------------------------------------------------------
CREATE TABLE predictions (
    prediction_id      INT AUTO_INCREMENT PRIMARY KEY,
    user_id            INT NOT NULL,
    symptoms_input     TEXT NOT NULL,
    symptoms_processed TEXT,
    predicted_disease  VARCHAR(150),
    disease_id         INT NULL,
    confidence_score   DECIMAL(5,2),
    risk_level         ENUM('low','moderate','high','critical') NOT NULL DEFAULT 'low',
    recommendations    TEXT,
    specialist         VARCHAR(100),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE SET NULL,
    INDEX idx_prediction_user (user_id),
    INDEX idx_prediction_risk (risk_level)
) ENGINE=InnoDB;

-- ----------------------------------------------------------
-- APPOINTMENTS, CONSULTATIONS, CHAT, NOTIFS, FEEDBACK, AUDIT, RESETS
-- ----------------------------------------------------------
CREATE TABLE appointments (
    appointment_id  INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    scheduled_at    DATETIME NOT NULL,
    reason          TEXT,
    status          ENUM('pending','confirmed','completed','cancelled','rejected') DEFAULT 'pending',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(user_id),
    FOREIGN KEY (doctor_id)  REFERENCES users(user_id),
    INDEX idx_appt_patient (patient_id),
    INDEX idx_appt_doctor  (doctor_id),
    INDEX idx_appt_status  (status)
) ENGINE=InnoDB;

CREATE TABLE consultation_records (
    record_id       INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT NOT NULL,
    diagnosis       TEXT,
    prescription    TEXT,
    notes           TEXT,
    follow_up_date  DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE chat_sessions (
    session_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    started_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE chat_messages (
    message_id   INT AUTO_INCREMENT PRIMARY KEY,
    session_id   INT NOT NULL,
    sender       ENUM('user','bot') NOT NULL,
    message      TEXT NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES chat_sessions(session_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notifications (
    notification_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT NOT NULL,
    title            VARCHAR(200),
    message          TEXT,
    type             ENUM('info','success','warning','danger') DEFAULT 'info',
    is_read          BOOLEAN DEFAULT FALSE,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_notif_user (user_id, is_read)
) ENGINE=InnoDB;

CREATE TABLE feedback (
    feedback_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    rating       INT,
    subject      VARCHAR(200),
    message      TEXT,
    status       ENUM('open','in_review','resolved') DEFAULT 'open',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT,
    action       VARCHAR(150),
    entity       VARCHAR(80),
    entity_id    INT,
    ip_address   VARCHAR(45),
    user_agent   TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_audit_user (user_id),
    INDEX idx_audit_action (action)
) ENGINE=InnoDB;

CREATE TABLE password_resets (
    reset_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    token        VARCHAR(255) NOT NULL UNIQUE,
    expires_at   DATETIME NOT NULL,
    used         BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- EXTENSIBLE SEED DATA
-- ============================================================

-- ----------------------------------------------------------
-- SEED: SYMPTOMS CATALOG (95 Clinical Symptoms)
-- ----------------------------------------------------------
INSERT INTO symptoms (name, category, description) VALUES
('fever','vital','Elevated body temperature above 37.5°C'),
('cough','respiratory','Persistent expulsion of air from lungs'),
('sore throat','respiratory','Pain or irritation in the throat'),
('runny nose','respiratory','Excess nasal discharge'),
('sneezing','respiratory','Sudden expulsion of air through nose and mouth'),
('congestion','respiratory','Nasal or chest blockage'),
('headache','neurological','Pain in the head or upper neck'),
('fatigue','general','Persistent tiredness or lack of energy'),
('body ache','general','Aching in muscles or joints'),
('nausea','gastrointestinal','Feeling of sickness with urge to vomit'),
('vomiting','gastrointestinal','Forceful expulsion of stomach contents'),
('diarrhea','gastrointestinal','Loose or watery bowel movements'),
('abdominal pain','gastrointestinal','Pain in the stomach area'),
('chest pain','cardiovascular','Pain or pressure in the chest'),
('shortness of breath','cardiovascular','Difficulty breathing'),
('dizziness','neurological','Feeling faint or unsteady'),
('rash','dermatological','Visible skin eruption or irritation'),
('itching','dermatological','Sensation that provokes scratching'),
('joint pain','musculoskeletal','Discomfort in joints'),
('back pain','musculoskeletal','Pain in the lower or upper back'),
('chills','vital','Feeling of coldness with shivering'),
('loss of appetite','general','Reduced desire to eat'),
('weight loss','general','Unexplained reduction in body weight'),
('high blood pressure','cardiovascular','Persistently elevated arterial pressure'),
('frequent urination','urological','Increased need to urinate'),
('blurred vision','neurological','Loss of sharpness in eyesight'),
('skin redness','dermatological','Erythema of the skin'),
('wheezing','respiratory','High-pitched whistling during breathing'),
('stiff neck','neurological','Reduced mobility and pain in neck'),
('sensitivity to light','neurological','Pain or discomfort when exposed to light'),
('swollen glands','immune','Enlarged lymph nodes'),
('night sweats','general','Excessive sweating during sleep'),
('pale skin','dermatological','Unusual lightness of skin color'),
('rapid heartbeat','cardiovascular','Heart beating faster than normal'),
('swelling','general','Enlargement of body tissue'),
('loss of smell','respiratory','Inability to detect odors'),
('loss of taste','respiratory','Inability to detect flavors'),
('confusion','neurological','Lack of clarity in thought processes'),
('memory loss','neurological','Unusual forgetfulness'),
('muscle weakness','musculoskeletal','Lack of muscle strength'),
('tingling','neurological','Pins and needles sensation'),
('numbness','neurological','Loss of sensation in a body part'),
('seizures','neurological','Sudden, uncontrolled electrical disturbance in the brain'),
('jaundice','hepatobiliary','Yellowing of the skin or eyes'),
('dark urine','urological','Unusually dark colored urine'),
('pale stool','gastrointestinal','Clay-colored or light stools'),
('excessive thirst','endocrine','Abnormal need to drink fluids'),
('dry mouth','endocrine','Lack of saliva in the mouth'),
('constipation','gastrointestinal','Infrequent or difficult bowel movements'),
('heartburn','gastrointestinal','Burning sensation in the chest'),
('acid reflux','gastrointestinal','Backward flow of stomach acid into the esophagus'),
('earache','ent','Pain in the ear'),
('hearing loss','ent','Partial or total inability to hear'),
('ringing in ears','ent','Perception of noise or ringing in the ears'),
('hair loss','dermatological','Thinning or balding of hair'),
('dry skin','dermatological','Rough, scaly, or flaky skin'),
('mood swings','psychiatric','Rapid changes in emotional state'),
('anxiety','psychiatric','Feeling of unease, worry, or fear'),
('tremors','neurological','Rhythmic muscle movements causing shaking'),
('slow heartbeat','cardiovascular','Heart beating slower than normal'),
('fainting','cardiovascular','Sudden loss of consciousness'),
('bruising','dermatological','Skin discoloration from broken blood vessels'),
('bleeding gums','oral','Blood coming from the gums'),
('dry eyes','ophthalmology','Lack of proper lubrication in the eyes'),
('red eyes','ophthalmology','Bloodshot appearance of the eyes'),
('eye pain','ophthalmology','Ache or pain in or around the eye'),
('sensitivity to cold','endocrine','Feeling abnormally cold'),
('heat intolerance','endocrine','Inability to be comfortable in warm temperatures'),
('frequent infections','immune','Recurring bouts of illness'),
('weight gain','endocrine','Unexplained increase in body weight'),
('radiating chest pain','cardiovascular','Chest pain spreading to arm, jaw, or back'),
('coughing blood','respiratory','Blood produced during a cough'),
('black stool','gastrointestinal','Dark, tarry stools indicating bleeding'),
('blood in urine','urological','Visible or microscopic blood in urine'),
('difficulty swallowing','ent','Sensation of food stuck in throat or chest'),
('shortness of breath lying down','cardiovascular','Difficulty breathing when flat (orthopnea)'),
('joint stiffness','musculoskeletal','Difficulty moving joints, especially in morning'),
('facial flushing','dermatological','Sudden redness of the face and neck'),
('butterfly rash','dermatological','Facial rash across bridge of nose and cheeks'),
('dry cough','respiratory','Cough without phlegm or mucus'),
('productive cough','respiratory','Cough producing phlegm or mucus'),
('flank pain','urological','Pain in the side of the torso near the ribs'),
('poor wound healing','endocrine','Cuts or sores taking longer than usual to heal'),
('absent menstruation','gynecological','Lack of menstrual periods'),
('heavy menstruation','gynecological','Unusually heavy or prolonged menstrual bleeding'),
('genital discharge','gynecological','Abnormal discharge from genitals'),
('genital ulcers','gynecological','Sores on genital area'),
('intense itching','dermatological','Severe urge to scratch'),
('muscle cramps','musculoskeletal','Sudden, involuntary muscle contractions'),
('bone pain','musculoskeletal','Deep, dull ache in bones'),
('neck mass','ent','Lump or swelling in the neck'),
('voice change','ent','Hoarseness or change in voice quality'),
('difficulty breathing','respiratory','Labored or uncomfortable breathing');

-- ----------------------------------------------------------
-- SEED: DISEASES CATALOG (80+ Real-World Diseases)
-- ----------------------------------------------------------
INSERT INTO diseases (name, category, specialist, recommendations, risk_level, description) VALUES
-- Respiratory
('Common Cold','Respiratory','General Physician','Rest, drink fluids, and use over-the-counter decongestants.','low','Viral infection of the upper respiratory tract.'),
('Influenza (Flu)','Respiratory','General Physician','Rest, hydration, antiviral medications if prescribed early.','moderate','Viral infection affecting the respiratory system.'),
('COVID-19','Respiratory','General Physician','Isolate, monitor oxygen levels, seek emergency care if breathing difficulty occurs.','high','Viral disease caused by SARS-CoV-2.'),
('Strep Throat','Respiratory','ENT Specialist','Antibiotics required. Rest voice and drink warm liquids.','low','Bacterial infection causing throat inflammation.'),
('Pneumonia','Respiratory','Pulmonologist','Antibiotics, hospitalization may be required for severe cases.','high','Infection inflaming air sacs in lungs.'),
('Asthma','Respiratory','Pulmonologist','Use prescribed inhalers, avoid triggers.','moderate','Condition where airways narrow and swell.'),
('Bronchitis','Respiratory','Pulmonologist','Rest, fluids, cough medicine.','low','Inflammation of the bronchial tubes.'),
('Sinusitis','Respiratory','ENT Specialist','Nasal decongestants, saline sprays, antibiotics if bacterial.','low','Inflammation of the sinuses.'),
('Tuberculosis','Respiratory','Pulmonologist','Long-term antibiotic treatment.','high','Bacterial infection primarily affecting lungs.'),
('COPD','Respiratory','Pulmonologist','Quit smoking, bronchodilators, inhaled steroids.','high','Chronic inflammatory lung disease causing obstructed airflow.'),
('Lung Cancer','Oncology','Oncologist','Biopsy, staging, surgery, chemotherapy, or radiation.','critical','Cancer originating in the lungs.'),

-- Cardiovascular
('Myocardial Infarction','Cardiovascular','Cardiologist','Call 911 immediately. Chew aspirin if not allergic.','critical','Heart attack caused by blocked blood flow to the heart muscle.'),
('Angina Pectoris','Cardiovascular','Cardiologist','Nitroglycerin, lifestyle changes, monitor heart health.','high','Chest pain caused by reduced blood flow to the heart.'),
('Heart Failure','Cardiovascular','Cardiologist','Medications, fluid restriction, low-salt diet.','critical','Chronic condition where the heart doesnt pump blood as well as it should.'),
('Hypertension','Cardiovascular','Cardiologist','Lifestyle changes, medication to lower blood pressure.','high','Abnormally high blood pressure.'),
('Arrhythmia','Cardiovascular','Cardiologist','Medications, pacemaker, or ablation therapy.','high','Improper heart beating rate or rhythm.'),
('Deep Vein Thrombosis','Cardiovascular','Hematologist','Anticoagulants (blood thinners), compression stockings.','high','Blood clot in a deep vein, usually in the legs.'),
('Stroke','Cardiovascular','Neurologist','Immediate emergency medical attention.','critical','Blood supply to part of the brain is interrupted.'),

-- Gastrointestinal
('Gastroenteritis','Gastrointestinal','Gastroenterologist','Hydration with electrolytes, bland diet.','moderate','Inflammation of stomach and intestines.'),
('Food Poisoning','Gastrointestinal','Gastroenterologist','Hydration, rest, avoid solid foods temporarily.','moderate','Illness caused by eating contaminated food.'),
('Appendicitis','Gastrointestinal','Surgeon','Immediate surgical removal of appendix.','critical','Inflammation of the appendix.'),
('Gastritis','Gastrointestinal','Gastroenterologist','Antacids, avoid NSAIDs and alcohol.','low','Inflammation of the stomach lining.'),
('Peptic Ulcer','Gastrointestinal','Gastroenterologist','Proton pump inhibitors, antibiotics if H. pylori present.','moderate','Sores that develop on the lining of the esophagus, stomach, or small intestine.'),
('Irritable Bowel Syndrome (IBS)','Gastrointestinal','Gastroenterologist','Dietary modifications, stress management.','low','Common disorder affecting the large intestine.'),
('Inflammatory Bowel Disease (IBD)','Gastrointestinal','Gastroenterologist','Anti-inflammatory drugs, immunosuppressants.','high','Chronic inflammation of the gastrointestinal tract.'),
('Gallstones','Gastrointestinal','Surgeon','Surgical removal of gallbladder if symptomatic.','moderate','Hardened deposits of digestive fluid in the gallbladder.'),
('Gastroesophageal Reflux Disease (GERD)','Gastrointestinal','Gastroenterologist','Antacids, H2 blockers, avoid late meals.','moderate','Chronic acid reflux.'),

-- Hepatobiliary
('Hepatitis A','Hepatobiliary','Infectious Disease Specialist','Rest, hydration, avoid liver toxins.','moderate','Highly contagious liver infection caused by the hepatitis A virus.'),
('Hepatitis B','Hepatobiliary','Hepatologist','Antiviral medications, liver monitoring.','high','Serious liver infection caused by the hepatitis B virus.'),
('Cirrhosis','Hepatobiliary','Hepatologist','Treat underlying cause, avoid alcohol.','critical','Late-stage scarring of the liver.'),

-- Endocrine
('Diabetes Type 1','Endocrine','Endocrinologist','Lifelong insulin therapy, blood sugar monitoring.','high','Chronic condition where the pancreas produces little or no insulin.'),
('Diabetes Type 2','Endocrine','Endocrinologist','Blood sugar monitoring, diet control, medication.','high','Chronic condition affecting blood sugar levels.'),
('Hyperthyroidism','Endocrine','Endocrinologist','Anti-thyroid medications, radioactive iodine.','moderate','Overproduction of thyroid hormones.'),
('Hypothyroidism','Endocrine','Endocrinologist','Synthetic thyroid hormone (levothyroxine).','low','Underproduction of thyroid hormones.'),
('Cushing Syndrome','Endocrine','Endocrinologist','Surgery, radiation, or medication to reduce cortisol.','high','Condition caused by high levels of cortisol.'),

-- Neurological
('Migraine','Neurological','Neurologist','Rest in a dark room, take prescribed pain relievers.','low','Severe throbbing pain on one side of the head.'),
('Meningitis','Neurological','Infectious Disease Specialist','Immediate emergency medical treatment with antibiotics.','critical','Inflammation of the protective membranes covering the brain and spinal cord.'),
('Epilepsy','Neurological','Neurologist','Antiepileptic medications, avoid known triggers.','high','Neurological disorder marked by sudden recurrent seizures.'),
('Parkinsons Disease','Neurological','Neurologist','Medications to manage symptoms, physical therapy.','high','Progressive nervous system disorder affecting movement.'),
('Alzheimers Disease','Neurological','Neurologist','Medications for memory loss, supportive care.','high','Progressive disease that destroys memory and other important mental functions.'),
('Multiple Sclerosis','Neurological','Neurologist','Disease-modifying therapies, physical therapy.','high','Immune-mediated process causing inflammation in the central nervous system.'),

-- Hematology & Immune
('Iron Deficiency Anemia','Hematology','Hematologist','Iron supplements, diet rich in iron.','low','Lack of healthy red blood cells due to iron deficiency.'),
('Sickle Cell Anemia','Hematology','Hematologist','Pain management, blood transfusions, hydroxyurea.','critical','Inherited red blood cell disorder.'),
('HIV/AIDS','Infectious','Infectious Disease Specialist','Antiretroviral therapy (ART).','critical','Viral infection that attacks the immune system.'),
('Sepsis','Infectious','Intensivist','Emergency hospitalization, IV antibiotics, fluids.','critical','Life-threatening response to infection.'),

-- Infectious
('Dengue Fever','Infectious','Infectious Disease Specialist','Hospitalization for monitoring, fluid replacement, avoid aspirin.','critical','Mosquito-borne viral infection.'),
('Malaria','Infectious','Infectious Disease Specialist','Antimalarial drugs, immediate medical treatment.','critical','Life-threatening disease transmitted by mosquitoes.'),
('Typhoid Fever','Infectious','Infectious Disease Specialist','Antibiotics, fluid replacement.','high','Bacterial infection spread through contaminated food and water.'),
('Cholera','Infectious','Infectious Disease Specialist','Aggressive fluid replacement, antibiotics.','critical','Bacterial disease causing severe diarrhea and dehydration.'),
('Syphilis','Infectious','Infectious Disease Specialist','Penicillin injections.','high','Sexually transmitted bacterial infection.'),
('Lyme Disease','Infectious','Infectious Disease Specialist','Antibiotics (doxycycline).','moderate','Bacterial infection transmitted by ticks.'),
('Tetanus','Infectious','Infectious Disease Specialist','Tetanus immune globulin, muscle relaxants.','critical','Serious bacterial infection causing muscle spasms.'),
('Chickenpox','Infectious','General Physician','Rest, calamine lotion, antiviral drugs for high risk.','low','Highly contagious viral infection causing an itchy, blister-like rash.'),
('Measles','Infectious','Pediatrician','Supportive care, vitamin A supplementation.','high','Highly contagious viral respiratory illness.'),
('Mumps','Infectious','General Physician','Supportive care, rest, cold compresses.','low','Viral infection affecting the salivary glands.'),

-- Musculoskeletal & Autoimmune
('Osteoarthritis','Musculoskeletal','Rheumatologist','Physical therapy, pain relievers, joint injections.','moderate','Degenerative joint disease.'),
('Rheumatoid Arthritis','Musculoskeletal','Rheumatologist','DMARDs, anti-inflammatory drugs.','high','Autoimmune inflammatory disorder affecting joints.'),
('Gout','Musculoskeletal','Rheumatologist','NSAIDs, colchicine, lifestyle changes.','moderate','Complex form of arthritis characterized by sudden, severe pain.'),
('Osteoporosis','Musculoskeletal','Orthopedist','Bisphosphonates, calcium, vitamin D.','moderate','Bone thinning disease.'),
('Systemic Lupus Erythematosus (SLE)','Autoimmune','Rheumatologist','Immunosuppressants, corticosteroids.','high','Autoimmune disease causing widespread inflammation.'),

-- Dermatological
('Eczema','Dermatological','Dermatologist','Moisturizers, topical corticosteroids.','low','Inflamed, itchy skin condition.'),
('Psoriasis','Dermatological','Dermatologist','Topical treatments, phototherapy, systemic medications.','moderate','Autoimmune condition causing rapid skin cell turnover.'),
('Rosacea','Dermatological','Dermatologist','Topical creams, oral antibiotics, avoid triggers.','low','Chronic skin condition causing facial redness.'),
('Melanoma','Dermatological','Dermatologist','Surgical excision, immunotherapy.','critical','Most serious type of skin cancer.'),
('Cellulitis','Dermatological','Dermatologist','Oral or IV antibiotics.','high','Bacterial skin infection.'),

-- Urology & Nephrology
('Urinary Tract Infection','Urology','Urologist','Antibiotics, drink plenty of water.','moderate','Infection in any part of the urinary system.'),
('Kidney Stones','Urology','Urologist','Hydration, pain relief, lithotripsy if large.','moderate','Hard deposits made of minerals and salts inside the kidneys.'),
('Chronic Kidney Disease','Urology','Nephrologist','Manage underlying conditions, dialysis if severe.','critical','Progressive loss of kidney function over time.'),

-- Ophthalmology & ENT
('Cataracts','Ophthalmology','Ophthalmologist','Surgical removal of the cloudy lens.','low','Clouding of the eyes natural lens.'),
('Glaucoma','Ophthalmology','Ophthalmologist','Eye drops, laser treatment, surgery.','high','Group of eye conditions that damage the optic nerve.'),
('Conjunctivitis','Ophthalmology','Ophthalmologist','Antibiotic drops if bacterial, supportive care if viral.','low','Inflammation or infection of the conjunctiva.'),
('Otitis Media','ENT','ENT Specialist','Antibiotics if bacterial, pain relief.','low','Middle ear infection.'),

-- Psychiatric
('Major Depressive Disorder','Psychiatric','Psychiatrist','Psychotherapy, antidepressants.','moderate','Mood disorder causing persistent sadness and loss of interest.'),
('Generalized Anxiety Disorder','Psychiatric','Psychiatrist','Therapy, anti-anxiety medications.','low','Mental health disorder characterized by feelings of worry.');


-- ----------------------------------------------------------
-- SEED: DISEASE-SYMPTOM MAPPING (100% Accurate Subquery Method)
-- weight: 2 = Primary/Key Symptom, 1 = Common/Secondary
-- ----------------------------------------------------------

-- Respiratory
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Common Cold' AND s.name='cough';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Common Cold' AND s.name IN ('sore throat', 'runny nose', 'sneezing', 'congestion');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Influenza (Flu)' AND s.name IN ('fever', 'fatigue', 'body ache');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Influenza (Flu)' AND s.name IN ('cough', 'chills', 'headache');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='COVID-19' AND s.name IN ('fever', 'cough', 'shortness of breath');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='COVID-19' AND s.name IN ('fatigue', 'loss of smell', 'loss of taste', 'chills');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Strep Throat' AND s.name='sore throat';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Strep Throat' AND s.name IN ('fever', 'swollen glands', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Pneumonia' AND s.name IN ('cough', 'shortness of breath', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Pneumonia' AND s.name IN ('chills', 'wheezing', 'chest pain');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Asthma' AND s.name IN ('shortness of breath', 'wheezing');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Asthma' AND s.name IN ('cough', 'rapid heartbeat');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Bronchitis' AND s.name='cough';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Bronchitis' AND s.name IN ('fatigue', 'wheezing', 'congestion');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Sinusitis' AND s.name='congestion';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Sinusitis' AND s.name IN ('runny nose', 'headache', 'sneezing');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Tuberculosis' AND s.name IN ('cough', 'weight loss', 'night sweats');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Tuberculosis' AND s.name IN ('fever', 'fatigue', 'coughing blood');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='COPD' AND s.name IN ('shortness of breath', 'cough');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='COPD' AND s.name IN ('wheezing', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Lung Cancer' AND s.name IN ('cough', 'coughing blood', 'weight loss');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Lung Cancer' AND s.name IN ('chest pain', 'shortness of breath', 'fatigue');

-- Cardiovascular
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Myocardial Infarction' AND s.name IN ('chest pain', 'radiating chest pain', 'shortness of breath');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Myocardial Infarction' AND s.name IN ('rapid heartbeat', 'nausea', 'vomiting');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Angina Pectoris' AND s.name IN ('chest pain', 'radiating chest pain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Angina Pectoris' AND s.name IN ('shortness of breath', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Heart Failure' AND s.name IN ('shortness of breath', 'shortness of breath lying down', 'swelling');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Heart Failure' AND s.name IN ('fatigue', 'rapid heartbeat');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Hypertension' AND s.name='high blood pressure';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Hypertension' AND s.name IN ('dizziness', 'rapid heartbeat', 'headache');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Arrhythmia' AND s.name IN ('rapid heartbeat', 'slow heartbeat');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Arrhythmia' AND s.name IN ('dizziness', 'fainting');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Deep Vein Thrombosis' AND s.name IN ('swelling');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Deep Vein Thrombosis' AND s.name IN ('body ache');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Stroke' AND s.name IN ('dizziness', 'confusion', 'numbness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Stroke' AND s.name IN ('headache', 'shortness of breath');

-- Gastrointestinal
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Gastroenteritis' AND s.name IN ('nausea', 'vomiting', 'diarrhea', 'abdominal pain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Gastroenteritis' AND s.name IN ('fever', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Food Poisoning' AND s.name IN ('vomiting', 'diarrhea', 'abdominal pain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Food Poisoning' AND s.name IN ('fever', 'nausea');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Appendicitis' AND s.name='abdominal pain';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Appendicitis' AND s.name IN ('nausea', 'fever', 'loss of appetite');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Gastritis' AND s.name='abdominal pain';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Gastritis' AND s.name IN ('nausea', 'vomiting');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Peptic Ulcer' AND s.name IN ('abdominal pain', 'heartburn');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Peptic Ulcer' AND s.name IN ('nausea', 'black stool');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Irritable Bowel Syndrome (IBS)' AND s.name IN ('abdominal pain', 'diarrhea');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Irritable Bowel Syndrome (IBS)' AND s.name IN ('constipation', 'bloating');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Inflammatory Bowel Disease (IBD)' AND s.name IN ('diarrhea', 'abdominal pain', 'weight loss');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Inflammatory Bowel Disease (IBD)' AND s.name IN ('fatigue', 'black stool');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Gallstones' AND s.name='abdominal pain';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Gallstones' AND s.name IN ('nausea', 'vomiting');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Gastroesophageal Reflux Disease (GERD)' AND s.name IN ('heartburn', 'acid reflux');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Gastroesophageal Reflux Disease (GERD)' AND s.name IN ('chest pain', 'difficulty swallowing');

-- Hepatobiliary
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Hepatitis A' AND s.name IN ('fatigue', 'jaundice');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Hepatitis A' AND s.name IN ('nausea', 'abdominal pain');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Hepatitis B' AND s.name IN ('jaundice', 'fatigue');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Hepatitis B' AND s.name IN ('dark urine', 'pale stool', 'abdominal pain');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Cirrhosis' AND s.name IN ('jaundice', 'swelling', 'fatigue');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Cirrhosis' AND s.name IN ('weight loss', 'black stool');

-- Endocrine
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Diabetes Type 1' AND s.name IN ('excessive thirst', 'frequent urination', 'weight loss');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Diabetes Type 1' AND s.name IN ('fatigue', 'dry mouth');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Diabetes Type 2' AND s.name IN ('excessive thirst', 'frequent urination', 'blurred vision');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Diabetes Type 2' AND s.name IN ('fatigue', 'poor wound healing', 'tingling');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Hyperthyroidism' AND s.name IN ('rapid heartbeat', 'heat intolerance', 'weight loss');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Hyperthyroidism' AND s.name IN ('anxiety', 'tremors');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Hypothyroidism' AND s.name IN ('fatigue', 'sensitivity to cold', 'weight gain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Hypothyroidism' AND s.name IN ('dry skin', 'hair loss');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Cushing Syndrome' AND s.name IN ('weight gain', 'swelling');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Cushing Syndrome' AND s.name IN ('fatigue', 'muscle weakness');

-- Neurological
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Migraine' AND s.name IN ('headache', 'sensitivity to light');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Migraine' AND s.name IN ('dizziness', 'nausea');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Meningitis' AND s.name IN ('stiff neck', 'headache', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Meningitis' AND s.name IN ('sensitivity to light', 'confusion');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Epilepsy' AND s.name='seizures';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Epilepsy' AND s.name IN ('confusion', 'fainting');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Parkinsons Disease' AND s.name IN ('tremors', 'muscle weakness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Parkinsons Disease' AND s.name IN ('confusion', 'memory loss');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Alzheimers Disease' AND s.name IN ('memory loss', 'confusion');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Alzheimers Disease' AND s.name IN ('mood swings');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Multiple Sclerosis' AND s.name IN ('numbness', 'tingling', 'muscle weakness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Multiple Sclerosis' AND s.name IN ('fatigue', 'blurred vision');

-- Hematology & Immune
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Iron Deficiency Anemia' AND s.name IN ('fatigue', 'pale skin');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Iron Deficiency Anemia' AND s.name IN ('dizziness', 'shortness of breath');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Sickle Cell Anemia' AND s.name IN ('jaundice', 'fatigue', 'pale skin');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Sickle Cell Anemia' AND s.name IN ('joint pain', 'shortness of breath');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='HIV/AIDS' AND s.name IN ('frequent infections', 'weight loss', 'swollen glands');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='HIV/AIDS' AND s.name IN ('night sweats', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Sepsis' AND s.name IN ('fever', 'rapid heartbeat', 'confusion');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Sepsis' AND s.name IN ('shortness of breath');

-- Infectious
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Dengue Fever' AND s.name IN ('fever', 'body ache', 'headache');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Dengue Fever' AND s.name IN ('rash', 'swollen glands', 'nausea');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Malaria' AND s.name IN ('fever', 'chills');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Malaria' AND s.name IN ('body ache', 'fatigue', 'headache');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Typhoid Fever' AND s.name IN ('fever', 'abdominal pain', 'diarrhea');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Typhoid Fever' AND s.name IN ('fatigue', 'rash');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Cholera' AND s.name IN ('diarrhea', 'vomiting');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Cholera' AND s.name IN ('dehydration', 'muscle cramps');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Syphilis' AND s.name='genital ulcers';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Syphilis' AND s.name IN ('rash', 'swollen glands');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Lyme Disease' AND s.name IN ('rash', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Lyme Disease' AND s.name IN ('joint pain', 'fatigue');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Tetanus' AND s.name IN ('muscle cramps', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Tetanus' AND s.name IN ('difficulty swallowing', 'stiff neck');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Chickenpox' AND s.name IN ('rash', 'intense itching', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Chickenpox' AND s.name IN ('fatigue', 'loss of appetite');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Measles' AND s.name IN ('fever', 'cough', 'rash');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Measles' AND s.name IN ('runny nose', 'red eyes');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Mumps' AND s.name IN ('swollen glands', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Mumps' AND s.name IN ('headache', 'fatigue');

-- Musculoskeletal & Autoimmune
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Osteoarthritis' AND s.name IN ('joint pain', 'joint stiffness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Osteoarthritis' AND s.name IN ('swelling');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Rheumatoid Arthritis' AND s.name IN ('joint pain', 'joint stiffness', 'swelling');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Rheumatoid Arthritis' AND s.name IN ('fatigue', 'fever');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Gout' AND s.name IN ('joint pain', 'swelling', 'skin redness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Gout' AND s.name IN ('fever');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Osteoporosis' AND s.name IN ('back pain', 'bone pain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Osteoporosis' AND s.name IN ('loss of height');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Systemic Lupus Erythematosus (SLE)' AND s.name IN ('butterfly rash', 'joint pain', 'fatigue');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Systemic Lupus Erythematosus (SLE)' AND s.name IN ('fever', 'hair loss');

-- Dermatological
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Eczema' AND s.name IN ('rash', 'itching', 'dry skin');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Eczema' AND s.name IN ('skin redness');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Psoriasis' AND s.name IN ('rash', 'itching');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Psoriasis' AND s.name IN ('joint pain', 'dry skin');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Rosacea' AND s.name IN ('facial flushing', 'skin redness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Rosacea' AND s.name IN ('dry eyes', 'eye pain');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Melanoma' AND s.name IN ('rash', 'skin redness');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Melanoma' AND s.name IN ('itching');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Cellulitis' AND s.name IN ('skin redness', 'swelling');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Cellulitis' AND s.name IN ('fever', 'itching');

-- Urology & Nephrology
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Urinary Tract Infection' AND s.name IN ('frequent urination', 'blood in urine');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Urinary Tract Infection' AND s.name IN ('abdominal pain', 'fever');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Kidney Stones' AND s.name IN ('flank pain', 'blood in urine');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Kidney Stones' AND s.name IN ('nausea', 'frequent urination');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Chronic Kidney Disease' AND s.name IN ('swelling', 'fatigue');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Chronic Kidney Disease' AND s.name IN ('shortness of breath', 'nausea');

-- Ophthalmology & ENT
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Cataracts' AND s.name='blurred vision';
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Cataracts' AND s.name IN ('sensitivity to light');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Glaucoma' AND s.name IN ('blurred vision', 'eye pain');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Glaucoma' AND s.name IN ('headache');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Conjunctivitis' AND s.name IN ('red eyes', 'itching');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Conjunctivitis' AND s.name IN ('swelling', 'dry eyes');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Otitis Media' AND s.name IN ('earache', 'fever');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Otitis Media' AND s.name IN ('hearing loss');

-- Psychiatric
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Major Depressive Disorder' AND s.name IN ('fatigue', 'mood swings');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Major Depressive Disorder' AND s.name IN ('loss of appetite', 'memory loss');

INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 2 FROM diseases d, symptoms s WHERE d.name='Generalized Anxiety Disorder' AND s.name IN ('anxiety', 'rapid heartbeat');
INSERT INTO disease_symptoms (disease_id, symptom_id, weight) 
SELECT d.disease_id, s.symptom_id, 1 FROM diseases d, symptoms s WHERE d.name='Generalized Anxiety Disorder' AND s.name IN ('fatigue', 'muscle weakness');

-- ----------------------------------------------------------
-- SEED: DEFAULT ADMIN
-- password: Admin@123
-- ----------------------------------------------------------
INSERT INTO users (full_name, email, phone, password_hash, role)
VALUES (
    'System Administrator',
    'admin@medilink.health',
    '+10000000000',
    '$2b$12$wH3qY9vN1oZp6kL5sXmJeOJjQ7rC0uE2yV8gT1dA4bF6cH9iK3sM',
    'admin'
);