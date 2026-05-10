package org.example.animalshelter.model;

public class Shelter {
    private Long id;
    private String name;
    private String country;
    private String city;
    private String imageUrl;
    private Integer totalCages;
    private Integer totalCapacity;
    private Integer currentAnimals;
    private Integer freeSpots;

    public Shelter() {
    }

    public Shelter(Long id, String name, String country, String city, String imageUrl) {
        this.id = id;
        this.name = name;
        this.country = country;
        this.city = city;
        this.imageUrl = imageUrl;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public Integer getTotalCages() {
        return totalCages;
    }

    public void setTotalCages(Integer totalCages) {
        this.totalCages = totalCages;
    }

    public Integer getTotalCapacity() {
        return totalCapacity;
    }

    public void setTotalCapacity(Integer totalCapacity) {
        this.totalCapacity = totalCapacity;
    }

    public Integer getCurrentAnimals() {
        return currentAnimals;
    }

    public void setCurrentAnimals(Integer currentAnimals) {
        this.currentAnimals = currentAnimals;
    }

    public Integer getFreeSpots() {
        return freeSpots;
    }

    public void setFreeSpots(Integer freeSpots) {
        this.freeSpots = freeSpots;
    }
}