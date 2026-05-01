package org.example.animalshelter.dao;

import org.example.animalshelter.model.Employee;

public interface EmployeeDao {
        Employee authenticate(String username, String password);
}
