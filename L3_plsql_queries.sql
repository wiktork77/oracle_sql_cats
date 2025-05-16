SET SERVEROUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';


-- TASK 34

DECLARE
    ile NUMBER;
    fun Kocury.funkcja%TYPE := '&funkcja';
BEGIN
    SELECT COUNT(*) INTO ile
    FROM Kocury
    WHERE funkcja = fun;
    
    IF ile > 0 THEN
        DBMS_OUTPUT.PUT_LINE('znaleziono kota(y) o funkcji ' || fun);
    ELSE
        DBMS_OUTPUT.PUT_LINE('nie istnieje');
    END IF;
END;
/


-- View for easier testing
CREATE OR REPLACE VIEW koty_rp AS
SELECT pseudo, imie,
CASE
    WHEN imie LIKE '%A%' THEN 1
    ELSE 0
END czy_a,
w_stadku_od,
CASE
    WHEN EXTRACT(MONTH FROM w_stadku_od) = 5 THEN 1
    ELSE 0
END czy_maj,
12*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) roczny_przydzial
FROM Kocury K;

SELECT *
FROM koty_rp;

-- TASK 35

DECLARE
    ps Kocury.pseudo%TYPE := '&pseudonim';
    kot Kocury%ROWTYPE;
BEGIN
    SELECT * INTO kot
    FROM Kocury
    WHERE pseudo = ps;
    
    IF 12*(NVL(kot.przydzial_myszy, 0) + NVL(kot.myszy_extra, 0)) > 700 THEN
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy > 700');
    ELSIF kot.imie LIKE '%A%' THEN
        DBMS_OUTPUT.PUT_LINE('imie zawiera litere A');
    ELSIF EXTRACT(MONTH FROM kot.w_stadku_od) = 5 THEN
        DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada');
    ELSE
        DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');        
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20001, 'kot o podanym pseudonimie nie istnieje');
END;
/


-- TASK 36

DECLARE
    CURSOR koty IS
    SELECT imie, funkcja, max_myszy, przydzial_myszy
    FROM Kocury NATURAL JOIN Funkcje
    ORDER BY NVL(przydzial_myszy, 0)
    FOR UPDATE;
    
    zmian NUMBER := 0;
    suma NUMBER := 0;
    dodatek NUMBER := 0;
BEGIN
    SELECT SUM(NVL(przydzial_myszy, 0)) INTO suma
    FROM Kocury;

    WHILE suma <= 1050
    LOOP
        FOR kot IN koty
        LOOP
            EXIT WHEN suma > 1050;
            
            dodatek := ROUND(0.1*NVL(kot.przydzial_myszy, 0)); -- Had to do it to match the result from the list;
            
            IF NVL(kot.przydzial_myszy, 0) + dodatek > kot.max_myszy THEN
                dodatek := kot.max_myszy - NVL(kot.przydzial_myszy, 0);
            END IF;
            
            UPDATE Kocury
            SET przydzial_myszy = NVL(przydzial_myszy, 0) + dodatek
            WHERE CURRENT OF koty;
            
            suma := suma + dodatek;
            
            IF dodatek > 0 THEN
                zmian := zmian + 1;
            END IF;
            
        END LOOP;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(zmian);
    DBMS_OUTPUT.PUT_LINE(suma);
END;
/


SELECT *
FROM Kocury;
ROLLBACK;


-- TASK 37

DECLARE
    CURSOR koty_naj IS
    SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) prz
    FROM Kocury
    ORDER BY NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) DESC;
    
    ile NUMBER;
    
    MNIEJ_NIZ_5_KOTOW EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO ile
    FROM Kocury;
    
    IF ile < 5 THEN
        RAISE MNIEJ_NIZ_5_KOTOW;
    END IF;
    
    ile := 1;
    
    DBMS_OUTPUT.PUT_LINE('Nr  Psedonim   Zjada');
    DBMS_OUTPUT.PUT_LINE(LPAD('-', 20, '-'));
    FOR kot IN koty_naj
    LOOP
        EXIT WHEN ile > 5;
        DBMS_OUTPUT.PUT_LINE(RPAD(ile, 4, ' ') || RPAD(kot.pseudo, 11, ' ') || ' ' || LPAD(kot.prz, 3, ' '));
        ile := ile + 1;
    END LOOP;
EXCEPTION
    WHEN MNIEJ_NIZ_5_KOTOW THEN RAISE_APPLICATION_ERROR(-20001, 'Jest mniej niz 5 kotow w bazie!');
END;
/



-- TASK 38

-- Version with taking max level from the tree, kind of cheating but easier
DECLARE
    CURSOR koty_base IS
    SELECT *
    FROM Kocury
    WHERE funkcja IN ('KOT', 'MILUSIA');
    
    kot_pom Kocury%ROWTYPE; 
    
    max_gleb NUMBER := '&limit';
    
    lm NUMBER;
    
    gleb NUMBER;
