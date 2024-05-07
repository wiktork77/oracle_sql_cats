SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
---------------------------------------------------------------------------- ZAD 47 ===========================================================================
-- DROP TYPE KocuryO
CREATE OR REPLACE TYPE KocuryO AS OBJECT
(
    imie VARCHAR(15),
    plec VARCHAR(1),
    pseudo VARCHAR(15),
    funkcja VARCHAR(10),
    szef REF KocuryO,
    w_stadku_od DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2),
    MEMBER FUNCTION calkowity_przydzial RETURN NUMBER,
    MEMBER FUNCTION dane RETURN VARCHAR2
);

-- DROP TYPE BODY KocuryO
CREATE OR REPLACE TYPE BODY KocuryO AS
MEMBER FUNCTION calkowity_przydzial RETURN NUMBER IS
BEGIN
    RETURN NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0);
END;

MEMBER FUNCTION dane RETURN VARCHAR2 IS
BEGIN
    RETURN imie||'(ps: '||pseudo||', plec: '||plec||') pelni funkcje '||funkcja||' w bandzie nr.'||nr_bandy||' i zjada '||SELF.calkowity_przydzial()||' myszy miesiecznie.';
END;
END;

-- DROP TABLE KocuryT
CREATE TABLE KocuryT OF KocuryO
(
    imie CONSTRAINT kt_im_nn NOT NULL,
    plec CONSTRAINT kt_pl_ch CHECK(plec IN ('M', 'D')),
    pseudo CONSTRAINT kt_ps_pk PRIMARY KEY,
    funkcja CONSTRAINT kt_fu_fk REFERENCES Funkcje(funkcja),
    szef SCOPE IS KocuryT,
    w_stadku_od DEFAULT SYSDATE,
    nr_bandy CONSTRAINT kt_nb_fk REFERENCES Bandy(nr_bandy)
);

-- DROP TYPE PlebsO FORCE
CREATE OR REPLACE TYPE PlebsO AS OBJECT
(
    pseudo VARCHAR(15),
    kot REF KocuryO,
    MEMBER FUNCTION dane RETURN VARCHAR2
);

-- DROP TYPE BODY PlebsO
CREATE OR REPLACE TYPE BODY PlebsO AS
MEMBER FUNCTION dane RETURN VARCHAR2 IS
wladca KocuryO;
BEGIN
    SELECT DEREF(kot) INTO wladca FROM dual;
    RETURN pseudo||' (plebs) '|| 'jest sluga ' || wladca.dane();
END;
END;

-- DROP TABLE PlebsT
CREATE TABLE PlebsT OF PlebsO
(
    pseudo CONSTRAINT pt_ps_pk PRIMARY KEY,
    kot SCOPE IS KocuryT CONSTRAINT pt_kot_nodangling NOT NULL,
    CONSTRAINT pt_ps_fk FOREIGN KEY (pseudo) REFERENCES KocuryT(pseudo)
);

-- DROP TYPE ElitaO FORCE
CREATE OR REPLACE TYPE ElitaO AS OBJECT
(
    pseudo VARCHAR(15),
    kot REF KocuryO,
    sluga REF PlebsO,
    MEMBER FUNCTION kto_sluga RETURN REF PlebsO
);

-- DROP TYPE BODY ElitaO
CREATE OR REPLACE TYPE BODY ElitaO AS
MEMBER FUNCTION kto_sluga RETURN REF PlebsO IS
BEGIN
    RETURN sluga;
END;
END;

-- DROP TABLE ElitaT
CREATE TABLE ElitaT OF ElitaO
(
    pseudo CONSTRAINT et_ps_pk PRIMARY KEY,
    kot SCOPE IS KocuryT CONSTRAINT et_kot_nodangling NOT NULL,
    sluga SCOPE IS PlebsT
);

-- DROP TYPE KontoO FORCE
CREATE OR REPLACE TYPE KontoO AS OBJECT
(
    nr_myszy NUMBER(8),
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    kot REF ElitaO,
    MEMBER PROCEDURE usun_mysz(d DATE)
);


-- DROP TYPE BODY KontoO
CREATE OR REPLACE TYPE BODY KontoO AS
MEMBER PROCEDURE usun_mysz(d DATE) IS
BEGIN
    data_usuniecia := d;
END;
END;


