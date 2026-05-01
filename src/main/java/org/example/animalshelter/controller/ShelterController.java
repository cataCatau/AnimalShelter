package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.ShelterDao;
import org.example.animalshelter.model.Shelter;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
public class ShelterController {

    private final ShelterDao shelterDao;

    public ShelterController(ShelterDao shelterDao){
        this.shelterDao=shelterDao;

    }

    @GetMapping("/shelters")
    public String showShelters(Model model, HttpSession session){

        if(session.getAttribute("loggedIn") == null){
            return "redirect:/login";
        }

        List<Shelter> listShelters = shelterDao.findAll();
        model.addAttribute("shelters", listShelters);
        return "shelters";
    }
}
