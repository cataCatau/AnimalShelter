
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
                       max_capacity INT DEFAULT 5 -- Added capacity, per requirements
);

-- Animals Table
CREATE TABLE animals (
                         id SERIAL PRIMARY KEY,
                         shelter_id INT REFERENCES shelters(id) ON DELETE CASCADE,
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
$$ LANGUAGE plpgsql;
