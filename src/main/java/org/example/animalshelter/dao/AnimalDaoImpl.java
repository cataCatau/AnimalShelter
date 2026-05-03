package org.example.animalshelter.dao;

import org.example.animalshelter.model.Animal;
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

        long shelterId = rs.getLong("shelter_id");
        animal.setShelterId(rs.wasNull() ? null : shelterId);

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
        return animal;
    };

    @Override
    public List<Animal> findAll() {
        return jdbcTemplate.query("SELECT * FROM animals", rowMapper);
    }

    @Override
    public Animal findById(Long id) {
        return jdbcTemplate.queryForObject("SELECT * FROM animals WHERE id = ?", rowMapper, id);
    }

    @Override
    public List<Animal> findByCageId(Long cageId) {

        return jdbcTemplate.query("SELECT * FROM animals WHERE cage_id = ?", rowMapper, cageId);
    }

    @Override
    public List<Animal> findByShelterId(Long shelterId){
        String sql = "SELECT a.* FROM animals a " +
                "JOIN cages c ON a.cage_id = c.id " +
                "WHERE c.shelter_id = ?";
        return jdbcTemplate.query(sql, rowMapper, shelterId);
    }

    @Override
    public void save(Animal animal) {
        String sql = "INSERT INTO animals (shelter_id, cage_id, name, species, breed, date_of_birth, date_of_entry, image_url, gender, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        jdbcTemplate.update(sql, animal.getShelterId(), animal.getCageId(), animal.getName(),
                            animal.getSpecies(), animal.getBreed(), animal.getDateOfBirth(),
                            animal.getDateOfEntry(), animal.getImageUrl(), animal.getGender(),
                            animal.getDescription());
    }

    @Override
    public void update(Animal animal) {
        String sql = "UPDATE animals SET shelter_id = ?, cage_id = ?, name = ?, species = ?, breed = ?, date_of_birth = ?, date_of_entry = ?, image_url = ?, gender = ?, description = ? WHERE id = ?";
        jdbcTemplate.update(sql, animal.getShelterId(), animal.getCageId(), animal.getName(),
                            animal.getSpecies(), animal.getBreed(), animal.getDateOfBirth(),
                            animal.getDateOfEntry(), animal.getImageUrl(),
                            animal.getGender(), animal.getDescription(), animal.getId());
    }

    @Override
    public void delete(Long id) {
        jdbcTemplate.update("DELETE FROM animals WHERE id = ?", id);
    }
}