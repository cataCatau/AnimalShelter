package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.ShelterDao;
import org.example.animalshelter.dao.AnimalDao;
import org.example.animalshelter.model.Shelter;
import org.example.animalshelter.model.Animal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

import java.util.List;
@Controller
public class AnimalController {

    private final AnimalDao animalDao;

    AnimalController(AnimalDao animalDao) {
        this.animalDao = animalDao;
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
        model.addAttribute("animal", new Animal());
        model.addAttribute("shelterId", shelterId);

        return "animal-form";
    }

    @PostMapping("/shelters/{id}/animals/save")
    public String saveAnimal(@PathVariable("id") Long shelterId, @ModelAttribute("animal") Animal animal, HttpSession session) {
        if (session.getAttribute("loggedIn") == null) {
            return "redirect:/login";
        }

        animalDao.save(animal);
        return "redirect:/shelters/" + shelterId + "/animals";
    }
}
