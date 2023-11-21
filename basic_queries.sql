ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';


SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA"
FROM Wrogowie_kocurow
WHERE EXTRACT(Year FROM data_incydentu) = 2009;


SELECT imie, funkcja, w_stadku_od "Z NAMI OD"
FROM Kocury
WHERE w_stadku_od BETWEEN TO_DATE('2005-09-1') AND TO_DATE('2007-07-31')
AND plec = 'D';


SELECT imie_wroga "WROG", gatunek, stopien_wrogosci "STOPIEN WROGOSCI"
FROM Wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;


SELECT imie || ' zwany ' || pseudo || ' (fun. ' || funkcja || ') lowi myszki w bandzie ' || nr_bandy || ' od ' || w_stadku_od "WSZYSTKO O KOCURACH"
FROM Kocury
WHERE plec = 'M'
ORDER BY w_stadku_od DESC;


SELECT pseudo, REGEXP_REPLACE(
    REGEXP_REPLACE(pseudo, 'A', '#', 1, 1), 'L', '%', 1, 1     -- string, pattern, replace_str, where_to_start( 1 = start), which_occurrence
) "Po wymianie A na # oraz L na %"
FROM Kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';


SELECT imie, w_stadku_od "W stadku",FLOOR(przydzial_myszy*(10/11)) "zjadal",ADD_MONTHS(w_stadku_od, 6) "podwyzka", przydzial_myszy
FROM Kocury
WHERE MONTHS_BETWEEN(sysdate, w_stadku_od) / 12 > 14
AND EXTRACT(Month FROM w_stadku_od) BETWEEN 3 AND 9;


SELECT imie, NVL(przydzial_myszy, 0)*3 "MYSZY KWARTALNIE", NVL(myszy_extra, 0)*3 "KWARTALNE DODATKI"
FROM Kocury
WHERE NVL(przydzial_myszy, 0) > 2*NVL(myszy_extra, 0) AND przydzial_myszy >= 55
ORDER BY NVL(przydzial_myszy, 0)*3 DESC;


SELECT imie, DECODE(SIGN(NVL(przydzial_myszy, 0)*12 + NVL(myszy_extra, 0)*12 - 660), -1, 'Ponizej 660',
                                                                                0, 'Limit',
                                                                                TO_CHAR(NVL(przydzial_myszy, 0)*12 + NVL(myszy_extra, 0)*12)
)  "Zjada rocznie"
FROM Kocury
ORDER BY imie;


SELECT pseudo, w_stadku_od "W STADKU",
CASE
    WHEN EXTRACT(Day FROM w_stadku_od) <= 15 AND NEXT_DAY(LAST_DAY(TO_DATE('2023-10-24')) - INTERVAL '7' day, 3) >= TO_DATE('2023-10-24')
        THEN TO_CHAR(
            NEXT_DAY(
                LAST_DAY(TO_DATE('2023-10-24')) - 7, 'ŒRODA')
                )
    WHEN EXTRACT(Day FROM w_stadku_od) > 15
        THEN TO_CHAR(
            NEXT_DAY(LAST_DAY(
                trunc(
                    ADD_MONTHS(TO_DATE('2023-10-24'), 1),'MM'
                    )
                ) - INTERVAL '7' day, 3
            )
        )
    ELSE TO_CHAR(
            NEXT_DAY(LAST_DAY(
                trunc(
                    ADD_MONTHS(TO_DATE('2023-10-24'), 1),'MM'
                    )
                ) - INTERVAL '7' day, 3
            )
        )
END "WYPLATA"
FROM Kocury
ORDER BY w_stadku_od;


SELECT pseudo, w_stadku_od "W STADKU",
CASE
    WHEN EXTRACT(Day FROM w_stadku_od) <= 15 AND NEXT_DAY(LAST_DAY(TO_DATE('2023-10-26')) - INTERVAL '7' day, 3) >= TO_DATE('2023-10-26')
        THEN TO_CHAR(
            NEXT_DAY(
                LAST_DAY(TO_DATE('2023-10-26')) - INTERVAL '7' day, 3)
                )
    WHEN EXTRACT(Day FROM w_stadku_od) > 15
        THEN TO_CHAR(
            NEXT_DAY(LAST_DAY(
                trunc(
                    ADD_MONTHS(TO_DATE('2023-10-26'), 1),'MM'
                    )
                ) - INTERVAL '7' day, 3
            )
        )
    ELSE TO_CHAR(
            NEXT_DAY(LAST_DAY(
                trunc(
                    ADD_MONTHS(TO_DATE('2023-10-26'), 1),'MM'
                    )
                ) - INTERVAL '7' day, 3
            )
        )
END "WYPLATA"
FROM Kocury
ORDER BY w_stadku_od;


SELECT pseudo || ' - ' ||
CASE
    WHEN COUNT(pseudo) > 1 THEN 'Nieunikalny'
    ELSE 'Unikalny'
END "Unikalnosc atr. PSEUDO"
FROM Kocury
GROUP BY pseudo;


SELECT szef || ' - ' ||
CASE
    WHEN COUNT(*) > 1 THEN 'Nieunikalny'
    ELSE 'Unikalny'
END "Unikalnosc atr. SZEF"
FROM Kocury
GROUP BY szef
HAVING szef IS NOT NULL;


SELECT pseudo, COUNT(pseudo) "Liczba wrogow"
FROM Wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(pseudo) >= 2;


SELECT 'Liczba kotow = ' " ", COUNT(funkcja) " ", ' lowi jako ' "   ", funkcja "    ", 'i zjada max.' "     ",
MAX(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "      ", 'myszy miesiecznie' "          "
FROM Kocury
WHERE plec != 'M'
GROUP BY funkcja
HAVING funkcja != 'SZEFUNIO' AND AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) > 50;


SELECT nr_bandy "Nr bandy", plec "Plec", MIN(NVL(przydzial_myszy, 0)) "Minimalny przydzial"
FROM Kocury
GROUP BY nr_bandy, plec;



SELECT LEVEL "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM Kocury
WHERE plec = 'M'
CONNECT BY PRIOR pseudo = szef
START WITH funkcja = 'BANDZIOR'


SELECT LPAD(LEVEL - 1, (LEVEL - 1)* 4 + 1, '===>') || '                ' || imie "Hierarchia",
CASE
    WHEN szef IS NOT NULL THEN szef
    ELSE 'Sam sobie panem'
END "Pseudo szefa", funkcja
FROM Kocury
WHERE NVL(myszy_extra,0) > 0
CONNECT BY PRIOR pseudo = szef
START WITH funkcja = 'SZEFUNIO';


SELECT LPAD(' ', (LEVEL - 1)*4, ' ') || pseudo "Droga sluzbowa"
FROM kocury
CONNECT BY PRIOR szef = pseudo
START WITH (MONTHS_BETWEEN(TO_DATE('2023-06-29'), w_stadku_od) / 12) > 14 AND plec = 'M' AND myszy_extra IS NULL;






