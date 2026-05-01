package org.example.animalshelter.model;

public class Cage {
    private Long id;
    private Long shelterId;
    private String speciesType;
    private Integer maximumCapacity;

    public Cage() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getShelterId() { return shelterId; }
    public void setShelterId(Long shelterId) { this.shelterId = shelterId; }
    public String getSpeciesType() { return speciesType; }
    public void setSpeciesType(String speciesType) { this.speciesType = speciesType; }
    public Integer getMaximumCapacity() { return maximumCapacity; }
    public void setMaximumCapacity(Integer maximumCapacity) { this.maximumCapacity = maximumCapacity; }
}