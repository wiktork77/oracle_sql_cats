ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';


SELECT pseudo "POLUJE W POLU", przydzial_myszy "PRZYDZIAL MYSZY", nazwa "BANDA"
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE teren IN ('POLE', 'CALOSC') AND przydzial_myszy > 50
ORDER BY "PRZYDZIAL MYSZY" DESC;


SELECT K1.imie, K1.w_stadku_od "POLUJE OD"
FROM Kocury K1 JOIN Kocury K2 ON K2.imie = 'JACEK'
WHERE K1.w_stadku_od < K2.w_stadku_od
ORDER BY K1.w_stadku_od DESC;


SELECT K.imie "Imie", K.funkcja "Funkcja", K2.imie "Szef 1", K3.imie "Szef 2", K4.imie "Szef 3"
FROM Kocury K LEFT JOIN Kocury K2 ON K.szef=K2.pseudo
              LEFT JOIN Kocury K3 ON K2.szef=K3.pseudo
              LEFT JOIN Kocury K4 ON K3.szef=K4.pseudo
WHERE K.funkcja IN ('KOT', 'MILUSIA');


WITH hierarchia AS
(
    SELECT CONNECT_BY_ROOT imie Imie, CONNECT_BY_ROOT funkcja "Funkcja", LEVEL poziom, imie Imiesz
    FROM Kocury
    CONNECT BY PRIOR szef=pseudo
    START WITH funkcja IN ('KOT', 'MILUSIA')
)
SELECT *
FROM hierarchia
PIVOT
(
    MAX(Imiesz)
    FOR poziom
    IN (2 "Szef 1", 3 "Szef 2", 4 "Szef 3")
);



SELECT CONNECT_BY_ROOT imie "Imie",
       CONNECT_BY_ROOT funkcja "Funkcja",
       SYS_CONNECT_BY_PATH(imie, ' | ') "Imiona kolejnych szefow"
FROM Kocury
-- wybieramy tylko te wezly, ktore sa koncowka sciezki, sciezka zostaje zachowana dzieki sys_connect_by_path, pomimo tego, ze inne wezly zostaly wyfiltrowane
WHERE szef IS NULL
CONNECT BY PRIOR szef = pseudo
START WITH funkcja IN ('KOT','MILUSIA');


SELECT imie "Imie kotki", nazwa "Nazwa bandy", WK.imie_wroga "Imie wroga", W.stopien_wrogosci "Ocena wroga", WK.data_incydentu "Data inc."
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
              JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
              JOIN Wrogowie W ON WK.imie_wroga = W.imie_wroga
WHERE K.plec='D' AND WK.data_incydentu > TO_DATE('2007-01-01');


WITH zestawienie_kotow_band AS
(
    SELECT DISTINCT K.pseudo, B.nazwa n_bandy
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
)
SELECT n_bandy "Nazwa bandy", COUNT(*) "Koty z wrogami"
FROM zestawienie_kotow_band
GROUP BY n_bandy;


SELECT funkcja "Funkcja", K.pseudo "Pseudonim kota", liczba "Liczba wrogow"
FROM 
(
    SELECT pseudo, COUNT(*) liczba
    FROM Wrogowie_kocurow
    GROUP BY pseudo
) ZEST JOIN Kocury K ON ZEST.pseudo = K.pseudo
WHERE liczba > 1;


SELECT imie, (NVL(przydzial_myszy, 0) + myszy_extra)*12 "DAWKA ROCZNA", 'Powyzej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL AND (NVL(przydzial_myszy, 0) + myszy_extra)*12 > 864
UNION ALL
SELECT imie, (NVL(przydzial_myszy, 0) + myszy_extra)*12 "DAWKA ROCZNA", '864' "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL AND (NVL(przydzial_myszy, 0) + myszy_extra)*12 = 864
UNION ALL
SELECT imie, (NVL(przydzial_myszy, 0) + myszy_extra)*12 "DAWKA ROCZNA", 'Ponizej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL AND (NVL(przydzial_myszy, 0) + myszy_extra)*12 < 864
ORDER BY "DAWKA ROCZNA" DESC;


