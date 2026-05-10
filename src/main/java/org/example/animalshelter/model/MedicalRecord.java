package org.example.animalshelter.model;

import java.time.LocalDate;

public class MedicalRecord {
    private Long id;
    private Long animalId;
    private LocalDate interventionDate;
    private String interventionType;
    private String description;

    // Getters și Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getAnimalId() { return animalId; }
    public void setAnimalId(Long animalId) { this.animalId = animalId; }

    public LocalDate getInterventionDate() { return interventionDate; }
    public void setInterventionDate(LocalDate interventionDate) { this.interventionDate = interventionDate; }

    public String getInterventionType() { return interventionType; }
    public void setInterventionType(String interventionType) { this.interventionType = interventionType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}