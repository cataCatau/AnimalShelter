package org.example.animalshelter.dao;

import org.example.animalshelter.model.Animal;
import java.util.List;

public interface AnimalDao {
    List<Animal> findAll();
    Animal findById(Long id);
    List<Animal> findByCageId(Long cageId);
    List<Animal> findByShelterId(Long shelterId);
    void save(Animal animal);
    void update(Animal animal);
    void delete(Long id);
}