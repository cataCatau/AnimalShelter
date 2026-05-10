BEGIN;

-- ==========================================
-- 1. CURATARE
-- ==========================================
DROP VIEW IF EXISTS vw_shelter_statistics CASCADE;
DROP FUNCTION IF EXISTS fn_calculate_adoption_chance(INT) CASCADE;
DROP FUNCTION IF EXISTS fn_get_transfer_suggestion(INT) CASCADE;
DROP FUNCTION IF EXISTS fn_check_cage_capacity() CASCADE;
DROP FUNCTION IF EXISTS fn_validate_salary() CASCADE;

DROP TABLE IF EXISTS medical_records CASCADE;
DROP TABLE IF EXISTS adoptions CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS animals CASCADE;
DROP TABLE IF EXISTS cages CASCADE;
DROP TABLE IF EXISTS shelters CASCADE;

-- ==========================================
-- 2. CREARE TABELE
-- ==========================================
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

CREATE TABLE medical_records (
                                 id SERIAL PRIMARY KEY,
                                 animal_id INT NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
                                 intervention_date DATE NOT NULL DEFAULT CURRENT_DATE,
                                 intervention_type VARCHAR(100) NOT NULL,
                                 description TEXT
);

-- ==========================================
-- 3. LOGICA COMPLEXA
-- ==========================================

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
        WHERE s.id <> p_current_shelter_id AND (SELECT COUNT(*) FROM animals a WHERE a.cage_id = c.id AND a.is_adopted = false) < c.maximum_capacity
    )
SELECT name, city, ROUND(dist::numeric, 2), cage_id FROM available_spots ORDER BY dist ASC LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calculate_adoption_chance(p_animal_id integer) RETURNS integer AS $$
DECLARE
v_birth_date DATE;
    v_entry_date DATE;
    v_gender VARCHAR(50);
    v_age_months INT;
    v_months_in_shelter INT;
    v_score INT := 100;
BEGIN
SELECT date_of_birth, date_of_entry, gender INTO v_birth_date, v_entry_date, v_gender FROM animals WHERE id = p_animal_id;
IF NOT FOUND THEN RETURN 0; END IF;
    IF v_birth_date IS NOT NULL THEN
        v_age_months := EXTRACT(YEAR FROM age(CURRENT_DATE, v_birth_date)) * 12 + EXTRACT(MONTH FROM age(CURRENT_DATE, v_birth_date));
        v_score := v_score - LEAST(30, (v_age_months / 12) * 2);
END IF;
    IF v_entry_date IS NOT NULL THEN
        v_months_in_shelter := EXTRACT(YEAR FROM age(CURRENT_DATE, v_entry_date)) * 12 + EXTRACT(MONTH FROM age(CURRENT_DATE, v_entry_date));
        v_score := v_score - LEAST(40, v_months_in_shelter * 3);
END IF;
    IF v_gender = 'Unknown' THEN v_score := v_score - 5; END IF;
    IF v_score < 10 THEN v_score := 10; END IF;
RETURN v_score;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_check_cage_capacity() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_adopted = FALSE AND NEW.cage_id IS NOT NULL THEN
        IF (SELECT COUNT(*) FROM animals WHERE cage_id = NEW.cage_id AND is_adopted = FALSE) >= (SELECT maximum_capacity FROM cages WHERE id = NEW.cage_id) THEN
            RAISE EXCEPTION 'CAGE_FULL_ERROR';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_cage_capacity BEFORE INSERT ON animals FOR EACH ROW EXECUTE FUNCTION fn_check_cage_capacity();

CREATE OR REPLACE FUNCTION fn_validate_salary() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 3000 THEN RAISE EXCEPTION 'SALARY_TOO_LOW'; END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_salary BEFORE INSERT OR UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION fn_validate_salary();

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
-- 4. POPULARE PROCEDURALA AUTOMATIZATA CU IMAGINI DINAMICE
-- ==========================================
DO $$
DECLARE
v_nume_animale text[] := ARRAY['Rex', 'Bella', 'Max', 'Luna', 'Charlie', 'Lucy', 'Cooper', 'Daisy', 'Milo', 'Zoe', 'Rocky', 'Lola', 'Buddy', 'Sadie', 'Buster', 'Tiger', 'Leo', 'Simba'];
    v_specii text[] := ARRAY['Dog', 'Cat', 'Rabbit', 'Parrot', 'Guinea Pig'];
    v_rase_caini text[] := ARRAY['Labrador', 'German Shepherd', 'Golden Retriever', 'Bulldog', 'Beagle', 'Poodle', 'Mixed'];
    v_rase_pisici text[] := ARRAY['Siamese', 'Persian', 'Maine Coon', 'Bengal', 'Sphynx', 'Mixed'];
    v_gender text[] := ARRAY['Male', 'Female', 'Unknown'];
    v_prenume text[] := ARRAY['Ion', 'Andrei', 'Maria', 'Elena', 'Vasile', 'Gheorghe', 'Ana', 'Mihai', 'Alexandru', 'Cristina', 'Florin', 'Laura', 'Diana', 'Gabriel', 'Adrian'];
    v_nume text[] := ARRAY['Popescu', 'Ionescu', 'Radu', 'Dumitru', 'Stan', 'Stoica', 'Gheorghiu', 'Matei', 'Ciobanu', 'Ilie', 'Marin', 'Toma', 'Popa', 'Constantin', 'Nita'];
    v_roles text[] := ARRAY['Caregiver', 'Veterinarian', 'Cleaner', 'Manager'];
    v_medical_types text[] := ARRAY['Vaccin Rabic', 'Deparazitare', 'Control de rutina', 'Tratament infectie', 'Vaccin Polivalent', 'Interventie chirurgicala'];

    v_specie text;
    v_rasa text;
    v_image_url text;
    i int;
    j int;
