package org.example.animalshelter.dao;

import org.example.animalshelter.model.Animal;
import org.example.animalshelter.model.Person;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public class AnimalDaoImpl implements AnimalDao {

    private final JdbcTemplate jdbcTemplate;

    public AnimalDaoImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Animal> rowMapper = (rs, rowNum) -> {
        Animal animal = new Animal();
        animal.setId(rs.getLong("id"));

        long cageId = rs.getLong("cage_id");
        animal.setCageId(rs.wasNull() ? null : cageId);

        animal.setName(rs.getString("name"));
        animal.setSpecies(rs.getString("species"));
        animal.setBreed(rs.getString("breed"));

        java.sql.Date dob = rs.getDate("date_of_birth");
        animal.setDateOfBirth(dob != null ? dob.toLocalDate() : null);

        java.sql.Date doe = rs.getDate("date_of_entry");
        animal.setDateOfEntry(doe != null ? doe.toLocalDate() : null);

        animal.setImageUrl(rs.getString("image_url"));
        animal.setGender(rs.getString("gender"));
        animal.setDescription(rs.getString("description"));

        animal.setAdoptionScore(rs.getInt("adoption_score"));
        animal.setIsAdopted(rs.getBoolean("is_adopted"));
        return animal;
    };

    @Override
    public List<Animal> findAll() {
        return jdbcTemplate.query("SELECT a.*, fn_calculate_adoption_chance(a.id) AS adoption_score FROM animals a", rowMapper);
    }

    @Override
    public Animal findById(Long id) {
        return jdbcTemplate.queryForObject("SELECT a.*, fn_calculate_adoption_chance(a.id) AS adoption_score FROM animals a WHERE a.id = ?", rowMapper, id);
    }

    @Override
    public List<Animal> findByCageId(Long cageId) {
        return jdbcTemplate.query("SELECT a.*, fn_calculate_adoption_chance(a.id) AS adoption_score FROM animals a WHERE a.cage_id = ?", rowMapper, cageId);
    }

    @Override
    public List<Animal> findByShelterId(Long shelterId) {
        String sql = "SELECT a.*, fn_calculate_adoption_chance(a.id) AS adoption_score " +
                "FROM animals a " +
                "JOIN cages c ON a.cage_id = c.id " +
                "WHERE c.shelter_id = ?";
        return jdbcTemplate.query(sql, rowMapper, shelterId);
    }

    @Override
    public void save(Animal animal) {
        String sql = "INSERT INTO animals (cage_id, name, species, breed, date_of_birth, date_of_entry, image_url, gender, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        jdbcTemplate.update(sql, animal.getCageId(), animal.getName(),
                            animal.getSpecies(), animal.getBreed(), animal.getDateOfBirth(),
                            animal.getDateOfEntry(), animal.getImageUrl(), animal.getGender(),
                            animal.getDescription());
    }

    @Override
    public void update(Animal animal) {
        String sql = "UPDATE animals SET cage_id = ?, name = ?, species = ?, breed = ?, date_of_birth = ?, date_of_entry = ?, image_url = ?, gender = ?, description = ? WHERE id = ?";
        jdbcTemplate.update(sql,animal.getCageId(), animal.getName(),
                            animal.getSpecies(), animal.getBreed(), animal.getDateOfBirth(),
                            animal.getDateOfEntry(), animal.getImageUrl(),
                            animal.getGender(), animal.getDescription(), animal.getId());
    }

    @Override
    public void delete(Long id) {
        jdbcTemplate.update("DELETE FROM animals WHERE id = ?", id);
    }

    @Override
    public void adoptAnimal(Long animalId, Person person) {
        String sqlPerson = "INSERT INTO people (first_name, last_name, phone, email) VALUES (?, ?, ?, ?) RETURNING id";
        Long personId = jdbcTemplate.queryForObject(
                sqlPerson,
                Long.class,
                person.getFirstName(), person.getLastName(), person.getPhone(), person.getEmail()
        );

        String sqlAdoption = "INSERT INTO adoptions (animal_id, person_id, adoption_date) VALUES (?, ?, CURRENT_DATE)";
        jdbcTemplate.update(sqlAdoption, animalId, personId);

        String sqlUpdateAnimal = "UPDATE animals SET is_adopted = true WHERE id = ?";
        jdbcTemplate.update(sqlUpdateAnimal, animalId);
    }
}