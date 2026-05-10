BEGIN;

-- ==========================================
-- 1. CURATARE
-- ==========================================
DROP TABLE IF EXISTS adoptions CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS animals CASCADE;
DROP TABLE IF EXISTS cages CASCADE;
DROP TABLE IF EXISTS shelters CASCADE;

-- ==========================================
-- 2. TABELE (6 Tabele -> Bifat minim 5)
-- ==========================================
CREATE TABLE shelters (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          country VARCHAR(50) NOT NULL,
                          city VARCHAR(50) NOT NULL,
                          image_url TEXT, -- Adaugat pentru interfata noastra
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
                         image_url TEXT, -- Adaugat pentru interfata noastra
                         gender VARCHAR(20),
                         description TEXT,
                         is_adopted BOOLEAN DEFAULT FALSE
);

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

-- ==========================================
-- 3. LOGICA COMPLEXA (Proceduri, View-uri, Triggere)
-- ==========================================

-- Algoritm complex: Sugestie Transfer bazat pe distanta GPS (Haversine)
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

-- Trigger 1: Verificare Capacitate Cusca
CREATE OR REPLACE FUNCTION fn_check_cage_capacity() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM animals WHERE cage_id = NEW.cage_id) >= (SELECT maximum_capacity FROM cages WHERE id = NEW.cage_id) THEN
        RAISE EXCEPTION 'CAGE_FULL_ERROR';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_cage_capacity BEFORE INSERT ON animals FOR EACH ROW EXECUTE FUNCTION fn_check_cage_capacity();

-- Trigger 2: Salariu Minim (Prins in Java)
CREATE OR REPLACE FUNCTION fn_validate_salary() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 3000 THEN RAISE EXCEPTION 'SALARY_TOO_LOW'; END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_salary BEFORE INSERT OR UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION fn_validate_salary();

-- View Statistic (Pentru Dashboard si afisare inteligenta)
CREATE OR REPLACE VIEW vw_shelter_statistics AS
SELECT
    s.*,
    (SELECT COUNT(*) FROM cages c WHERE c.shelter_id = s.id) AS total_cages,
    COALESCE((SELECT SUM(maximum_capacity) FROM cages c WHERE c.shelter_id = s.id), 0) AS total_capacity,
    (SELECT COUNT(*) FROM animals a JOIN cages c ON a.cage_id = c.id WHERE c.shelter_id = s.id AND a.is_adopted = false) AS current_animals,
    COALESCE((SELECT SUM(maximum_capacity) FROM cages c WHERE c.shelter_id = s.id), 0) -
    (SELECT COUNT(*) FROM animals a JOIN cages c ON a.cage_id = c.id WHERE c.shelter_id = s.id AND a.is_adopted = false) AS free_spots
FROM shelters s;

-- ==========================================
-- 4. POPULARE MANUALA AUTOMATIZATA (Minim 15/tabel)
-- ==========================================

INSERT INTO shelters (name, country, city, latitude, longitude, image_url) VALUES
                                                                               ('Speranta', 'Romania', 'Bucuresti', 44.42, 26.10, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Happy Paws', 'Romania', 'Ploiesti', 44.93, 26.01, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Green Shelter', 'Romania', 'Brasov', 45.64, 25.58, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Blue Cross', 'Romania', 'Sibiu', 45.79, 24.12, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Noah Arc', 'Romania', 'Cluj', 46.77, 23.58, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Safe Haven', 'Romania', 'Timisoara', 45.74, 21.20, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Paws & Love', 'Romania', 'Iasi', 47.15, 27.60, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('VetCare', 'Romania', 'Constanta', 44.17, 28.63, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Animal Rescue', 'Romania', 'Craiova', 44.33, 23.81, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('LifeLine', 'Romania', 'Galati', 45.43, 28.02, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('PetStop', 'Romania', 'Oradea', 47.04, 21.91, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('FurEver', 'Romania', 'Arad', 46.18, 21.31, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('SoulMates', 'Romania', 'Bacau', 46.56, 26.91, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('Kindness', 'Romania', 'Pitesti', 44.85, 24.86, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'),
                                                                               ('TailWaggers', 'Romania', 'Targu Mures', 46.54, 24.56, 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop');

-- 15 Custi
INSERT INTO cages (shelter_id, code, maximum_capacity)
SELECT (i % 15) + 1, 'C-' || i, 5 FROM generate_series(1, 15) i;

-- 15 Animale in 15 custi diferite
INSERT INTO animals (cage_id, name, species, breed, image_url)
SELECT i, 'Doggo ' || i, 'Dog', 'Mixed', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop' FROM generate_series(1, 15) i;

-- 15 Angajati (Primul e admin/admin Manager)
INSERT INTO employees (shelter_id, first_name, last_name, username, password, role, salary)
VALUES (1, 'Super', 'Admin', 'admin', 'admin', 'Manager', 5000);

INSERT INTO employees (shelter_id, first_name, last_name, username, password, role, salary)
SELECT (i % 15) + 1, 'Ion', 'Popescu' || i, 'user' || i, 'parola123', 'Caregiver', 3500 FROM generate_series(2, 15) i;

-- 15 Persoane
INSERT INTO people (first_name, last_name, phone, email)
SELECT 'Vasile', 'Ionescu' || i, '0722000' || LPAD(i::text, 3, '0'), 'test' || i || '@mail.com' FROM generate_series(1, 15) i;

-- 15 Adoptii (Adoptam alte 15 animale ca sa avem fix 15 intrari in tabelul adoptions)
INSERT INTO animals (cage_id, name, species, breed, is_adopted)
SELECT (i % 15) + 1, 'AdoptedCat ' || i, 'Cat', 'Street', TRUE FROM generate_series(16, 30) i;

INSERT INTO adoptions (animal_id, person_id)
SELECT i, i - 15 FROM generate_series(16, 30) i;

COMMIT;