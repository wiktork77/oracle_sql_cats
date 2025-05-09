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
       RPAD(
       REPLACE(
        SYS_CONNECT_BY_PATH(imie, ' '),
        TO_CHAR(' ' || CONNECT_BY_ROOT(imie) || ' '),
        ''
       ), 20, 'X') "Imiona kolejnych szefow"
FROM Kocury
WHERE CONNECT_BY_ISLEAF = 1
START WITH funkcja IN ('KOT', 'MILUSIA')
CONNECT BY PRIOR szef = pseudo;