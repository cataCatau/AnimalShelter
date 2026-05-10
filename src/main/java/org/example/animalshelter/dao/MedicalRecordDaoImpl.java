package org.example.animalshelter.dao;

import org.example.animalshelter.model.MedicalRecord;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class MedicalRecordDaoImpl implements MedicalRecordDao {

    private final JdbcTemplate jdbcTemplate;

    public MedicalRecordDaoImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<MedicalRecord> rowMapper = (rs, rowNum) -> {
        MedicalRecord record = new MedicalRecord();
        record.setId(rs.getLong("id"));
        record.setAnimalId(rs.getLong("animal_id"));
        if (rs.getDate("intervention_date") != null) {
            record.setInterventionDate(rs.getDate("intervention_date").toLocalDate());
        }
        record.setInterventionType(rs.getString("intervention_type"));
        record.setDescription(rs.getString("description"));
        return record;
    };

    @Override
    public List<MedicalRecord> findByAnimalId(Long animalId) {
        return jdbcTemplate.query("SELECT * FROM medical_records WHERE animal_id = ? ORDER BY intervention_date DESC", rowMapper, animalId);
    }

    @Override
    public void save(MedicalRecord record) {
        String sql = "INSERT INTO medical_records (animal_id, intervention_date, intervention_type, description) VALUES (?, ?, ?, ?)";
        jdbcTemplate.update(sql, record.getAnimalId(), record.getInterventionDate(), record.getInterventionType(), record.getDescription());
    }
}