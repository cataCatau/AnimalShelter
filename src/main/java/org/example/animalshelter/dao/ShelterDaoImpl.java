package org.example.animalshelter.dao;

import org.example.animalshelter.model.Shelter;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class ShelterDaoImpl implements ShelterDao {

    private final JdbcTemplate jdbcTemplate;

    public ShelterDaoImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Shelter> rowMapper = (rs, rowNum) -> {
        Shelter shelter = new Shelter();
        shelter.setId(rs.getLong("id"));
        shelter.setName(rs.getString("name"));
        shelter.setCountry(rs.getString("country"));
        shelter.setCity(rs.getString("city"));
        shelter.setImageUrl(rs.getString("image_url"));
        shelter.setTotalCages(rs.getInt("total_cages"));
        shelter.setTotalCapacity(rs.getInt("total_capacity"));
        shelter.setCurrentAnimals(rs.getInt("current_animals"));
        shelter.setFreeSpots(rs.getInt("free_spots"));
        return shelter;
    };

    @Override
    public List<Shelter> findAll() {
        String sql = "SELECT * FROM vw_shelter_statistics ORDER BY id";
        return jdbcTemplate.query(sql, rowMapper);
    }

    @Override
    public Shelter findById(Long id) {
        String sql = "SELECT * FROM vw_shelter_statistics WHERE id = ?";
        return jdbcTemplate.queryForObject(sql, rowMapper, id);
    }

    @Override
    public void save(Shelter shelter) {
        String sql = "INSERT INTO shelters (name, country, city, image_url) VALUES (?, ?, ?, ?)";
        jdbcTemplate.update(sql, shelter.getName(), shelter.getCountry(), shelter.getCity(),
                            shelter.getImageUrl());
    }

    @Override
    public void update(Shelter shelter) {
        String sql = "UPDATE shelters SET name = ?, country = ?, city = ?, shelter = ? WHERE id = ?";
        jdbcTemplate.update(sql, shelter.getName(), shelter.getCountry(), shelter.getCity(),
                            shelter.getImageUrl(), shelter.getId());
    }

    @Override
    public void delete(Long id) {
        String sql = "DELETE FROM shelters WHERE id = ?";
        jdbcTemplate.update(sql, id);
    }

    @Override
    public int countAll() {
        String sql = "SELECT COUNT(*) FROM shelters";
        Integer result = jdbcTemplate.queryForObject(sql, Integer.class);
        return result != null ? result : 0;
    }
}