BEGIN
    SELECT MAX(level) - 1 INTO lm
    FROM Kocury
    START WITH funkcja IN('KOT', 'MILUSIA')
    CONNECT BY PRIOR szef = pseudo;
    
    DBMS_OUTPUT.PUT(RPAD('Imie', 15, ' '));
    
    IF lm > max_gleb THEN
        lm := max_gleb;
    END IF;
    
    FOR i IN 1..lm
    LOOP
        DBMS_OUTPUT.PUT(RPAD('SZEF ' || i, 15, ' '));
    END LOOP;
    DBMS_OUTPUT.NEW_LINE();
    
    FOR kot IN koty_base
    LOOP
        DBMS_OUTPUT.PUT(RPAD(kot.imie, 15, ' '));
        gleb := 1;
        kot_pom := kot;
        
        WHILE kot_pom.szef IS NOT NULL AND gleb <= max_gleb
        LOOP
            SELECT * INTO kot_pom
            FROM Kocury
            WHERE pseudo = kot_pom.szef;
            
            DBMS_OUTPUT.PUT(RPAD(kot_pom.imie, 15, ' '));
            
            gleb := gleb + 1;
        END LOOP;
        DBMS_OUTPUT.NEW_LINE();
    END LOOP;
END;
/


-- VERSION WITH associative arrays, the maximum depth isnt known before computation + bulk binding
DECLARE
    CURSOR koty_base IS
    SELECT imie, szef
    FROM Kocury
    WHERE funkcja IN ('KOT', 'MILUSIA');
    
    max_gleb NUMBER := '&limit';

    TYPE hierarchy_t IS TABLE OF VARCHAR2(500) INDEX BY Kocury.pseudo%TYPE;
    hierarchy_tbl hierarchy_t;
    
    TYPE koty_rec IS RECORD (
        imie Kocury.imie%TYPE,
        szef Kocury.szef%TYPE
    );
    
    TYPE koty_t IS TABLE OF koty_rec INDEX BY PLS_INTEGER;
    
    koty_tbl koty_t;
    
    kot_pom koty_rec;
    
    max_actual_depth NUMBER := 0;
    current_depth NUMBER;
BEGIN
    OPEN koty_base;
    FETCH koty_base
    BULK COLLECT INTO koty_tbl;
    CLOSE koty_base;
    
    
    FOR i IN 1..koty_tbl.LAST
    LOOP
        current_depth := 0;
        hierarchy_tbl(koty_tbl(i).imie) := RPAD(koty_tbl(i).imie, 15, ' ');
        kot_pom := koty_tbl(i);
        WHILE kot_pom.szef IS NOT NULL AND current_depth < max_gleb
        LOOP
            SELECT imie, szef INTO kot_pom
            FROM Kocury
            WHERE pseudo = kot_pom.szef;
            
            hierarchy_tbl(koty_tbl(i).imie) := hierarchy_tbl(koty_tbl(i).imie) || RPAD(kot_pom.imie, 15, ' ');
            
            current_depth := current_depth + 1;
            
            IF current_depth > max_actual_depth THEN
                max_actual_depth := current_depth;
            END IF;
        END LOOP;
    END LOOP;
    
    DBMS_OUTPUT.PUT(RPAD('Imie', 15, ' '));
    
    FOR i IN 1..max_actual_depth
    LOOP
        DBMS_OUTPUT.PUT(RPAD('SZEF ' || i, 15, ' '));
    END LOOP;
    
    DBMS_OUTPUT.NEW_LINE();
    
    FOR i IN 1..koty_tbl.LAST
    LOOP
        DBMS_OUTPUT.PUT_LINE(hierarchy_tbl(koty_tbl(i).imie));
    END LOOP;
END;
/


-- TASK 39

DECLARE
    nrb Bandy.nr_bandy%TYPE := '&nr_bandy';
    nzb Bandy.nazwa%TYPE := '&nazwa';
    trn Bandy.teren%TYPE := '&teren';
    
    nazwa_istnieje EXCEPTION;
    nr_istnieje EXCEPTION;
    nr_ujemny EXCEPTION;
    dlugosc_zla_banda EXCEPTION;
    dlugosc_zly_teren EXCEPTION;
    teren_istnieje EXCEPTION;
    
    ile NUMBER;
BEGIN
    IF nrb < 0 THEN
        RAISE nr_ujemny;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(nzb);
    
    IF LENGTH(nzb) < 1 OR nzb IS NULL THEN
        RAISE dlugosc_zla_banda;
    END IF;
    
    IF LENGTH(trn) < 1 OR trn IS NULL THEN
        RAISE dlugosc_zly_teren;
    END IF;

    -- nr istnieje
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE nr_bandy = nrb;
    
    IF ile > 0 THEN
        RAISE nr_istnieje;
    END IF;
    
    -- nazwa istnieje
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE nazwa = nzb;
    
    IF ile > 0 THEN
        RAISE nazwa_istnieje;
    END IF;
    
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE teren = trn;
    
    IF ile > 0 THEN
        RAISE teren_istnieje;
    END IF;
    
    INSERT INTO Bandy
    VALUES(nrb, nzb, trn, NULL);
