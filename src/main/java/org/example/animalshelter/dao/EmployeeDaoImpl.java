package org.example.animalshelter.dao;

import org.example.animalshelter.model.Employee;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

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

    @Override
    public void save(Employee employee) {
        String sql = "INSERT INTO employees (shelter_id, first_name, last_name, username, password, phone, role, salary) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        jdbcTemplate.update(sql,
                employee.getShelterId(), employee.getFirstName(), employee.getLastName(),
                employee.getUsername(), employee.getPassword(), employee.getPhone(),
                employee.getRole(), employee.getSalary());
    }

    @Override
    public List<Employee> findByShelterId(Long shelterId) {
        return jdbcTemplate.query("SELECT * FROM employees WHERE shelter_id = ?", rowMapper, shelterId);
    }

    @Override
    public Employee findById(Long id) {
        return jdbcTemplate.queryForObject("SELECT * FROM employees WHERE id = ?", rowMapper, id);
    }

    @Override
    public void update(Employee emp) {
        String sql = "UPDATE employees SET first_name=?, last_name=?, username=?, password=?, phone=?, role=?, salary=? WHERE id=?";
        jdbcTemplate.update(sql, emp.getFirstName(), emp.getLastName(), emp.getUsername(),
                emp.getPassword(), emp.getPhone(), emp.getRole(), emp.getSalary(), emp.getId());
    }

    @Override
    public void delete(Long id) {
        jdbcTemplate.update("DELETE FROM employees WHERE id = ?", id);
    }
}