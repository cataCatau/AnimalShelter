BEGIN;

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

DO $$
DECLARE

v_prenume text[] := ARRAY['Ion', 'Andrei', 'Maria', 'Elena', 'Vasile', 'Gheorghe', 'Ana', 'Mihai', 'Alexandru', 'Cristina', 'Florin', 'Laura', 'Diana', 'Gabriel', 'Adrian'];
    v_nume text[] := ARRAY['Popescu', 'Ionescu', 'Radu', 'Dumitru', 'Stan', 'Stoica', 'Gheorghiu', 'Matei', 'Ciobanu', 'Ilie', 'Marin', 'Toma', 'Popa', 'Constantin', 'Nita'];
    v_roles text[] := ARRAY['Caregiver', 'Veterinarian', 'Cleaner', 'Manager'];
    v_medical_types text[] := ARRAY['Rabic Vaccine', 'Routine Control', 'Infection Treatment', 'Chirurgical Intervention'];


    v_specii text[] := ARRAY['Dog', 'Cat', 'Rabbit', 'Parrot', 'Guinea Pig'];
    v_gender text[] := ARRAY['Male', 'Female', 'Unknown'];


    v_shelter_images text[] := ARRAY[
        'https://gawa.org.uk/wp-content/uploads/2023/06/advice.jpg',
        'https://images.steamusercontent.com/ugc/1808771046526765401/EF9DCDBE9CD5AADC1DA94F17EC2349F8FF930CD7/',
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWUxp5NVFpt_xHVOTS3XQN5A0BnbJIEulF6w&s',
        'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop'
    ];


    v_specie text;
    v_animal_name text;
    v_rasa text;
    v_image_url text;
    v_desc text;
    i int;
    j int;
BEGIN


