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


-- TASK 27

-- correlated subquery solution
SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) zjada
FROM Kocury K
WHERE &miejsce >= (
    SELECT COUNT(DISTINCT NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
    FROM Kocury
    WHERE NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) >= NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)
)
ORDER BY zjada DESC;


-- ROWNUM pseudocolumn solution
WITH mouse_rank AS
(
    SELECT DISTINCT NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) przydzial
    FROM Kocury
    ORDER BY przydzial DESC
), cat_rank AS (
    SELECT przydzial, ROWNUM rnk
    FROM mouse_rank
)
SELECT K.pseudo, CR.przydzial "ZJADA"
FROM Kocury K INNER JOIN cat_rank CR ON NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) = CR.przydzial
WHERE CR.rnk <= &miejsce;


-- SELF JOIN SOLUTION
SELECT K1.pseudo, MIN(NVL(K1.przydzial_myszy, 0) + NVL(K1.myszy_extra, 0)) przydzial
FROM Kocury K1 INNER JOIN Kocury K2 ON NVL(K1.przydzial_myszy, 0) + NVL(K1.myszy_extra, 0) <= NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)
GROUP BY K1.pseudo
HAVING COUNT(DISTINCT NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)) <= &miejsce
ORDER BY 2 DESC;


-- ANALTYIC FUNCTION SOLUTION
WITH cat_rank AS (
    SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) przydzial, DENSE_RANK() OVER(ORDER BY NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) DESC) rnk
    FROM Kocury
)
SELECT * FROM cat_rank
WHERE rnk <= &miejsce;


-- TASK 28

-- solution with everything spread out
WITH lata AS (
    SELECT TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) rok, COUNT(*) ile
    FROM Kocury
    GROUP BY EXTRACT(YEAR FROM w_stadku_od)
), srednia AS (
    SELECT 'srednia', ROUND(AVG(ile), 7) sr
    FROM lata
), mniej AS (
    SELECT rok, ile, DENSE_RANK() OVER(ORDER BY ABS(ile - (SELECT sr FROM srednia))) miejsce
    FROM lata
    WHERE ile < (SELECT sr FROM srednia)
), wiecej AS (
    SELECT rok, ile, DENSE_RANK() OVER(ORDER BY ABS(ile - (SELECT sr FROM srednia))) miejsce
    FROM lata
    WHERE ile > (SELECT sr FROM srednia)
)
SELECT rok, ile "LICZBA WSTAPIEN" FROM mniej
WHERE miejsce = 1
UNION
SELECT * FROM srednia
UNION
SELECT rok, ile FROM wiecej
WHERE miejsce = 1;


-- TASK 29

-- SOLUTION WITH JOINS ONLY
SELECT K.pseudo, MIN(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) zjada, MIN(K.nr_bandy) "NR BANDY",
AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)) "SREDNIA BANDY"
FROM Kocury K INNER JOIN Kocury K2 ON K.nr_bandy = K2.nr_bandy
WHERE K.plec = 'M'
GROUP BY K.pseudo
HAVING MIN(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) <= AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0))
ORDER BY 3 DESC;


-- SOLUTION WITH 1 JOIN AND 1 SUBQUERY (CTE for readability) IN FROM CLAUSE 
WITH sr_bandy AS (
    SELECT nr_bandy, AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) sr
    FROM Kocury
    GROUP BY nr_bandy
)
SELECT K.imie, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) zjada, K.nr_bandy "NR BANDY", SB.sr "SREDNIA BANDY"
FROM sr_bandy SB INNER JOIN Kocury K ON SB.nr_bandy = K.nr_bandy
WHERE K.plec = 'M' AND NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) <= SB.sr
ORDER BY 3 DESC;


-- SOLUTION WITH NO JOINS BUT SUBQUERY IN SELECT AND WHERE
SELECT imie, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) zjada, K.nr_bandy "NR BANDY", (
    SELECT AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
    FROM Kocury
    WHERE nr_bandy = K.nr_bandy
) "SREDNIA BANDY"
FROM Kocury K
WHERE K.plec = 'M' AND NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) <= (
    SELECT AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
    FROM Kocury
    WHERE nr_bandy = K.nr_bandy
)
ORDER BY 3 DESC;


-- TASK 30


-- SOLUTION WITH ANALYTIC FUNCTIONS (MUCH CLEANER AND BETTER)

SELECT K.imie, w_stadku_od ||
CASE
    WHEN w_stadku_od = MIN(w_stadku_od) OVER(PARTITION BY K.nr_bandy) THEN ' <--- NAJSTARSZY STAZEM W BANDZIE ' || B.nazwa
    WHEN w_stadku_od = MAX(w_stadku_od) OVER(PARTITION BY K.nr_bandy) THEN ' <--- NAJMLODSZY STAZEM W BANDZIE ' || B.nazwa
    ELSE ''
END "WSTAPIL DO STADA"
FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
ORDER BY 1;


