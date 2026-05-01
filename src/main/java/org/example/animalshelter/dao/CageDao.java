package org.example.animalshelter.dao;

import org.example.animalshelter.model.Cage;
import java.util.List;

public interface CageDao {
    List<Cage> findAll();
    Cage findById(Long id);
    List<Cage> findByShelterId(Long shelterId);
    void save(Cage cage);
    void update(Cage cage);
    void delete(Long id);
}