EXCEPTION
    WHEN nazwa_istnieje THEN RAISE_APPLICATION_ERROR(-20001, 'TAKA NAZWA - ' || nzb || ' JUZ ISTNIEJE!');
    WHEN nr_istnieje THEN RAISE_APPLICATION_ERROR(-20002, 'TAKI NUMER - ' || nrb || ' JUZ ISTNIEJE!');
    WHEN nr_ujemny THEN RAISE_APPLICATION_ERROR(-20003, 'NUMER JEST UJEMNY! BANDY PRZYJMUJA TYLKO NUMERY NIEUJEMNE');
    WHEN dlugosc_zla_banda THEN RAISE_APPLICATION_ERROR(-20004, 'NAZWA BANDY MA ZEROWA DLUGOSC!');
    WHEN dlugosc_zly_teren THEN RAISE_APPLICATION_ERROR(-20005, 'TEREN BANDY MA ZLA DLUGOSC !');
    WHEN teren_istnieje THEN RAISE_APPLICATION_ERROR(-20006, 'TEREN BANDY JEST JUZ ZAJETY!');
END;
/


SELECT *
FROM Bandy;

ROLLBACK;


-- TASK 40

CREATE OR REPLACE PROCEDURE dod_bande(nrb Bandy.nr_bandy%TYPE, nzb Bandy.nazwa%TYPE, trn Bandy.teren%TYPE) IS 
    nazwa_istnieje EXCEPTION;
    nr_istnieje EXCEPTION;
    nr_ujemny EXCEPTION;
    dlugosc_zla_banda EXCEPTION;
    dlugosc_zly_teren EXCEPTION;
    teren_istnieje EXCEPTION;
    
    ile NUMBER;
BEGIN
    IF nrb < 0 THEN
        RAISE nr_ujemny;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(nzb);
    
    IF LENGTH(nzb) < 1 OR nzb IS NULL THEN
        RAISE dlugosc_zla_banda;
    END IF;
    
    IF LENGTH(trn) < 1 OR trn IS NULL THEN
        RAISE dlugosc_zly_teren;
    END IF;

    -- nr istnieje
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE nr_bandy = nrb;
    
    IF ile > 0 THEN
        RAISE nr_istnieje;
    END IF;
    
    -- nazwa istnieje
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE nazwa = nzb;
    
    IF ile > 0 THEN
        RAISE nazwa_istnieje;
    END IF;
    
    SELECT COUNT(*) INTO ile
    FROM Bandy
    WHERE teren = trn;
    
    IF ile > 0 THEN
        RAISE teren_istnieje;
    END IF;
    
    INSERT INTO Bandy
    VALUES(nrb, nzb, trn, NULL);
EXCEPTION
    WHEN nazwa_istnieje THEN RAISE_APPLICATION_ERROR(-20001, 'TAKA NAZWA - ' || nzb || ' JUZ ISTNIEJE!');
    WHEN nr_istnieje THEN RAISE_APPLICATION_ERROR(-20002, 'TAKI NUMER - ' || nrb || ' JUZ ISTNIEJE!');
    WHEN nr_ujemny THEN RAISE_APPLICATION_ERROR(-20003, 'NUMER JEST UJEMNY! BANDY PRZYJMUJA TYLKO NUMERY NIEUJEMNE');
    WHEN dlugosc_zla_banda THEN RAISE_APPLICATION_ERROR(-20004, 'NAZWA BANDY MA ZEROWA DLUGOSC!');
    WHEN dlugosc_zly_teren THEN RAISE_APPLICATION_ERROR(-20005, 'TEREN BANDY MA ZLA DLUGOSC !');
    WHEN teren_istnieje THEN RAISE_APPLICATION_ERROR(-20006, 'TEREN BANDY JEST JUZ ZAJETY!');
END;
/


SELECT * FROM Bandy;

-- TASK 41

CREATE OR REPLACE TRIGGER seq_nr_bandy
BEFORE INSERT ON Bandy
FOR EACH ROW
DECLARE
    max_nr_bandy NUMBER;
BEGIN
    SELECT MAX(nr_bandy) INTO max_nr_bandy
    FROM Bandy;
    
    :NEW.nr_bandy := max_nr_bandy + 1;
    
    DBMS_OUTPUT.PUT_LINE(:NEW.nr_bandy);
END;
/

ROLLBACK;


-- TASK 42

-- classic solution to avoid mutating-table error, with package and multiple triggers
CREATE OR REPLACE PACKAGE dane_wirusa AS
    przydzial_tygrysa NUMBER;
    strata_tygrysa NUMBER;
    extra_tygrysa NUMBER;
    extra_milus NUMBER;
    
    update_lock BOOLEAN := FALSE;
END;
/

CREATE OR REPLACE TRIGGER wirus_milus_przed
BEFORE UPDATE OF przydzial_myszy ON Kocury
BEGIN
    IF dane_wirusa.update_lock = FALSE THEN
    DBMS_OUTPUT.PUT_LINE('inside przed');
        SELECT NVL(przydzial_myszy, 0) INTO dane_wirusa.przydzial_tygrysa
        FROM Kocury
        WHERE pseudo = 'TYGRYS';
        
        dane_wirusa.strata_tygrysa := 0;
        dane_wirusa.extra_tygrysa := 0;
        dane_wirusa.extra_milus := 0;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER wirus_milus_przed_er
BEFORE UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW
WHEN (OLD.funkcja = 'MILUSIA')
DECLARE
    diff NUMBER;
    ujemna_zmiana EXCEPTION;
