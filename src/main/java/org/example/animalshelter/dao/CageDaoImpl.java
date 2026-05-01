package org.example.animalshelter.dao;

import org.example.animalshelter.model.Cage;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class CageDaoImpl implements CageDao {

    private final JdbcTemplate jdbcTemplate;

    public CageDaoImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Cage> rowMapper = (rs, rowNum) -> {
        Cage cage = new Cage();
        cage.setId(rs.getLong("id"));
        cage.setShelterId(rs.getLong("shelter_id"));
        cage.setSpeciesType(rs.getString("species_type"));
        cage.setMaximumCapacity(rs.getInt("maximum_capacity"));
        return cage;
    };

    @Override
    public List<Cage> findAll() {
        return jdbcTemplate.query("SELECT * FROM cages", rowMapper);
    }

    @Override
    public Cage findById(Long id) {
        return jdbcTemplate.queryForObject("SELECT * FROM cages WHERE id = ?", rowMapper, id);
    }

    @Override
    public List<Cage> findByShelterId(Long shelterId) {
        return jdbcTemplate.query("SELECT * FROM cages WHERE shelter_id = ?", rowMapper, shelterId);
    }

    @Override
    public void save(Cage cage) {
        String sql = "INSERT INTO cages (shelter_id, species_type, maximum_capacity) VALUES (?, ?, ?)";
        jdbcTemplate.update(sql, cage.getShelterId(), cage.getSpeciesType(), cage.getMaximumCapacity());
    }

    @Override
    public void update(Cage cage) {
        String sql = "UPDATE cages SET shelter_id = ?, species_type = ?, maximum_capacity = ? WHERE id = ?";
        jdbcTemplate.update(sql, cage.getShelterId(), cage.getSpeciesType(), cage.getMaximumCapacity(), cage.getId());
    }

    @Override
    public void delete(Long id) {
        jdbcTemplate.update("DELETE FROM cages WHERE id = ?", id);
    }
}