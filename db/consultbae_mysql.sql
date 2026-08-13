SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS match_conflicts;
DROP TABLE IF EXISTS audio_submissions;
DROP TABLE IF EXISTS cbnexus_contacts;
DROP TABLE IF EXISTS gig_worker_status;
DROP TABLE IF EXISTS naukri_applications;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS person_source_records;
DROP TABLE IF EXISTS people;

CREATE TABLE people (
    person_id INT AUTO_INCREMENT PRIMARY KEY,
    canonical_name VARCHAR(255),
    canonical_email VARCHAR(255),
    canonical_phone VARCHAR(20),
    canonical_city VARCHAR(100),
    matched_from_sources VARCHAR(255),
    match_confidence VARCHAR(20),
    INDEX idx_email (canonical_email),
    INDEX idx_phone (canonical_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE person_source_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    source VARCHAR(50),
    raw_name VARCHAR(255),
    raw_data JSON,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    skill VARCHAR(100),
    source VARCHAR(50),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE,
    INDEX idx_skill (skill)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE naukri_applications (
    person_id INT,
    experience_years DECIMAL(4,1),
    ctc_annual_inr INT,
    ctc_normalization_method VARCHAR(50),
    applied_date DATE,
    applied_date_raw VARCHAR(50),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE gig_worker_status (
    person_id INT,
    rate_monthly_inr INT,
    rate_normalization_method VARCHAR(50),
    status VARCHAR(20),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cbnexus_contacts (
    person_id INT,
    verified BOOLEAN,
    projects_completed INT,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE audio_submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    submitted_name VARCHAR(255),
    submitted_phone VARCHAR(20),
    file_path VARCHAR(500),
    duration_sec DECIMAL(8,2),
    sample_rate_hz INT,
    bitrate_kbps DECIMAL(8,2),
    loudness_dbfs DECIMAL(6,2),
    quality_estimate VARCHAR(50),
    created_at DATETIME,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE match_conflicts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name_key VARCHAR(255),
    city VARCHAR(100),
    detail JSON
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- Data

INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (1, 'Tanvi Gupta', 'tanvi.gupta31@example.com', '9000000254', 'Bengaluru', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (1, 'source1_naukri', 'Tanvi Gupta', '{"source": "source1_naukri", "raw_name": "Tanvi Gupta", "name": "Tanvi Gupta", "name_key": "tanvi gupta", "email": "tanvi.gupta31@example.com", "phone": "9000000254", "city": "Bengaluru", "experience_years": 4.2, "ctc_annual_inr": 417964, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-24", "applied_date_raw": "24-07-2026", "skills": ["n8n", "langchain", "rest apis", "mongodb", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'langchain', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'sql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (1, 4.2, 417964, 'raw_annual', '2026-07-24', '24-07-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (1, 'source2_gig', 'Tanvi Gupta', '{"source": "source2_gig", "raw_name": "Tanvi Gupta", "name": "Tanvi Gupta", "name_key": "tanvi gupta", "email": "tanvi.gupta31@example.com", "phone": null, "city": "Bengaluru", "rate_monthly_inr": 234256, "rate_normalization_method": "converted_from_hourly", "status": "Paused", "skills": ["n8n", "langchain", "rest apis", "mongodb", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'langchain', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (1, 'sql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (1, 234256, 'converted_from_hourly', 'Paused');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (1, 'source3_cbnexus', 'Tanvi Gupta', '{"source": "source3_cbnexus", "raw_name": "Tanvi Gupta", "name": "Tanvi Gupta", "name_key": "tanvi gupta", "email": null, "phone": "9000000254", "city": "Bengaluru", "verified": false, "projects_completed": 14}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (1, 0, 14);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (2, 'Manish Reddy', 'manish.reddy73@example.com', '9000000237', 'Gurgaon', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (2, 'source1_naukri', 'Manish Reddy', '{"source": "source1_naukri", "raw_name": "Manish Reddy", "name": "Manish Reddy", "name_key": "manish reddy", "email": "manish.reddy73@example.com", "phone": "9000000237", "city": "Gurgaon", "experience_years": 3.5, "ctc_annual_inr": 332456, "ctc_normalization_method": "raw_annual", "applied_date": "2026-08-08", "applied_date_raw": "2026-08-08", "skills": ["docker", "zapier", "javascript"]}');
INSERT INTO skills (person_id, skill, source) VALUES (2, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (2, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (2, 'javascript', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (2, 3.5, 332456, 'raw_annual', '2026-08-08', '2026-08-08');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (3, 'Priya Singh', 'priya.singh61@mailtest.example.org', '9000000287', 'Gurgaon', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (3, 'source1_naukri', 'Priya Singh', '{"source": "source1_naukri", "raw_name": "Priya Singh", "name": "Priya Singh", "name_key": "priya singh", "email": "priya.singh61@mailtest.example.org", "phone": "9000000287", "city": "Gurgaon", "experience_years": 3.0, "ctc_annual_inr": 775670, "ctc_normalization_method": "raw_annual", "applied_date": "2026-08-01", "applied_date_raw": "01-08-2026", "skills": ["react", "zapier", "n8n", "mysql", "python", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (3, 'sql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (3, 3.0, 775670, 'raw_annual', '2026-08-01', '01-08-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (3, 'source3_cbnexus', 'Priya Singh', '{"source": "source3_cbnexus", "raw_name": "Priya Singh", "name": "Priya Singh", "name_key": "priya singh", "email": null, "phone": "9000000287", "city": "Gurgaon", "verified": true, "projects_completed": 3}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (3, 1, 3);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (4, 'Vikram Saxena', 'vikram.saxena60@example.com', '9000000113', 'Gurgaon', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (4, 'source1_naukri', 'Vikram Saxena', '{"source": "source1_naukri", "raw_name": "Vikram Saxena", "name": "Vikram Saxena", "name_key": "vikram saxena", "email": "vikram.saxena60@example.com", "phone": "9000000113", "city": "Gurgaon", "experience_years": 1.9, "ctc_annual_inr": 654699, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-07", "applied_date_raw": "7 Jul 2026", "skills": ["selenium", "web scraping", "react", "docker", "sql", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'fastapi', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (4, 1.9, 654699, 'raw_annual', '2026-07-07', '7 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (4, 'source2_gig', 'Vikram Saxena', '{"source": "source2_gig", "raw_name": "Vikram Saxena", "name": "Vikram Saxena", "name_key": "vikram saxena", "email": "vikram.saxena60@example.com", "phone": null, "city": "Gurgaon", "rate_monthly_inr": 148368, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["selenium", "web scraping", "react", "docker", "sql", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (4, 'fastapi', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (4, 148368, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (4, 'source3_cbnexus', 'Vikram Saxena', '{"source": "source3_cbnexus", "raw_name": "Vikram Saxena", "name": "Vikram Saxena", "name_key": "vikram saxena", "email": null, "phone": "9000000113", "city": "Gurgaon", "verified": false, "projects_completed": 15}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (4, 0, 15);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (5, 'Amit Agarwal', 'amit.agarwal3@mailtest.example.org', '9000000288', 'Pune', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (5, 'source1_naukri', 'Amit Agarwal', '{"source": "source1_naukri", "raw_name": "Amit Agarwal", "name": "Amit Agarwal", "name_key": "amit agarwal", "email": "amit.agarwal3@mailtest.example.org", "phone": "9000000288", "city": "Pune", "experience_years": 1.8, "ctc_annual_inr": 420000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-19", "applied_date_raw": "19-07-2026", "skills": ["sql", "python", "javascript", "docker"]}');
INSERT INTO skills (person_id, skill, source) VALUES (5, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (5, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (5, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (5, 'docker', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (5, 1.8, 420000, 'inferred_lpa_shorthand', '2026-07-19', '19-07-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (6, 'Sahil Malhotra', 'sahil.malhotra1@example.in', '9000000143', 'Noida', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (6, 'source1_naukri', 'Sahil Malhotra', '{"source": "source1_naukri", "raw_name": "Sahil Malhotra", "name": "Sahil Malhotra", "name_key": "sahil malhotra", "email": "sahil.malhotra1@example.in", "phone": "9000000143", "city": "Noida", "experience_years": 1.7, "ctc_annual_inr": 806661, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-13", "applied_date_raw": "07/13/2026", "skills": ["fastapi", "docker", "mysql", "zapier", "pandas", "rest apis"]}');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (6, 'rest apis', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (6, 1.7, 806661, 'raw_annual', '2026-07-13', '07/13/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (6, 'source3_cbnexus', 'SAHIL MALHOTRA', '{"source": "source3_cbnexus", "raw_name": "SAHIL MALHOTRA", "name": "Sahil Malhotra", "name_key": "sahil malhotra", "email": null, "phone": "9000000143", "city": "Noida", "verified": false, "projects_completed": 0}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (6, 0, 0);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (7, 'Shreya Gupta', 'shreya.gupta85@example.com', '9000000227', 'Noida', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (7, 'source1_naukri', 'Shreya Gupta', '{"source": "source1_naukri", "raw_name": "Shreya Gupta", "name": "Shreya Gupta", "name_key": "shreya gupta", "email": "shreya.gupta85@example.com", "phone": "9000000227", "city": "Noida", "experience_years": 3.3, "ctc_annual_inr": 830000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-19", "applied_date_raw": "19 Jul 2026", "skills": ["zapier", "web scraping", "docker", "n8n", "python"]}');
INSERT INTO skills (person_id, skill, source) VALUES (7, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (7, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (7, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (7, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (7, 'python', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (7, 3.3, 830000, 'inferred_lpa_shorthand', '2026-07-19', '19 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (7, 'source3_cbnexus', 'Shreya Gupta', '{"source": "source3_cbnexus", "raw_name": "Shreya Gupta", "name": "Shreya Gupta", "name_key": "shreya gupta", "email": null, "phone": "9000000227", "city": "Noida", "verified": true, "projects_completed": 13}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (7, 1, 13);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (8, 'Isha Chopra', 'isha.chopra95@mailtest.example.org', '9000000138', 'Pune', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (8, 'source1_naukri', 'Isha Chopra', '{"source": "source1_naukri", "raw_name": "Isha Chopra", "name": "Isha Chopra", "name_key": "isha chopra", "email": "isha.chopra95@mailtest.example.org", "phone": "9000000138", "city": "Pune", "experience_years": 5.4, "ctc_annual_inr": 472935, "ctc_normalization_method": "raw_annual", "applied_date": "2026-08-02", "applied_date_raw": "2026-08-02", "skills": ["react", "javascript", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'mysql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (8, 5.4, 472935, 'raw_annual', '2026-08-02', '2026-08-02');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (8, 'source2_gig', 'Isha Chopra', '{"source": "source2_gig", "raw_name": "Isha Chopra", "name": "Isha Chopra", "name_key": "isha chopra", "email": "isha.chopra95@mailtest.example.org", "phone": null, "city": "Pune", "rate_monthly_inr": 247456, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["react", "javascript", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (8, 'mysql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (8, 247456, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (8, 'source3_cbnexus', 'Isha Chopra', '{"source": "source3_cbnexus", "raw_name": "Isha Chopra", "name": "Isha Chopra", "name_key": "isha chopra", "email": null, "phone": "9000000138", "city": "Pune", "verified": false, "projects_completed": 7}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (8, 0, 7);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (9, 'Priya Nair', 'priya.nair70@example.com', '9000000222', 'Gurgaon', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (9, 'source1_naukri', 'Priya Nair', '{"source": "source1_naukri", "raw_name": "Priya Nair", "name": "Priya Nair", "name_key": "priya nair", "email": "priya.nair70@example.com", "phone": "9000000222", "city": "Gurgaon", "experience_years": 5.6, "ctc_annual_inr": 366311, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-28", "applied_date_raw": "28-07-2026", "skills": ["zapier", "rest apis", "react", "python", "n8n", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (9, 'web scraping', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (9, 5.6, 366311, 'raw_annual', '2026-07-28', '28-07-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (10, 'Rohit Mishra', 'rohit.mishra70@mailtest.example.org', '9000000167', 'Delhi', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (10, 'source1_naukri', 'Rohit Mishra', '{"source": "source1_naukri", "raw_name": "Rohit Mishra", "name": "Rohit Mishra", "name_key": "rohit mishra", "email": "rohit.mishra70@mailtest.example.org", "phone": "9000000167", "city": "Delhi", "experience_years": 4.4, "ctc_annual_inr": 871686, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-13", "applied_date_raw": "2026-07-13", "skills": ["docker", "pandas", "fastapi", "sql", "zapier", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (10, 'mysql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (10, 4.4, 871686, 'raw_annual', '2026-07-13', '2026-07-13');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (11, 'Rahul Malhotra', 'rahul.malhotra69@mailtest.example.org', '9000000260', 'Delhi', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (11, 'source1_naukri', 'Rahul Malhotra', '{"source": "source1_naukri", "raw_name": "Rahul Malhotra", "name": "Rahul Malhotra", "name_key": "rahul malhotra", "email": "rahul.malhotra69@mailtest.example.org", "phone": "9000000260", "city": "Delhi", "experience_years": 2.5, "ctc_annual_inr": 864237, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-03", "applied_date_raw": "07/03/2026", "skills": ["mysql", "rest apis", "sql", "mongodb", "selenium"]}');
INSERT INTO skills (person_id, skill, source) VALUES (11, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (11, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (11, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (11, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (11, 'selenium', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (11, 2.5, 864237, 'raw_annual', '2026-07-03', '07/03/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (11, 'source3_cbnexus', 'RAHUL MALHOTRA', '{"source": "source3_cbnexus", "raw_name": "RAHUL MALHOTRA", "name": "Rahul Malhotra", "name_key": "rahul malhotra", "email": null, "phone": "9000000260", "city": "Delhi", "verified": false, "projects_completed": 4}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (11, 0, 4);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (12, 'Rahul Jain', 'rahul.jain34@example.in', '9000000114', 'Noida', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (12, 'source1_naukri', 'Rahul Jain', '{"source": "source1_naukri", "raw_name": "Rahul Jain", "name": "Rahul Jain", "name_key": "rahul jain", "email": "rahul.jain34@example.in", "phone": "9000000114", "city": "Noida", "experience_years": 2.8, "ctc_annual_inr": 1195422, "ctc_normalization_method": "raw_annual", "applied_date": "2026-06-24", "applied_date_raw": "2026-06-24", "skills": ["zapier", "selenium", "docker", "python"]}');
INSERT INTO skills (person_id, skill, source) VALUES (12, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (12, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (12, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (12, 'python', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (12, 2.8, 1195422, 'raw_annual', '2026-06-24', '2026-06-24');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (13, 'Nikhil Malhotra', 'nikhil.malhotra41@example.in', '9000000145', 'Delhi', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (13, 'source1_naukri', 'Nikhil Malhotra', '{"source": "source1_naukri", "raw_name": "Nikhil Malhotra", "name": "Nikhil Malhotra", "name_key": "nikhil malhotra", "email": "nikhil.malhotra41@example.in", "phone": "9000000145", "city": "Delhi", "experience_years": 4.2, "ctc_annual_inr": 510000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-21", "applied_date_raw": "21-08-2026", "skills": ["fastapi", "javascript", "web scraping", "sql", "python"]}');
INSERT INTO skills (person_id, skill, source) VALUES (13, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (13, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (13, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (13, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (13, 'python', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (13, 4.2, 510000, 'inferred_lpa_shorthand', '2026-08-21', '21-08-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (14, 'Karan Bhatia', 'karan.bhatia32@mailtest.example.org', '9000000211', 'Noida', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (14, 'source1_naukri', 'Karan Bhatia', '{"source": "source1_naukri", "raw_name": "Karan Bhatia", "name": "Karan Bhatia", "name_key": "karan bhatia", "email": "karan.bhatia32@mailtest.example.org", "phone": "9000000211", "city": "Noida", "experience_years": 4.7, "ctc_annual_inr": 826748, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-08", "applied_date_raw": "8 Jul 2026", "skills": ["sql", "mongodb", "selenium", "zapier", "web scraping", "javascript"]}');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'javascript', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (14, 4.7, 826748, 'raw_annual', '2026-07-08', '8 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (14, 'source2_gig', 'Karan Bhatia', '{"source": "source2_gig", "raw_name": "Karan Bhatia", "name": "Karan Bhatia", "name_key": "karan bhatia", "email": "karan.bhatia32@mailtest.example.org", "phone": null, "city": "Noida", "rate_monthly_inr": 70928, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["sql", "mongodb", "selenium", "zapier", "web scraping", "javascript"]}');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (14, 'javascript', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (14, 70928, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (14, 'source3_cbnexus', 'KARAN BHATIA', '{"source": "source3_cbnexus", "raw_name": "KARAN BHATIA", "name": "Karan Bhatia", "name_key": "karan bhatia", "email": null, "phone": "9000000211", "city": "Noida", "verified": true, "projects_completed": 2}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (14, 1, 2);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (15, 'Ritu Sharma', 'ritu.sharma23@mailtest.example.org', '9000000146', 'Noida', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (15, 'source1_naukri', 'Ritu Sharma', '{"source": "source1_naukri", "raw_name": "Ritu Sharma", "name": "Ritu Sharma", "name_key": "ritu sharma", "email": "ritu.sharma23@mailtest.example.org", "phone": "9000000146", "city": "Noida", "experience_years": 4.8, "ctc_annual_inr": 610000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-03", "applied_date_raw": "2026-08-03", "skills": ["n8n", "web scraping", "mongodb", "sql", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (15, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (15, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (15, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (15, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (15, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (15, 4.8, 610000, 'inferred_lpa_shorthand', '2026-08-03', '2026-08-03');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (15, 'source3_cbnexus', 'RITU SHARMA', '{"source": "source3_cbnexus", "raw_name": "RITU SHARMA", "name": "Ritu Sharma", "name_key": "ritu sharma", "email": null, "phone": "9000000146", "city": "Noida", "verified": true, "projects_completed": 15}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (15, 1, 15);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (16, 'Arjun Mishra', 'arjun.mishra70@example.com', '9000000106', 'Delhi', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (16, 'source1_naukri', 'Arjun Mishra', '{"source": "source1_naukri", "raw_name": "Arjun Mishra", "name": "Arjun Mishra", "name_key": "arjun mishra", "email": "arjun.mishra70@example.com", "phone": "9000000106", "city": "Delhi", "experience_years": 1.3, "ctc_annual_inr": 580000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-22", "applied_date_raw": "22-08-2026", "skills": ["react", "docker", "javascript"]}');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'javascript', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (16, 1.3, 580000, 'inferred_lpa_shorthand', '2026-08-22', '22-08-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (16, 'source2_gig', 'Arjun Mishra', '{"source": "source2_gig", "raw_name": "Arjun Mishra", "name": "Arjun Mishra", "name_key": "arjun mishra", "email": "arjun.mishra70@example.com", "phone": null, "city": "Delhi", "rate_monthly_inr": 77440, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["react", "docker", "javascript"]}');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (16, 'javascript', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (16, 77440, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (16, 'source3_cbnexus', 'Arjun Mishra', '{"source": "source3_cbnexus", "raw_name": "Arjun Mishra", "name": "Arjun Mishra", "name_key": "arjun mishra", "email": null, "phone": "9000000106", "city": "Delhi", "verified": false, "projects_completed": 10}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (16, 0, 10);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (17, 'Meera Bhatia', 'meera.bhatia52@mailtest.example.org', '9000000223', 'Delhi', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (17, 'source1_naukri', 'Meera Bhatia', '{"source": "source1_naukri", "raw_name": "Meera Bhatia", "name": "Meera Bhatia", "name_key": "meera bhatia", "email": "meera.bhatia52@mailtest.example.org", "phone": "9000000223", "city": "Delhi", "experience_years": 5.1, "ctc_annual_inr": 1120000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-03", "applied_date_raw": "2026-07-03", "skills": ["langchain", "docker", "mysql", "python", "sql", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'langchain', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (17, 5.1, 1120000, 'inferred_lpa_shorthand', '2026-07-03', '2026-07-03');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (17, 'source2_gig', 'Meera Bhatia', '{"source": "source2_gig", "raw_name": "Meera Bhatia", "name": "Meera Bhatia", "name_key": "meera bhatia", "email": "meera.bhatia52@mailtest.example.org", "phone": null, "city": "Delhi", "rate_monthly_inr": 58080, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["langchain", "docker", "mysql", "python", "sql", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'langchain', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'mysql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (17, 'react', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (17, 58080, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (17, 'source3_cbnexus', 'MEERA BHATIA', '{"source": "source3_cbnexus", "raw_name": "MEERA BHATIA", "name": "Meera Bhatia", "name_key": "meera bhatia", "email": null, "phone": "9000000223", "city": "Delhi", "verified": false, "projects_completed": 4}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (17, 0, 4);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (18, 'Varun Jain', 'varun.jain29@example.com', '9000000263', 'Pune', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (18, 'source1_naukri', 'Varun Jain', '{"source": "source1_naukri", "raw_name": "Varun Jain", "name": "Varun Jain", "name_key": "varun jain", "email": "varun.jain29@example.com", "phone": "9000000263", "city": "Pune", "experience_years": 3.1, "ctc_annual_inr": 760000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-19", "applied_date_raw": "08/19/2026", "skills": ["n8n", "web scraping", "fastapi", "mysql", "pandas", "mongodb"]}');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'mongodb', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (18, 3.1, 760000, 'inferred_lpa_shorthand', '2026-08-19', '08/19/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (18, 'source2_gig', 'Varun Jain', '{"source": "source2_gig", "raw_name": "Varun Jain", "name": "Varun Jain", "name_key": "varun jain", "email": "varun.jain29@example.com", "phone": null, "city": "Pune", "rate_monthly_inr": 249040, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["n8n", "web scraping", "fastapi", "mysql", "pandas", "mongodb"]}');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'mysql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (18, 'mongodb', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (18, 249040, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (18, 'source3_cbnexus', 'Varun Jain', '{"source": "source3_cbnexus", "raw_name": "Varun Jain", "name": "Varun Jain", "name_key": "varun jain", "email": null, "phone": "9000000263", "city": "Pune", "verified": true, "projects_completed": 14}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (18, 1, 14);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (19, 'Arjun Mehta', 'arjun.mehta9@example.in', '9000000131', 'Noida', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (19, 'source1_naukri', 'Arjun Mehta', '{"source": "source1_naukri", "raw_name": "Arjun Mehta", "name": "Arjun Mehta", "name_key": "arjun mehta", "email": "arjun.mehta9@example.in", "phone": "9000000131", "city": "Noida", "experience_years": 4.0, "ctc_annual_inr": 1181149, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-21", "applied_date_raw": "21-07-2026", "skills": ["sql", "selenium", "n8n"]}');
INSERT INTO skills (person_id, skill, source) VALUES (19, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (19, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (19, 'n8n', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (19, 4.0, 1181149, 'raw_annual', '2026-07-21', '21-07-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (19, 'source3_cbnexus', 'Arjun Mehta', '{"source": "source3_cbnexus", "raw_name": "Arjun Mehta", "name": "Arjun Mehta", "name_key": "arjun mehta", "email": null, "phone": "9000000131", "city": "Noida", "verified": false, "projects_completed": 9}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (19, 0, 9);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (20, 'Kavya Mehta', 'kavya.mehta7@example.com', '9000000177', 'Bengaluru', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (20, 'source1_naukri', 'Kavya Mehta', '{"source": "source1_naukri", "raw_name": "Kavya Mehta", "name": "Kavya Mehta", "name_key": "kavya mehta", "email": "kavya.mehta7@example.com", "phone": "9000000177", "city": "Bengaluru", "experience_years": 5.1, "ctc_annual_inr": 240000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-02", "applied_date_raw": "2 Jul 2026", "skills": ["n8n", "mongodb", "fastapi", "pandas", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (20, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (20, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (20, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (20, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (20, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (20, 5.1, 240000, 'inferred_lpa_shorthand', '2026-07-02', '2 Jul 2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (21, 'Sneha Chopra', 'sneha.chopra99@example.in', '9000000162', 'Pune', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (21, 'source1_naukri', 'Sneha Chopra', '{"source": "source1_naukri", "raw_name": "Sneha Chopra", "name": "Sneha Chopra", "name_key": "sneha chopra", "email": "sneha.chopra99@example.in", "phone": "9000000162", "city": "Pune", "experience_years": 4.9, "ctc_annual_inr": 1000000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-03", "applied_date_raw": "03-07-2026", "skills": ["pandas", "react", "mysql", "javascript", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'sql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (21, 4.9, 1000000, 'inferred_lpa_shorthand', '2026-07-03', '03-07-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (21, 'source2_gig', 'Sneha Chopra', '{"source": "source2_gig", "raw_name": "Sneha Chopra", "name": "Sneha Chopra", "name_key": "sneha chopra", "email": "sneha.chopra99@example.in", "phone": null, "city": "Pune", "rate_monthly_inr": 28000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["pandas", "react", "mysql", "javascript", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'mysql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (21, 'sql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (21, 28000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (21, 'source3_cbnexus', 'Sneha Chopra', '{"source": "source3_cbnexus", "raw_name": "Sneha Chopra", "name": "Sneha Chopra", "name_key": "sneha chopra", "email": null, "phone": "9000000162", "city": "Pune", "verified": false, "projects_completed": 14}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (21, 0, 14);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (22, 'Deepak Mehta', 'deepak.mehta86@example.in', '9000000116', 'Noida', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (22, 'source1_naukri', 'Deepak Mehta', '{"source": "source1_naukri", "raw_name": "Deepak Mehta", "name": "Deepak Mehta", "name_key": "deepak mehta", "email": "deepak.mehta86@example.in", "phone": "9000000116", "city": "Noida", "experience_years": 2.7, "ctc_annual_inr": 327287, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-23", "applied_date_raw": "2026-07-23", "skills": ["mysql", "mongodb", "n8n", "langchain", "rest apis", "selenium"]}');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'langchain', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (22, 'selenium', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (22, 2.7, 327287, 'raw_annual', '2026-07-23', '2026-07-23');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (22, 'source3_cbnexus', 'Deepak Mehta', '{"source": "source3_cbnexus", "raw_name": "Deepak Mehta", "name": "Deepak Mehta", "name_key": "deepak mehta", "email": null, "phone": "9000000116", "city": "Noida", "verified": true, "projects_completed": 11}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (22, 1, 11);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (23, 'Pooja Gupta', 'pooja.gupta57@mailtest.example.org', '9000000271', 'Noida', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (23, 'source1_naukri', 'Pooja Gupta', '{"source": "source1_naukri", "raw_name": "Pooja Gupta", "name": "Pooja Gupta", "name_key": "pooja gupta", "email": "pooja.gupta57@mailtest.example.org", "phone": "9000000271", "city": "Noida", "experience_years": 3.9, "ctc_annual_inr": 1190000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-06-24", "applied_date_raw": "24-06-2026", "skills": ["docker", "mysql", "sql", "n8n", "selenium"]}');
INSERT INTO skills (person_id, skill, source) VALUES (23, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (23, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (23, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (23, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (23, 'selenium', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (23, 3.9, 1190000, 'inferred_lpa_shorthand', '2026-06-24', '24-06-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (24, 'R. Verma', 'rohit.verma13@mailtest.example.org', '9000000294', 'Bengaluru', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (24, 'source1_naukri', 'R. Verma', '{"source": "source1_naukri", "raw_name": "R. Verma", "name": "R. Verma", "name_key": "r verma", "email": "rohit.verma13@mailtest.example.org", "phone": "9000000294", "city": "Bengaluru", "experience_years": 2.4, "ctc_annual_inr": 610000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-13", "applied_date_raw": "08/13/2026", "skills": ["python", "react", "mongodb"]}');
INSERT INTO skills (person_id, skill, source) VALUES (24, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (24, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (24, 'mongodb', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (24, 2.4, 610000, 'inferred_lpa_shorthand', '2026-08-13', '08/13/2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (25, 'Sneha Mishra', 'sneha.mishra14@mailtest.example.org', '9000000229', 'Pune', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (25, 'source1_naukri', 'Sneha Mishra', '{"source": "source1_naukri", "raw_name": "Sneha Mishra", "name": "Sneha Mishra", "name_key": "sneha mishra", "email": "sneha.mishra14@mailtest.example.org", "phone": "9000000229", "city": "Pune", "experience_years": 1.4, "ctc_annual_inr": 410629, "ctc_normalization_method": "raw_annual", "applied_date": "2026-06-15", "applied_date_raw": "15-06-2026", "skills": ["mysql", "docker", "selenium", "pandas"]}');
INSERT INTO skills (person_id, skill, source) VALUES (25, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (25, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (25, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (25, 'pandas', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (25, 1.4, 410629, 'raw_annual', '2026-06-15', '15-06-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (26, 'Nikhil Chopra', 'alt.nikhil.chopra70@example.com', '9000000103', 'Noida', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (26, 'source1_naukri', 'Nikhil Chopra', '{"source": "source1_naukri", "raw_name": "Nikhil Chopra", "name": "Nikhil Chopra", "name_key": "nikhil chopra", "email": "alt.nikhil.chopra70@example.com", "phone": "9000000103", "city": "Noida", "experience_years": 0.8, "ctc_annual_inr": 780000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-03", "applied_date_raw": "07/03/2026", "skills": ["pandas", "sql", "n8n"]}');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'n8n', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (26, 0.8, 780000, 'inferred_lpa_shorthand', '2026-07-03', '07/03/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (26, 'source1_naukri', 'Nikhil Chopra', '{"source": "source1_naukri", "raw_name": "Nikhil Chopra", "name": "Nikhil Chopra", "name_key": "nikhil chopra", "email": "nikhil.chopra70@example.com", "phone": "9000000103", "city": "Noida", "experience_years": 0.8, "ctc_annual_inr": 780000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-03", "applied_date_raw": "07/03/2026", "skills": ["pandas", "sql", "n8n"]}');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (26, 'n8n', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (26, 0.8, 780000, 'inferred_lpa_shorthand', '2026-07-03', '07/03/2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (27, 'Priya Saxena', 'priya.saxena61@example.com', '9000000231', 'Delhi', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (27, 'source1_naukri', 'Priya Saxena', '{"source": "source1_naukri", "raw_name": "Priya Saxena", "name": "Priya Saxena", "name_key": "priya saxena", "email": "priya.saxena61@example.com", "phone": "9000000231", "city": "Delhi", "experience_years": 5.0, "ctc_annual_inr": 660000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-16", "applied_date_raw": "08/16/2026", "skills": ["python", "mysql", "zapier", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (27, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (27, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (27, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (27, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (27, 5.0, 660000, 'inferred_lpa_shorthand', '2026-08-16', '08/16/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (27, 'source3_cbnexus', 'Priya Saxena', '{"source": "source3_cbnexus", "raw_name": "Priya Saxena", "name": "Priya Saxena", "name_key": "priya saxena", "email": null, "phone": "9000000231", "city": "Delhi", "verified": false, "projects_completed": 12}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (27, 0, 12);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (28, 'Varun Saxena', 'varun.saxena21@example.in', '9000000170', 'Gurgaon', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (28, 'source1_naukri', 'Varun Saxena', '{"source": "source1_naukri", "raw_name": "Varun Saxena", "name": "Varun Saxena", "name_key": "varun saxena", "email": "varun.saxena21@example.in", "phone": "9000000170", "city": "Gurgaon", "experience_years": 3.7, "ctc_annual_inr": 775796, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-05", "applied_date_raw": "5 Jul 2026", "skills": ["mongodb", "zapier", "sql", "langchain", "mysql", "rest apis"]}');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'langchain', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'rest apis', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (28, 3.7, 775796, 'raw_annual', '2026-07-05', '5 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (28, 'source2_gig', 'Varun Saxena', '{"source": "source2_gig", "raw_name": "Varun Saxena", "name": "Varun Saxena", "name_key": "varun saxena", "email": "varun.saxena21@example.in", "phone": null, "city": "Gurgaon", "rate_monthly_inr": 161392, "rate_normalization_method": "converted_from_hourly", "status": "Inactive", "skills": ["mongodb", "zapier", "sql", "langchain", "mysql", "rest apis"]}');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'langchain', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'mysql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (28, 'rest apis', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (28, 161392, 'converted_from_hourly', 'Inactive');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (28, 'source3_cbnexus', 'VARUN SAXENA', '{"source": "source3_cbnexus", "raw_name": "VARUN SAXENA", "name": "Varun Saxena", "name_key": "varun saxena", "email": null, "phone": "9000000170", "city": "Gurgaon", "verified": true, "projects_completed": 1}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (28, 1, 1);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (29, 'Gaurav Mehta', 'gaurav.mehta79@mailtest.example.org', '9000000133', 'Bengaluru', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (29, 'source1_naukri', 'Gaurav Mehta', '{"source": "source1_naukri", "raw_name": "Gaurav Mehta", "name": "Gaurav Mehta", "name_key": "gaurav mehta", "email": "gaurav.mehta79@mailtest.example.org", "phone": "9000000133", "city": "Bengaluru", "experience_years": 3.1, "ctc_annual_inr": 792474, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-19", "applied_date_raw": "19-07-2026", "skills": ["rest apis", "sql", "selenium", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'fastapi', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (29, 3.1, 792474, 'raw_annual', '2026-07-19', '19-07-2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (29, 'source2_gig', 'Gaurav Mehta', '{"source": "source2_gig", "raw_name": "Gaurav Mehta", "name": "Gaurav Mehta", "name_key": "gaurav mehta", "email": "gaurav.mehta79@mailtest.example.org", "phone": null, "city": "Bengaluru", "rate_monthly_inr": 56000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["rest apis", "sql", "selenium", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (29, 'fastapi', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (29, 56000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (29, 'source3_cbnexus', 'Gaurav Mehta', '{"source": "source3_cbnexus", "raw_name": "Gaurav Mehta", "name": "Gaurav Mehta", "name_key": "gaurav mehta", "email": null, "phone": "9000000133", "city": "Bengaluru", "verified": false, "projects_completed": 1}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (29, 0, 1);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (30, 'Rohit Nair', 'rohit.nair32@mailtest.example.org', '9000000268', 'Gurgaon', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (30, 'source1_naukri', 'Rohit Nair', '{"source": "source1_naukri", "raw_name": "Rohit Nair", "name": "Rohit Nair", "name_key": "rohit nair", "email": "rohit.nair32@mailtest.example.org", "phone": "9000000268", "city": "Gurgaon", "experience_years": 2.4, "ctc_annual_inr": 760000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-19", "applied_date_raw": "2026-08-19", "skills": ["rest apis", "n8n", "web scraping", "docker"]}');
INSERT INTO skills (person_id, skill, source) VALUES (30, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (30, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (30, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (30, 'docker', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (30, 2.4, 760000, 'inferred_lpa_shorthand', '2026-08-19', '2026-08-19');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (30, 'source3_cbnexus', 'Rohit Nair', '{"source": "source3_cbnexus", "raw_name": "Rohit Nair", "name": "Rohit Nair", "name_key": "rohit nair", "email": null, "phone": "9000000268", "city": "Gurgaon", "verified": true, "projects_completed": 13}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (30, 1, 13);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (31, 'Deepak Nair', 'deepak.nair44@example.com', '9000000296', 'Bengaluru', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (31, 'source1_naukri', 'Deepak Nair', '{"source": "source1_naukri", "raw_name": "Deepak Nair", "name": "Deepak Nair", "name_key": "deepak nair", "email": "deepak.nair44@example.com", "phone": "9000000296", "city": "Bengaluru", "experience_years": 5.0, "ctc_annual_inr": 1160787, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-15", "applied_date_raw": "15 Jul 2026", "skills": ["react", "n8n", "mongodb", "pandas"]}');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'pandas', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (31, 5.0, 1160787, 'raw_annual', '2026-07-15', '15 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (31, 'source2_gig', 'Deepak Nair', '{"source": "source2_gig", "raw_name": "Deepak Nair", "name": "Deepak Nair", "name_key": "deepak nair", "email": "deepak.nair44@example.com", "phone": null, "city": "Bengaluru", "rate_monthly_inr": 81840, "rate_normalization_method": "converted_from_hourly", "status": "Paused", "skills": ["react", "n8n", "mongodb", "pandas"]}');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (31, 'pandas', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (31, 81840, 'converted_from_hourly', 'Paused');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (31, 'source3_cbnexus', 'DEEPAK NAIR', '{"source": "source3_cbnexus", "raw_name": "DEEPAK NAIR", "name": "Deepak Nair", "name_key": "deepak nair", "email": null, "phone": "9000000296", "city": "Bengaluru", "verified": true, "projects_completed": 2}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (31, 1, 2);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (32, 'Rahul Chopra', 'rahul.chopra70@example.com', '9000000137', 'Noida', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (32, 'source1_naukri', 'Rahul Chopra', '{"source": "source1_naukri", "raw_name": "Rahul Chopra", "name": "Rahul Chopra", "name_key": "rahul chopra", "email": "rahul.chopra70@example.com", "phone": "9000000137", "city": "Noida", "experience_years": 1.7, "ctc_annual_inr": 270000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-27", "applied_date_raw": "27 Jul 2026", "skills": ["zapier", "docker", "python"]}');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'python', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (32, 1.7, 270000, 'inferred_lpa_shorthand', '2026-07-27', '27 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (32, 'source2_gig', 'Rahul Chopra', '{"source": "source2_gig", "raw_name": "Rahul Chopra", "name": "Rahul Chopra", "name_key": "rahul chopra", "email": "rahul.chopra70@example.com", "phone": null, "city": "Noida", "rate_monthly_inr": 72000, "rate_normalization_method": "raw_monthly", "status": "Inactive", "skills": ["zapier", "docker", "python"]}');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (32, 'python', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (32, 72000, 'raw_monthly', 'Inactive');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (32, 'source3_cbnexus', 'Rahul Chopra', '{"source": "source3_cbnexus", "raw_name": "Rahul Chopra", "name": "Rahul Chopra", "name_key": "rahul chopra", "email": null, "phone": "9000000137", "city": "Noida", "verified": false, "projects_completed": 10}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (32, 0, 10);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (33, 'Deepak Singh', 'deepak.singh36@mailtest.example.org', '9000000202', 'Bengaluru', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (33, 'source1_naukri', 'Deepak Singh', '{"source": "source1_naukri", "raw_name": "Deepak Singh", "name": "Deepak Singh", "name_key": "deepak singh", "email": "deepak.singh36@mailtest.example.org", "phone": "9000000202", "city": "Bengaluru", "experience_years": 1.7, "ctc_annual_inr": 1135514, "ctc_normalization_method": "raw_annual", "applied_date": "2026-08-11", "applied_date_raw": "08/11/2026", "skills": ["web scraping", "fastapi", "docker", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (33, 'web scraping', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (33, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (33, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (33, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (33, 1.7, 1135514, 'raw_annual', '2026-08-11', '08/11/2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (34, 'Amit Reddy', 'amit.reddy9@mailtest.example.org', '9000000165', 'Delhi', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (34, 'source1_naukri', 'Amit Reddy', '{"source": "source1_naukri", "raw_name": "Amit Reddy", "name": "Amit Reddy", "name_key": "amit reddy", "email": "amit.reddy9@mailtest.example.org", "phone": "9000000165", "city": "Delhi", "experience_years": 2.7, "ctc_annual_inr": 1140000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-21", "applied_date_raw": "21 Jul 2026", "skills": ["react", "mysql", "langchain"]}');
INSERT INTO skills (person_id, skill, source) VALUES (34, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (34, 'mysql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (34, 'langchain', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (34, 2.7, 1140000, 'inferred_lpa_shorthand', '2026-07-21', '21 Jul 2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (35, 'Tanvi Agarwal', 'tanvi.agarwal97@example.in', '9000000148', 'Pune', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (35, 'source1_naukri', 'Tanvi Agarwal', '{"source": "source1_naukri", "raw_name": "Tanvi Agarwal", "name": "Tanvi Agarwal", "name_key": "tanvi agarwal", "email": "tanvi.agarwal97@example.in", "phone": "9000000148", "city": "Pune", "experience_years": 5.0, "ctc_annual_inr": 626740, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-27", "applied_date_raw": "27 Jul 2026", "skills": ["mongodb", "rest apis", "fastapi", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'mongodb', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'web scraping', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (35, 5.0, 626740, 'raw_annual', '2026-07-27', '27 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (35, 'source2_gig', 'Tanvi Agarwal', '{"source": "source2_gig", "raw_name": "Tanvi Agarwal", "name": "Tanvi Agarwal", "name_key": "tanvi agarwal", "email": "tanvi.agarwal97@example.in", "phone": null, "city": "Pune", "rate_monthly_inr": 216656, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["mongodb", "rest apis", "fastapi", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (35, 'web scraping', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (35, 216656, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (35, 'source3_cbnexus', 'Tanvi Agarwal', '{"source": "source3_cbnexus", "raw_name": "Tanvi Agarwal", "name": "Tanvi Agarwal", "name_key": "tanvi agarwal", "email": null, "phone": "9000000148", "city": "Pune", "verified": false, "projects_completed": 3}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (35, 0, 3);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (36, 'Nikhil Mehta', 'nikhil.mehta5@example.com', '9000000104', 'Pune', 'source1_naukri,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (36, 'source1_naukri', 'Nikhil Mehta', '{"source": "source1_naukri", "raw_name": "Nikhil Mehta", "name": "Nikhil Mehta", "name_key": "nikhil mehta", "email": "nikhil.mehta5@example.com", "phone": "9000000104", "city": "Pune", "experience_years": 2.9, "ctc_annual_inr": 930000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-26", "applied_date_raw": "2026-07-26", "skills": ["docker", "langchain", "zapier", "selenium", "python", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'docker', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'langchain', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (36, 'react', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (36, 2.9, 930000, 'inferred_lpa_shorthand', '2026-07-26', '2026-07-26');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (36, 'source3_cbnexus', 'Nikhil Mehta', '{"source": "source3_cbnexus", "raw_name": "Nikhil Mehta", "name": "Nikhil Mehta", "name_key": "nikhil mehta", "email": null, "phone": "9000000104", "city": "Pune", "verified": true, "projects_completed": 10}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (36, 1, 10);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (37, 'Isha Kapoor', 'isha.kapoor54@example.com', '9000000295', 'Delhi', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (37, 'source1_naukri', 'Isha Kapoor', '{"source": "source1_naukri", "raw_name": "Isha Kapoor", "name": "Isha Kapoor", "name_key": "isha kapoor", "email": "isha.kapoor54@example.com", "phone": "9000000295", "city": "Delhi", "experience_years": 5.1, "ctc_annual_inr": 590000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-08-21", "applied_date_raw": "08/21/2026", "skills": ["fastapi", "python", "javascript", "selenium", "react", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'react', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'mysql', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (37, 5.1, 590000, 'inferred_lpa_shorthand', '2026-08-21', '08/21/2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (37, 'source2_gig', 'Isha Kapoor', '{"source": "source2_gig", "raw_name": "Isha Kapoor", "name": "Isha Kapoor", "name_key": "isha kapoor", "email": "isha.kapoor54@example.com", "phone": null, "city": "Delhi", "rate_monthly_inr": 15000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["fastapi", "python", "javascript", "selenium", "react", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (37, 'mysql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (37, 15000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (37, 'source3_cbnexus', 'Isha Kapoor', '{"source": "source3_cbnexus", "raw_name": "Isha Kapoor", "name": "Isha Kapoor", "name_key": "isha kapoor", "email": null, "phone": "9000000295", "city": "Delhi", "verified": true, "projects_completed": 6}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (37, 1, 6);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (38, 'Arjun Bhatia', 'arjun.bhatia14@example.com', '9000000212', 'Delhi', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (38, 'source1_naukri', 'Arjun Bhatia', '{"source": "source1_naukri", "raw_name": "Arjun Bhatia", "name": "Arjun Bhatia", "name_key": "arjun bhatia", "email": "arjun.bhatia14@example.com", "phone": "9000000212", "city": "Delhi", "experience_years": 1.5, "ctc_annual_inr": 621881, "ctc_normalization_method": "raw_annual", "applied_date": "2026-06-02", "applied_date_raw": "02-06-2026", "skills": ["zapier", "rest apis", "sql", "fastapi", "pandas", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'sql', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'pandas', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (38, 'web scraping', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (38, 1.5, 621881, 'raw_annual', '2026-06-02', '02-06-2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (39, 'Isha Sharma', 'isha.sharma15@example.com', '9000000259', 'Delhi', 'source1_naukri', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (39, 'source1_naukri', 'Isha Sharma', '{"source": "source1_naukri", "raw_name": "Isha Sharma", "name": "Isha Sharma", "name_key": "isha sharma", "email": "isha.sharma15@example.com", "phone": "9000000259", "city": "Delhi", "experience_years": 3.5, "ctc_annual_inr": 1030000, "ctc_normalization_method": "inferred_lpa_shorthand", "applied_date": "2026-07-12", "applied_date_raw": "07/12/2026", "skills": ["n8n", "python", "selenium", "javascript", "rest apis", "mongodb"]}');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'n8n', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'python', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'selenium', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'rest apis', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (39, 'mongodb', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (39, 3.5, 1030000, 'inferred_lpa_shorthand', '2026-07-12', '07/12/2026');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (40, 'Neha Bhatia', 'neha.bhatia60@mailtest.example.org', '9000000273', 'Pune', 'source1_naukri,source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (40, 'source1_naukri', 'Neha Bhatia', '{"source": "source1_naukri", "raw_name": "Neha Bhatia", "name": "Neha Bhatia", "name_key": "neha bhatia", "email": "neha.bhatia60@mailtest.example.org", "phone": "9000000273", "city": "Pune", "experience_years": 4.2, "ctc_annual_inr": 694306, "ctc_normalization_method": "raw_annual", "applied_date": "2026-07-22", "applied_date_raw": "22 Jul 2026", "skills": ["fastapi", "zapier", "javascript", "selenium"]}');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'fastapi', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'zapier', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'javascript', 'source1_naukri');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'selenium', 'source1_naukri');
INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, ctc_normalization_method, applied_date, applied_date_raw) VALUES (40, 4.2, 694306, 'raw_annual', '2026-07-22', '22 Jul 2026');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (40, 'source2_gig', 'Neha Bhatia', '{"source": "source2_gig", "raw_name": "Neha Bhatia", "name": "Neha Bhatia", "name_key": "neha bhatia", "email": "neha.bhatia60@mailtest.example.org", "phone": null, "city": "Pune", "rate_monthly_inr": 79000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["fastapi", "zapier", "javascript", "selenium"]}');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (40, 'selenium', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (40, 79000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (40, 'source3_cbnexus', 'Neha Bhatia', '{"source": "source3_cbnexus", "raw_name": "Neha Bhatia", "name": "Neha Bhatia", "name_key": "neha bhatia", "email": null, "phone": "9000000273", "city": "Pune", "verified": false, "projects_completed": 10}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (40, 0, 10);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (41, 'Arjun Mehta', 'arjun.mehta77@mailtest.example.org', NULL, 'Noida', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (41, 'source2_gig', 'Arjun Mehta', '{"source": "source2_gig", "raw_name": "Arjun Mehta", "name": "Arjun Mehta", "name_key": "arjun mehta", "email": "arjun.mehta77@mailtest.example.org", "phone": null, "city": "Noida", "rate_monthly_inr": 42000, "rate_normalization_method": "raw_monthly", "status": "Inactive", "skills": ["fastapi", "pandas", "web scraping", "zapier", "docker", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (41, 'mysql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (41, 42000, 'raw_monthly', 'Inactive');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (42, 'Manish Bhatia', 'manish.bhatia3@example.com', '9000000161', 'Noida', 'source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (42, 'source2_gig', 'Manish Bhatia', '{"source": "source2_gig", "raw_name": "Manish Bhatia", "name": "Manish Bhatia", "name_key": "manish bhatia", "email": "manish.bhatia3@example.com", "phone": null, "city": "Noida", "rate_monthly_inr": 73000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["pandas", "docker", "javascript", "react", "rest apis", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (42, 'web scraping', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (42, 73000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (42, 'source3_cbnexus', 'MANISH BHATIA', '{"source": "source3_cbnexus", "raw_name": "MANISH BHATIA", "name": "Manish Bhatia", "name_key": "manish bhatia", "email": null, "phone": "9000000161", "city": "Noida", "verified": true, "projects_completed": 5}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (42, 1, 5);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (43, 'Isha.Chopra95@Mailtest.Example.Org', 'pune', NULL, '1406/Hr', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (43, 'source2_gig', 'ISHA.CHOPRA95@MAILTEST.EXAMPLE.ORG', '{"source": "source2_gig", "raw_name": "ISHA.CHOPRA95@MAILTEST.EXAMPLE.ORG", "name": "Isha.Chopra95@Mailtest.Example.Org", "name_key": "ishachopramailtestexampleorg", "email": "pune", "phone": null, "city": "1406/Hr", "rate_monthly_inr": null, "rate_normalization_method": null, "status": null, "skills": ["react", "javascript", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (43, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (43, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (43, 'mysql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (43, NULL, NULL, NULL);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (44, 'Divya Chopra', 'divya.chopra59@example.in', '9000000111', 'Noida', 'source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (44, 'source2_gig', 'Divya Chopra', '{"source": "source2_gig", "raw_name": "Divya Chopra", "name": "Divya Chopra", "name_key": "divya chopra", "email": "divya.chopra59@example.in", "phone": null, "city": "Noida", "rate_monthly_inr": 55000, "rate_normalization_method": "raw_monthly", "status": "Inactive", "skills": ["zapier", "docker", "mongodb", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (44, 'zapier', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (44, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (44, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (44, 'fastapi', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (44, 55000, 'raw_monthly', 'Inactive');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (44, 'source3_cbnexus', 'DIVYA CHOPRA', '{"source": "source3_cbnexus", "raw_name": "DIVYA CHOPRA", "name": "Divya Chopra", "name_key": "divya chopra", "email": null, "phone": "9000000111", "city": "Noida", "verified": false, "projects_completed": 5}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (44, 0, 5);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (45, 'Karan Chopra', 'karan.chopra76@mailtest.example.org', '9000000245', 'Pune', 'source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (45, 'source2_gig', 'Karan Chopra', '{"source": "source2_gig", "raw_name": "Karan Chopra", "name": "Karan Chopra", "name_key": "karan chopra", "email": "karan.chopra76@mailtest.example.org", "phone": null, "city": "Pune", "rate_monthly_inr": 76912, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["n8n", "selenium", "python", "mongodb", "pandas"]}');
INSERT INTO skills (person_id, skill, source) VALUES (45, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (45, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (45, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (45, 'mongodb', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (45, 'pandas', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (45, 76912, 'converted_from_hourly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (45, 'source3_cbnexus', 'Karan Chopra', '{"source": "source3_cbnexus", "raw_name": "Karan Chopra", "name": "Karan Chopra", "name_key": "karan chopra", "email": null, "phone": "9000000245", "city": "Pune", "verified": false, "projects_completed": 10}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (45, 0, 10);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (46, 'Vikram Mehta', 'vikram.mehta6@example.com', '9000000261', 'Pune', 'source2_gig,source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (46, 'source2_gig', 'Vikram Mehta', '{"source": "source2_gig", "raw_name": "Vikram Mehta", "name": "Vikram Mehta", "name_key": "vikram mehta", "email": "vikram.mehta6@example.com", "phone": null, "city": "Pune", "rate_monthly_inr": 22000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["rest apis", "python", "langchain"]}');
INSERT INTO skills (person_id, skill, source) VALUES (46, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (46, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (46, 'langchain', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (46, 22000, 'raw_monthly', 'Active');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (46, 'source3_cbnexus', 'Vikram Mehta', '{"source": "source3_cbnexus", "raw_name": "Vikram Mehta", "name": "Vikram Mehta", "name_key": "vikram mehta", "email": null, "phone": "9000000261", "city": "Pune", "verified": true, "projects_completed": 2}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (46, 1, 2);
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (47, 'Pooja Kapoor', 'pooja.kapoor62@example.in', NULL, 'Noida', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (47, 'source2_gig', 'Pooja Kapoor', '{"source": "source2_gig", "raw_name": "Pooja Kapoor", "name": "Pooja Kapoor", "name_key": "pooja kapoor", "email": "pooja.kapoor62@example.in", "phone": null, "city": "Noida", "rate_monthly_inr": 21000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["rest apis", "sql", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (47, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (47, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (47, 'react', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (47, 21000, 'raw_monthly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (48, 'Kavya Verma', 'kavya.verma74@mailtest.example.org', NULL, 'Gurgaon', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (48, 'source2_gig', 'Kavya Verma', '{"source": "source2_gig", "raw_name": "Kavya Verma", "name": "Kavya Verma", "name_key": "kavya verma", "email": "kavya.verma74@mailtest.example.org", "phone": null, "city": "Gurgaon", "rate_monthly_inr": 261008, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["sql", "pandas", "web scraping", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (48, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (48, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (48, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (48, 'react', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (48, 261008, 'converted_from_hourly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (49, 'Tanvi Reddy', 'tanvi.reddy80@example.com', NULL, 'Pune', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (49, 'source2_gig', 'Tanvi Reddy', '{"source": "source2_gig", "raw_name": "Tanvi Reddy", "name": "Tanvi Reddy", "name_key": "tanvi reddy", "email": "tanvi.reddy80@example.com", "phone": null, "city": "Pune", "rate_monthly_inr": 59000, "rate_normalization_method": "raw_monthly", "status": "Paused", "skills": ["langchain", "docker", "python", "rest apis", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (49, 'langchain', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (49, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (49, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (49, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (49, 'sql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (49, 59000, 'raw_monthly', 'Paused');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (50, 'Varun Singh', 'varun.singh81@example.com', NULL, 'Noida', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (50, 'source2_gig', 'Varun Singh', '{"source": "source2_gig", "raw_name": "Varun Singh", "name": "Varun Singh", "name_key": "varun singh", "email": "varun.singh81@example.com", "phone": null, "city": "Noida", "rate_monthly_inr": 134288, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["python", "react", "fastapi", "mongodb"]}');
INSERT INTO skills (person_id, skill, source) VALUES (50, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (50, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (50, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (50, 'mongodb', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (50, 134288, 'converted_from_hourly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (51, 'Tanvi Kapoor', 'tanvi.kapoor38@example.com', NULL, 'Delhi', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (51, 'source2_gig', 'Tanvi Kapoor', '{"source": "source2_gig", "raw_name": "Tanvi Kapoor", "name": "Tanvi Kapoor", "name_key": "tanvi kapoor", "email": "tanvi.kapoor38@example.com", "phone": null, "city": "Delhi", "rate_monthly_inr": 38000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["docker", "selenium", "web scraping", "mysql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (51, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (51, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (51, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (51, 'mysql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (51, 38000, 'raw_monthly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (52, 'Nikhil Nair', 'nikhil.nair26@example.in', NULL, 'Gurgaon', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (52, 'source2_gig', 'Nikhil Nair', '{"source": "source2_gig", "raw_name": "Nikhil Nair", "name": "Nikhil Nair", "name_key": "nikhil nair", "email": "nikhil.nair26@example.in", "phone": null, "city": "Gurgaon", "rate_monthly_inr": 179168, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["python", "n8n", "web scraping"]}');
INSERT INTO skills (person_id, skill, source) VALUES (52, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (52, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (52, 'web scraping', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (52, 179168, 'converted_from_hourly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (53, 'Pooja Reddy', 'pooja.reddy96@mailtest.example.org', NULL, 'Noida', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (53, 'source2_gig', 'Pooja Reddy', '{"source": "source2_gig", "raw_name": "Pooja Reddy", "name": "Pooja Reddy", "name_key": "pooja reddy", "email": "pooja.reddy96@mailtest.example.org", "phone": null, "city": "Noida", "rate_monthly_inr": 103840, "rate_normalization_method": "converted_from_hourly", "status": "Inactive", "skills": ["pandas", "docker", "fastapi", "web scraping", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (53, 'pandas', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (53, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (53, 'fastapi', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (53, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (53, 'sql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (53, 103840, 'converted_from_hourly', 'Inactive');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (54, 'Tanvi Sharma', 'tanvi.sharma56@mailtest.example.org', NULL, 'Noida', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (54, 'source2_gig', 'Tanvi Sharma', '{"source": "source2_gig", "raw_name": "Tanvi Sharma", "name": "Tanvi Sharma", "name_key": "tanvi sharma", "email": "tanvi.sharma56@mailtest.example.org", "phone": null, "city": "Noida", "rate_monthly_inr": 73000, "rate_normalization_method": "raw_monthly", "status": "Active", "skills": ["langchain", "python", "web scraping", "n8n", "fastapi"]}');
INSERT INTO skills (person_id, skill, source) VALUES (54, 'langchain', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (54, 'python', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (54, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (54, 'n8n', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (54, 'fastapi', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (54, 73000, 'raw_monthly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (55, 'Deepak Nair', 'deepak.nair57@example.in', NULL, 'Delhi', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (55, 'source2_gig', 'Deepak Nair', '{"source": "source2_gig", "raw_name": "Deepak Nair", "name": "Deepak Nair", "name_key": "deepak nair", "email": "deepak.nair57@example.in", "phone": null, "city": "Delhi", "rate_monthly_inr": 257312, "rate_normalization_method": "converted_from_hourly", "status": "Active", "skills": ["javascript", "react", "docker", "web scraping", "mysql", "sql"]}');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'react', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'web scraping', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'mysql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (55, 'sql', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (55, 257312, 'converted_from_hourly', 'Active');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (56, 'Anjali Agarwal', 'anjali.agarwal53@mailtest.example.org', NULL, 'Bengaluru', 'source2_gig', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (56, 'source2_gig', 'Anjali Agarwal', '{"source": "source2_gig", "raw_name": "Anjali Agarwal", "name": "Anjali Agarwal", "name_key": "anjali agarwal", "email": "anjali.agarwal53@mailtest.example.org", "phone": null, "city": "Bengaluru", "rate_monthly_inr": 71000, "rate_normalization_method": "raw_monthly", "status": "Inactive", "skills": ["sql", "javascript", "selenium", "rest apis", "docker", "react"]}');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'sql', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'javascript', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'selenium', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'rest apis', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'docker', 'source2_gig');
INSERT INTO skills (person_id, skill, source) VALUES (56, 'react', 'source2_gig');
INSERT INTO gig_worker_status (person_id, rate_monthly_inr, rate_normalization_method, status) VALUES (56, 71000, 'raw_monthly', 'Inactive');
INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, canonical_city, matched_from_sources, match_confidence) VALUES (57, 'Arjun Mehta', NULL, '9000000272', 'Noida', 'source3_cbnexus', 'exact');
INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (57, 'source3_cbnexus', 'Arjun Mehta', '{"source": "source3_cbnexus", "raw_name": "Arjun Mehta", "name": "Arjun Mehta", "name_key": "arjun mehta", "email": null, "phone": "9000000272", "city": "Noida", "verified": true, "projects_completed": 14}');
INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (57, 1, 14);
INSERT INTO match_conflicts (name_key, city, detail) VALUES ('arjun mehta', 'Noida', '{"name_key": "arjun mehta", "city": "Noida", "rows": [{"source": "source1_naukri", "raw_name": "Arjun Mehta", "email": "arjun.mehta9@example.in", "phone": "9000000131"}, {"source": "source2_gig", "raw_name": "Arjun Mehta", "email": "arjun.mehta77@mailtest.example.org", "phone": null}, {"source": "source3_cbnexus", "raw_name": "Arjun Mehta", "email": null, "phone": "9000000131"}, {"source": "source3_cbnexus", "raw_name": "Arjun Mehta", "email": null, "phone": "9000000272"}], "reason": "Same name + city but conflicting phone/email values across records -- could be the same person with a data error, or two different real people. NOT auto-merged."}');
