package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.AnimalDao;
import org.example.animalshelter.model.Animal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDate;
import java.util.List;

@Controller
public class AnimalController {

    private final AnimalDao animalDao;

    public AnimalController(AnimalDao animalDao) {
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
        if (session.getAttribute("loggedIn") == null) return "redirect:/login";

        try {
            if (animal.getId() == null || animal.getId() == 0) {
                animalDao.save(animal);
            } else {
                animalDao.update(animal);
            }
            return "redirect:/shelters/" + shelterId + "/animals";

        } catch (Exception e) {
            String errorMsg = e.getMessage();
            String friendlyError = errorMsg.contains("CAGE_FULL_ERROR")
                    ? "The selected cage is already full!"
                    : "Database error. Please try again.";

            redirectAttributes.addFlashAttribute("error", friendlyError);
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
}