SELECT B.nr_bandy, nazwa, teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nr_bandy, nazwa, teren
HAVING COUNT(K.pseudo) = 0; 


SELECT nr_bandy, nazwa, teren
FROM Bandy
MINUS
SELECT DISTINCT B.nr_bandy, nazwa, teren
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy;


SELECT imie, funkcja, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy >= ALL(
    SELECT 3*przydzial_myszy
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE funkcja='MILUSIA' AND teren IN ('SAD', 'CALOSC')
);


WITH ktoIle AS
(
    SELECT funkcja, ROUND(AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) ile
    FROM Kocury
    WHERE funkcja != 'SZEFUNIO'
    GROUP BY funkcja
)
SELECT funkcja, ile "Srednio najw. i najmn. myszy"
FROM ktoIle
WHERE ile IN ((SELECT MIN(ile) FROM ktoIle), (SELECT MAX(ile) FROM ktoIle));


SELECT K.pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) "ZJADA"
FROM Kocury K
WHERE &n >= 
(
    SELECT COUNT(DISTINCT(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)))
    FROM Kocury K2
    WHERE NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0) >= NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)
)
ORDER BY "ZJADA" DESC;


SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) zjada
FROM Kocury
WHERE NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) IN
(
    SELECT zjada FROM
    (
        SELECT DISTINCT(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) zjada
        FROM Kocury
        ORDER BY zjada DESC
    )
    WHERE ROWNUM <= &n
);

-- helper
SELECT K.pseudo, MAX(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) zjada, COUNT(DISTINCT NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0))
FROM Kocury K JOIN Kocury K2 ON NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) <= NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)
GROUP BY K.pseudo;


SELECT K.pseudo, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) zjada
FROM Kocury K JOIN Kocury K2 ON NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) <= NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)
GROUP BY K.pseudo,  NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)
-- ile kotów !lepszych (pod wzgledem wartosci zjadanych mysz) + 1 (sam kot) = miejsce w rankingu
HAVING COUNT(DISTINCT NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)) <= &n;



WITH ranking AS
(
    SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) zjada,
    (
        DENSE_RANK()
        OVER(ORDER BY NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) DESC)
    ) miejsce
    FROM Kocury
)
SELECT pseudo, zjada FROM ranking
WHERE miejsce <= &n;



WITH sredniaWstapien AS
(
    SELECT AVG(COUNT(EXTRACT(Year FROM w_stadku_od))) srednia
    FROM Kocury
    GROUP BY EXTRACT(Year FROM w_stadku_od)
),
wstapieniaLatami AS
(
    SELECT TO_CHAR(EXTRACT(Year FROM w_stadku_od)) rok, COUNT(EXTRACT(Year FROM w_stadku_od)) ile_wstapien
    FROM Kocury
    GROUP BY EXTRACT(Year FROM w_stadku_od)
),
poSredniej AS
(
    SELECT rok, ile_wstapien
    FROM wstapieniaLatami
    WHERE ile_wstapien >= (SELECT srednia FROM sredniaWstapien)
),
przedSrednia AS
(
    SELECT rok, ile_wstapien
    FROM wstapieniaLatami
    WHERE ile_wstapien <= (SELECT srednia FROM sredniaWstapien)
)
SELECT rok, ile_wstapien
FROM wstapieniaLatami
WHERE ile_wstapien IN ((SELECT MAX(ile_wstapien) FROM przedSrednia), (SELECT MIN(ile_wstapien) FROM poSredniej))
UNION ALL
SELECT 'Srednia', srednia
FROM sredniaWstapien
ORDER BY 2;

-- helper
--SELECT K.imie, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) zjada, K.nr_bandy "NR BANDY", NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0) zjada2
--FROM Kocury K JOIN Kocury K2 ON K.nr_bandy = K2.nr_bandy
--WHERE K.plec='M'
--ORDER BY K.imie;


