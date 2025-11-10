-- analyzer.sql
-- PL/SQL block demonstrating RECORD, associative array, nested table, VARRAY, and GOTO

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
  -- record type for employee
  TYPE employee_rec_t IS RECORD (
    emp_id      employees.emp_id%TYPE,
    first_name  employees.first_name%TYPE,
    last_name   employees.last_name%TYPE,
    dept        employees.dept%TYPE
  );
  emp_rec employee_rec_t;

  -- nested table type for project ids
  TYPE proj_id_table_t IS TABLE OF projects.proj_id%TYPE;

  -- associative array mapping emp_id -> proj_id_table_t
  TYPE emp_proj_map_t IS TABLE OF proj_id_table_t INDEX BY PLS_INTEGER;
  emp_proj_map emp_proj_map_t;

  -- nested table for overloaded employees
  TYPE emp_list_t IS TABLE OF NUMBER;
  overloaded_emps emp_list_t := emp_list_t();

  -- varray for top 3 busiest employees
  TYPE top3_varray_t IS VARRAY(3) OF NUMBER;
  top3 top3_varray_t := top3_varray_t();

  v_total_hours NUMBER;
  CURSOR c_emp IS SELECT emp_id, first_name, last_name, dept FROM employees ORDER BY emp_id;
  CURSOR c_assignments(p_emp_id NUMBER) IS
    SELECT proj_id, hours_per_week FROM assignments WHERE emp_id = p_emp_id;

  -- for ranking busiest employees
  TYPE emp_hour_rec IS RECORD (emp_id NUMBER, hours NUMBER);
  TYPE emp_hour_table_t IS TABLE OF emp_hour_rec INDEX BY PLS_INTEGER;
  emp_hours emp_hour_table_t;
  emp_hours_count PLS_INTEGER := 0;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting Employee Project Assignment Analyzer');

  FOR r IN c_emp LOOP
    emp_rec.emp_id := r.emp_id;
    emp_rec.first_name := r.first_name;
    emp_rec.last_name := r.last_name;
    emp_rec.dept := r.dept;

    -- initialize nested table for this employee
    emp_proj_map(emp_rec.emp_id) := proj_id_table_t();

    v_total_hours := 0;
    FOR a IN c_assignments(emp_rec.emp_id) LOOP
      emp_proj_map(emp_rec.emp_id).EXTEND;
      emp_proj_map(emp_rec.emp_id)(emp_proj_map(emp_rec.emp_id).COUNT) := a.proj_id;
      v_total_hours := v_total_hours + a.hours_per_week;
    END LOOP;

    emp_hours_count := emp_hours_count + 1;
    emp_hours(emp_hours_count).emp_id := emp_rec.emp_id;
    emp_hours(emp_hours_count).hours := v_total_hours;

    -- If employee has no assignments, skip checks using GOTO (demo purpose)
    IF emp_proj_map(emp_rec.emp_id).COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Employee ' || emp_rec.emp_id || ' (' || emp_rec.first_name || ') has no assignments.');
      GOTO skip_checks;
    END IF;

    IF v_total_hours > 60 THEN
      overloaded_emps.EXTEND;
      overloaded_emps(overloaded_emps.COUNT) := emp_rec.emp_id;
    END IF;

    <<skip_checks>>
    NULL;
  END LOOP;

  -- naive sort to find top3 busiest
  IF emp_hours_count > 0 THEN
    FOR i IN 1..emp_hours_count LOOP
      FOR j IN i+1..emp_hours_count LOOP
        IF emp_hours(j).hours > emp_hours(i).hours THEN
          DECLARE tmp emp_hour_rec;
          tmp := emp_hours(i);
          emp_hours(i) := emp_hours(j);
          emp_hours(j) := tmp;
        END IF;
      END LOOP;
    END LOOP;

    FOR i IN 1..LEAST(3, emp_hours_count) LOOP
      top3.EXTEND;
      top3(top3.COUNT) := emp_hours(i).emp_id;
    END LOOP;
  END IF;

  -- Output results
  DBMS_OUTPUT.PUT_LINE('--- Overloaded employees (>60 hours/week) ---');
  IF overloaded_emps.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('None');
  ELSE
    FOR i IN 1..overloaded_emps.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('EmpID: ' || overloaded_emps(i));
    END LOOP;
  END IF;

  DBMS_OUTPUT.PUT_LINE('--- Top 3 busiest employees ---');
  IF top3.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('None');
  ELSE
    FOR i IN 1..top3.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('Rank ' || i || ' -> EmpID: ' || top3(i));
      IF emp_proj_map.EXISTS(top3(i)) THEN
        DBMS_OUTPUT.PUT('Projects: ');
        FOR j IN 1..emp_proj_map(top3(i)).COUNT LOOP
          DBMS_OUTPUT.PUT(emp_proj_map(top3(i))(j) || CASE WHEN j < emp_proj_map(top3(i)).COUNT THEN ', ' ELSE CHR(10) END);
        END LOOP;
      END IF;
    END LOOP;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unhandled error: ' || SQLERRM);
    RAISE;
END;
/
