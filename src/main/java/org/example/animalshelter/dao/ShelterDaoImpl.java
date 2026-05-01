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
        return shelter;
    };

    @Override
    public List<Shelter> findAll() {
        String sql = "SELECT * FROM shelters";
        return jdbcTemplate.query(sql, rowMapper);
    }

    @Override
    public Shelter findById(Long id) {
        String sql = "SELECT * FROM shelters WHERE id = ?";
        return jdbcTemplate.queryForObject(sql, rowMapper, id);
    }

    @Override
    public void save(Shelter shelter) {
        String sql = "INSERT INTO shelters (name, country, city) VALUES (?, ?, ?)";
        jdbcTemplate.update(sql, shelter.getName(), shelter.getCountry(), shelter.getCity());
    }

    @Override
    public void update(Shelter shelter) {
        String sql = "UPDATE shelters SET name = ?, country = ?, city = ? WHERE id = ?";
        jdbcTemplate.update(sql, shelter.getName(), shelter.getCountry(), shelter.getCity(), shelter.getId());
    }

    @Override
    public void delete(Long id) {
        String sql = "DELETE FROM shelters WHERE id = ?";
        jdbcTemplate.update(sql, id);
    }
}