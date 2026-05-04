package org.example.animalshelter.model;

public class Shelter {
    private Long id;
    private String name;
    private String country;
    private String city;
    private String imageUrl;


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
}