-- DROP TABLE KontoT
CREATE TABLE KontoT OF KontoO
(
    nr_myszy CONSTRAINT kt_nm_pk PRIMARY KEY,
    data_wprowadzenia CONSTRAINT kt_dw_nn NOT NULL,
    kot SCOPE IS ElitaT CONSTRAINT kt_kot_nodangling NOT NULL,
    CONSTRAINT kt_du_ch CHECK(data_usuniecia > data_wprowadzenia)
);


-- DROP TYPE IncydentyO FORCE
CREATE OR REPLACE TYPE IncydentyO AS OBJECT
(
    pseudo VARCHAR(15),
    kot REF KocuryO,
    imie_wroga VARCHAR(15),
    data_incydentu DATE,
    opis_incydentu VARCHAR(50),
    MEMBER FUNCTION co_sie_stalo RETURN VARCHAR2
);


-- DROP TYPE BODY IncydentyO
CREATE OR REPLACE TYPE BODY IncydentyO AS
MEMBER FUNCTION co_sie_stalo RETURN VARCHAR2 IS
kotek_imie VARCHAR(15);
BEGIN
    SELECT DEREF(kot).imie INTO kotek_imie FROM dual;
    RETURN 'Incydent (dnia ' || data_incydentu || '): ' || kotek_imie || ' (ps. ' || pseudo || ') wraz z wrogiem ' || imie_wroga || '. Dosz³o do: ' || NVL(opis_incydentu, 'brak opisu');
END;
END;



-- DROP TABLE IncydentyT
CREATE TABLE IncydentyT OF IncydentyO
(
    CONSTRAINT it_psiw_pk PRIMARY KEY(pseudo, imie_wroga),
    kot SCOPE IS KocuryT CONSTRAINT it_kot_nodangling NOT NULL,
    pseudo CONSTRAINT it_ps_fk REFERENCES Kocury(pseudo),
    imie_wroga CONSTRAINT it_iw_fk REFERENCES Wrogowie(imie_wroga),
    data_incydentu CONSTRAINT it_di_nn NOT NULL
);


-- wypelnianie - koty
-- Aby dodac kota, ktory ma szefa, to jego szef juz musi istniec w tabeli KocuryT.
DECLARE
    CURSOR koty_poziomami IS
    SELECT *
    FROM Kocury
    CONNECT BY PRIOR pseudo = szef
    START WITH szef IS NULL
    ORDER BY LEVEL;
    szef_ref REF KocuryO;
BEGIN
    FOR k in koty_poziomami
    LOOP
        IF k.szef IS NULL THEN
            szef_ref := NULL;
        ELSE
            SELECT REF(KT) INTO szef_ref FROM KocuryT KT WHERE KT.pseudo = k.szef;
        END IF;
        INSERT INTO KocuryT VALUES(k.imie, k.plec, k.pseudo, k.funkcja, szef_ref, k.w_stadku_od, k.przydzial_myszy, k.myszy_extra, k.nr_bandy);
    END LOOP;
END;

-- wypelnianie - incydenty
DECLARE
CURSOR incydenty IS SELECT * FROM Wrogowie_kocurow;
kot_ref REF KocuryO;
BEGIN
    FOR i IN incydenty
    LOOP
        SELECT REF(KT) INTO kot_ref FROM KocuryT KT WHERE KT.pseudo = i.pseudo;
        INSERT INTO IncydentyT VALUES(i.pseudo, kot_ref, i.imie_wroga, i.data_incydentu, i.opis_incydentu);
    END LOOP;
END;


-- wypelnianie - plebs - nie maja myszy extra lub 0
DECLARE
CURSOR plebs_kursor IS SELECT pseudo FROM Kocury WHERE NVL(myszy_extra, 0) = 0;
kot_ref REF KocuryO;
BEGIN
FOR k IN plebs_kursor
LOOP
    SELECT REF(KT) INTO kot_ref FROM KocuryT KT WHERE KT.pseudo = k.pseudo;
    INSERT INTO PlebsT VALUES(k.pseudo, kot_ref);
END LOOP;
END;

-- wypelnianie - elita - maja myszy extra zasada przypisywania slugi - najmniejsza roznica we wstapieniu do stada

CREATE OR REPLACE FUNCTION get_plebs_for_elite(ps_elity Kocury.pseudo%TYPE) RETURN REF PlebsO IS
plebs REF PlebsO;
pseudo_pleb VARCHAR2(15);
BEGIN
    SELECT pseudo INTO pseudo_pleb FROM PlebsT P
    WHERE ABS(P.kot.w_stadku_od - (SELECT w_stadku_od FROM Kocury WHERE pseudo=ps_elity))
    = (SELECT MIN(ABS(PT.kot.w_stadku_od - (SELECT w_stadku_od FROM Kocury WHERE pseudo=ps_elity))) FROM PlebsT PT);
    SELECT REF(PT) INTO plebs FROM PlebsT PT WHERE PT.pseudo = pseudo_pleb;
    RETURN plebs;