INSERT INTO shelters (name, country, city, latitude, longitude, image_url) VALUES
                                                                               ('Speranta', 'Romania', 'Bucuresti', 44.42, 26.10, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Happy Paws', 'Romania', 'Ploiesti', 44.93, 26.01, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Green Shelter', 'Romania', 'Brasov', 45.64, 25.58, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Blue Cross', 'Romania', 'Sibiu', 45.79, 24.12, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Noah Arc', 'Romania', 'Cluj', 46.77, 23.58, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Safe Haven', 'Romania', 'Timisoara', 45.74, 21.20, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Paws & Love', 'Romania', 'Iasi', 47.15, 27.60, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('VetCare', 'Romania', 'Constanta', 44.17, 28.63, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Animal Rescue', 'Romania', 'Craiova', 44.33, 23.81, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('LifeLine', 'Romania', 'Galati', 45.43, 28.02, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('PetStop', 'Romania', 'Oradea', 47.04, 21.91, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('FurEver', 'Romania', 'Arad', 46.18, 21.31, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('SoulMates', 'Romania', 'Bacau', 46.56, 26.91, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('Kindness', 'Romania', 'Pitesti', 44.85, 24.86, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]),
                                                                               ('TailWaggers', 'Romania', 'Targu Mures', 46.54, 24.56, v_shelter_images[floor(random() * array_length(v_shelter_images, 1)) + 1]);


FOR i IN 1..15 LOOP
        FOR j IN 1..3 LOOP
            INSERT INTO cages (shelter_id, code, maximum_capacity)
            VALUES (i, 'C-' || i || '-' || j, floor(random() * 5 + 3)::int);
END LOOP;
END LOOP;


FOR i IN 1..55 LOOP
        v_specie := v_specii[floor(random() * array_length(v_specii, 1)) + 1];

CASE v_specie
            WHEN 'Dog' THEN
                v_animal_name := (ARRAY['Rex', 'Fox', 'Max', 'Doggo', 'Pawn'])[floor(random() * 5) + 1];
                v_rasa := (ARRAY['Labrador', 'German Shepherd', 'Husky', 'Beagle'])[floor(random() * 4) + 1];
                v_desc := 'A very loyal and playful dog, looking for a loving home with plenty of space to run and play. Very good with children.';
CASE v_rasa
                    WHEN 'Labrador' THEN v_image_url := 'https://www.pdinsurance.co.nz/wp-content/uploads/2021/03/Labrador-Personality-and-Profile-1-1536x1152.jpg';
WHEN 'German Shepherd' THEN v_image_url := 'https://petzpark.com.au/cdn/shop/articles/German-Shepherd-Puppies_4f9dd7e1-7ea7-4049-bfac-133a6bec8a65_900x.jpg?v=1777475446';
WHEN 'Husky' THEN v_image_url := 'https://images.pexels.com/photos/3715587/pexels-photo-3715587.jpeg';
WHEN 'Beagle' THEN v_image_url := 'https://www.pdsa.org.uk/media/7705/beagle-outdoors-gallery-8-min.jpg?anchor=center&mode=crop&quality=100&height=500&bgcolor=fff&rnd=132158008000000000';
ELSE v_image_url := 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=800';
END CASE;

WHEN 'Cat' THEN
                v_animal_name := (ARRAY['Luna', 'Bella', 'Kitty', 'Milo', 'Simba'])[floor(random() * 5) + 1];
                v_rasa := (ARRAY['Siamese', 'Persian', 'Maine Coon', 'Sphynx'])[floor(random() * 4) + 1];
                v_desc := 'An independent but affectionate cat. Enjoys sunny spots by the window, long naps, and occasional cuddles.';
CASE v_rasa
                    WHEN 'Siamese' THEN v_image_url := 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQbL46gcxtBCYXzRO0sjwSEYNyH41B7wqlEQg&s';
WHEN 'Persian' THEN v_image_url := 'https://www.vetstreet.com/wp-content/uploads/2022/09/view-pet-portrait-cat-mammal-close-843475-pxhere.com-1.jpg';
WHEN 'Maine Coon' THEN v_image_url := 'https://www.whiskas.co.uk/sites/g/files/fnmzdf8916/files/2024-05/shutterstock_2384092615.jpg';
WHEN 'Sphynx' THEN v_image_url := 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSy75DGT16NuYE2vFjjEHpkH5E9sE-i8L2Xtw&s';
ELSE v_image_url := 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=800';
END CASE;

WHEN 'Rabbit' THEN
                v_animal_name := (ARRAY['Thumper', 'Bugs', 'Snowball', 'Daisy', 'Hop'])[floor(random() * 5) + 1];
                v_rasa := (ARRAY['Holland Lop', 'Lionhead','Flemish Giant'])[floor(random() * 3) + 1];
                v_desc := 'A gentle and quiet rabbit. Needs a diet rich in hay and fresh vegetables. Enjoys a peaceful environment.';
CASE v_rasa
                    WHEN 'Holland Lop' THEN v_image_url := 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1VowY5mRh383PY9_GXu79ijO0vckdfj3MKQ&s';
WHEN 'Lionhead' THEN v_image_url := 'https://images.unsplash.com/photo-1518796745738-41048802f99a?w=800&q=80';
WHEN 'Flemish Giant' THEN v_image_url := 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQdVnpNN6ggk1vcdzdjMKMrC9aKXZrYdDrp5g&s';
ELSE v_image_url := 'https://images.unsplash.com/photo-1585110396000-c9fd4e4e5088?q=80&w=800';
END CASE;

WHEN 'Parrot' THEN
                v_animal_name := (ARRAY['Rio', 'Coco', 'Polly', 'Kiwi', 'Mango'])[floor(random() * 5) + 1];
                v_rasa := (ARRAY['Macaw', 'Cockatiel', 'African Grey', 'Budgie'])[floor(random() * 4) + 1];
                v_desc := 'A highly intelligent and vocal bird. Requires daily interaction, mental stimulation, and a spacious cage.';
CASE v_rasa
                    WHEN 'Macaw' THEN v_image_url := 'https://www.thesprucepets.com/thmb/5ZWNQEPnawq5eTvTpNrWTNqHWTo=/1643x0/filters:no_upscale():strip_icc()/200396918-001-56a2bcf55f9b58b7d0cdf8c8.jpg';
WHEN 'Cockatiel' THEN v_image_url := 'https://myrightbird.com/assets/uploads/mybird_meet_the_cockatiel.jpg';
WHEN 'African Grey' THEN v_image_url := 'https://scx2.b-cdn.net/gfx/news/hires/2017/africangreyp.jpg';
WHEN 'Budgie' THEN v_image_url := 'https://problemparrots.co.uk/wp-content/uploads/2024/06/Budgie.jpg';
ELSE v_image_url := 'https://images.unsplash.com/photo-1552728089-57168a145833?q=80&w=800';
END CASE;

WHEN 'Guinea Pig' THEN
                v_animal_name := (ARRAY['Peanut', 'Squeaky', 'Oreo', 'Gizmo', 'Piglet'])[floor(random() * 5) + 1];
                v_rasa := (ARRAY['American', 'Abyssinian', 'Peruvian', 'Silkie'])[floor(random() * 4) + 1];
                v_desc := 'A social and adorable little pet. Communicates with cute squeaks and loves eating fresh greens.';
CASE v_rasa
                    WHEN 'American' THEN v_image_url := 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=800&q=80';
WHEN 'Abyssinian' THEN v_image_url := 'https://animalsdiscovered.com/wp-content/uploads/2025/11/Abyssinian-guinea-pig.jpg';
WHEN 'Peruvian' THEN v_image_url := 'https://www.animalfunfacts.net/images/stories/pets/guinea_pigs/short-haired_peruvian_l.jpg';
WHEN 'Silkie' THEN v_image_url := 'https://www.animalfunfacts.net/images/stories/pets/guinea_pigs/sheltie_guinea_pig_l.jpg';
ELSE v_image_url := 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?q=80&w=800';
END CASE;

ELSE

                v_animal_name := 'Buddy';
                v_rasa := 'Mixed';
                v_desc := 'A wonderful companion ready to be part of a new family.';
                v_image_url := 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=800&auto=format&fit=crop';
END CASE;

        IF i <= 40 THEN

            INSERT INTO animals (cage_id, name, species, breed, date_of_birth, date_of_entry, gender, image_url, description, is_adopted)
            VALUES (
                (i % 45) + 1, v_animal_name, v_specie, v_rasa,
                CURRENT_DATE - (floor(random() * 3000) || ' days')::interval,
                CURRENT_DATE - (floor(random() * 500) || ' days')::interval,
                v_gender[floor(random() * array_length(v_gender, 1)) + 1],
                v_image_url, v_desc, FALSE
            );
ELSE

            INSERT INTO animals (cage_id, name, species, breed, date_of_birth, date_of_entry, gender, image_url, description, is_adopted)
            VALUES (
                NULL, v_animal_name, v_specie, v_rasa,
                CURRENT_DATE - (floor(random() * 3000) || ' days')::interval,
                CURRENT_DATE - (floor(random() * 500) || ' days')::interval,
                v_gender[floor(random() * array_length(v_gender, 1)) + 1],
                v_image_url, v_desc, TRUE
            );
END IF;
END LOOP;


FOR i IN 1..20 LOOP
        INSERT INTO people (first_name, last_name, phone, email)
        VALUES (
            v_prenume[floor(random() * array_length(v_prenume, 1)) + 1],
            v_nume[floor(random() * array_length(v_nume, 1)) + 1],
            '07' || lpad(floor(random() * 100000000)::text, 8, '0'),
            'user' || i || '@test.ro'
        );
END LOOP;


FOR i IN 41..55 LOOP
        INSERT INTO adoptions (animal_id, person_id, adoption_date)
        VALUES (
            i,
            floor(random() * 20) + 1,
            CURRENT_DATE - (floor(random() * 100) || ' days')::interval
        );
END LOOP;


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


FOR i IN 1..40 LOOP
        INSERT INTO medical_records (animal_id, intervention_date, intervention_type, description)
        VALUES (
            floor(random() * 55) + 1,
            CURRENT_DATE - (floor(random() * 200) || ' days')::interval,
            v_medical_types[floor(random() * array_length(v_medical_types, 1)) + 1],
            'Succesful intervention.'
        );
END LOOP;

END $$;

COMMIT;