-- ³¹czymy ka¿dego kota z ka¿dym z jego bandy
SELECT K.imie, MIN(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) "zjada", MIN(K.nr_bandy) "NR BANDY", AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0)) "SREDNIA BANDY"
FROM Kocury K JOIN Kocury K2 ON K.nr_bandy = K2.nr_bandy
WHERE K.plec='M'
-- grupujemy ze wzgledu na imie pierwszego kota
GROUP BY K.imie
-- srednia w bandzie na podstawie wszystkich kotow polaczonych do 1 kota (patrz pomocnicze)
HAVING MIN(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0))  <= AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0))
ORDER BY "SREDNIA BANDY";

SELECT K2.imie, NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0) zjada, K2.nr_bandy "NR BANDY", K.sr "SREDNIA BANDY"
FROM (
    SELECT AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) sr, nr_bandy
    FROM Kocury
    GROUP BY nr_bandy
) K JOIN Kocury K2 ON K.nr_bandy=K2.nr_bandy
WHERE NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0) <= K.sr
AND K2.plec='M'
ORDER BY K2.nr_bandy DESC;


SELECT K.imie, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) zjada, K.nr_bandy,
(
    SELECT AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0))
    FROM Kocury K2
    WHERE K.nr_bandy = K2.nr_bandy
) sr_bandy
FROM Kocury K
WHERE NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) <=
(
    SELECT AVG(NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra, 0))
    FROM Kocury K2
    WHERE K.nr_bandy = K2.nr_bandy
)
AND K.plec='M'
ORDER BY K.nr_bandy;


WITH najstarsi AS
(
    SELECT K.imie, K.w_stadku_od || ' <--- NAJSTARSZY STAZEM W BANDZIE ' || B.nazwa wst
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE K.w_stadku_od = (
        SELECT MIN(K2.w_stadku_od) w_stadku
        FROM Kocury K2 JOIN Bandy B on K2.nr_bandy = B.nr_bandy
        WHERE K2.nr_bandy = K.nr_bandy
        GROUP BY B.nazwa
    )
),
najmlodsi AS
(
    SELECT K.imie, K.w_stadku_od || ' <--- NAJMLODSZY STAZEM W BANDZIE ' || B.nazwa wst
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE K.w_stadku_od = (
        SELECT MAX(K2.w_stadku_od) w_stadku
        FROM Kocury K2 JOIN Bandy B on K2.nr_bandy = B.nr_bandy
        WHERE K2.nr_bandy = K.nr_bandy
        GROUP BY B.nazwa
    )
),
reszta AS
(
    SELECT imie, w_stadku_od || ' ' wst
    FROM Kocury WHERE imie IN
    (
        SELECT imie FROM Kocury
        MINUS
        SELECT imie FROM najmlodsi
        MINUS
        SELECT imie FROM najstarsi
    )

)
SELECT imie, wst  FROM najstarsi
UNION ALL
SELECT imie, wst FROM najmlodsi
UNION ALL
SELECT imie, wst FROM reszta
ORDER BY imie;


DROP VIEW Bandy_Info;

CREATE VIEW Bandy_Info
AS
SELECT nazwa, AVG(NVL(K.przydzial_myszy, 0)) SRE_SPOZ,
              MAX(NVL(K.przydzial_myszy, 0)) MAX_SPOZ,
              MIN(NVL(K.przydzial_myszy, 0)) MIN_SPOZ,
              COUNT(K.pseudo) KOTY,
              COUNT(K.myszy_extra) KOTY_Z_DOD
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY nazwa;

SELECT * FROM Bandy_Info;

SELECT K.pseudo, K.imie, K.funkcja, K.przydzial_myszy ZJADA, 'OD ' || BI.MIN_SPOZ || ' DO ' || BI.MAX_SPOZ "GRANICE SPOZYCIA", K.w_stadku_od "LOWI OD"
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy JOIN Bandy_info BI ON B.nazwa = BI.nazwa
WHERE K.pseudo='&pseudonim_kota';



