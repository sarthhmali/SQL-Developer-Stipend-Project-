-- =========================================
-- HOSPITAL MANAGEMENT SYSTEM
-- PostgreSQL SQL Project
-- =========================================

-- Drop tables if already exist (for re-run)
DROP TABLE IF EXISTS prescriptions, medicines, payments, bills,
admissions, rooms, appointments, doctors, departments, patients CASCADE;

-- =========================================
-- 1. PATIENTS TABLE
-- =========================================
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    gender VARCHAR(10),
    date_of_birth DATE,
    phone VARCHAR(15) UNIQUE,
    email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- 2. DEPARTMENTS TABLE
-- =========================================
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL
);

-- =========================================
-- 3. DOCTORS TABLE
-- =========================================
CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(100),
    department_id INT REFERENCES departments(department_id),
    phone VARCHAR(15),
    experience_years INT CHECK (experience_years >= 0)
);

-- =========================================
-- 4. APPOINTMENTS TABLE
-- =========================================
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    doctor_id INT REFERENCES doctors(doctor_id),
    appointment_date DATE,
    appointment_time TIME,
    status VARCHAR(20)
    CHECK (status IN ('Scheduled','Completed','Cancelled'))
);

-- =========================================
-- 5. ROOMS TABLE
-- =========================================
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_type VARCHAR(50),
    room_charge NUMERIC(10,2),
    availability BOOLEAN DEFAULT TRUE
);

-- =========================================
-- 6. ADMISSIONS TABLE
-- =========================================
CREATE TABLE admissions (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    room_id INT REFERENCES rooms(room_id),
    admission_date DATE,
    discharge_date DATE
);

-- =========================================
-- 7. BILLS TABLE
-- =========================================
CREATE TABLE bills (
    bill_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    admission_id INT REFERENCES admissions(admission_id),
    total_amount NUMERIC(10,2),
    bill_date DATE DEFAULT CURRENT_DATE
);

-- =========================================
-- 8. PAYMENTS TABLE
-- =========================================
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    bill_id INT REFERENCES bills(bill_id),
    payment_date DATE,
    payment_mode VARCHAR(50),
    amount_paid NUMERIC(10,2)
);

-- =========================================
-- 9. MEDICINES TABLE
-- =========================================
CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100),
    price NUMERIC(10,2),
    stock INT CHECK (stock >= 0)
);

-- =========================================
-- 10. PRESCRIPTIONS TABLE
-- =========================================
CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    doctor_id INT REFERENCES doctors(doctor_id),
    medicine_id INT REFERENCES medicines(medicine_id),
    quantity INT,
    prescription_date DATE DEFAULT CURRENT_DATE
);

-- =========================================
-- SAMPLE DATA INSERTION
-- =========================================

INSERT INTO departments (department_name)
VALUES ('Cardiology'), ('Neurology'), ('Orthopedics');

INSERT INTO doctors (first_name,last_name,specialization,department_id,phone,experience_years)
VALUES
('Raj','Sharma','Cardiologist',1,'9876543210',10),
('Anita','Verma','Neurologist',2,'9876543222',8);

INSERT INTO patients (first_name,last_name,gender,date_of_birth,phone,email,address)
VALUES
('Amit','Patil','Male','1998-05-20','9000011111','amit@gmail.com','Pune'),
('Sneha','Kulkarni','Female','2000-08-10','9000022222','sneha@gmail.com','Mumbai');

INSERT INTO rooms (room_type,room_charge)
VALUES ('General',1500),('ICU',5000);

INSERT INTO medicines (medicine_name,price,stock)
VALUES
('Paracetamol',10,500),
('Amoxicillin',25,300);

-- =========================================
-- APPOINTMENT ENTRY
-- =========================================
INSERT INTO appointments (patient_id,doctor_id,appointment_date,appointment_time,status)
VALUES (1,1,'2025-01-05','10:30','Scheduled');

-- =========================================
-- ADMISSION ENTRY
-- =========================================
INSERT INTO admissions (patient_id,room_id,admission_date)
VALUES (1,1,'2025-01-05');

-- =========================================
-- BILLING & PAYMENT
-- =========================================
INSERT INTO bills (patient_id,admission_id,total_amount)
VALUES (1,1,8000);

INSERT INTO payments (bill_id,payment_date,payment_mode,amount_paid)
VALUES (1,'2025-01-06','UPI',8000);

-- =========================================
-- STORED PROCEDURE
-- =========================================
CREATE OR REPLACE FUNCTION add_new_patient(
    fname VARCHAR,
    lname VARCHAR,
    gen VARCHAR,
    dob DATE,
    ph VARCHAR
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO patients(first_name,last_name,gender,date_of_birth,phone)
    VALUES (fname,lname,gen,dob,ph);
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- TRIGGER TO UPDATE ROOM AVAILABILITY
-- =========================================
CREATE OR REPLACE FUNCTION room_unavailable()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE rooms
    SET availability = FALSE
    WHERE room_id = NEW.room_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER room_assign_trigger
AFTER INSERT ON admissions
FOR EACH ROW
EXECUTE FUNCTION room_unavailable();

-- =========================================
-- VIEWS
-- =========================================
CREATE VIEW patient_billing_view AS
SELECT p.first_name, p.last_name, b.total_amount, b.bill_date
FROM bills b
JOIN patients p ON b.patient_id = p.patient_id;

-- =========================================
-- REPORTING QUERIES
-- =========================================

-- Total Hospital Revenue
SELECT SUM(amount_paid) AS total_revenue FROM payments;

-- Currently Admitted Patients
SELECT p.first_name, r.room_type, a.admission_date
FROM admissions a
JOIN patients p ON a.patient_id = p.patient_id
JOIN rooms r ON a.room_id = r.room_id
WHERE a.discharge_date IS NULL;

-- Low Stock Medicines
SELECT medicine_name, stock FROM medicines WHERE stock < 100;
