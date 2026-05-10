package org.example.animalshelter.controller;

import jakarta.servlet.http.HttpSession;
import org.example.animalshelter.dao.EmployeeDao;
import org.example.animalshelter.model.Employee;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class EmployeeController {

    private final EmployeeDao employeeDao;

    public EmployeeController(EmployeeDao employeeDao) {
        this.employeeDao = employeeDao;
    }

    @GetMapping("/shelters/{id}/employees")
    public String listEmployees(@PathVariable("id") Long shelterId, Model model, HttpSession session) {
        String role = (String) session.getAttribute("employeeRole");
        if (session.getAttribute("loggedIn") == null || (!"Manager".equals(role) && !"Admin".equals(role))) {
            return "redirect:/shelters";
        }
        
        model.addAttribute("employees", employeeDao.findByShelterId(shelterId));
        model.addAttribute("shelterId", shelterId);
        return "employees";
    }

    @GetMapping("/shelters/{id}/employees/new")
    public String showAddEmployeeForm(@PathVariable("id") Long shelterId, Model model, HttpSession session) {
        String role = (String) session.getAttribute("employeeRole");
        if (session.getAttribute("loggedIn") == null || (!"Manager".equals(role) && !"Admin".equals(role))) {
            return "redirect:/shelters";
        }
        
        if (!model.containsAttribute("employee")) {
            Employee emp = new Employee();
            emp.setShelterId(shelterId);
            model.addAttribute("employee", emp);
        }
        
        model.addAttribute("shelterId", shelterId);
        return "employee-form";
    }

    @GetMapping("/shelters/{sId}/employees/{eId}/edit")
    public String editEmployeeForm(@PathVariable("sId") Long shelterId, @PathVariable("eId") Long empId, Model model, HttpSession session) {
        String role = (String) session.getAttribute("employeeRole");
        if (session.getAttribute("loggedIn") == null || (!"Manager".equals(role) && !"Admin".equals(role))) {
            return "redirect:/shelters";
        }
        
        model.addAttribute("employee", employeeDao.findById(empId));
        model.addAttribute("shelterId", shelterId);
        return "employee-form";
    }

    @GetMapping("/shelters/{sId}/employees/{eId}/delete")
    public String deleteEmployee(@PathVariable("sId") Long sId, @PathVariable("eId") Long eId, HttpSession session) {
        String role = (String) session.getAttribute("employeeRole");
        if (session.getAttribute("loggedIn") == null || (!"Manager".equals(role) && !"Admin".equals(role))) {
            return "redirect:/shelters";
        }
        
        employeeDao.delete(eId);
        return "redirect:/shelters/" + sId + "/employees";
    }

    @PostMapping("/shelters/{shelterId}/employees/save")
    public String saveEmployee(@PathVariable("shelterId") Long shelterId, @ModelAttribute("employee") Employee emp, RedirectAttributes ra, HttpSession session) {
        String role = (String) session.getAttribute("employeeRole");
        if (session.getAttribute("loggedIn") == null || (!"Manager".equals(role) && !"Admin".equals(role))) {
            return "redirect:/shelters";
        }
        
        emp.setShelterId(shelterId);
        
        try {
            if (emp.getId() == null || emp.getId() == 0) {
                employeeDao.save(emp);
            } else {
                employeeDao.update(emp);
            }
            return "redirect:/shelters/" + shelterId + "/employees";
        } catch (Exception e) {
            if (e.getMessage() != null && e.getMessage().contains("SALARY_TOO_LOW")) {
                ra.addFlashAttribute("error", "⛔ Salary must be at least 3000 RON!");
            } else {
                ra.addFlashAttribute("error", "An error occurred: " + e.getMessage());
            }
            ra.addFlashAttribute("employee", emp);
            return "redirect:/shelters/" + shelterId + "/employees/new";
        }
    }
}