WITH rankingZBand AS
(
    SELECT K.pseudo, K.plec, NVL(K.przydzial_myszy, 0) myszy, NVL(K.myszy_extra, 0) extra,
    (
        RANK()
        OVER(PARTITION BY K.nr_bandy ORDER BY K.w_stadku_od)
    ) msc
    FROM Kocury K JOIN Bandy B ON K.nr_bandy=B.nr_bandy
    WHERE B.nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
)
SELECT pseudo, plec, myszy "Myszy przed podw.", extra "Extra przed podw."
FROM rankingZBand
WHERE msc <= 3;

UPDATE Kocury K
SET przydzial_myszy=CASE plec
                        WHEN 'D' THEN przydzial_myszy + (SELECT MIN(przydzial_myszy) FROM Kocury)*0.1
                        WHEN 'M' THEN przydzial_myszy + 10
                    END,
    myszy_extra = NVL(myszy_extra, 0) + (
        SELECT AVG(NVL(K2.myszy_extra, 0)) sr
        FROM Kocury K2
        WHERE K2.nr_bandy=K.nr_bandy
        GROUP BY K2.nr_bandy
    )*0.15
WHERE pseudo IN
(
    SELECT pseudo
    FROM 
    (
        SELECT K.pseudo, K.plec, NVL(K.przydzial_myszy, 0) myszy, NVL(K.myszy_extra, 0) extra,
        (
            RANK()
            OVER(PARTITION BY K.nr_bandy ORDER BY K.w_stadku_od)
        ) msc
        FROM Kocury K JOIN Bandy B ON K.nr_bandy=B.nr_bandy
        WHERE B.nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
    )
    WHERE msc <= 3
);

WITH rankingZBand AS
(
    SELECT K.pseudo, K.plec, NVL(K.przydzial_myszy, 0) myszy, NVL(K.myszy_extra, 0) extra,
    (
        RANK()
        OVER(PARTITION BY K.nr_bandy ORDER BY K.w_stadku_od)
    ) msc
    FROM Kocury K JOIN Bandy B ON K.nr_bandy=B.nr_bandy
    WHERE B.nazwa IN ('CZARNI RYCERZE', 'LACIACI MYSLIWI')
)
SELECT pseudo, plec, myszy "Myszy po podw.", extra "Extra po podw."
FROM rankingZBand
WHERE msc <= 3;
rollback;