END;

DECLARE
CURSOR elita_kursor IS SELECT pseudo FROM Kocury WHERE NVL(myszy_extra, 0) != 0;
sluga_ref REF PlebsO;
kot_ref REF KocuryO;
kot_obj PlebsO;
BEGIN
    FOR k IN elita_kursor
    LOOP
        SELECT REF(KT) INTO kot_ref FROM KocuryT KT WHERE KT.pseudo = k.pseudo;
        sluga_ref := get_plebs_for_elite(k.pseudo);
        SELECT DEREF(sluga_ref) INTO kot_obj FROM dual;
        dbms_output.put_line('elita: '||k.pseudo || ' -> ' || kot_obj.pseudo);
        INSERT INTO ElitaT VALUES(k.pseudo, kot_ref, sluga_ref);
    END LOOP;
END;

-- wypelnianie konta

DECLARE
CURSOR elita_kursor IS SELECT pseudo FROM ElitaT;
nr_myszy NUMBER;
kot_ref REF ElitaO;
BEGIN
    SELECT (COUNT(*) + 1) INTO nr_myszy FROM KontoT;
    FOR k IN elita_kursor
    LOOP
        SELECT REF(ET) INTO kot_ref FROM ElitaT ET WHERE k.pseudo = ET.pseudo;
        INSERT INTO KontoT VALUES(nr_myszy, SYSDATE, NULL, kot_ref);
        nr_myszy := nr_myszy + 1;
    END LOOP;
END;
--Rollback;

-- grupowanie
SELECT ET.sluga.pseudo "Sluga", COUNT(*) "Ile wladcow"
FROM ElitaT ET
GROUP BY ET.sluga.pseudo;

-- zlaczenie
SELECT KT.pseudo, COUNT(IT.kot) "Ile incydentow"
FROM KocuryT KT LEFT JOIN IncydentyT IT ON REF(KT) = IT.kot
GROUP BY KT.pseudo
ORDER BY "Ile incydentow" DESC;

-- podzapytanie
SELECT KT.pseudo, VALUE(KT).calkowity_przydzial() "przydzial"
FROM KocuryT KT WHERE VALUE(KT).calkowity_przydzial() > 
(
    SELECT AVG(KT.calkowity_przydzial())
    FROM KocuryT KT
);

-- zad 2.18
SELECT KT.imie, KT.w_stadku_od
FROM KocuryT KT JOIN KocuryT KTJ ON KTJ.imie = 'JACEK'
WHERE KT.w_stadku_od < KTJ.w_stadku_od
ORDER BY KT.w_stadku_od DESC;

-- ZAD 2.19A TUTAJ TE¯ TODO
SELECT KT.imie "Imie", KT.funkcja "Funkcja", KT.szef.imie "Szef1", KT.szef.szef.imie "Szef2", KT.szef.szef.szef.imie "Szef3"
FROM KocuryT KT;

-- ZAD 2.22


SELECT KT.funkcja "funkcja", KT.pseudo "Pseudonim kota", COUNT(IT.kot) "Liczba wrogow"
FROM KocuryT KT JOIN IncydentyT IT ON IT.kot = REF(KT)
HAVING COUNT(IT.kot) >= 2
GROUP BY KT.funkcja, KT.pseudo;



-- zad 3.35
DECLARE
    roczny_przydzial NUMBER;
    imie KocuryT.imie%TYPE;
    data_przystapienia KocuryT.w_stadku_od%TYPE;
    miesiac NUMBER;