BEGIN
    IF dane_wirusa.update_lock = FALSE THEN
        diff := NVL(:NEW.przydzial_myszy, 0) - NVL(:OLD.przydzial_myszy, 0);
        DBMS_OUTPUT.PUT_LINE('inside er');
        IF diff < 0 THEN
            RAISE ujemna_zmiana;
        END IF;
        
        
        IF diff < 0.1*dane_wirusa.przydzial_tygrysa THEN
            dane_wirusa.strata_tygrysa := dane_wirusa.strata_tygrysa + 0.1*dane_wirusa.przydzial_tygrysa;
            dane_wirusa.extra_milus := dane_wirusa.extra_milus + 5;
        ELSE
            dane_wirusa.extra_tygrysa := dane_wirusa.extra_tygrysa + 5;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('UPDATED!');
    END IF;
EXCEPTION
    WHEN ujemna_zmiana THEN RAISE_APPLICATION_ERROR(-20001, 'Ujemna zmiana!');
END;
/


CREATE OR REPLACE TRIGGER wirus_milus_po
AFTER UPDATE ON Kocury
DECLARE
nowy_prz_tygrysa NUMBER;
BEGIN
    
    IF dane_wirusa.update_lock = FALSE THEN
        dane_wirusa.update_lock := TRUE;
        
        UPDATE Kocury
        SET przydzial_myszy = ROUND(NVL(przydzial_myszy, 0) + dane_wirusa.strata_tygrysa),
            myszy_extra = NVL(myszy_extra, 0) + dane_wirusa.extra_milus
        WHERE funkcja = 'MILUSIA';
        
        nowy_prz_tygrysa := ROUND(dane_wirusa.przydzial_tygrysa - dane_wirusa.strata_tygrysa);
        IF nowy_prz_tygrysa < 0 THEN
           nowy_prz_tygrysa := 0; 
        END IF;
        
        UPDATE Kocury
        SET przydzial_myszy = nowy_prz_tygrysa,
            myszy_extra = NVL(myszy_extra, 0) + dane_wirusa.extra_tygrysa
        WHERE pseudo = 'TYGRYS';
        
        DBMS_OUTPUT.PUT_LINE(dane_wirusa.strata_tygrysa);
        DBMS_OUTPUT.PUT_LINE(dane_wirusa.extra_tygrysa);
        DBMS_OUTPUT.PUT_LINE(dane_wirusa.extra_milus);
        
        dane_wirusa.update_lock := FALSE;
    END IF;

EXCEPTION
    WHEN OTHERS THEN dane_wirusa.update_lock := FALSE;
END;
/

-- tests
SELECT *
FROM Kocury
WHERE funkcja = 'MILUSIA';

SELECT *
FROM Kocury;

UPDATE Kocury
SET przydzial_myszy = 152
WHERE funkcja = 'MILUSIA';

SELECT 4*0.1*NVL(przydzial_myszy, 0)
FROM Kocury
WHERE pseudo = 'TYGRYS';

ROLLBACK;

DROP TRIGGER wirus_milus_przed;
DROP TRIGGER wirus_milus_przed_er;
DROP TRIGGER wirus_milus_po;

-- solution with compound trigger (and with smaller package because lock is needed)

CREATE OR REPLACE PACKAGE wirus_compound_state AS
    trigger_lock BOOLEAN := FALSE;
END;
/

CREATE OR REPLACE TRIGGER wirus_milusi_compound
FOR UPDATE OF przydzial_myszy
ON Kocury
WHEN(OLD.funkcja = 'MILUSIA')
COMPOUND TRIGGER
przydzial_tygrysa NUMBER := 0;
strata_tygrysa NUMBER := 0;
extra_tygrysa NUMBER := 0;
extra_milus NUMBER := 0;

    BEFORE STATEMENT IS
    BEGIN
    IF wirus_compound_state.trigger_lock = FALSE THEN
        SELECT NVL(przydzial_myszy, 0) INTO przydzial_tygrysa
        FROM Kocury
        WHERE pseudo = 'TYGRYS';
    END IF;
    END BEFORE STATEMENT;
    
    BEFORE EACH ROW IS
        diff NUMBER;
        ujemna_zmiana EXCEPTION;
    BEGIN
    IF wirus_compound_state.trigger_lock = FALSE THEN
        diff := NVL(:NEW.przydzial_myszy, 0) - NVL(:OLD.przydzial_myszy, 0);
        IF diff < 0 THEN
            RAISE ujemna_zmiana;
        END IF;
            
        IF diff < 0.1*przydzial_tygrysa THEN
            strata_tygrysa := strata_tygrysa + 0.1*przydzial_tygrysa;
            extra_milus := extra_milus + 5;
        ELSE
            extra_tygrysa := extra_tygrysa + 5;
        END IF;
        
    END IF;
    EXCEPTION
        WHEN ujemna_zmiana THEN RAISE_APPLICATION_ERROR(-20001, 'Ujemna zmiana!');
    END BEFORE EACH ROW;


    AFTER STATEMENT IS
        nowy_prz_tygrysa NUMBER;
    BEGIN
    IF wirus_compound_state.trigger_lock = FALSE THEN
        wirus_compound_state.trigger_lock := TRUE;
    
        
        nowy_prz_tygrysa := ROUND(przydzial_tygrysa - strata_tygrysa);
        IF nowy_prz_tygrysa < 0 THEN
           nowy_prz_tygrysa := 0; 
        END IF;
        
        
        UPDATE Kocury
        SET przydzial_myszy = ROUND(NVL(przydzial_myszy, 0) + strata_tygrysa),
            myszy_extra = NVL(myszy_extra, 0) + extra_milus
        WHERE funkcja = 'MILUSIA';
        
        UPDATE Kocury
        SET przydzial_myszy = nowy_prz_tygrysa,
            myszy_extra = NVL(myszy_extra, 0) + extra_tygrysa
        WHERE pseudo = 'TYGRYS';
        
        wirus_compound_state.trigger_lock := FALSE;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN wirus_compound_state.trigger_lock := FALSE;
    END AFTER STATEMENT;
