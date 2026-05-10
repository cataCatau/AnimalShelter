package org.example.animalshelter.dao;

import org.example.animalshelter.model.Animal;
import org.example.animalshelter.model.Person;

import java.util.List;

public interface AnimalDao {
    List<Animal> findAll();
    Animal findById(Long id);
    List<Animal> findByCageId(Long cageId);
    List<Animal> findByShelterId(Long shelterId);
    void save(Animal animal);
    void update(Animal animal);
    void adoptAnimal(Long animalId, Person person);
    List<Animal> findAllAdopted();
    void delete(Long id);
}