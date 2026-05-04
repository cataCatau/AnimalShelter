package org.example.animalshelter.model;

import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

public class Animal {
    private Long id;
    private Long cageId;
    private String name;
    private String species;
    private String breed;
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate dateOfBirth;
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate dateOfEntry;
    private String imageUrl;
    private String gender;
    private String description;
    private Integer adoptionScore;
    public Animal() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getCageId() { return cageId; }
    public void setCageId(Long cageId) { this.cageId = cageId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSpecies() { return species; }
    public void setSpecies(String species) { this.species = species; }
    public String getBreed() { return breed; }
    public void setBreed(String breed) { this.breed = breed; }
    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }
    public LocalDate getDateOfEntry() { return dateOfEntry; }
    public void setDateOfEntry(LocalDate dateOfEntry) { this.dateOfEntry = dateOfEntry; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description;}
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public Integer getAdoptionScore() { return adoptionScore; }
    public void setAdoptionScore(Integer adoptionScore) { this.adoptionScore = adoptionScore; }
}