-- SOLUTION WITH SET OPERATORS (because of the instruction requires it)
WITH weterani AS (
    SELECT K.imie, TO_CHAR(K.w_stadku_od) od, B.nazwa
    FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE K.w_stadku_od = (
        SELECT MIN(w_stadku_od)
        FROM Kocury
        WHERE nr_bandy = K.nr_bandy
    )
), nowi AS (
    SELECT K.imie, TO_CHAR(K.w_stadku_od) od, B.nazwa
    FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE K.w_stadku_od = (
        SELECT MAX(w_stadku_od)
        FROM Kocury
        WHERE nr_bandy = K.nr_bandy
    )
), wybrani AS (
    SELECT imie, od || ' <--- NAJMLODSZY STAZEM W BANDZIE ' || nazwa
    FROM nowi
    UNION ALL
    SELECT imie, od || ' <--- NAJSTARSZY STAZEM W BANDZIE ' || nazwa
    FROM weterani
), inni AS (
    SELECT imie, TO_CHAR(w_stadku_od) od
    FROM Kocury
    MINUS
    SELECT imie, od
    FROM nowi
    MINUS
    SELECT imie, od
    FROM weterani
)
SELECT *
FROM inni
UNION ALL
SELECT *
FROM wybrani
ORDER BY 1;


-- TASK 31

CREATE OR REPLACE VIEW widok_bandy AS
SELECT B.nazwa, AVG(NVL(K.przydzial_myszy, 0)) sre_spoz, MAX(NVL(K.przydzial_myszy, 0)) max_spoz, MIN(NVL(K.przydzial_myszy, 0)) min_spoz,
       COUNT(*) koty, COUNT(K.myszy_extra) koty_z_dod 
FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
GROUP BY B.nazwa;


SELECT K.pseudo "PSEUDONIM", K.imie, K.funkcja, NVL(K.przydzial_myszy, 0) zjada, 'OD ' || WB.min_spoz || ' DO ' || WB.max_spoz "GRANICE SPOZYCIA",
K.w_stadku_od "LOWI OD"
FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
              INNER JOIN widok_bandy WB ON B.nazwa = WB.nazwa
WHERE pseudo = '&pseudonim';


-- TASK 32

WITH wybrani AS (
    SELECT pseudo, plec, nazwa, NVL(przydzial_myszy, 0) myszy, NVL(myszy_extra, 0) m_extra, DENSE_RANK() OVER(PARTITION BY nazwa ORDER BY w_stadku_od) ranking
    FROM Kocury NATURAL JOIN Bandy
    WHERE nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
)
SELECT pseudo, plec, myszy, m_extra
FROM wybrani W
WHERE W.ranking <=3; 

-- updating

UPDATE Kocury k
SET (przydzial_myszy, myszy_extra) = (
    SELECT 
        CASE WHEN k.plec = 'D' THEN NVL(przydzial_myszy, 0) + 0.1*mn.min_przy ELSE NVL(przydzial_myszy, 0) + 10 END,
        NVL(myszy_extra, 0) + 0.15*sb.sr_mysz_extra
    FROM (
        SELECT nr_bandy, AVG(NVL(myszy_extra, 0)) AS sr_mysz_extra
        FROM Kocury NATURAL JOIN Bandy
        WHERE nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
        GROUP BY nr_bandy
    ) sb INNER JOIN (
        SELECT MIN(NVL(przydzial_myszy, 0)) min_przy
        FROM Kocury
    ) mn ON 1=1
    WHERE sb.nr_bandy = k.nr_bandy
)
WHERE pseudo IN (
    WITH wybrani AS (
        SELECT pseudo, plec, nazwa, NVL(przydzial_myszy, 0) AS myszy, 
               NVL(myszy_extra, 0) AS m_extra, 
               DENSE_RANK() OVER(PARTITION BY nazwa ORDER BY w_stadku_od) AS ranking
        FROM Kocury NATURAL JOIN Bandy
        WHERE nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
    )
    SELECT pseudo
    FROM wybrani
    WHERE ranking <= 3
);


ROLLBACK;


-- TASK 33

-- SOLUTION WITH SUM AND DECODE
-- CTE is essenctial here to keep the (odd) sorting of the base result
WITH base AS (
    SELECT DECODE(plec, 'D', nazwa, ' ') "NAZWA BANDY",
    DECODE(plec, 'D', 'Kotka', 'Kocor') plec,
    TO_CHAR(COUNT(*)) ile,
    SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) szefunio,
    SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) bandzior,
    SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) lowczy,
    SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) lapacz,
    SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) kot,
    SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) milusia,
    SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) dzielczy,
    SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma
    FROM Kocury NATURAL JOIN Bandy
    GROUP BY nazwa, plec
    ORDER BY nazwa, plec DESC
)
SELECT *
FROM base
UNION ALL
SELECT
'ZJADA RAZEM',
' ',
' ',
SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) szefunio,
SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) bandzior,
SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) lowczy,
SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) lapacz,
SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) kot,
SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) milusia,
SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) dzielczy,
SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma
FROM Kocury;


