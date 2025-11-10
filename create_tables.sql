-- create_tables.sql
-- Creates the tables used by the PL/SQL Collections demo
-- 1. Create schema objects
CREATE TABLE employees (
  emp_id      NUMBER PRIMARY KEY,
  first_name  VARCHAR2(50),
  last_name   VARCHAR2(50),
  dept        VARCHAR2(50)
);

CREATE TABLE projects (
  proj_id     NUMBER PRIMARY KEY,
  proj_name   VARCHAR2(100),
  start_date  DATE,
  end_date    DATE
);

CREATE TABLE assignments (
  assign_id      NUMBER PRIMARY KEY,
  emp_id         NUMBER REFERENCES employees(emp_id),
  proj_id        NUMBER REFERENCES projects(proj_id),
  role           VARCHAR2(50),
  hours_per_week NUMBER
);
