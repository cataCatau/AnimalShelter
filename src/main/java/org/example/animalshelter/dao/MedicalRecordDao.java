package org.example.animalshelter.dao;

import org.example.animalshelter.model.MedicalRecord;
import java.util.List;

public interface MedicalRecordDao {
    List<MedicalRecord> findByAnimalId(Long animalId);
    void save(MedicalRecord record);
}