BEGIN
    SELECT KT.calkowity_przydzial()*12, KT.imie, KT.w_stadku_od
    INTO roczny_przydzial, imie, data_przystapienia
    FROM KocuryT KT WHERE KT.pseudo=UPPER('&pseudo');
    miesiac:=EXTRACT(MONTH FROM data_przystapienia);
    CASE
        WHEN roczny_przydzial > 700 THEN dbms_output.put_line('calkowity roczny przydzial myszy > 700');
        WHEN imie LIKE '%A%' THEN dbms_output.put_line('Imie zawiera litere A');
        WHEN miesiac=5 THEN dbms_output.put_line('maj jest miesiacem przystapienia do stada');
        ELSE dbms_output.put_line('nie odpowiada kryteriom');
    END CASE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN dbms_output.put_line('Nie znaleziono kota o podanym pseudonimie!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM); 
END;


-- Zad 3.37

DECLARE
    CURSOR kursor_koty IS
    SELECT KT.pseudo, KT.calkowity_przydzial() calk
    FROM KocuryT KT
    ORDER BY calk DESC;
    nr_kota NUMBER := 0;
    sa_koty BOOLEAN:= false;
    BRAK_DANYCH EXCEPTION;
    ZA_MALO_DANYCH EXCEPTION;
BEGIN
    dbms_output.put_line('Nr  Pseudonim   Zjada');
    dbms_output.put_line('---------------------');
    FOR kot IN kursor_koty
    LOOP
        nr_kota := nr_kota + 1;
        dbms_output.put_line(nr_kota || '   ' || kot.pseudo || LPAD(kot.calk, 17-LENGTH(kot.pseudo), ' '));
        EXIT WHEN nr_kota = 5;
    END LOOP;
    IF (nr_kota = 0) THEN
        RAISE BRAK_DANYCH;
    END IF;
    IF (nr_kota < 5) THEN
        RAISE ZA_MALO_DANYCH;
    END IF;
EXCEPTION
    WHEN BRAK_DANYCH THEN dbms_output.put_line('Brak kotow!');
    WHEN ZA_MALO_DANYCH THEN dbms_output.put_line('Za malo kotow, aby wyswietlic top 5!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;


--=======================================================================ZAD 48==============================================================================


-- DROP TYPE KocuryO
CREATE OR REPLACE TYPE KocuryO AS OBJECT
(
    imie VARCHAR(15),
    plec VARCHAR(1),
    pseudo VARCHAR(15),
    funkcja VARCHAR(10),
    szef REF KocuryO,
    w_stadku_od DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2),
    MEMBER FUNCTION calkowity_przydzial RETURN NUMBER,
    MEMBER FUNCTION dane RETURN VARCHAR2
);



CREATE TABLE Plebs(
    pseudo VARCHAR2(15) CONSTRAINT pl_ps_pk PRIMARY KEY,
    CONSTRAINT pl_ps_fk FOREIGN KEY (pseudo) REFERENCES Kocury(pseudo)
);


CREATE TABLE Elita(
    pseudo VARCHAR(15) CONSTRAINT el_ps_pl PRIMARY KEY,
    sluga VARCHAR(15) REFERENCES Plebs(pseudo),
    CONSTRAINT el_ps_fk FOREIGN KEY(pseudo) REFERENCES Kocury(pseudo)
);


CREATE TABLE Konta(
    nr_myszy NUMBER(8) CONSTRAINT ko_nm_pk PRIMARY KEY,
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    kot VARCHAR(15) REFERENCES Elita(pseudo)
);


-- wypelnianie - plebs
DECLARE
CURSOR plebs_kursor IS SELECT pseudo FROM Kocury WHERE NVL(myszy_extra, 0) = 0;
BEGIN
FOR k IN plebs_kursor
LOOP
    INSERT INTO Plebs VALUES(k.pseudo);
END LOOP;
END;


-- wypelnianie - elita

CREATE OR REPLACE FUNCTION get_plebs_pseudo_for_elite(ps_elity Kocury.pseudo%TYPE) RETURN VARCHAR2 IS
pseudo_pleb VARCHAR2(15);
BEGIN
    SELECT pseudo INTO pseudo_pleb FROM PlebsT P
    WHERE ABS(P.kot.w_stadku_od - (SELECT w_stadku_od FROM Kocury WHERE pseudo=ps_elity))
    = (SELECT MIN(ABS(PT.kot.w_stadku_od - (SELECT w_stadku_od FROM Kocury WHERE pseudo=ps_elity))) FROM PlebsT PT);
    RETURN pseudo_pleb;
END;

DECLARE
CURSOR elita_kursor IS SELECT pseudo FROM Kocury WHERE NVL(myszy_extra, 0) != 0;
sluga_pseudo VARCHAR(15);
BEGIN
    FOR k IN elita_kursor
    LOOP
        sluga_pseudo := get_plebs_pseudo_for_elite(k.pseudo);
        INSERT INTO Elita VALUES(k.pseudo, sluga_pseudo);
    END LOOP;
END;

-- wypelnianie konta
DECLARE
CURSOR elita_kursor IS SELECT pseudo FROM ElitaT;
nr_myszy NUMBER;
BEGIN
    SELECT (COUNT(*) + 1) INTO nr_myszy FROM KontoT;
    FOR k IN elita_kursor
    LOOP
        INSERT INTO Konta VALUES(nr_myszy, SYSDATE, NULL, k.pseudo);
        nr_myszy := nr_myszy + 1;
    END LOOP;
END;

-- perspektywy
-- kocury
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/adobj/defining-complex-relationships-in-object-views.html#GUID-6F3C9031-708B-4C94-A94A-80D48DE98F7F

CREATE OR REPLACE FORCE VIEW KocuryPO OF KocuryO
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT imie, plec, pseudo, funkcja, MAKE_REF(KocuryPO, szef), w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy 
FROM Kocury;


CREATE OR REPLACE TYPE PlebsO AS OBJECT
(
    pseudo VARCHAR(15),
    kot REF KocuryO,
    MEMBER FUNCTION dane RETURN VARCHAR2
);

-- plebs
CREATE OR REPLACE VIEW PlebsPO OF PlebsO
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT pseudo, MAKE_REF(KocuryPO, pseudo)
FROM Plebs;


CREATE OR REPLACE TYPE ElitaO AS OBJECT
(
    pseudo VARCHAR(15),
    kot REF KocuryO,
    sluga REF PlebsO,
    MEMBER FUNCTION kto_sluga RETURN REF PlebsO
);

-- elita
CREATE OR REPLACE VIEW ElitaPO OF ElitaO
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT pseudo, MAKE_REF(KocuryPO, pseudo), MAKE_REF(PlebsPO, sluga)
FROM Elita;

CREATE OR REPLACE TYPE KontoO AS OBJECT
(
    nr_myszy NUMBER(8),
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    kot REF ElitaO,
    MEMBER PROCEDURE usun_mysz(d DATE)
);

-- konta
CREATE OR REPLACE VIEW KontaPO OF KontoO
WITH OBJECT IDENTIFIER(nr_myszy) AS
SELECT nr_myszy, data_wprowadzenia, data_usuniecia, MAKE_REF(ElitaPO, kot)
FROM Konta;

-- ZAPYTANIA
-- GRUPOWANIE
SELECT EPO.sluga.pseudo "Sluga", COUNT(*) "Ile wladcow"
FROM ElitaPO EPO
GROUP BY EPO.sluga.pseudo;

--  ZLACZENIE - PLEBS BEZ WLADCY
SELECT PPO.pseudo
FROM PlebsPO PPO LEFT JOIN ElitaPO EPO ON REF(PPO) = EPO.sluga
WHERE EPO.pseudo IS NULL;

-- podzapytanie
SELECT KPO.pseudo, KPO.calkowity_przydzial() "przydzial"
FROM KocuryPO KPO WHERE KPO.calkowity_przydzial() > 
(
    SELECT AVG(KPO.calkowity_przydzial())
    FROM KocuryPO KPO
) ORDER BY KPO.calkowity_przydzial() DESC;

-- zad 2.18

SELECT KPO.imie, KPO.w_stadku_od
FROM KocuryPO KPO JOIN KocuryPO KPOJ ON KPOJ.imie = 'JACEK'
WHERE KPO.w_stadku_od < KPOJ.w_stadku_od
ORDER BY KPO.w_stadku_od DESC;

-- BEZ JOINOW, OBIEKTOWO!
-- ZAD 2.19 A
SELECT KPO.imie "Imie", KPO.funkcja "Funkcja", KPO.szef.imie "Szef1", KPO.szef.szef.imie "Szef2", KPO.szef.szef.szef.imie "Szef3"
FROM KocuryPO KPO;

-- zad 3.35

DECLARE
    roczny_przydzial NUMBER;
    imie KocuryPO.imie%TYPE;
    data_przystapienia KocuryPO.w_stadku_od%TYPE;
    miesiac NUMBER;
BEGIN
    SELECT KPO.calkowity_przydzial()*12, KPO.imie, KPO.w_stadku_od
    INTO roczny_przydzial, imie, data_przystapienia
    FROM KocuryPO KPO WHERE KPO.pseudo=UPPER('&pseudo');
    miesiac:=EXTRACT(MONTH FROM data_przystapienia);
    CASE
        WHEN roczny_przydzial > 700 THEN dbms_output.put_line('calkowity roczny przydzial myszy > 700');
        WHEN imie LIKE '%A%' THEN dbms_output.put_line('Imie zawiera litere A');
        WHEN miesiac=5 THEN dbms_output.put_line('maj jest miesiacem przystapienia do stada');
        ELSE dbms_output.put_line('nie odpowiada kryteriom');
    END CASE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN dbms_output.put_line('Nie znaleziono kota o podanym pseudonimie!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM); 
END;



-- zad 3.37
DECLARE
    CURSOR kursor_koty IS
    SELECT KPO.pseudo, KPO.calkowity_przydzial() calk
    FROM KocuryPO KPO
    ORDER BY calk DESC;
    nr_kota NUMBER := 0;
    sa_koty BOOLEAN:= false;
    BRAK_DANYCH EXCEPTION;
    ZA_MALO_DANYCH EXCEPTION;
BEGIN
    dbms_output.put_line('Nr  Pseudonim   Zjada');
    dbms_output.put_line('---------------------');
    FOR kot IN kursor_koty
    LOOP
        nr_kota := nr_kota + 1;
        dbms_output.put_line(nr_kota || '   ' || kot.pseudo || LPAD(kot.calk, 17-LENGTH(kot.pseudo), ' '));
        EXIT WHEN nr_kota = 5;
    END LOOP;
    IF (nr_kota = 0) THEN
        RAISE BRAK_DANYCH;
    END IF;
    IF (nr_kota < 5) THEN
        RAISE ZA_MALO_DANYCH;
    END IF;
EXCEPTION
    WHEN BRAK_DANYCH THEN dbms_output.put_line('Brak kotow!');
    WHEN ZA_MALO_DANYCH THEN dbms_output.put_line('Za malo kotow, aby wyswietlic top 5!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;







--=========================================================================== ZAD 49 ======================================================================

-- norma - co najmniej 10, co najwyzej 99, nie istnieja myszy o wadze >=100, wowczas wtedy takie stworzenia sa klasyfikowane inaczej


BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE Myszy
    (
        nr_myszy NUMBER(8) CONSTRAINT my_nm_pk PRIMARY KEY,
        lowca CONSTRAINT my_lo_fk REFERENCES Kocury(pseudo),
        zjadacz CONSTRAINT my_zj_fk REFERENCES Kocury(pseudo),
        waga_myszy NUMBER(2) CONSTRAINT my_wm_ch CHECK(waga_myszy BETWEEN 15 AND 99),
        data_zlowienia DATE CONSTRAINT my_dz_nn NOT NULL,
        data_wydania DATE,
        CONSTRAINT my_dw_gt_zl_ch CHECK(data_wydania >= data_zlowienia)
    )';
END;

DROP TABLE Myszy;

--
CREATE OR REPLACE FUNCTION next_last_wednesday(date_arg DATE) RETURN DATE IS
ostatnia DATE;
BEGIN
    ostatnia := NEXT_DAY(LAST_DAY(date_arg) - 7, 'Œroda');
    IF date_arg > ostatnia THEN
        ostatnia := NEXT_DAY(LAST_DAY(ADD_MONTHS(date_arg, 1)) - 7 , 'Œroda');
    END IF;
    RETURN ostatnia;
END;

CREATE OR REPLACE FUNCTION date_diff(d1 DATE, d2 DATE) RETURN NUMBER IS
BEGIN
    RETURN ABS(d1 - d2);
END;

SELECT * FROM Myszy;

DECLARE
    aktualna_data DATE := '2004-01-01';
    data_sroda DATE := next_last_wednesday(aktualna_data);
    data_max DATE := '2024-01-22';
    data_temp DATE;
    przydzial_mies NUMBER(4);
    srednia NUMBER;
    TYPE tpseudo IS TABLE OF Kocury.pseudo%TYPE;
    TYPE tprzydzial IS TABLE OF NUMBER(3);
    TYPE mdane IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    pseudonimy tpseudo := tpseudo();
    przydzialy tprzydzial := tprzydzial();
    myszy_dane mdane;
    nr_myszy BINARY_INTEGER := 0;
    i_zjadacz NUMBER(2);
BEGIN
    LOOP
    EXIT WHEN aktualna_data >= data_max;
        -- init danych dla bloku miesiecznego.
        SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) INTO przydzial_mies
        FROM Kocury
        WHERE w_stadku_od < data_sroda;
        SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO pseudonimy, przydzialy
        FROM Kocury
        WHERE w_stadku_od < data_sroda;
        
        srednia := CEIL(przydzial_mies/pseudonimy.COUNT);
        i_zjadacz := 1;
        
        FOR i IN 1..przydzial_mies
        LOOP
            nr_myszy := nr_myszy + 1;
            myszy_dane(nr_myszy).nr_myszy := nr_myszy;
            -- strategia przypisywania ³owcy - round robin, jesli zakladamy, ze lowca moze dostac do zjedzenia mysz, ktora zlowil.
            myszy_dane(nr_myszy).lowca := pseudonimy(MOD(i, pseudonimy.COUNT) + 1);
            
            IF data_sroda <= data_max THEN
                myszy_dane(nr_myszy).data_wydania := data_sroda;
                data_temp := data_sroda;
                -- przypisuj myszy kotowi do zjedzenia, dopoki nie dostanie tyle ile zjada miesiecznie.
                IF przydzialy(i_zjadacz) > 0 THEN
                    przydzialy(i_zjadacz) := przydzialy(i_zjadacz) - 1;
                ELSE
                    i_zjadacz := i_zjadacz + 1;
                END IF;
                
                IF i_zjadacz > przydzialy.COUNT THEN
                    i_zjadacz := DBMS_RANDOM.VALUE(1, przydzialy.COUNT);
                END IF;
                
                myszy_dane(nr_myszy).zjadacz := pseudonimy(i_zjadacz);
            ELSE
                data_temp := data_max;
            END IF;
            -- Strategia dystrybucji dat - te¿ round robin w danym bloku
            myszy_dane(nr_myszy).data_zlowienia := aktualna_data + MOD(nr_myszy, date_diff(aktualna_data, data_temp) + 1);
            myszy_dane(nr_myszy).waga_myszy := DBMS_RANDOM.VALUE(15, 99);
            
        END LOOP;
        aktualna_data := data_sroda + 1;
        data_sroda := next_last_wednesday(aktualna_data);
        
    END LOOP;
    
    FORALL i IN 1..myszy_dane.COUNT
    INSERT INTO Myszy
    VALUES(myszy_dane(i).nr_myszy, myszy_dane(i).lowca, myszy_dane(i).zjadacz, myszy_dane(i).waga_myszy, myszy_dane(i).data_zlowienia, myszy_dane(i).data_wydania);
END;

DELETE FROM MYSZY;

DECLARE
CURSOR pseudonimy_kursor IS SELECT pseudo FROM Kocury;
BEGIN
    FOR kot in pseudonimy_kursor
    LOOP
       EXECUTE IMMEDIATE 'CREATE TABLE Myszy' || kot.pseudo || '(' ||
           'nr_myszy NUMBER(7) CONSTRAINT mk_nm_pk_' || kot.pseudo || ' PRIMARY KEY,' ||
           'waga_myszy NUMBER(3) CONSTRAINT mk_wm_ch_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 15 AND 99),' ||
           'data_zlowienia DATE CONSTRAINT mk_dz_nn_' || kot.pseudo ||' NOT NULL)' ;
    END LOOP;
END;


DECLARE
CURSOR pseudonimy_kursor IS SELECT pseudo FROM Kocury;
BEGIN
    FOR kot in pseudonimy_kursor
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE Myszy' || kot.pseudo;
    END LOOP;
END;

CREATE OR REPLACE PROCEDURE przyjmij_na_stan(ps Kocury.pseudo%TYPE, data_zlowienia DATE)
AS
    TYPE twagi IS TABLE OF NUMBER(3);
    TYPE tnumery IS TABLE OF NUMBER(7);
    wagi twagi := twagi();
    numery tnumery := tnumery();
    ile NUMBER(2);
    zly_pseudo EXCEPTION;
    zla_data EXCEPTION;
BEGIN
    IF data_zlowienia > SYSDATE THEN
        RAISE zla_data;
    END IF;
    
    SELECT COUNT(pseudo) INTO ile FROM Kocury;
    IF ile = 0 THEN
        RAISE zly_pseudo;
    END IF;
    
    EXECUTE IMMEDIATE 'SELECT nr_myszy, waga_myszy FROM Myszy'|| ps || ' WHERE data_zlowienia= ''' || data_zlowienia || ''''
    BULK COLLECT INTO numery, wagi;
    
    
    FORALL i in 1..numery.COUNT
    INSERT INTO Myszy VALUES (numery(i), UPPER(ps), NULL, wagi(i), data_zlowienia, NULL);
    
    EXECUTE IMMEDIATE 'DELETE FROM Myszy' || ps || ' WHERE data_zlowienia= ''' || data_zlowienia || '''';
    EXCEPTION
    WHEN zly_pseudo THEN dbms_output.put_line('Nie ma kota o takim pseudonimie!');
    WHEN zla_data THEN dbms_output.put_line('Zla data.');
END;

SELECT * FROM Myszy;


SELECT MAX(nr_myszy) FROM Myszy;

SELECT COUNT(*) FROM Myszy;

INSERT INTO MyszyMALA
VALUES(229219, 45, '2024-01-22');
INSERT INTO MyszyMALA
VALUES(229220, 17, '2024-01-22');
DELETE FROM MyszyMala;

BEGIN
    przyjmij_na_stan('MALA', TO_DATE('2024-01-22'));
END;

rollback;

CREATE OR REPLACE PROCEDURE Wyplata3
AS
    TYPE tpseudo IS TABLE OF Kocury.pseudo%TYPE;
        pseudonimy tpseudo := tpseudo();
    TYPE tprzydzialy is TABLE OF NUMBER(4);
        przydzialy tprzydzialy := tprzydzialy();
    TYPE tnrmyszy IS TABLE OF NUMBER(7);
        numery_myszy tnrmyszy := tnrmyszy();
    TYPE tzjadacze IS TABLE OF Kocury.pseudo%TYPE INDEX BY BINARY_INTEGER;
        zjadacze tzjadacze;
    TYPE mwiersze IS TABLE OF Myszy%ROWTYPE;
        wiersze mwiersze;
    najedzeni NUMBER(2) := 0;
    i_zjadacz NUMBER(2) := 1;
    ile NUMBER(5);
    powtorna_wyplata EXCEPTION;
BEGIN
    SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)
    BULK COLLECT INTO pseudonimy, przydzialy
    FROM Kocury CONNECT BY PRIOR pseudo = szef
    START WITH szef IS NULL
    ORDER BY level;
    
    SELECT COUNT(nr_myszy) INTO ile
    FROM myszy
    WHERE data_wydania = TO_DATE(next_last_wednesday(SYSDATE));
    IF ile > 0 THEN RAISE powtorna_wyplata;
    END IF;
    
    SELECT *
    BULK COLLECT INTO wiersze
    FROM Myszy
    WHERE data_wydania IS NULL;
    
    FOR i IN 1..wiersze.COUNT
    LOOP
        WHILE przydzialy(i_zjadacz) = 0 AND najedzeni < pseudonimy.COUNT
            LOOP
                najedzeni := najedzeni + 1;
                i_zjadacz := MOD(i_zjadacz, pseudonimy.COUNT) + 1;
            END LOOP;
            IF najedzeni = pseudonimy.COUNT THEN
                zjadacze(i) := pseudonimy(DBMS_RANDOM.VALUE(1, pseudonimy.COUNT));
            ELSE
                i_zjadacz := MOD(i_zjadacz, pseudonimy.COUNT) + 1;
                zjadacze(i) := pseudonimy(i_zjadacz);
                przydzialy(i_zjadacz) := przydzialy(i_zjadacz) - 1;
            end if;
        wiersze(i).data_wydania := next_last_wednesday(wiersze(i).data_zlowienia);
    END LOOP;
    FORALL i IN 1..wiersze.COUNT
        UPDATE Myszy SET data_wydania=wiersze(i).data_wydania , zjadacz=zjadacze(i)
        WHERE nr_myszy=wiersze(i).nr_myszy;
    EXCEPTION
        WHEN powtorna_wyplata THEN DBMS_OUTPUT.PUT_LINE('Wyplata juz nastapila!');
END;

BEGIN
    Wyplata3();
END;



BEGIN
    DBMS_OUTPUT.PUT_LINE(next_last_wednesday(SYSDATE));
END;

SELECT * FROM Myszy;

rollback;


-- TRIGGER NA ELICIE ALBO NA PLEBSIE - CZY NIE MA W DRUGIEJ TABELI!

CREATE OR REPLACE TRIGGER sprawdzenie_elita_plebs_1
    BEFORE INSERT OR UPDATE ON Elita FOR EACH ROW
DECLARE
    ile NUMBER;
BEGIN
    SELECT COUNT(*) INTO ile FROM Plebs P WHERE P.pseudo = :NEW.pseudo;
    IF ile > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot nalezy do plebsu!');
    END IF;
END;

INSERT INTO Elita VALUES('PLACEK', NULL);

