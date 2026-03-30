-- challenge_extensions.sql — SQL Analytics Lab: Challenge Extensions
-- Module 3: SQL & Relational Data

-- ============================================================
-- TIER 1: Complex Analytics Queries
-- ============================================================

-- Tier 1a: At-Risk Projects
-- Projects where total allocated hours exceed 80% of the project budget
-- Note: budget is stored in USD; treating it as available hours per instructions.
-- With current seed data (budget in hundreds of thousands, hours in hundreds),
-- no projects exceed the 80% threshold — query logic is correct.

SELECT
    p.name AS project_name,
    p.budget AS budget_as_hours,
    SUM(pa.hours_allocated) AS total_hours,
    ROUND((SUM(pa.hours_allocated)::numeric / p.budget) * 100, 2) AS utilization_pct
FROM projects p
JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING SUM(pa.hours_allocated) > p.budget * 0.80
ORDER BY utilization_pct DESC;

-- Tier 1b: Cross-Department Employee Assignments
-- Employees assigned to projects where the majority of assignees are from a different department.
-- Note: projects table has no department_id column in this schema.
-- We identify each project's "home department" as the department with the most assigned employees.

WITH project_home_dept AS (
    SELECT pa.project_id,
           e.department_id,
           COUNT(*) AS cnt,
           RANK() OVER (PARTITION BY pa.project_id ORDER BY COUNT(*) DESC) AS rnk
    FROM project_assignments pa
    JOIN employees e ON pa.employee_id = e.employee_id
    GROUP BY pa.project_id, e.department_id
)
SELECT
    e.first_name,
    e.last_name,
    ed.name AS employee_department,
    p.name AS project_name,
    hd.name AS project_home_department
FROM employees e
JOIN departments ed ON e.department_id = ed.department_id
JOIN project_assignments pa ON e.employee_id = pa.employee_id
JOIN projects p ON pa.project_id = p.project_id
JOIN project_home_dept phd ON pa.project_id = phd.project_id AND phd.rnk = 1
JOIN departments hd ON phd.department_id = hd.department_id
WHERE e.department_id != phd.department_id
ORDER BY e.last_name, p.name;

-- ============================================================
-- TIER 2: Dynamic Reporting with Views and Functions
-- ============================================================

-- Tier 2a: Department Summary View
CREATE OR REPLACE VIEW department_summary AS
SELECT
    d.name AS department_name,
    COUNT(e.employee_id) AS employee_count,
    SUM(e.salary) AS total_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.name;

-- Tier 2b: Project Status View
CREATE OR REPLACE VIEW project_status AS
SELECT
    p.name AS project_name,
    p.start_date,
    p.end_date,
    p.budget,
    COUNT(pa.employee_id) AS assigned_employees,
    COALESCE(SUM(pa.hours_allocated), 0) AS total_hours,
    CASE
        WHEN p.end_date IS NULL THEN 'Ongoing'
        WHEN p.end_date < CURRENT_DATE THEN 'Completed'
        ELSE 'Active'
    END AS status
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.start_date, p.end_date, p.budget;

-- Tier 2c: Materialized View for Department Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS department_summary_mat AS
SELECT
    d.name AS department_name,
    COUNT(e.employee_id) AS employee_count,
    SUM(e.salary) AS total_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.name;

-- Tier 2d: PL/pgSQL Function — Department Info as JSON
CREATE OR REPLACE FUNCTION get_department_info(dept_name VARCHAR)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'department', dept_name,
        'employee_count', COUNT(e.employee_id),
        'total_salary', SUM(e.salary),
        'active_projects', (
            SELECT COUNT(DISTINCT p.project_id)
            FROM projects p
            JOIN project_assignments pa ON p.project_id = pa.project_id
            JOIN employees emp ON pa.employee_id = emp.employee_id
            JOIN departments d2 ON emp.department_id = d2.department_id
            WHERE d2.name = dept_name
            AND (p.end_date IS NULL OR p.end_date >= CURRENT_DATE)
        )
    )
    INTO result
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE d.name = dept_name;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Call the function
SELECT get_department_info('Engineering');

-- ============================================================
-- TIER 3: Schema Evolution and Migration
-- ============================================================

-- Tier 3a: salary_history Table DDL
CREATE TABLE IF NOT EXISTS salary_history (
    history_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    salary NUMERIC(10,2) NOT NULL,
    effective_date DATE NOT NULL,
    change_reason VARCHAR(150)
);

-- Tier 3b: Migration Script — Populate from employees table
INSERT INTO salary_history (employee_id, salary, effective_date, change_reason)
SELECT employee_id, salary, hire_date, 'Initial salary at hire'
FROM employees;

-- Tier 3c: Seed realistic salary history (2-3 records per employee over 3 years)
INSERT INTO salary_history (employee_id, salary, effective_date, change_reason)
SELECT employee_id, salary * 0.90, hire_date + INTERVAL '1 year', 'Annual review 2023'
FROM employees
WHERE hire_date <= '2023-01-01';

INSERT INTO salary_history (employee_id, salary, effective_date, change_reason)
SELECT employee_id, salary * 0.95, hire_date + INTERVAL '2 years', 'Annual review 2024'
FROM employees
WHERE hire_date <= '2022-01-01';

-- Tier 3d: Salary Growth Rate by Department Over Time
SELECT
    d.name AS department_name,
    EXTRACT(YEAR FROM sh.effective_date) AS year,
    ROUND(AVG(sh.salary), 2) AS avg_salary
FROM salary_history sh
JOIN employees e ON sh.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name, year
ORDER BY d.name, year;

-- Tier 3e: Employees Due for Salary Review (no change in 12+ months)
SELECT
    e.first_name,
    e.last_name,
    d.name AS department_name,
    MAX(sh.effective_date) AS last_review_date,
    CURRENT_DATE - MAX(sh.effective_date) AS days_since_review
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN salary_history sh ON e.employee_id = sh.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, d.name
HAVING MAX(sh.effective_date) < CURRENT_DATE - INTERVAL '12 months'
ORDER BY days_since_review DESC;