-- SOLUTION WITH PIVOT TABLE and 2 aggregations in pivot

WITH base AS (
    SELECT
    DECODE(plec, 'D', nazwa, ' ') "NAZWA BANDY",
    DECODE(plec, 'D', 'Kotka', 'Kocor') plec,
    TO_CHAR(f1_ct + f2_ct + f3_ct + f4_ct + f5_ct + f6_ct + f7_ct) ile,
    NVL(f1_st, 0) szefunio, NVL(f2_st, 0) bandzior, NVL(f3_st, 0) lowczy, NVL(f4_st, 0) lapacz, NVL(f5_st, 0) kot, NVL(f6_st, 0) milusia, NVL(f7_st, 0) dzielczy,
    NVL(f1_st, 0) + NVL(f2_st, 0) + NVL(f3_st, 0) + NVL(f4_st, 0) + NVL(f5_st, 0) + NVL(f6_st, 0) + NVL(f7_st, 0) suma
    FROM (
        SELECT nazwa, plec, funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) total
        FROM Kocury NATURAL JOIN Bandy
    ) PIVOT (
        SUM(total) st, COUNT(*) ct -- option 1 to count how many cats there are in the group
        FOR funkcja
        IN ('SZEFUNIO' f1, 'BANDZIOR' f2, 'LOWCZY' f3, 'LAPACZ' f4, 'KOT' f5, 'MILUSIA' f6, 'DZIELCZY' f7)
    )
    ORDER BY nazwa, plec DESC
)
SELECT *
FROM base
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ', NVL(f1, 0) szefunio, NVL(f2, 0) bandzior, NVL(f3, 0) lowczy, NVL(f4, 0) lapacz, NVL(f5, 0) kot, NVL(f6, 0) milusia, NVL(f7, 0) dzielczy,
NVL(f1, 0) + NVL(f2, 0) + NVL(f3, 0) + NVL(f4, 0) + NVL(f5, 0) + NVL(f6, 0) + NVL(f7, 0) suma
FROM (
    SELECT funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) total
    FROM Kocury
) PIVOT (
    SUM(total)
    FOR funkcja
    IN ('SZEFUNIO' f1, 'BANDZIOR' f2, 'LOWCZY' f3, 'LAPACZ' f4, 'KOT' f5, 'MILUSIA' f6, 'DZIELCZY' f7)
);




-- SOLUTION WITH PIVOT TABLE and 1 aggregation in pivot but using a join
WITH ile_w_bandach_plci AS (
    SELECT nazwa, plec, COUNT(*) ile
    FROM Kocury NATURAL JOIN Bandy
    GROUP BY nazwa, plec
), base AS (
    SELECT
    DECODE(plec, 'D', nazwa, ' ') "NAZWA BANDY",
    DECODE(plec, 'D', 'Kotka', 'Kocor') plec,
    TO_CHAR(ile) ile,
    NVL(f1, 0) szefunio, NVL(f2, 0) bandzior, NVL(f3, 0) lowczy, NVL(f4, 0) lapacz, NVL(f5, 0) kot, NVL(f6, 0) milusia, NVL(f7, 0) dzielczy,
    NVL(f1, 0) + NVL(f2, 0) + NVL(f3, 0) + NVL(f4, 0) + NVL(f5, 0) + NVL(f6, 0) + NVL(f7, 0) suma
    FROM (
        SELECT nazwa, plec, funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) total
        FROM Kocury NATURAL JOIN Bandy
    ) PIVOT (
        SUM(total)
        FOR funkcja
        IN ('SZEFUNIO' f1, 'BANDZIOR' f2, 'LOWCZY' f3, 'LAPACZ' f4, 'KOT' f5, 'MILUSIA' f6, 'DZIELCZY' f7)
    ) kcr NATURAL JOIN ile_w_bandach_plci IWBP -- ON kcr.nazwa = IWBP.nazwa AND kcr.plec = IWBP.plec
    ORDER BY nazwa, plec DESC
)
SELECT *
FROM base
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ', NVL(f1, 0) szefunio, NVL(f2, 0) bandzior, NVL(f3, 0) lowczy, NVL(f4, 0) lapacz, NVL(f5, 0) kot, NVL(f6, 0) milusia, NVL(f7, 0) dzielczy,
NVL(f1, 0) + NVL(f2, 0) + NVL(f3, 0) + NVL(f4, 0) + NVL(f5, 0) + NVL(f6, 0) + NVL(f7, 0) suma
FROM (
    SELECT funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) total
    FROM Kocury
) PIVOT (
    SUM(total)
    FOR funkcja
    IN ('SZEFUNIO' f1, 'BANDZIOR' f2, 'LOWCZY' f3, 'LAPACZ' f4, 'KOT' f5, 'MILUSIA' f6, 'DZIELCZY' f7)
);
