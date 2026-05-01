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
        employee.setUsername(rs.getString("username"));
        employee.setPassword(rs.getString("password"));
        employee.setFullName(rs.getString("full_name"));
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