WITH podzialRole AS
(
    SELECT B.nazwa,
    DECODE(K.plec, 'D', 'Kotka', 'Kocur') plec,
    TO_CHAR(COUNT(K.pseudo)) ile,
    SUM(DECODE(K.funkcja,'SZEFUNIO', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) szefunio,
    SUM(DECODE(K.funkcja, 'BANDZIOR', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) bandzior,
    SUM(DECODE(K.funkcja, 'LOWCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) lowczy,
    SUM(DECODE(K.funkcja, 'LAPACZ', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) lapacz,
    SUM(DECODE(K.funkcja, 'KOT', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) kot,
    SUM(DECODE(K.funkcja, 'MILUSIA', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) milusia,
    SUM(DECODE(K.funkcja, 'DZIELCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) dzielczy,
    SUM(NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0)) suma
    FROM Kocury K JOIN Bandy B on K.nr_bandy = B.nr_bandy
    GROUP BY B.nazwa, K.plec
    ORDER BY B.nazwa, K.plec DESC
)
SELECT * FROM podzialRole
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ',
SUM(DECODE(K.funkcja,'SZEFUNIO', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) szefunio,
SUM(DECODE(K.funkcja, 'BANDZIOR', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) bandzior,
SUM(DECODE(K.funkcja, 'LOWCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) lowczy,
SUM(DECODE(K.funkcja, 'LAPACZ', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) lapacz,
SUM(DECODE(K.funkcja, 'KOT', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) kot,
SUM(DECODE(K.funkcja, 'MILUSIA', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) milusia,
SUM(DECODE(K.funkcja, 'DZIELCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0), 0)) dzielczy,
SUM(NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra, 0)) suma
FROM Kocury K JOIN Bandy B on K.nr_bandy = B.nr_bandy;



WITH podzial AS
(
    SELECT B.nazwa, DECODE(K.plec, 'D', 'Kotka', 'Kocor') plec, K.funkcja, NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) przydzial
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy 
),
baza AS
(
    SELECT *
    FROM podzial
    PIVOT
    (
        SUM(przydzial)
        FOR funkcja
        IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy)
    )
    ORDER BY 1, 2
),
dopelnienie AS
(
    SELECT B.nazwa, DECODE(K.plec, 'D', 'Kotka', 'Kocor') plec,  COUNT(K.plec) ile, SUM(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) suma
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    GROUP BY B.nazwa, K.plec
),
zestawienie AS
(
    SELECT B.nazwa, B.plec, D.ile, B.szefunio, B.bandzior, B.lowczy, B.lapacz, B.kot, B.milusia, B.dzielczy, D.suma
    FROM baza B JOIN dopelnienie D ON B.nazwa = D.nazwa AND B.plec = D.plec
    ORDER BY 1, 2 DESC
)
SELECT DECODE(plec, 'Kotka', nazwa, ' ') "NAZWA BANDY",
       plec, TO_CHAR(ile) ile,
       NVL(szefunio, 0) szefunio,
       NVL(bandzior, 0) bandzior,
       NVL(lowczy, 0) lowczy,
       NVL(lapacz, 0) lapacz,
       NVL(kot, 0) kot,
       NVL(milusia, 0) milusia,
       NVL(dzielczy, 0) dzielczy,
       suma
       FROM zestawienie
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ',
SUM(DECODE(K.funkcja,'SZEFUNIO', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) szefunio,
SUM(DECODE(K.funkcja, 'BANDZIOR', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) bandzior,
SUM(DECODE(K.funkcja, 'LOWCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) lowczy,
SUM(DECODE(K.funkcja, 'LAPACZ', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) lapacz,
SUM(DECODE(K.funkcja, 'KOT', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) kot,
SUM(DECODE(K.funkcja, 'MILUSIA', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) milusia,
SUM(DECODE(K.funkcja, 'DZIELCZY', NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0),0)) dzielczy,
SUM(NVL(K.przydzial_myszy,0)+NVL(K.myszy_extra,0)) suma
FROM Kocury K JOIN Bandy B on K.nr_bandy = B.nr_bandy;






















--------------------

SELECT K.pseudo, K.przydzial_myszy, B.nazwa "Banda"
FROM Kocury K join Bandy B ON K.nr_bandy = B.nr_bandy
WHERE K.przydzial_myszy > 50 AND B.teren IN ('POLE', 'CALOSC');


SELECT K1.imie, K1.w_stadku_od
FROM Kocury K1 JOIN Kocury K2 ON K2.imie = 'JACEK'
WHERE K1.w_stadku_od < K2.w_stadku_od
ORDER BY K1.w_stadku_od DESC;


SELECT K.imie, B.nazwa, W.imie_wroga, W.stopien_wrogosci, WK.data_incydentu
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo JOIN Wrogowie W ON WK.imie_wroga = W.imie_wroga
WHERE K.plec = 'D' AND WK.data_incydentu > TO_DATE('2007-01-01')
ORDER BY K.imie;


SELECT B.nazwa, COUNT(DISTINCT K.pseudo)
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy JOIN wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY B.nazwa;


SELECT MIN(K.funkcja), K.pseudo, COUNT(K.pseudo)
FROM Kocury K JOIN wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY K.pseudo
HAVING COUNT(K.pseudo) > 1;


SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM Kocury
WHERE (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 > 864 AND myszy_extra IS NOT NULL
UNION ALL
SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 "DAWKA ROCZNA", '864' "DAWKA"
FROM Kocury
WHERE (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 = 864 AND myszy_extra IS NOT NULL
UNION ALL
SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM Kocury
WHERE (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12 < 864 AND myszy_extra IS NOT NULL;


SELECT B.nr_bandy, nazwa, teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
WHERE K.nr_bandy IS NULL;


SELECT nr_bandy, nazwa, teren
FROM Bandy
MINUS
SELECT B.nr_bandy, nazwa, teren
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy;

SELECT K.imie, K.funkcja, K.przydzial_myszy
FROM Kocury K
WHERE K.przydzial_myszy >= ALL(
    SELECT K.przydzial_myszy*3
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE K.funkcja = 'MILUSIA' AND B.teren IN ('SAD', 'CALOSC')
);


WITH srednio_funkcje AS
(
    SELECT funkcja, ROUND(AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) sr
    FROM Kocury
    WHERE funkcja != 'SZEFUNIO'
    GROUP BY funkcja
)
SELECT funkcja, ROUND(AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)))
FROM Kocury
GROUP BY funkcja
HAVING ROUND(AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) IN ((SELECT MIN(sr) FROM srednio_funkcje), (SELECT MAX(sr) FROM srednio_funkcje));




SELECT K.pseudo, K.nr_bandy
FROM Kocury K LEFT JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
WHERE K.plec = 'M' AND WK.pseudo IS NULL AND K.nr_bandy IN
(
    SELECT nr_bandy
    FROM Kocury 
    WHERE plec = 'M'
    GROUP BY nr_bandy
    HAVING AVG(przydzial_myszy) > 55
);


SELECT imie, nr_bandy
FROM Kocury
WHERE funkcja = (SELECT funkcja FROM Kocury WHERE pseudo='LOLA')
AND pseudo != 'LOLA';

SELECT K.imie, K.nr_bandy
FROM Kocury K JOIN Kocury K2 ON K2.pseudo = 'LOLA'
WHERE K.funkcja = K2.funkcja
AND K.pseudo != 'LOLA';

SELECT pseudo, przydzial_myszy, nr_bandy
FROM Kocury
WHERE przydzial_myszy IN (
SELECT MIN(K.przydzial_myszy) minimalnie
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
GROUP BY K.nr_bandy
);


SELECT pseudo, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy > ANY (
    SELECT przydzial_myszy
    FROM Kocury
    WHERE nr_bandy=4
);

SELECT B.nr_bandy
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nr_bandy
HAVING AVG(K.przydzial_myszy) > (SELECT AVG(przydzial_myszy) FROM Kocury WHERE nr_bandy=3);

SELECT pseudo, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy > ALL (
    SELECT K.przydzial_myszy
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    WHERE B.nazwa = 'LACIACI MYSLIWI'
);


SELECT K.pseudo, K.przydzial_myszy
FROM Kocury K
WHERE K.nr_bandy IN (SELECT nr_bandy FROM Bandy WHERE nazwa IN ('BIALI LOWCY','LACIACI MYSLIWI'))
AND K.przydzial_myszy > (SELECT AVG(przydzial_myszy) FROM Kocury);


SELECT pseudo, (SELECT AVG(K2.przydzial_myszy) FROM Kocury K2 WHERE K2.nr_bandy = K.nr_bandy) sr
FROM Kocury K
WHERE plec = 'M';


SELECT K.plec, MAX(K.przydzial_myszy)
FROM Kocury K JOIN Funkcje F ON K.funkcja = F.funkcja
WHERE K.przydzial_myszy >= 1.1*F.min_myszy
AND K.funkcja IN (SELECT funkcja FROM Kocury WHERE pseudo IN ('BOLEK', 'LASKA'))
GROUP BY K.plec;


SELECT MIN(K.funkcja)
FROM Kocury K
GROUP BY K.pseudo;



SELECT K.funkcja, B.nazwa, SUM(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)) calk_przydzial
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE B.nazwa IN ('BIALI LOWCY', 'CZARNI RYCERZE')
AND K.funkcja != 'SZEFUNIO'
GROUP BY K.funkcja, B.nazwa;


