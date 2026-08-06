"""Service layer for appointments."""
from backend.db import query, execute
from backend.services.notification_service import notify

DOCTOR_LIST_SQL = """
    SELECT u.user_id, u.full_name, u.email, u.phone, u.avatar_url,
           d.specialization, d.years_of_experience, d.consultation_fee,
           d.rating, d.is_verified
    FROM users u
    JOIN doctor_profiles d ON u.user_id = d.user_id
    WHERE u.role='doctor' AND u.is_active=TRUE
"""

def list_doctors(specialization: str = None):
    if specialization:
        return query(DOCTOR_LIST_SQL + " AND d.specialization LIKE %s ORDER BY d.rating DESC",
                     (f"%{specialization}%",))
    return query(DOCTOR_LIST_SQL + " ORDER BY d.rating DESC")

def book(patient_id: int, doctor_id: int, scheduled_at: str, reason: str) -> int:
    appt_id, _ = execute(
        """INSERT INTO appointments (patient_id, doctor_id, scheduled_at, reason)
           VALUES (%s,%s,%s,%s)""",
        (patient_id, doctor_id, scheduled_at, reason),
    )
    # Notify doctor
    notify(doctor_id, "New appointment request",
           "A patient has requested an appointment with you.", "info")
    # Notify patient
    notify(patient_id, "Appointment requested",
           "Your appointment request has been submitted. Awaiting confirmation.", "info")
    return appt_id

def for_patient(patient_id: int):
    return query(
        """SELECT a.*, u.full_name AS doctor_name, d.specialization
           FROM appointments a
           JOIN users u ON a.doctor_id = u.user_id
           LEFT JOIN doctor_profiles d ON a.doctor_id = d.user_id
           WHERE a.patient_id=%s ORDER BY a.scheduled_at DESC""",
        (patient_id,),
    )

def for_doctor(doctor_id: int):
    return query(
        """SELECT a.*, u.full_name AS patient_name, u.phone AS patient_phone,
                  p.gender, p.blood_group
           FROM appointments a
           JOIN users u ON a.patient_id = u.user_id
           LEFT JOIN patient_profiles p ON a.patient_id = p.user_id
           WHERE a.doctor_id=%s ORDER BY a.scheduled_at DESC""",
        (doctor_id,),
    )

def update_status(appointment_id: int, status: str, actor_id: int):
    execute("UPDATE appointments SET status=%s WHERE appointment_id=%s",
            (status, appointment_id))
    appt = query("SELECT * FROM appointments WHERE appointment_id=%s",
                 (appointment_id,), one=True)
    if appt:
        notify(appt["patient_id"], f"Appointment {status}",
               f"Your appointment has been {status}.", "info")

def all_appointments():
    return query(
        """SELECT a.*, p.full_name AS patient_name, d.full_name AS doctor_name
           FROM appointments a
           JOIN users p ON a.patient_id = p.user_id
           JOIN users d ON a.doctor_id = d.user_id
           ORDER BY a.scheduled_at DESC"""
    )