BEGIN

    -- 4.1. Adăposturi
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

-- 4.2. Generare Custi
FOR i IN 1..15 LOOP
        FOR j IN 1..3 LOOP
            INSERT INTO cages (shelter_id, code, maximum_capacity)
            VALUES (i, 'C-' || i || '-' || j, floor(random() * 5 + 3)::int);
END LOOP;
END LOOP;

    -- 4.3. Generare Animale Neadoptate
FOR i IN 1..40 LOOP
        v_specie := v_specii[floor(random() * array_length(v_specii, 1)) + 1];

        IF v_specie = 'Dog' THEN v_rasa := v_rase_caini[floor(random() * array_length(v_rase_caini, 1)) + 1];
        ELSIF v_specie = 'Cat' THEN v_rasa := v_rase_pisici[floor(random() * array_length(v_rase_pisici, 1)) + 1];
ELSE v_rasa := 'Common Breed';
END IF;

        -- Alocare imagine in functie de specie
CASE v_specie
            WHEN 'Dog' THEN v_image_url := 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=800&auto=format&fit=crop';
WHEN 'Cat' THEN v_image_url := 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=800&auto=format&fit=crop';
WHEN 'Rabbit' THEN v_image_url := 'https://images.unsplash.com/photo-1585110396000-c9fd4e4e5088?q=80&w=800&auto=format&fit=crop';
WHEN 'Parrot' THEN v_image_url := 'https://images.unsplash.com/photo-1552728089-57168a145833?q=80&w=800&auto=format&fit=crop';
WHEN 'Guinea Pig' THEN v_image_url := 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?q=80&w=800&auto=format&fit=crop';
ELSE v_image_url := 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop';
END CASE;

INSERT INTO animals (cage_id, name, species, breed, date_of_birth, date_of_entry, gender, image_url, is_adopted)
VALUES (
           (i % 45) + 1,
           v_nume_animale[floor(random() * array_length(v_nume_animale, 1)) + 1],
           v_specie,
           v_rasa,
           CURRENT_DATE - (floor(random() * 3000) || ' days')::interval,
           CURRENT_DATE - (floor(random() * 500) || ' days')::interval,
           v_gender[floor(random() * array_length(v_gender, 1)) + 1],
           v_image_url,
           FALSE
       );
END LOOP;

    -- 4.4. Generare Oameni
FOR i IN 1..20 LOOP
        INSERT INTO people (first_name, last_name, phone, email)
        VALUES (
            v_prenume[floor(random() * array_length(v_prenume, 1)) + 1],
            v_nume[floor(random() * array_length(v_nume, 1)) + 1],
            '07' || lpad(floor(random() * 100000000)::text, 8, '0'),
            'user' || i || '@test.ro'
        );
END LOOP;

    -- 4.5. Generare Adoptii
FOR i IN 1..15 LOOP
        v_specie := v_specii[floor(random() * array_length(v_specii, 1)) + 1];

CASE v_specie
            WHEN 'Dog' THEN v_image_url := 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=800&auto=format&fit=crop';
WHEN 'Cat' THEN v_image_url := 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=800&auto=format&fit=crop';
WHEN 'Rabbit' THEN v_image_url := 'https://www.charlotte.providencevets.com/files/providence-animal-hospital-charlotte-are-rabbits-rodents-blog.jpeg';
WHEN 'Parrot' THEN v_image_url := 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRc5Kl2JendxGUoBsg5aXHvqeUf1jdu8-TDA&s';
WHEN 'Guinea Pig' THEN v_image_url := 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?q=80&w=800&auto=format&fit=crop';
ELSE v_image_url := 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop';
END CASE;

INSERT INTO animals (cage_id, name, species, breed, date_of_birth, date_of_entry, gender, image_url, is_adopted)
VALUES (
           NULL,
           v_nume_animale[floor(random() * array_length(v_nume_animale, 1)) + 1],
           v_specie,
           'Mixed',
           CURRENT_DATE - (floor(random() * 2000) || ' days')::interval,
           CURRENT_DATE - (floor(random() * 400) || ' days')::interval,
           v_gender[floor(random() * array_length(v_gender, 1)) + 1],
           v_image_url,
           TRUE
       );

INSERT INTO adoptions (animal_id, person_id, adoption_date)
VALUES (
           (SELECT max(id) FROM animals),
           floor(random() * 20) + 1,
           CURRENT_DATE - (floor(random() * 100) || ' days')::interval
       );
END LOOP;

    -- 4.6. Generare Angajați
INSERT INTO employees (shelter_id, first_name, last_name, username, password, role, salary)
VALUES (1, 'Super', 'Admin', 'admin', 'admin', 'Manager', 5000);

FOR i IN 1..20 LOOP
        INSERT INTO employees (shelter_id, first_name, last_name, username, password, role, salary)
        VALUES (
            floor(random() * 15) + 1,
            v_prenume[floor(random() * array_length(v_prenume, 1)) + 1],
            v_nume[floor(random() * array_length(v_nume, 1)) + 1],
            'angajat' || i,
            'parola123',
            v_roles[floor(random() * array_length(v_roles, 1)) + 1],
            floor(random() * 3000 + 3000)::numeric
        );
END LOOP;

    -- 4.7. Generare Inregistrari Medicale
FOR i IN 1..40 LOOP
        INSERT INTO medical_records (animal_id, intervention_date, intervention_type, description)
        VALUES (
            floor(random() * 55) + 1,
            CURRENT_DATE - (floor(random() * 200) || ' days')::interval,
            v_medical_types[floor(random() * array_length(v_medical_types, 1)) + 1],
            'Interventie realizata cu succes in cabinetul veterinar.'
        );
END LOOP;

END $$;

COMMIT;