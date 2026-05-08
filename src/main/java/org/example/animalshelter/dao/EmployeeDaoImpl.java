package org.example.animalshelter.dao;

import org.example.animalshelter.model.Employee;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class EmployeeDaoImpl implements EmployeeDao {

    private final JdbcTemplate jdbcTemplate;

    public EmployeeDaoImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Employee> rowMapper = (rs, rowNum) -> {
        Employee employee = new Employee();
        employee.setId(rs.getLong("id"));
        employee.setShelterId(rs.getLong("shelter_id"));
        employee.setFirstName(rs.getString("first_name"));
        employee.setLastName(rs.getString("last_name"));
        employee.setUsername(rs.getString("username"));
        employee.setPassword(rs.getString("password"));
        employee.setPhone(rs.getString("phone"));
        employee.setRole(rs.getString("role"));
        employee.setSalary(rs.getDouble("salary"));
        return employee;
    };

    @Override
    public Employee authenticate(String username, String password){
        String sql = "SELECT * FROM employees WHERE username = ? AND password = ?";
        try {
            return jdbcTemplate.queryForObject(sql, rowMapper, username, password);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }
}