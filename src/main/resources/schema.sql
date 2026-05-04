
DROP TABLE IF EXISTS animals CASCADE;
DROP TABLE IF EXISTS cages CASCADE;
DROP TABLE IF EXISTS shelters CASCADE;
DROP FUNCTION IF EXISTS fn_calculate_adoption_chance CASCADE;

-- Shelters Table
CREATE TABLE shelters (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          country VARCHAR(50) NOT NULL,
                          city VARCHAR(50) NOT NULL,
                          image_url TEXT
);

-- Cages Table
CREATE TABLE cages (
                       id SERIAL PRIMARY KEY,
                       shelter_id INT NOT NULL REFERENCES shelters(id) ON DELETE CASCADE,
                       maximum_capacity INT DEFAULT 5 -- Added capacity, per requirements
);

-- Animals Table
CREATE TABLE animals (
                         id SERIAL PRIMARY KEY,
                         cage_id INT REFERENCES cages(id) ON DELETE SET NULL,
                         name VARCHAR(100) NOT NULL,
                         species VARCHAR(50) NOT NULL,
                         breed VARCHAR(100),
                         date_of_birth DATE,
                         date_of_entry DATE NOT NULL,
                         image_url TEXT,
                         gender VARCHAR(20),
                         description TEXT
);

-- Function that calculates the adoption chance of an animal (Returns a score from 10 to 100)
CREATE OR REPLACE FUNCTION fn_calculate_adoption_chance(p_animal_id INT)
RETURNS INT AS $$
DECLARE
v_birth_date DATE;
    v_entry_date DATE;
    v_gender VARCHAR(50);
    v_age_months INT;
    v_months_in_shelter INT;
    v_score INT := 100;
BEGIN
SELECT date_of_birth, date_of_entry, gender
INTO v_birth_date, v_entry_date, v_gender
FROM animals
WHERE id = p_animal_id;

IF NOT FOUND THEN
        RETURN 0;
END IF;

    IF v_birth_date IS NOT NULL THEN
        v_age_months := EXTRACT(YEAR FROM age(CURRENT_DATE, v_birth_date)) * 12 + EXTRACT(MONTH FROM age(CURRENT_DATE, v_birth_date));
        v_score := v_score - LEAST(30, (v_age_months / 12) * 2);
END IF;

    IF v_entry_date IS NOT NULL THEN
        v_months_in_shelter := EXTRACT(YEAR FROM age(CURRENT_DATE, v_entry_date)) * 12 + EXTRACT(MONTH FROM age(CURRENT_DATE, v_entry_date));
        v_score := v_score - LEAST(40, v_months_in_shelter * 3);
END IF;

    IF v_gender = 'Unknown' THEN
        v_score := v_score - 5;
END IF;

    IF v_score < 10 THEN
        v_score := 10;
END IF;

RETURN v_score;
END;

-- 1. Funcția care verifică capacitatea
CREATE OR REPLACE FUNCTION fn_check_cage_capacity()
RETURNS TRIGGER AS $$
DECLARE
v_current_count INT;
    v_max_capacity INT;
BEGIN
    -- 1. Numărăm animalele care sunt deja în această cușcă
SELECT COUNT(*) INTO v_current_count
FROM animals
WHERE cage_id = NEW.cage_id;

-- 2. Luăm capacitatea folosind numele corect: maximum_capacity
SELECT maximum_capacity INTO v_max_capacity
FROM cages
WHERE id = NEW.cage_id;

-- 3. Verificăm dacă mai este loc
IF v_current_count >= v_max_capacity THEN
        RAISE EXCEPTION 'CAGE_FULL_ERROR: Cage % is full! (Max: %)', NEW.cage_id, v_max_capacity;
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;