END;
/

-- tests

SELECT *
FROM Kocury
WHERE funkcja = 'MILUSIA';

SELECT *
FROM Kocury;

UPDATE Kocury
SET przydzial_myszy = 25
WHERE funkcja = 'MILUSIA';

ROLLBACK;


-- TASK 43
-- solution without using pivot table. collections dense solution
DECLARE
    TYPE tab_values_to_values_t IS TABLE OF NUMBER INDEX BY VARCHAR(30);
    TYPE bp_to_tab_values_t IS TABLE OF tab_values_to_values_t INDEX BY VARCHAR(30);
    TYPE bndy_t IS TABLE OF VARCHAR(30) INDEX BY PLS_INTEGER;
    TYPE funkc_t IS TABLE OF Funkcje.funkcja%TYPE INDEX BY PLS_INTEGER;

    TYPE suma_funkcji_t IS TABLE OF NUMBER INDEX BY Funkcje.funkcja%TYPE;

    bp_to_values bp_to_tab_values_t;
    tab_values_to_values tab_values_to_values_t;
    bndy bndy_t;
    funkc funkc_t;
    
    funkc_sumy suma_funkcji_t;
    
    suma_total NUMBER := 0;
    
    bp VARCHAR(30) := '';
    idx NUMBER := 0;
    
    CURSOR bnd IS
    SELECT B.nazwa, K.plec, F.funkcja, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) ile, COUNT(*) lb
    FROM Kocury K INNER JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                  INNER JOIN Funkcje F ON K.funkcja = F.funkcja
    GROUP BY B.nazwa, K.plec, F.funkcja
    ORDER BY B.nazwa, K.plec;
    
BEGIN
    SELECT funkcja
    BULK COLLECT INTO funkc
    FROM Funkcje;

    -- LOGIC
  
    FOR bn IN bnd
    LOOP
        bp := bn.nazwa || ' ' || bn.plec;
        
        IF NOT bp_to_values.EXISTS(bp) THEN
            bp_to_values(bp)('SUMA') := 0;
            bp_to_values(bp)('CNT') := 0;
            
            idx := idx + 1;
            bndy(idx) := bp;
        END IF;
        
        bp_to_values(bp)(bn.funkcja) := bn.ile;
        suma_total := suma_total + bn.ile;
        
        IF NOT funkc_sumy.EXISTS(bn.funkcja) THEN
            funkc_sumy(bn.funkcja) := bn.ile;
        ELSE
            funkc_sumy(bn.funkcja) := funkc_sumy(bn.funkcja) + bn.ile;
        END IF;
        
        bp_to_values(bp)('SUMA') := bp_to_values(bp)('SUMA') + bn.ile;
        bp_to_values(bp)('CNT') := bp_to_values(bp)('CNT') + bn.lb;
    END LOOP;
    
    
    -- PRESENTATION
    
    DBMS_OUTPUT.PUT(RPAD('NAZWA', 18, ' ') || RPAD('PLEC', 7, ' ') || LPAD('ILE', 5, ' '));
    
    FOR i IN 1..funkc.LAST
    LOOP
        DBMS_OUTPUT.PUT(LPAD(funkc(i), 10, ' '));
    END LOOP;
    
    DBMS_OUTPUT.PUT(LPAD('SUMA', 7, ' '));
    
    DBMS_OUTPUT.NEW_LINE();
    
    FOR i IN 1..bndy.LAST
    LOOP
        IF SUBSTR(bndy(i), LENGTH(bndy(i))) = 'M' THEN
            DBMS_OUTPUT.PUT(RPAD(' ', 18, ' '));
            DBMS_OUTPUT.PUT(RPAD('Kocor', 7, ' '));
        ELSE
            DBMS_OUTPUT.PUT(RPAD(SUBSTR(bndy(i), 1, LENGTH(bndy(i)) - 2), 18, ' '));
            DBMS_OUTPUT.PUT(RPAD('Kotka', 7, ' '));
        END IF;
        DBMS_OUTPUT.PUT(LPAD(bp_to_values(bndy(i))('CNT'), 5, ' '));
        FOR j IN 1..funkc.LAST
        LOOP
            IF bp_to_values(bndy(i)).EXISTS(funkc(j)) THEN
                DBMS_OUTPUT.PUT(LPAD(bp_to_values(bndy(i))(funkc(j)), 10, ' '));
            ELSE
                DBMS_OUTPUT.PUT(LPAD(0, 10, ' '));
            END IF;
        END LOOP;
        
        DBMS_OUTPUT.PUT(LPAD(bp_to_values(bndy(i))('SUMA'), 7, ' '));
        
        DBMS_OUTPUT.NEW_LINE();
    END LOOP;
    
    DBMS_OUTPUT.PUT(RPAD('ZJADA RAZEM', 18, ' ') || RPAD(' ', 7, ' ') || LPAD(' ', 5, ' '));
    
    FOR i IN 1..funkc.LAST
    LOOP
        IF funkc_sumy.EXISTS(funkc(i)) THEN
            DBMS_OUTPUT.PUT(LPAD(funkc_sumy(funkc(i)), 10, ' '));
        ELSE
            DBMS_OUTPUT.PUT(LPAD(0, 10, ' '));
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT(LPAD(suma_total, 7, ' '));
    DBMS_OUTPUT.NEW_LINE();
