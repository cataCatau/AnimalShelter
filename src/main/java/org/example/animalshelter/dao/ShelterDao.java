package org.example.animalshelter.dao;

import org.example.animalshelter.model.Shelter;

import java.util.List;

public interface ShelterDao {
    List<Shelter> findAll();
    Shelter findById(Long id);
    void save(Shelter shelter);
    void update(Shelter shelter);
    void delete(Long id);
    int countAll();
}