# KPI Brief — Levant Tech Solutions

## KPI 1: Department Salary Expenditure
**Definition:** Total salary paid per department, calculated as SUM(salary) grouped by department (Q2).
**Current value:** Engineering leads at $938,000, followed by Research at $558,000 and Customer Support at $464,000.
**Interpretation:** Engineering consumes the largest share of the salary budget, which reflects the company's heavy investment in technical talent.

## KPI 2: Project Staffing Ratio
**Definition:** Number of employees assigned per project, calculated as COUNT(employee_id) per project using LEFT JOIN on project_assignments (Q4).
**Current value:** Average of ~6 employees per active project; 2 projects (Blockchain Pilot, Quantum Computing Research) have 0 assignments.
**Interpretation:** Two projects are fully unstaffed, indicating a resource allocation gap that management should address before deadlines are missed.

## KPI 3: Employee Project Utilization Rate
**Definition:** Percentage of employees assigned to at least one project, derived by comparing total employees to unassigned employees (Q7).
**Current value:** 18 out of 60 employees (30%) are unassigned to any project.
**Interpretation:** 30% of the workforce is not contributing to any active project, suggesting an opportunity to improve resource utilization across departments.

## KPI 4: Above-Average Salary Departments
**Definition:** Departments where average employee salary exceeds the company-wide average, calculated using a CTE (Q5).
**Current value:** 4 departments qualify: Engineering ($78,167), Research ($69,750), Finance ($68,833), and Marketing ($64,667).
**Interpretation:** Half of the company's departments pay above-average salaries, concentrated in technical and analytical roles.

## KPI 5: Monthly Hiring Velocity
**Definition:** Number of new hires per month, calculated using EXTRACT on hire_date (Q8).
**Current value:** Peak hiring was in January 2022 with 4 hires; average is approximately 1–2 hires per month.
**Interpretation:** Hiring has been steady but slow, with no significant ramp-up periods, which may limit the company's ability to scale rapidly.
