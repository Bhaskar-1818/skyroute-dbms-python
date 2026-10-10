-- ============================================================================
-- SkyRoute — File 02 : staff hierarchy + access control  (MySQL 8.0, v2)
-- Run from dbms/ :  SOURCE schema/02-staff-roles.sql;
-- v2: Crew_Assignments removed (roster link lives in the app instead).
-- ============================================================================
USE skyroute_db;

-- C10: SUPERTYPE / SUBTYPE pattern. Everyone employed is one row in Employees
-- (single email registry, single phone book). Role-specific facts live in
-- subtype tables keyed by the SAME employee_id: a pilot MUST exist in
-- Employees first, so a licence can never dangle without a person.
CREATE TABLE Employees (
  employee_id   INT AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(100) NOT NULL,
  phone         VARCHAR(20) NOT NULL,
  base_airport  INT NULL,
  hire_date     DATE NOT NULL,
  UNIQUE KEY uq_employee_email (email),
  CONSTRAINT fk_employee_base FOREIGN KEY (base_airport)
    REFERENCES Airports (airport_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Pilots (
  employee_id    INT PRIMARY KEY,
  license_number VARCHAR(30) NOT NULL,
  license_type   VARCHAR(10) NOT NULL,
  UNIQUE KEY uq_pilot_license (license_number),
  CONSTRAINT fk_pilot_employee FOREIGN KEY (employee_id)
    REFERENCES Employees (employee_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Crew_Members (
  employee_id INT PRIMARY KEY,
  crew_role   VARCHAR(40) NOT NULL,
  CONSTRAINT fk_crew_employee FOREIGN KEY (employee_id)
    REFERENCES Employees (employee_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Ground_Staff (
  employee_id INT PRIMARY KEY,
  ground_role VARCHAR(40) NOT NULL,
  airport_id  INT NULL,
  CONSTRAINT fk_ground_employee FOREIGN KEY (employee_id)
    REFERENCES Employees (employee_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ground_airport FOREIGN KEY (airport_id)
    REFERENCES Airports (airport_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- C11: ACCESS CONTROL (DCL). Three least-privilege roles.
-- Grant on the CORRECT database name: a grant on a misspelled name succeeds
-- silently and protects nothing. SHOW GRANTS afterwards proves each role.
-- ============================================================================
CREATE USER IF NOT EXISTS 'sky_admin'@'localhost'  IDENTIFIED BY 'Admin@123';
CREATE USER IF NOT EXISTS 'sky_staff'@'localhost'  IDENTIFIED BY 'Staff@123';
CREATE USER IF NOT EXISTS 'sky_viewer'@'localhost' IDENTIFIED BY 'Viewer@123';

GRANT ALL PRIVILEGES
  ON skyroute_db.*
  TO 'sky_admin'@'localhost';

GRANT SELECT, INSERT, UPDATE
  ON skyroute_db.*
  TO 'sky_staff'@'localhost';

GRANT SELECT
  ON skyroute_db.*
  TO 'sky_viewer'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'sky_admin'@'localhost';
SHOW GRANTS FOR 'sky_staff'@'localhost';
SHOW GRANTS FOR 'sky_viewer'@'localhost';
