SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy-MM-dd';


-- TASK 17

SELECT K.pseudo, NVL(K.przydzial_myszy, 0) "przydzial myszy", B.nazwa
FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE B.teren IN ('POLE', 'CALOSC') AND
      NVL(K.przydzial_myszy, 0) > 50
ORDER BY "przydzial myszy" DESC;


-- TASK 18

SELECT k1.imie, k1.w_stadku_od "POLUJE OD"
FROM Kocury K1 INNER JOIN Kocury K2 ON K2.imie = 'JACEK' AND K1.w_stadku_od < K2.w_stadku_od
ORDER BY "POLUJE OD" DESC;


-- TASK 19a

SELECT K1.imie, K1.funkcja, NVL(K2.imie, ' ') "szef 1", NVL(K3.imie, ' ') "szef 2", NVL(K4.imie, ' ') "szef 3"
FROM Kocury K1 LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
               LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
               LEFT JOIN Kocury K4 ON K3.szef = K4.pseudo
WHERE K1.funkcja IN ('KOT', 'MILUSIA');


-- TASK 19b

SELECT NVL(im, ' ') imie, "Funkcja", NVL(s1, ' ') "Szef 1", NVL(s2, ' ') "Szef 2", NVL(s3, ' ') "Szef 3"
FROM (
    SELECT CONNECT_BY_ROOT imie im, CONNECT_BY_ROOT funkcja "Funkcja", imie p, level l 
    FROM Kocury
    START WITH funkcja IN ('KOT', 'MILUSIA')
    CONNECT BY PRIOR szef = pseudo
) PIVOT (
    MIN(p)
    FOR l
    IN (2 s1, 3 s2, 4 s3)
);


-- TASK 19c
-- CONNECT_BY_ISLEAF !! - essential tool here

SELECT CONNECT_BY_ROOT(imie) AS Imie, ' | ' " ",
       CONNECT_BY_ROOT(funkcja) AS Funkcja,
       REPLACE(
        SYS_CONNECT_BY_PATH(imie, ' '),
        TO_CHAR(' ' || CONNECT_BY_ROOT(imie) || ' '),
        ''
       ) "Imiona kolejnych szefow"
FROM Kocury
WHERE CONNECT_BY_ISLEAF = 1
START WITH funkcja IN ('KOT', 'MILUSIA')
CONNECT BY PRIOR szef = pseudo;


-- TASK 20

SELECT K.imie "Imie kotki", B.nazwa "Nazwa bandy", W.imie_wroga "Imie wroga", W.stopien_wrogosci "Ocena wroga", WK.data_incydentu "Data inc."
FROM Kocury K INNER JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
              INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
              INNER JOIN Wrogowie W ON WK.imie_wroga = W.imie_wroga
WHERE K.plec = 'D' AND
      WK.data_incydentu >= TO_DATE('2007-01-01', 'YYYY-MM-DD')
ORDER BY "Imie kotki", "Imie wroga";


-- TASK 21

-- version a) - include all bands
SELECT nazwa "Nazwa bandy", COUNT(DISTINCT K.imie) "Koty z wrogami"
FROM Kocury K INNER JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
              RIGHT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
GROUP BY nazwa;

-- version b) - include only bands that have members
SELECT nazwa "Nazwa bandy", COUNT(DISTINCT pseudo) "Koty z wrogami"
FROM Kocury NATURAL JOIN Wrogowie_kocurow
            NATURAL JOIN Bandy
GROUP BY nazwa;


-- TASK 22
-- MIN() can be used here because pseudo is unique, hence there is a 1-1 relation between pseudo and function
SELECT MIN(funkcja) "Funkcja", pseudo "Pseudonim kota", COUNT(*) "Liczba wrogow"
FROM Kocury NATURAL JOIN Wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(*) >= 2;


-- TASK 23

-- version a) - with set operator (because the task tells so)
SELECT imie, 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "ROCZNA DAWKA", 'powyzej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL AND 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) > 864
UNION ALL
SELECT imie, 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), '864'
FROM Kocury
WHERE myszy_extra IS NOT NULL AND 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) = 864
UNION ALL
SELECT imie, 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 'ponizej 864'
FROM Kocury
WHERE myszy_extra IS NOT NULL AND 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) < 864
ORDER BY 2 DESC;

-- (normal) version b), without set operators
SELECT imie, 12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "ROCZNA DAWKA",
DECODE(
    SIGN(864 -  12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))),
    0,
    '864',
    -1,
    'powyzej 864',
    'ponizej 864'
) "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL
ORDER BY 2 DESC;


-- TASK 24

-- version a) (no subqueries and set [UNION etc] operators)
SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
WHERE K.pseudo IS NULL;

-- version b) (set operators)
SELECT nr_bandy, nazwa, teren
FROM Bandy
MINUS
SELECT nr_bandy, nazwa, teren
FROM Bandy NATURAL JOIN Kocury;


-- TASK 25

SELECT imie, funkcja, NVL(przydzial_myszy, 0) "PRZYDZIAL MYSZY"
FROM Kocury
WHERE NVL(przydzial_myszy, 0) >= ALL(
    SELECT 3*NVL(przydzial_myszy, 0)
    FROM Kocury NATURAL JOIN Bandy
    WHERE funkcja = 'MILUSIA' AND
    (teren = 'SAD' OR teren = 'CALOSC')
);


-- TASK 26


-- SOLUTION WITH RANK
WITH sr AS
(
    SELECT funkcja, AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) srednia,
    RANK() OVER(ORDER BY AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) rank_min,
    RANK() OVER(ORDER BY AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) DESC) rank_max
    FROM Kocury
    WHERE funkcja != 'SZEFUNIO'
    GROUP BY funkcja
)
SELECT funkcja, srednia
FROM sr
WHERE rank_min = 1 OR rank_max = 1;


-- SOLUTION WITH SUBQUERIES

WITH sr AS
(
    SELECT funkcja, AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) srednia
    FROM Kocury
    WHERE funkcja != 'SZEFUNIO'
    GROUP BY funkcja
)
SELECT *
FROM sr
WHERE srednia IN
(
    (SELECT MAX(srednia) FROM sr),
    (SELECT MIN(srednia) FROM sr)
);