END;
/


-- solution with pivot table
-- dbms sql ?
DECLARE
    TYPE f_t IS TABLE OF Funkcje.funkcja%TYPE INDEX BY PLS_INTEGER;
    f f_t;

    CURSOR funkc IS
    SELECT * 
    FROM Funkcje;
    
    pivot_columns_sql VARCHAR(1000) := '';
    pivot_columns_select VARCHAR(1000) := '';
    select_sum_column VARCHAR(1000) := '';
    
    dyn_sql VARCHAR(2000) := '';
    
    PROCEDURE prepare_fun_statements IS
    BEGIN
        FOR i IN 1..f.LAST
        LOOP
            pivot_columns_sql := pivot_columns_sql || ', ''' || f(i) || ''' ' || 'f' || i;
            pivot_columns_select := pivot_columns_select || ', '|| 'NVL(f' || i || ', 0) ' || f(i);
            select_sum_column := select_sum_column || '+ ' || 'NVL(f' || i || ', 0)';
        END LOOP;
        select_sum_column := select_sum_column || ' suma';
        
        
        pivot_columns_sql := SUBSTR(pivot_columns_sql, 2);
        pivot_columns_select := SUBSTR(pivot_columns_select, 3);
        select_sum_column := SUBSTR(select_sum_column, 3);
    END;
    
BEGIN
    SELECT funkcja
    BULK COLLECT INTO f
    FROM funkcje;
    prepare_fun_statements();
    
    dyn_sql := 'SELECT :sel, :sm
    FROM (
        SELECT nazwa, plec, funkcja, przydzial_myszy, myszy_extra
        FROM Kocury NATURAL JOIN Bandy
    ) PIVOT (
        SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
        FOR funkcja IN (' || pivot_columns_sql || ')
    ) T
    ORDER BY nazwa, plec';
    
    EXECUTE IMMEDIATE dyn_sql
    USING pivot_columns_select, select_sum_column;
    
    DBMS_OUTPUT.PUT_LINE(pivot_columns_sql);
    DBMS_OUTPUT.PUT_LINE(pivot_columns_select);
    DBMS_OUTPUT.PUT_LINE(select_sum_column);
END;
/



-- TASK 44
-- note that all counts can be replaced by exists (select 1 ...) but since this is a small database it doesnt make a significant difference


CREATE OR REPLACE PACKAGE koty_funkcje AS
    FUNCTION cat_tax (ps Kocury.pseudo%TYPE) RETURN NUMBER;
    PROCEDURE dod_bande(nrb Bandy.nr_bandy%TYPE, nzb Bandy.nazwa%TYPE, trn Bandy.teren%TYPE);
END;
/

CREATE OR REPLACE PACKAGE BODY koty_funkcje AS
    FUNCTION cat_tax(ps Kocury.pseudo%TYPE) RETURN NUMBER IS
        ile NUMBER;
        podatek NUMBER;
        podstawa NUMBER;
        
        czy_bez_podwladnych NUMBER := 0;
        czy_ma_wrogow NUMBER := 0;
        czy_dolaczyl_w_marcu NUMBER := 0;
        
        KOT_NIE_ISTNIEJE EXCEPTION;
        PUSTY_PSEUDO EXCEPTION;
    BEGIN
        IF LENGTH(ps) < 1 OR ps IS NULL THEN
            RAISE PUSTY_PSEUDO;
        END IF;
    
        SELECT COUNT(*) INTO ile
        FROM Kocury
        WHERE pseudo = ps;
        
        IF ile < 1 THEN
            RAISE KOT_NIE_ISTNIEJE;
        END IF;
        
        SELECT DECODE(SIGN(COUNT(*)), 1, 0, 1) INTO czy_bez_podwladnych
        FROM Kocury
        WHERE szef = ps;
        
        SELECT COUNT(DISTINCT pseudo) INTO czy_ma_wrogow
        FROM Wrogowie_kocurow
        WHERE pseudo = ps;
        
        SELECT COUNT(*) INTO czy_dolaczyl_w_marcu
        FROM Kocury
        WHERE EXTRACT(MONTH FROM w_stadku_od) = 3 AND pseudo = ps;
        
        SELECT CEIL(0.05*(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) INTO podstawa
        FROM Kocury
        WHERE pseudo = ps;
        
    --    DBMS_OUTPUT.PUT_LINE('podatek podstawowy: ' || podstawa);
    --    DBMS_OUTPUT.PUT_LINE('podatek podwladnych: ' || 2*czy_bez_podwladnych);
    --    DBMS_OUTPUT.PUT_LINE('podatek wrogowy: ' || 1*czy_ma_wrogow);
    --    DBMS_OUTPUT.PUT_LINE('podatek marcowy: ' || 1*czy_dolaczyl_w_marcu)
    
        podatek := podstawa + 2*czy_bez_podwladnych + 1*czy_ma_wrogow + 1*czy_dolaczyl_w_marcu;
        
        RETURN podatek;
    EXCEPTION
        WHEN KOT_NIE_ISTNIEJE THEN RAISE_APPLICATION_ERROR(-20015, 'Kot nie istnieje!');
        WHEN PUSTY_PSEUDO THEN RAISE_APPLICATION_ERROR(-20015, 'Podano pusty ciag znakow!');
    END;


    PROCEDURE dod_bande(nrb Bandy.nr_bandy%TYPE, nzb Bandy.nazwa%TYPE, trn Bandy.teren%TYPE) IS 
        nazwa_istnieje EXCEPTION;
        nr_istnieje EXCEPTION;
        nr_ujemny EXCEPTION;
        dlugosc_zla_banda EXCEPTION;
        dlugosc_zly_teren EXCEPTION;
        teren_istnieje EXCEPTION;
        
        ile NUMBER;
    BEGIN
        IF nrb < 0 THEN
            RAISE nr_ujemny;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(nzb);
        
        IF LENGTH(nzb) < 1 OR nzb IS NULL THEN
            RAISE dlugosc_zla_banda;
        END IF;
        
        IF LENGTH(trn) < 1 OR trn IS NULL THEN
            RAISE dlugosc_zly_teren;
        END IF;
    
        -- nr istnieje
        SELECT COUNT(*) INTO ile
        FROM Bandy
        WHERE nr_bandy = nrb;
        
        IF ile > 0 THEN
            RAISE nr_istnieje;
        END IF;
        
        -- nazwa istnieje
        SELECT COUNT(*) INTO ile
        FROM Bandy
        WHERE nazwa = nzb;
        
        IF ile > 0 THEN
            RAISE nazwa_istnieje;
        END IF;
        
        SELECT COUNT(*) INTO ile
        FROM Bandy
        WHERE teren = trn;
        
        IF ile > 0 THEN
            RAISE teren_istnieje;
        END IF;
        
        INSERT INTO Bandy
        VALUES(nrb, nzb, trn, NULL);
    EXCEPTION
        WHEN nazwa_istnieje THEN RAISE_APPLICATION_ERROR(-20001, 'TAKA NAZWA - ' || nzb || ' JUZ ISTNIEJE!');
        WHEN nr_istnieje THEN RAISE_APPLICATION_ERROR(-20002, 'TAKI NUMER - ' || nrb || ' JUZ ISTNIEJE!');
        WHEN nr_ujemny THEN RAISE_APPLICATION_ERROR(-20003, 'NUMER JEST UJEMNY! BANDY PRZYJMUJA TYLKO NUMERY NIEUJEMNE');
        WHEN dlugosc_zla_banda THEN RAISE_APPLICATION_ERROR(-20004, 'NAZWA BANDY MA ZEROWA DLUGOSC!');
        WHEN dlugosc_zly_teren THEN RAISE_APPLICATION_ERROR(-20005, 'TEREN BANDY MA ZLA DLUGOSC !');
        WHEN teren_istnieje THEN RAISE_APPLICATION_ERROR(-20006, 'TEREN BANDY JEST JUZ ZAJETY!');
    END;
END;
/
-- usage, testing, hence the result is with the all other columns that make up the result :)

SELECT DISTINCT K.pseudo, CEIL(0.05*(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0))) podstawa, 2*CONNECT_BY_ISLEAF podwl,
DECODE(WK.pseudo, NULL, 0, 1) wrogowie, DECODE(EXTRACT(MONTH FROM K.w_stadku_od), 3, 1, 0) marzec, koty_funkcje.cat_tax(K.pseudo) podatek
FROM Kocury K LEFT JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
START WITH K.szef IS NULL
CONNECT BY PRIOR K.pseudo = K.szef;



-- TASK 45

CREATE TABLE Dodatki_extra(
    pseudo REFERENCES Kocury(pseudo),
    dod_exta NUMBER
);


CREATE OR REPLACE TRIGGER szpiegowanie_tygrysa
AFTER UPDATE OF przydzial_myszy, myszy_extra ON Kocury 
FOR EACH ROW
FOLLOWS wirus_milusi_compound
WHEN(OLD.funkcja = 'MILUSIA')
DECLARE
    TYPE ps_t IS TABLE OF Kocury.pseudo%TYPE INDEX BY PLS_INTEGER;
    ps_tbl ps_t;
    l_kar NUMBER := 0;
    
    czy_tabela_istnieje NUMBER := 0;
    
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF wirus_compound_state.trigger_lock = FALSE THEN
        SELECT pseudo
        BULK COLLECT INTO ps_tbl
        FROM Kocury
        WHERE funkcja = 'MILUSIA';
        
        
        IF NVL(:NEW.przydzial_myszy ,0) >  NVL(:OLD.przydzial_myszy, 0) AND LOGIN_USER != 'TYGRYS' THEN
            l_kar := l_kar + 1;
            DBMS_OUTPUT.PUT_LINE(:OLD.pseudo || ' - zmiana przydzialu na plus, kary: ' || l_kar);
        END IF;
        
        IF NVL(:NEW.myszy_extra ,0) >  NVL(:OLD.myszy_extra, 0) AND LOGIN_USER != 'TYGRYS' THEN
            l_kar := l_kar + 1;
            DBMS_OUTPUT.PUT_LINE(:OLD.pseudo || ' - zmiana myszy extra na plus, kary: ' || l_kar);
        END IF;
    
        
        FOR i IN 1..l_kar 
        LOOP
            FOR j IN 1..ps_tbl.LAST
            LOOP
                EXECUTE IMMEDIATE 'INSERT INTO DODATKI_EXTRA VALUES(:v1, :v2)'
                USING ps_tbl(j), -10;
            END LOOP;
        END LOOP;
    END IF;
    COMMIT;
END;
/

-- TESTS
SELECT *
FROM Kocury
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = 40, myszy_extra = 50
WHERE pseudo = 'LOLA';

SELECT *
FROM Dodatki_extra;


DELETE
FROM Dodatki_extra;

rollback;


-- TASK 46
drop table wpisy_myszy;

CREATE TABLE wpisy_myszy(
    kto VARCHAR(50),
    komu VARCHAR(15),
    kiedy DATE,
    jaka_operacja VARCHAR(50),
    ile NUMBER
);


CREATE OR REPLACE TRIGGER kontrola_wpisow
BEFORE INSERT OR UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW
DECLARE
    mi_myszy Funkcje.min_myszy%TYPE;
    ma_myszy Funkcje.max_myszy%TYPE;
    
    funkcja_null EXCEPTION;
    funkcja_change EXCEPTION;
    przydzial_poza_przedzialem EXCEPTION;
    kto VARCHAR(100);
    
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
IF wirus_compound_state.trigger_lock = FALSE THEN
    kto := LOGIN_USER;
    
    -- CHECKING IF FUNCTION IS DEFINED, IF ITS NOT THEN DO NOT ALLOW UPDATING przydzial_myszy OR INSERTING rows
    IF INSERTING AND :NEW.funkcja IS NULL THEN
        RAISE funkcja_null;
    END IF;
    
    IF UPDATING AND (:OLD.funkcja IS NULL OR :NEW.funkcja IS NULL) THEN
        RAISE funkcja_null;
    END IF;
    
    IF UPDATING AND (:OLD.funkcja != :NEW.funkcja) THEN
        RAISE funkcja_change;
    END IF;
    
    SELECT min_myszy, max_myszy INTO mi_myszy, ma_myszy
    FROM Funkcje
    WHERE funkcja = :NEW.funkcja;
    
    IF NVL(:NEW.przydzial_myszy, 0) NOT BETWEEN mi_myszy AND ma_myszy THEN
        IF INSERTING THEN
            INSERT INTO wpisy_myszy(kto, komu, kiedy, jaka_operacja, ile)
            VALUES(kto, :NEW.pseudo, SYSDATE, 'INSERT', :NEW.przydzial_myszy);
        ELSIF UPDATING THEN
            INSERT INTO wpisy_myszy(kto, komu, kiedy, jaka_operacja, ile)
            VALUES(kto, :OLD.pseudo, SYSDATE, 'UPDATE', :NEW.przydzial_myszy);
        END IF;
        COMMIT;
        RAISE przydzial_poza_przedzialem;
    END IF;
END IF;

EXCEPTION
    WHEN funkcja_null THEN RAISE_APPLICATION_ERROR(-20042, 'Kot musi miec przydzilona funkcje!');
    WHEN funkcja_change THEN RAISE_APPLICATION_ERROR(-20043, 'Zabrania sie zmiany funkcji przy jednoczesnej zmianie przydzialu myszy!');
    WHEN przydzial_poza_przedzialem THEN RAISE_APPLICATION_ERROR(-20044, 'Przydzial poza przedzialem zdefiniowanym przez funkcje!');
END;
/

SELECT *
FROM Kocury
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = 50, myszy_extra = 50
WHERE pseudo = 'LOLA';


INSERT INTO KOCURY(imie, pseudo)
VALUES('NAMEE', 'sads');


INSERT INTO KOCURY(imie, pseudo, funkcja)
VALUES('NAMEE', 'sads', 'KOT');


INSERT INTO KOCURY(imie, pseudo, funkcja, przydzial_myszy)
VALUES('NAMEE', 'sads', 'KOT', 35);

SELECT *
FROM funkcje;

SELECT *
FROM wpisy_myszy;

DELETE FROM wpisy_myszy;

rollback;





