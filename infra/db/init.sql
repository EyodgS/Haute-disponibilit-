CREATE TABLE IF NOT EXISTS appointments (
  id SERIAL PRIMARY KEY,
  patient_name VARCHAR(120) NOT NULL,
  doctor_name VARCHAR(120) NOT NULL,
  appointment_at TIMESTAMP NOT NULL
);

INSERT INTO appointments (patient_name, doctor_name, appointment_at)
VALUES
  ('Alice Martin', 'Dr. Dupont', NOW() + INTERVAL '1 day'),
  ('Karim Benali', 'Dr. Bernard', NOW() + INTERVAL '2 days'),
  ('Sophie Leroy', 'Dr. Simon', NOW() + INTERVAL '3 days')
ON CONFLICT DO NOTHING;
