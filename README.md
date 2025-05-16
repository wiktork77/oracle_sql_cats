# 🐱 Oracle Database Project — Cats

## Project Goal  
The goal of this project was to design a simple relational database representing the world of cats in Oracle. Based on this database, advanced SQL queries and medium-complexity PL/SQL blocks were implemented. The project covers the most essential elements of Oracle Database and the PL/SQL language.

## Project Description  
This project was developed as part of the **Database Programming** course at Wrocław University of Science and Technology.  
Three task sets were completed, including advanced SQL queries and intermediate PL/SQL programming.

## Task Sets  
The repository includes both English and original Polish versions of the task sets:  
- **Task Set 1**  
  - 📄 [English version](task_lists/English/L1-english.pdf)  
  - 📄 [Polish version](task_lists/Polish/L1-polish.pdf)  
- **Task Set 2**  
  - 📄 [English version](task_lists/English/L2-english.pdf)  
  - 📄 [Polish version](task_lists/Polish/L2-polish.pdf)  
- **Task Set 3**  
  - 📄 [English version](task_lists/English/L3-english.pdf)  
  - 📄 [Polish version](task_lists/Polish/L3-polish.pdf)  

## Solution Overview  

### Task Set 1  
#### 📄 [L1_basic_sql_queries.sql](L1_basic_sql_queries.sql)
- Database, user, and tablespace creation (`CREATE PLUGGABLE DATABASE`, `CREATE TABLESPACE`, `CREATE USER IDENTIFIED BY...`, `ALTER USER`, `ALTER SESSION`)  
- Table definitions (DDL): `CREATE`, `DROP`, `ALTER`, `CONSTRAINT`, `CHECK`, `PRIMARY KEY`, `FOREIGN KEY`  
- Table population (DML): `INSERT`, `INSERT ALL`, `COMMIT`  
- Data retrieval: `SELECT`, `WHERE`, `FROM`, `ORDER BY`, `ROWNUM`  
- Date operations: `EXTRACT(... FROM)`, `NLS_DATE_FORMAT`, `INTERVAL`, `NEXT_DAY`, `LAST_DAY`, `ADD_MONTHS`  
- Conditional logic in `SELECT`: `DECODE`, `CASE`  
- Grouping operations: `GROUP BY`, `HAVING`, aggregate functions  
- Hierarchical queries: `CONNECT BY (PRIOR)`, `START WITH`, `CONNECT_BY_IS_LEAF`, pseudocolumn `LEVEL`  
- Oracle functions: `NVL`, `REGEXP_REPLACE`, `RPAD`, `LPAD`  

### Task Set 2  
#### 📄 [L2_advanced_sql_queries.sql](L2_advanced_sql_queries.sql)
- Table joins: `INNER JOIN`, `NATURAL JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`  
- Pivot tables: `PIVOT`  
- Subqueries: independent and correlated  
- Advanced aggregate functions: `COUNT(DISTINCT ...)`, differences between `COUNT(attribute)` and `COUNT(*)`, `SUM(DECODE(...))`  
- Set operators: `UNION`, `UNION ALL`, `INTERSECT`, `MINUS`, and distinctions between `UNION` and `UNION ALL`  
- Analytical and window functions: `OVER`, `DENSE_RANK`, `RANK`, `ROW_NUMBER`, `PARTITION BY`, `ORDER BY`, `ROWS`, `RANGE`  
- Use of Common Table Expressions (CTE)  
- Views: `CREATE OR REPLACE VIEW`  

### Task Set 3  
#### 📄 [L3_plsql_queries.sql](L3_plsql_queries.sql)
- Anonymous PL/SQL blocks: variables, conditional statements, loops  
- Cursors: `OPEN`, `FETCH`, `CLOSE`, `%NOTFOUND`, `REF CURSOR`, `FOR ... IN CURSOR`  
- Indexed tables: `TABLE OF ... INDEX BY`, `.EXISTS`, `.COUNT`  
- Exception handling: `EXCEPTION`, `RAISE`, `RAISE_APPLICATION_ERROR`  
- Bulk operations: `BULK COLLECT INTO`  
- Dynamic SQL: `EXECUTE IMMEDIATE`  
- Functions and procedures: `FUNCTION ... RETURN`, `PROCEDURE`, `EXEC`, `RETURN`  
- Packages: `PACKAGE`, `PACKAGE BODY`, trigger-support packages  
- Triggers: `BEFORE`, `INSTEAD OF`, `AFTER`, `COMPOUND TRIGGER`, mutating table workaround, `FOR EACH ROW`, `FOLLOWS`  
- Autonomous transactions: `PRAGMA AUTONOMOUS_TRANSACTION`  

## 🖥️ Environment  
The database was set up using **Oracle 21c Express Edition** (version 21.3.0.0.0).  
All solutions were tested and executed on a **pluggable database** created specifically for this version.

To run the scripts:

- Use **Oracle SQL Developer** or any compatible IDE.
- Ensure that required **permissions** and **tablespaces** are properly configured.
- Scripts are compatible with Oracle 21c XE and are expected to run without modification in a clean setup.
