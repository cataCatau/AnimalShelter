package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.AnimalDao;
import org.example.animalshelter.model.Animal;
import org.example.animalshelter.model.Person;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Controller
public class AnimalController {

    private final AnimalDao animalDao;
    private final JdbcTemplate jdbcTemplate;

    public AnimalController(AnimalDao animalDao, JdbcTemplate jdbcTemplate) {
        this.animalDao = animalDao;
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/animals")
    public String showAnimals(Model model, HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }
        List<Animal> listAnimals = animalDao.findAll();
        model.addAttribute("animals", listAnimals);
        return "animals";
    }

    @GetMapping("/shelters/{id}/animals")
    public String showAnimalsByShelter(@PathVariable("id") Long shelterId, Model model, HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }
        List<Animal> listAnimals = animalDao.findByShelterId(shelterId);

        model.addAttribute("animals", listAnimals);
        model.addAttribute("shelterId", shelterId);
        return "animals";
    }

    @GetMapping("/shelters/{id}/animals/new")
    public String showAddAnimalForm(@PathVariable("id") Long shelterId, Model model, HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }

        if (!model.containsAttribute("animal")) {
            model.addAttribute("animal", new Animal());
        }

        model.addAttribute("shelterId", shelterId);
        model.addAttribute("today", LocalDate.now());
        return "animal-form";
    }

    @PostMapping("/shelters/{shelterId}/animals/save")
    public String saveOrUpdateAnimal(@PathVariable("shelterId") Long shelterId,
                                     @ModelAttribute("animal") Animal animal,
                                     RedirectAttributes redirectAttributes,
                                     HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }

        try {
            if (animal.getId() == null || animal.getId() == 0) {
                animalDao.save(animal);
            } else {
                animalDao.update(animal);
            }

            return "redirect:/shelters/" + shelterId + "/animals";

        } catch (Exception e) {
            String errorMsg = e.getMessage();
            String finalMessage = "A database error occurred: " + errorMsg;

            if (errorMsg != null && errorMsg.contains("CAGE_FULL_ERROR")) {
                try {
                    List<Map<String, Object>> suggestions = jdbcTemplate.queryForList(
                            "SELECT * FROM fn_get_transfer_suggestion(?)", shelterId.intValue()
                    );

                    if (!suggestions.isEmpty()) {
                        Map<String, Object> suggestion = suggestions.get(0);
                        finalMessage = String.format(
                                "Shelter is full! Suggested Transfer: %s in %s (Distance: %.2f km).",
                                suggestion.get("suggested_shelter_name"),
                                suggestion.get("city_name"),
                                ((Number) suggestion.get("distance_km")).doubleValue()
                        );
                    } else {
                        finalMessage = "Shelter is full and no other shelters with available space were found.";
                    }
                } catch (Exception ex) {
                    finalMessage = "Shelter is full! (Transfer calculation failed).";
                }
            }
            else if (errorMsg != null && errorMsg.contains("foreign key")) {
                finalMessage = "Error: The entered Cage ID does not exist in the database!";
            }

            redirectAttributes.addFlashAttribute("error", finalMessage);
            redirectAttributes.addFlashAttribute("animal", animal);

            if (animal.getId() == null || animal.getId() == 0) {
                return "redirect:/shelters/" + shelterId + "/animals/new";
            } else {
                return "redirect:/shelters/" + shelterId + "/animals/" + animal.getId() + "/edit";
            }
        }
    }

    @GetMapping("/shelters/{shelterId}/animals/{animalId}/edit")
    public String showEditAnimalForm(@PathVariable("shelterId") Long shelterId,
                                     @PathVariable("animalId") Long animalId,
                                     Model model,
                                     HttpSession session) {

        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }

        Animal animal = animalDao.findById(animalId);
        model.addAttribute("animal", animal);
        model.addAttribute("shelterId", shelterId);
        model.addAttribute("today", LocalDate.now());
        return "animal-form";
    }

    @GetMapping("/shelters/{shelterId}/animals/{animalId}/delete")
    public String deleteAnimal(@PathVariable("shelterId") Long shelterId,
                               @PathVariable("animalId") Long animalId,
                               HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }

        animalDao.delete(animalId);

        return "redirect:/shelters/" + shelterId + "/animals";
    }

    @GetMapping("/shelters/{shelterId}/animals/{animalId}/adopt")
    public String showAdoptionForm(@PathVariable("shelterId") Long shelterId,
                                   @PathVariable("animalId") Long animalId,
                                   Model model, HttpSession session) {
        if (session.getAttribute("loggedIn") == null) return "redirect:/login";

        model.addAttribute("shelterId", shelterId);
        model.addAttribute("animalId", animalId);
        model.addAttribute("person", new Person());
        return "adoption-form";
    }

    @PostMapping("/shelters/{shelterId}/animals/{animalId}/adopt")
    public String processAdoption(@PathVariable("shelterId") Long shelterId,
                                  @PathVariable("animalId") Long animalId,
                                  @ModelAttribute("person") Person person,
                                  HttpSession session) {
        if (session.getAttribute("loggedIn") == null) return "redirect:/login";
        animalDao.adoptAnimal(animalId, person);

        return "redirect:/shelters/" + shelterId + "/animals";
    }

    @GetMapping("/animals/adopted")
    public String showAdoptedAnimals(Model model, HttpSession session){
        if ( session.getAttribute("loggedIn") == null ) return "redirect:/login";
        List<Animal> adoptedAnimals = animalDao.findAllAdopted();
        model.addAttribute("animals", adoptedAnimals);
        return "adopted-animals";
    }
}