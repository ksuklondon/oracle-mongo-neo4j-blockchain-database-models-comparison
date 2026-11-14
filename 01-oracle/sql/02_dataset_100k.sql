-- =====================================================================
-- 02_dataset_100k.sql  -  generating and analysing 100,000 rows
-- Measured on my laptop: INSERT of 100k rows 0.28 s, aggregations ~0.01 s.
-- =====================================================================
SET TIMING ON

-- E1. Table
CREATE TABLE dane_100k (
    id        NUMBER PRIMARY KEY,
    nazwa     VARCHAR2(50),
    kategoria VARCHAR2(1),
    wartosc   NUMBER
);

-- E2. 100,000 rows in one statement (row generator CONNECT BY LEVEL)
--     wartosc grows by 37 (mod 10000), kategoria cycles B, C, D, E, A
INSERT INTO dane_100k (id, nazwa, wartosc, kategoria)
SELECT LEVEL,
       'Rekord ' || LEVEL,
       MOD(LEVEL * 37, 10000),
       CASE MOD(LEVEL, 5)
           WHEN 0 THEN 'A'
           WHEN 1 THEN 'B'
           WHEN 2 THEN 'C'
           WHEN 3 THEN 'D'
           ELSE 'E'
       END
FROM   dual
CONNECT BY LEVEL <= 100000;

COMMIT;

-- E3-E4. Control + preview
SELECT COUNT(*) FROM dane_100k;                                 -- 100000
SELECT * FROM dane_100k ORDER BY id FETCH FIRST 10 ROWS ONLY;

-- F1. Filtering
SELECT COUNT(*) FROM dane_100k WHERE wartosc > 9000;            -- 9990
SELECT COUNT(*) FROM dane_100k WHERE wartosc < 100;             -- 1000

-- F2. Top / bottom 10
SELECT id, nazwa, wartosc FROM dane_100k ORDER BY wartosc DESC FETCH FIRST 10 ROWS ONLY;
SELECT id, nazwa, wartosc FROM dane_100k ORDER BY wartosc ASC  FETCH FIRST 10 ROWS ONLY;

-- F3. Aggregates: 100000 | 0 | 9999 | 4999.5 | 499950000
SELECT COUNT(*), MIN(wartosc), MAX(wartosc), AVG(wartosc), SUM(wartosc)
FROM   dane_100k;

-- F4. Per category: 20,000 rows each, averages from 4997.5 (A) to 5001.5 (C)
SELECT kategoria, COUNT(*) AS liczba, AVG(wartosc) AS srednia,
       MIN(wartosc) AS minimum, MAX(wartosc) AS maksimum
FROM   dane_100k
GROUP  BY kategoria
ORDER  BY kategoria;

-- F5. HAVING on a count
SELECT kategoria, COUNT(*) AS liczba
FROM   dane_100k
GROUP  BY kategoria
HAVING COUNT(*) > 19000;

-- J. Final task: categories with average value above 5000 -> C (5001.5), E (5000.5)
SELECT kategoria, AVG(wartosc) AS srednia
FROM   dane_100k
GROUP  BY kategoria
HAVING AVG(wartosc) > 5000
ORDER  BY kategoria;
