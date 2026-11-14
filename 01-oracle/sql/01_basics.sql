-- =====================================================================
-- 01_basics.sql  -  SQL basics on the lab dataset (tables studenci, przedmioty)
-- Run as user bd_lab in FREEPDB1 (SQL*Plus or SQL Developer).
-- The two tables come from the data archive provided by the instructor.
-- =====================================================================

-- C1. Whole table + row count
SELECT * FROM studenci;
SELECT COUNT(*) AS liczba_studentow FROM studenci;

-- C2. Filtering with WHERE
SELECT imie, nazwisko, kierunek
FROM   studenci
WHERE  kierunek = 'Informatyka';

-- C3. Sorting
SELECT imie, nazwisko, kierunek FROM studenci ORDER BY nazwisko, imie;
SELECT imie, nazwisko, kierunek FROM studenci ORDER BY nazwisko DESC, imie DESC;

-- C4. Grouping
SELECT kierunek, COUNT(*) AS liczba
FROM   studenci
GROUP  BY kierunek;

-- C5. HAVING filters whole groups (after GROUP BY), WHERE filters rows (before it)
SELECT kierunek, COUNT(*) AS liczba
FROM   studenci
GROUP  BY kierunek
HAVING COUNT(*) >= 1;

-- D. JOIN: students with the courses of their field of study
SELECT s.imie, s.nazwisko, s.kierunek, p.nazwa AS przedmiot
FROM   studenci s
JOIN   przedmioty p ON p.kierunek = s.kierunek;
