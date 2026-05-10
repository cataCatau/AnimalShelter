package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.EmployeeDao;
import org.example.animalshelter.dao.ShelterDao;
import org.example.animalshelter.model.Employee;
import org.example.animalshelter.model.Shelter;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class ShelterController {

    private final ShelterDao shelterDao;
    private final EmployeeDao employeeDao;
    public ShelterController(ShelterDao shelterDao, EmployeeDao employeeDao){
        this.shelterDao = shelterDao;
        this.employeeDao = employeeDao;

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
