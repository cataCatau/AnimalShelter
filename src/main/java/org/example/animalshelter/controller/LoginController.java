package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.AnimalDao;
import org.example.animalshelter.dao.EmployeeDao;
import org.example.animalshelter.dao.ShelterDao;
import org.example.animalshelter.model.Employee;
import org.example.animalshelter.model.Shelter;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class LoginController {

    private final EmployeeDao employeeDao;
    private final AnimalDao animalDao;
    private final ShelterDao shelterDao;

    public LoginController(EmployeeDao employeeDao, AnimalDao animalDao, ShelterDao shelterDao) {
        this.employeeDao = employeeDao;
        this.animalDao = animalDao;
        this.shelterDao = shelterDao;
    }

    @GetMapping("/login")
    public String showLoginPage(Model model){
        model.addAttribute("statAnimals",  animalDao.countAll());
        model.addAttribute("statAdopted",  animalDao.countAdopted());
        model.addAttribute("statShelters", shelterDao.countAll());
        return "login";
    }

    @PostMapping("login")
    public String processLogin(@RequestParam("username") String username,
                               @RequestParam("password") String password,
                               HttpSession session,
                               Model model){

        Employee employee = employeeDao.authenticate(username, password);

        if(employee != null){
            session.setAttribute("loggedIn", employee);
            session.setAttribute("employeeRole", employee.getRole());
            model.addAttribute("statAnimals",  animalDao.countAll());
            model.addAttribute("statAdopted",  animalDao.countAdopted());
            model.addAttribute("statShelters", shelterDao.countAll());
            return "redirect:/shelters";
        }
        else {
            model.addAttribute("error", "Invalid credentials");
            return "login";
        }
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }
}
