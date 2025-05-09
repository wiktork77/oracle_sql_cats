-- SET DATE FORMAT 

ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy-MM-dd';


-- TASK 1

SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA"
FROM Wrogowie_kocurow
WHERE EXTRACT(YEAR FROM data_incydentu) = 2009;


-- TASK 2

SELECT imie, funkcja, w_stadku_od "Z NAMI OD"
FROM Kocury
WHERE plec = 'D'
AND w_stadku_od BETWEEN TO_DATE('2005-09-01', 'YYYY-MM-DD') AND TO_DATE('2007-07-31', 'YYYY-MM-DD');


-- TASK 3

SELECT imie_wroga "WROG", gatunek, stopien_wrogosci "STOPIEN WROGOSCI"
FROM wrogowie
WHERE lapowka IS NULL
ORDER BY "STOPIEN WROGOSCI";


-- TASK 4

SELECT imie || ' zwany ' || pseudo || ' (fun. ' || funkcja || ') lowi myszki w bandzie ' || nr_bandy || ' od ' || w_stadku_od "WSZYSTKO O KOCURACH"
FROM Kocury
WHERE plec='M'
ORDER BY w_stadku_od DESC, pseudo;


-- TASK 5

SELECT pseudo, REGEXP_REPLACE(REGEXP_REPLACE(pseudo, 'A', '#', 1, 1), 'L', '%', 1, 1) "Po wymianie A na # oraz L na %"
FROM Kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';


-- TASK 6

SELECT imie, w_stadku_od "W stadku", ROUND(przydzial_myszy*(10/11)) "Zjadal", w_stadku_od + INTERVAL '6' MONTH "Podwyzka", przydzial_myszy "Zjada"
FROM Kocury
WHERE ABS(MONTHS_BETWEEN(SYSDATE, w_stadku_od))/12 > 14
AND EXTRACT(MONTH FROM w_stadku_od) BETWEEN 3 AND 9
ORDER BY "Zjada" DESC;


-- TASK 7

SELECT imie, NVL(przydzial_myszy, 0)*3 "MYSZY KWARTALNIE", NVL(myszy_extra, 0)*3 "KWARTALNE DODATKI"
FROM Kocury
WHERE NVL(przydzial_myszy, 0) > 2*NVL(myszy_extra, 0) AND NVL(przydzial_myszy, 0) >= 55
ORDER BY "MYSZY KWARTALNIE" DESC;


-- TASK 8

SELECT imie,
CASE SIGN(12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) - 660)
    WHEN 1 THEN TO_CHAR(12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)))
    WHEN -1 THEN 'Ponizej 660'
    ELSE 'Limit'
END "Zjada rocznie"
FROM Kocury
ORDER BY imie;


-- TASK 9

-- dates to try: '2023-10-24' and '2023-10-26'
DEFINE problem9_date = TO_DATE('2023-10-24', 'YYYY-MM-DD');

SELECT pseudo, w_stadku_od "W STADKU",
DECODE(
    SIGN(EXTRACT(DAY FROM w_stadku_OD) - 15),
    1,
    NEXT_DAY(
        LAST_DAY(ADD_MONTHS(&problem9_date, 1)) - INTERVAL '7' DAY,
        3 -- 'LAST WEDNESDAY'
    ),
    DECODE(
        SIGN(
        NEXT_DAY(
            LAST_DAY(&problem9_date) - INTERVAL '7' DAY,
            3 -- 'LAST WEDNESDAY'
        ) - &problem9_date),
        -1,
        NEXT_DAY(
            LAST_DAY(ADD_MONTHS(&problem9_date, 1)) - INTERVAL '7' DAY,
            3 -- 'LAST WEDNESDAY'
        ),
        NEXT_DAY(
            LAST_DAY(&problem9_date) - INTERVAL '7' DAY,
            3 -- 'LAST WEDNESDAY'
        )
    )
) "WYPLATA"
FROM Kocury
ORDER BY EXTRACT(DAY FROM w_stadku_OD);


-- TASK 10

SELECT pseudo || ' - ' || DECODE(COUNT(*), 1, 'Unikalny', 'nieunikalny') "Unikalnosc atr. PSEUDO"
FROM Kocury
GROUP BY pseudo;

SELECT szef || ' - ' || DECODE(COUNT(*), 1, 'Unikalny', 'nieunikalny') "Unikalnosc atr. SZEF"
FROM Kocury
WHERE szef IS NOT NULL
GROUP BY szef;


-- TASK 11

SELECT pseudo "Pseudonim", COUNT(*) "Liczba wrogow"
FROM Wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(*) >= 2;


-- TASK 12

SELECT 'Liczba kotow = ' || COUNT(*) || ' lowy jako ' || funkcja || ' i zjada max. ' || MAX(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) || ' myszy miesiecznie' " "
FROM Kocury
WHERE plec != 'M' AND funkcja != 'SZEFUNIO'
GROUP BY funkcja
HAVING AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) > 50
ORDER BY COUNT(*);


-- TASK 13

SELECT nr_bandy "Nr bandy", plec "Plec", MIN(przydzial_myszy) "Minimalny przydzial"
FROM Kocury
GROUP BY nr_bandy, plec;


-- TASK 14

SELECT level "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM Kocury
WHERE plec = 'M'
START WITH funkcja = 'BANDZIOR'
CONNECT BY PRIOR pseudo = szef;


-- TASK 15

SELECT LPAD(level - 1, 4*(level - 1) + 1, '===>') || LPAD(imie, 16 + LENGTH(pseudo), ' ') "Hierarchia",
DECODE(szef, NULL, 'Sam sobie panem', szef) "Pseudo szefa",
funkcja "Funkcja"
FROM Kocury
WHERE myszy_extra IS NOT NULL
START WITH szef IS NULL
CONNECT BY PRIOR pseudo = szef;


-- TASK 16

SELECT LPAD(pseudo, 4*(level - 1) + LENGTH(pseudo), ' ') "Droga sluzbowa"
FROM Kocury
START WITH myszy_extra IS NULL AND ABS(MONTHS_BETWEEN(TO_DATE('2023-06-29', 'YYYY-MM-DD'), w_stadku_od)) / 12 > 14 AND plec = 'M'
CONNECT BY PRIOR szef = pseudo;


