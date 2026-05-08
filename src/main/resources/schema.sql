BEGIN;

-- 1. CURATARE
DROP TABLE IF EXISTS adoptions CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS animals CASCADE;
DROP TABLE IF EXISTS cages CASCADE;
DROP TABLE IF EXISTS shelters CASCADE;

-- 2. TABELE
CREATE TABLE shelters (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          country VARCHAR(50) NOT NULL,
                          city VARCHAR(50) NOT NULL,
                          image_url TEXT,
                          latitude DECIMAL(10, 8),
                          longitude DECIMAL(11, 8)
);

CREATE TABLE cages (
                       id SERIAL PRIMARY KEY,
                       shelter_id INT NOT NULL REFERENCES shelters(id) ON DELETE CASCADE,
                       code VARCHAR(10) UNIQUE,
                       maximum_capacity INT DEFAULT 5
);

CREATE TABLE animals (
                         id SERIAL PRIMARY KEY,
                         cage_id INT REFERENCES cages(id) ON DELETE SET NULL,
                         name VARCHAR(100) NOT NULL,
                         species VARCHAR(50) NOT NULL,
                         breed VARCHAR(100),
                         date_of_birth DATE,
                         date_of_entry DATE NOT NULL DEFAULT CURRENT_DATE,
                         image_url TEXT,
                         gender VARCHAR(20),
                         description TEXT,
                         is_adopted BOOLEAN DEFAULT FALSE
);

-- Tabelul tau de login (Employee)
CREATE TABLE employees (
                           id SERIAL PRIMARY KEY,
                           shelter_id INT NOT NULL REFERENCES shelters(id) ON DELETE CASCADE,
                           first_name VARCHAR(50) NOT NULL,
                           last_name VARCHAR(50) NOT NULL,
                           username VARCHAR(50) UNIQUE NOT NULL,
                           password VARCHAR(100) NOT NULL,
                           phone VARCHAR(20),
                           role VARCHAR(50),
                           salary DECIMAL(10, 2) NOT NULL
);

CREATE TABLE people (
                        id SERIAL PRIMARY KEY,
                        first_name VARCHAR(50) NOT NULL,
                        last_name VARCHAR(50) NOT NULL,
                        phone VARCHAR(20) NOT NULL,
                        email VARCHAR(100) UNIQUE
);

CREATE TABLE adoptions (
                           id SERIAL PRIMARY KEY,
                           animal_id INT NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
                           person_id INT NOT NULL REFERENCES people(id) ON DELETE CASCADE,
                           adoption_date DATE DEFAULT CURRENT_DATE,
                           return_date DATE,
                           return_reason TEXT
);

-- 3. LOGICA (FUNCTII SI TRIGGERE)

-- Algoritm complex: Sugestie Transfer (Haversine)
CREATE OR REPLACE FUNCTION fn_get_transfer_suggestion(p_current_shelter_id INT)
RETURNS TABLE (suggested_shelter_name VARCHAR, city_name VARCHAR, distance_km NUMERIC, free_cage_id INT) AS $$
BEGIN
RETURN QUERY
    WITH current_loc AS (SELECT latitude, longitude FROM shelters WHERE id = p_current_shelter_id),
    available_spots AS (
        SELECT s.id, s.name, s.city, s.latitude, s.longitude, c.id as cage_id,
               (6371 * acos(cos(radians(cl.latitude)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians(cl.longitude)) +
                sin(radians(cl.latitude)) * sin(radians(s.latitude)))) AS dist
        FROM shelters s CROSS JOIN current_loc cl JOIN cages c ON s.id = c.shelter_id
        WHERE s.id <> p_current_shelter_id AND (SELECT COUNT(*) FROM animals a WHERE a.cage_id = c.id) < c.maximum_capacity
    )
SELECT name, city, ROUND(dist::numeric, 2), cage_id FROM available_spots ORDER BY dist ASC LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Trigger 1: Capacitate
CREATE OR REPLACE FUNCTION fn_check_cage_capacity() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM animals WHERE cage_id = NEW.cage_id) >= (SELECT maximum_capacity FROM cages WHERE id = NEW.cage_id) THEN
        RAISE EXCEPTION 'CAGE_FULL_ERROR';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_cage_capacity BEFORE INSERT ON animals FOR EACH ROW EXECUTE FUNCTION fn_check_cage_capacity();

-- Trigger 2: Salariu Minim
CREATE OR REPLACE FUNCTION fn_validate_salary() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 3000 THEN RAISE EXCEPTION 'SALARY_TOO_LOW'; END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_salary BEFORE INSERT OR UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION fn_validate_salary();

-- 4. POPULARE (15 inregistrari per tabel)
INSERT INTO shelters (name, country, city, latitude, longitude) VALUES
                                                                    ('Speranta', 'Romania', 'Bucuresti', 44.42, 26.10), ('Happy Paws', 'Romania', 'Ploiesti', 44.93, 26.01),
                                                                    ('Green Shelter', 'Romania', 'Brasov', 45.64, 25.58), ('Blue Cross', 'Romania', 'Sibiu', 45.79, 24.12),
                                                                    ('Noah Arc', 'Romania', 'Cluj', 46.77, 23.58), ('Safe Haven', 'Romania', 'Timisoara', 45.74, 21.20),
                                                                    ('Paws & Love', 'Romania', 'Iasi', 47.15, 27.60), ('VetCare', 'Romania', 'Constanta', 44.17, 28.63),
                                                                    ('Animal Rescue', 'Romania', 'Craiova', 44.33, 23.81), ('LifeLine', 'Romania', 'Galati', 45.43, 28.02),
                                                                    ('PetStop', 'Romania', 'Oradea', 47.04, 21.91), ('FurEver', 'Romania', 'Arad', 46.18, 21.31),
                                                                    ('SoulMates', 'Romania', 'Bacau', 46.56, 26.91), ('Kindness', 'Romania', 'Pitesti', 44.85, 24.86),
                                                                    ('TailWaggers', 'Romania', 'Targu Mures', 46.54, 24.56);

INSERT INTO cages (shelter_id, code, maximum_capacity)
SELECT (i % 15) + 1, 'C-' || i, 5 FROM generate_series(1, 15) i;

-- Punem animalele in custi diferite ca sa nu sarim de 5 si sa crape scriptul
INSERT INTO animals (cage_id, name, species, breed, date_of_entry)
SELECT i, 'Rex ' || i, 'Dog', 'Mixed', CURRENT_DATE FROM generate_series(1, 15) i;

-- LOGIN AICI: user: admin1, admin2... / parola: password123
INSERT INTO employees (shelter_id, first_name, last_name, username, password, role, salary)
SELECT (i % 15) + 1, 'Ion', 'Popescu' || i, 'admin' || i, 'password123', 'Caregiver', 3500 FROM generate_series(1, 15) i;

INSERT INTO people (first_name, last_name, phone, email)
SELECT 'Vasile', 'Ionescu' || i, '0722', 'test' || i || '@mail.com' FROM generate_series(1, 15) i;

INSERT INTO adoptions (animal_id, person_id) SELECT i, i FROM generate_series(1, 5) i;

COMMIT;