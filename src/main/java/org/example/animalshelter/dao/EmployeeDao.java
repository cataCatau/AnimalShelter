package org.example.animalshelter.dao;

import org.example.animalshelter.model.Employee;

import java.util.List;

public interface EmployeeDao {
        Employee authenticate(String username, String password);
        void save(Employee employee);
        List<Employee> findByShelterId(Long shelterId);
        Employee findById(Long id);
        void update(Employee employee);
        void delete(Long id);
}
