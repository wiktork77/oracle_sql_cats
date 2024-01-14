SET SERVEROUTPUT ON;

-- Zad 34
DECLARE
    ile NUMBER;
    f Kocury.funkcja%TYPE;
BEGIN
    SELECT COUNT(pseudo), funkcja
    INTO ile, f
    FROM Kocury WHERE funkcja=(UPPER('&fn'))
    GROUP BY funkcja;
    IF ile > 0 THEN dbms_output.put_line('Znaleziono koty pelniace funkcje ' || f);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN dbms_output.put_line('Nie znaleziono kota o podanej funkcji!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;


-- Zad 35
DECLARE
    roczny_przydzial NUMBER;
    imie Kocury.imie%TYPE;
    data_przystapienia Kocury.w_stadku_od%TYPE;
    miesiac NUMBER;
BEGIN
    SELECT (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))*12, imie, w_stadku_od
    INTO roczny_przydzial, imie, data_przystapienia
    FROM Kocury WHERE pseudo=UPPER('&pseudo');
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



SELECT imie, NVL(przydzial_myszy, 0) przydzial
FROM Kocury
ORDER BY przydzial ASC;

-- Zad 36
DECLARE
    suma_przydzialow NUMBER default 0;
    liczba_zmian NUMBER := 0;
    
    CURSOR kursor_koty IS
        SELECT imie, NVL(przydzial_myszy, 0) przydzial, funkcja
        FROM Kocury
        ORDER BY przydzial
    FOR UPDATE OF przydzial_myszy;
    max_przydzial NUMBER;
    wiersz kursor_koty%ROWTYPE;
    sa_koty BOOLEAN:= false;
    BRAK_DANYCH EXCEPTION;
BEGIN
    SELECT SUM(NVL(przydzial_myszy, 0))
    INTO suma_przydzialow
    FROM Kocury;
    <<zewn>>LOOP
        OPEN kursor_koty;
        
        LOOP 
            FETCH kursor_koty INTO wiersz;
            EXIT WHEN kursor_koty%NOTFOUND;
            
            IF (NOT sa_koty) THEN sa_koty:=true;
            END IF;
            -- !
            SELECT max_myszy INTO max_przydzial FROM funkcje WHERE funkcja=wiersz.funkcja;
            
            IF (1.1*wiersz.przydzial <= max_przydzial) THEN
                suma_przydzialow := suma_przydzialow + ROUND(0.1*wiersz.przydzial);
                UPDATE Kocury
                SET przydzial_myszy=ROUND(1.1*wiersz.przydzial)
                WHERE CURRENT OF kursor_koty;
                liczba_zmian := liczba_zmian + 1;
            ELSIF (wiersz.przydzial != max_przydzial) THEN
                suma_przydzialow := suma_przydzialow + (max_przydzial - wiersz.przydzial);
                UPDATE Kocury
                SET przydzial_myszy=max_przydzial
                WHERE CURRENT OF kursor_koty;
                liczba_zmian := liczba_zmian + 1;
            END IF;
            
            EXIT zewn WHEN suma_przydzialow > 1050;
        END LOOP;
        IF sa_koty=false THEN
            RAISE brak_danych;
        END IF;
        CLOSE kursor_koty;
    END LOOP zewn;
    dbms_output.put_line('zmiany: ' || liczba_zmian);
    dbms_output.put_line('suma: ' || suma_przydzialow);
    
    EXCEPTION
    WHEN BRAK_DANYCH
        THEN dbms_output.put_line('Brak kotow!');
    WHEN OTHERS
        THEN dbms_output.put_line(SQLERRM);
END;

SELECT imie, NVL(przydzial_myszy, 0) "Myszki po podwyzce"
FROM Kocury;

ROLLBACK;


-- Zad 37

DECLARE
    CURSOR kursor_koty IS
    SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) przydzial_calk
    FROM Kocury
 --   WHERE funkcja='MILUSIA'
 --   WHERE pseudo='abc'
    ORDER BY przydzial_calk DESC;
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
        dbms_output.put_line(nr_kota || '   ' || kot.pseudo || LPAD(kot.przydzial_calk, 17-LENGTH(kot.pseudo), ' '));
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


-- Zad 38
DECLARE
    przelozeni NUMBER := &liczba_przelozonych;
    max_przelozeni NUMBER;
    poziom NUMBER default 0;
    kot Kocury%ROWTYPE;
    UJEMNI_PRZELOZENI EXCEPTION;
    CURSOR koty_kursor IS
    SELECT * FROM Kocury WHERE funkcja IN ('KOT', 'MILUSIA');
BEGIN
    SELECT MAX(LEVEL) - 1 INTO max_przelozeni FROM Kocury CONNECT BY PRIOR szef=pseudo START WITH FUNKCJA IN ('KOT', 'MILUSIA');
    IF (przelozeni > max_przelozeni) THEN przelozeni:=max_przelozeni;
    END IF;
    IF (przelozeni < 0) THEN RAISE UJEMNI_PRZELOZENI;
    END IF;
    
    dbms_output.put(RPAD('Imie', 15, ' '));
    FOR i in 1..przelozeni
    LOOP
        dbms_output.put('|  ' || RPAD('Szef ' || i, 15));
    END LOOP;
    dbms_output.new_line();
    dbms_output.put('------------- ');
    
    
    FOR i in 1..przelozeni
    LOOP
        dbms_output.put('--- ------------- ');
    END LOOP;
    dbms_output.new_line();
    
    
    FOR korzen IN koty_kursor
    LOOP
        kot := korzen;
        poziom := 0;
        dbms_output.put(RPAD(kot.imie, 15, ' ' ));
        WHILE poziom < przelozeni
        LOOP
            IF (kot.szef IS NOT NULL) THEN
                SELECT * INTO kot FROM Kocury WHERE pseudo = kot.szef;
                dbms_output.put('|  '  || RPAD(kot.imie, 15, ' '));
            ELSE
                dbms_output.put(RPAD('|  ', 18, ' '));
            END IF;
            poziom := poziom + 1;
        END LOOP;
        dbms_output.new_line();
    END LOOP;
EXCEPTION
    WHEN UJEMNI_PRZELOZENI THEN dbms_output.put_line('Liczba przelozonych nie moze byc ujemna!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;


-- Zad 39
DECLARE
    nr Bandy.nr_bandy%TYPE:=&nr_bandy;
    nazwab Bandy.nazwa%TYPE:=UPPER('&nazwa_bandy');
    terenb Bandy.teren%TYPE:=UPPER('&teren_bandy');
    wiadomosc_wyjatku VARCHAR2(50):='';
    l_znalezionych NUMBER default 0;
    ISTNIEJE EXCEPTION;
    ZLY_NUMER EXCEPTION;
    
BEGIN
    IF (nr < 0) THEN RAISE ZLY_NUMER;
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE nr_bandy=nr;
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || nr || ', ' ;
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE nazwa=nazwab;
    
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || nazwab || ', ';
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE teren=terenb;
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || terenb || ', ' ;
    END IF;
    
    IF (LENGTH(wiadomosc_wyjatku) > 0) THEN
        RAISE ISTNIEJE;
    END IF;
    
    INSERT INTO BANDY(nr_bandy, nazwa, teren) VALUES(nr, nazwab, terenb);
    
EXCEPTION
    WHEN ZLY_NUMER THEN dbms_output.put_line('Nalezy podac nieujemny numer bandy!!');
    WHEN ISTNIEJE THEN dbms_output.put_line(SUBSTR(wiadomosc_wyjatku, 0, LENGTH(wiadomosc_wyjatku) - 2) || ': juz istnieje');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;

ROLLBACK;


-- Zad 40
CREATE OR REPLACE PROCEDURE dodaj_bande(nr Bandy.nr_bandy%TYPE, nazwab Bandy.nazwa%TYPE, terenb Bandy.teren%TYPE)
IS
    wiadomosc_wyjatku VARCHAR2(50):='';
    l_znalezionych NUMBER default 0;
    ISTNIEJE EXCEPTION;
    ZLY_NUMER EXCEPTION;
BEGIN
    IF (nr < 0) THEN RAISE ZLY_NUMER;
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE nr_bandy=nr;
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || nr || ', ' ;
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE UPPER(nazwa)=UPPER(nazwab);
    
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || nazwab || ', ';
    END IF;
    
    SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE UPPER(teren)=UPPER(terenb);
    IF (l_znalezionych > 0) THEN
        wiadomosc_wyjatku := wiadomosc_wyjatku || terenb || ', ' ;
    END IF;
    
    IF (LENGTH(wiadomosc_wyjatku) > 0) THEN
        RAISE ISTNIEJE;
    END IF;
    
    INSERT INTO BANDY(nr_bandy, nazwa, teren) VALUES(nr, nazwab, terenb);
EXCEPTION
    WHEN ZLY_NUMER THEN dbms_output.put_line('Nalezy podac nieujemny numer bandy!!');
    WHEN ISTNIEJE THEN dbms_output.put_line(SUBSTR(wiadomosc_wyjatku, 0, LENGTH(wiadomosc_wyjatku) - 2) || ': juz istnieje');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;

EXECUTE dodaj_bande(1, 'a', 'SAD');
EXECUTE dodaj_bande(7, 'NOWI', 'SMIETNIK');
EXECUTE dodaj_bande(-2, 'Czarni rycerze', 'Calosc');
EXECUTE dodaj_bande(22, 'Czarni rycerze', 'Calosc');
EXECUTE dodaj_bande(0, 'a', 'b');
ROLLBACK;


-- Zad 41
CREATE OR REPLACE TRIGGER numery_po_kolei
BEFORE INSERT ON Bandy
FOR EACH ROW
DECLARE
    najwyzszy_nr NUMBER;
BEGIN
    SELECT MAX(nr_bandy) INTO najwyzszy_nr FROM Bandy;
    :NEW.nr_bandy := najwyzszy_nr + 1;
END;

EXECUTE dodaj_bande(23, 'Nowi', 'Smietnik');
ROLLBACK;



-- Zad 42
CREATE OR REPLACE PACKAGE dane IS
    kara NUMBER := 0;
    nagroda NUMBER := 0;
    przydzial Kocury.przydzial_myszy%TYPE;
END;

CREATE OR REPLACE TRIGGER przed_zmiana
BEFORE UPDATE OF przydzial_myszy
ON Kocury
BEGIN
    SELECT przydzial_myszy INTO dane.przydzial FROM Kocury WHERE pseudo='TYGRYS';
END;

CREATE OR REPLACE TRIGGER sprawdzenie_zmiany
BEFORE UPDATE OF przydzial_myszy
ON Kocury
FOR EACH ROW
BEGIN
    IF (:NEW.funkcja='MILUSIA') THEN
        IF (:NEW.przydzial_myszy <= :OLD.przydzial_myszy) THEN
            dbms_output.put_line('BRAK ZMIANY!');
            :NEW.przydzial_myszy := :OLD.przydzial_myszy;
        ELSIF (:NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1*dane.przydzial) THEN
            dbms_output.put_line('Za mala podwyzka');
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + 0.1*dane.przydzial;
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            dane.kara := dane.kara + 1;
        ELSE
            dbms_output.put_line('Zadowalajaca podwyzka');
            dane.nagroda := dane.nagroda + 1;
        END IF;
    END IF;
END;

CREATE OR REPLACE TRIGGER po_zmianach_rozliczenie_tygrysa
AFTER UPDATE OF przydzial_myszy
ON Kocury
DECLARE
    przydzial Kocury.przydzial_myszy%TYPE := dane.przydzial;
    tygrys_extra Kocury.myszy_extra%TYPE;
BEGIN
    SELECT myszy_extra INTO tygrys_extra FROM Kocury WHERE pseudo='TYGRYS';
    przydzial := przydzial - dane.kara*ROUND(0.1*dane.przydzial);
    tygrys_extra := tygrys_extra + dane.nagroda*5;
    
    IF (dane.nagroda <> 0 OR dane.kara <> 0) THEN
        dane.nagroda := 0;
        dane.kara := 0;
        UPDATE Kocury
        SET przydzial_myszy = przydzial,
            myszy_extra = tygrys_extra
        WHERE pseudo = 'TYGRYS';
    END IF;
END;



-- wszystkie podwyzki za male
UPDATE Kocury
SET przydzial_myszy = 26
WHERE funkcja ='MILUSIA';

-- wszystkie podwyzki dobre
UPDATE Kocury
SET przydzial_myszy = 60
WHERE funkcja ='MILUSIA';


-- Z: 3, N: 1
UPDATE Kocury
SET przydzial_myszy = 35
WHERE funkcja ='MILUSIA';

-- Z:1, N:3
UPDATE Kocury
SET przydzial_myszy = 32
WHERE funkcja ='MILUSIA';


-- PO ROWNO
UPDATE Kocury
SET przydzial_myszy = 33
WHERE funkcja ='MILUSIA';


SELECT * FROM Kocury;
ROLLBACK;


DROP TRIGGER przed_zmiana;
DROP TRIGGER sprawdzenie_zmiany;
DROP TRIGGER po_zmianach_rozliczenie_tygrysa;
DROP PACKAGE dane;


CREATE OR REPLACE TRIGGER wyzwalacz_zlozony
FOR UPDATE OF przydzial_myszy
ON Kocury
COMPOUND TRIGGER
    kara NUMBER := 0;
    nagroda NUMBER := 0;
    przydzial Kocury.przydzial_myszy%TYPE;
    tygrys_extra Kocury.myszy_extra%TYPE;
    
    BEFORE STATEMENT IS
    BEGIN
        SELECT przydzial_myszy, myszy_extra INTO przydzial, tygrys_extra FROM Kocury WHERE pseudo='TYGRYS';
    END BEFORE STATEMENT;
    
    BEFORE EACH ROW IS
    BEGIN
        IF (:NEW.funkcja='MILUSIA') THEN
            IF (:NEW.przydzial_myszy <= :OLD.przydzial_myszy) THEN
                dbms_output.put_line('BRAK ZMIANY!');
                :NEW.przydzial_myszy := :OLD.przydzial_myszy;
            ELSIF (:NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1*przydzial) THEN
                dbms_output.put_line('Za mala podwyzka');
                :NEW.przydzial_myszy := :NEW.przydzial_myszy + 0.1*przydzial;
                :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
                kara := kara + 1;
            ELSE
                dbms_output.put_line('Zadowalajaca podwyzka');
                nagroda := nagroda + 1;
            END IF;
    END IF;
    END BEFORE EACH ROW;
    
    AFTER STATEMENT IS
    BEGIN
        przydzial := przydzial - kara*ROUND(0.1*przydzial);
        tygrys_extra := tygrys_extra + nagroda*5;
    
    IF (nagroda <> 0 OR kara <> 0) THEN
        nagroda := 0;
        kara := 0;
        UPDATE Kocury
        SET przydzial_myszy = przydzial,
            myszy_extra = tygrys_extra
        WHERE pseudo = 'TYGRYS';
    END IF;
    END AFTER STATEMENT;
END;


-- zad 43 - propozycja
DECLARE
suma NUMBER DEFAULT 0;
CURSOR funkcje_kursor IS
SELECT F.funkcja fun, NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)),0) ile FROM Kocury K RIGHT JOIN Funkcje F ON K.funkcja = F.funkcja
GROUP BY F.funkcja
ORDER BY fun;

CURSOR bandy_plcie IS
SELECT B.nazwa, (CASE K.plec WHEN 'D' THEN 'Kotka' ELSE 'Kocor' END) plec , COUNT(K.plec) ile, NVL(SUM(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)), 0) suma
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nazwa, K.plec
ORDER BY B.nazwa, K.plec;

CURSOR kto_ile IS
SELECT B.nazwa, F.funkcja,
MIN((SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0) FROM Kocury WHERE nr_bandy=B.nr_bandy AND funkcja=F.funkcja AND plec=K.plec)) ile_myszy
FROM Bandy B JOIN Funkcje F ON 1=1 JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nazwa, F.funkcja, K.plec
ORDER BY B.nazwa, K.plec, F.funkcja;

funkcje_zjada kto_ile%ROWTYPE;


PROCEDURE make_header IS
    BEGIN
        dbms_output.put(RPAD('NAZWA BANDY', 18, ' '));
        dbms_output.put(RPAD('PLEC', 7, ' '));
        dbms_output.put(LPAD('ILE', 4, ' '));

        FOR el IN funkcje_kursor
        LOOP
            dbms_output.put(' ' || LPAD(el.fun, 9, ' '));
        END LOOP;

        dbms_output.put(' ' || LPAD('SUMA', 9, ' '));
        dbms_output.new_line();
END make_header;

PROCEDURE make_lines IS
    BEGIN
        dbms_output.put('----------------- ------ ----');
        FOR el IN funkcje_kursor
        LOOP
            dbms_output.put(' ' || LPAD('-', 9, '-') );
        END LOOP; 
        dbms_output.put(' ' || LPAD('-', 9, '-') );
        dbms_output.new_line();
    END make_lines;
BEGIN
    make_header;
    make_lines;
    OPEN kto_ile;
    -- O(funkcje*bandy*2*bandy) = O(2*funkcje*bandy^2)
    FOR el IN bandy_plcie
    LOOP
        dbms_output.put(RPAD((CASE el.plec WHEN 'Kotka' THEN el.nazwa ELSE ' ' END), 18, ' '));
        dbms_output.put(RPAD(el.plec, 7, ' '));
        dbms_output.put(LPAD(el.ile, 4, ' '));
        FOR f IN funkcje_kursor
        LOOP
            FETCH kto_ile INTO funkcje_zjada;
            dbms_output.put(LPAD(funkcje_zjada.ile_myszy, 10, ' ') );
        END LOOP;
        dbms_output.put(LPAD(el.suma, 10, ' '));
        dbms_output.new_line();
    END LOOP;
    CLOSE kto_ile;
    
    make_lines;
    dbms_output.put(RPAD('ZJADA RAZEM', 18, ' '));
    dbms_output.put(RPAD(' ', 7, ' '));
    dbms_output.put(LPAD(' ', 4, ' '));
    FOR el in funkcje_kursor
    LOOP
        dbms_output.put(LPAD(el.ile, 10, ' ') );
        suma := suma + el.ile;
    END LOOP;
    dbms_output.put(LPAD(suma, 10, ' ') );
    dbms_output.new_line();
END;


--SELECT B.nazwa, (CASE K.plec WHEN 'D' THEN 'Kotka' ELSE 'Kocor' END) plec , COUNT(K.plec) ile, NVL(SUM(NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0)), 0) suma
--FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
--GROUP BY B.nazwa, K.plec
--ORDER BY B.nazwa, K.plec;
--
--SELECT B.nazwa, F.funkcja,
--MIN((SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0) FROM Kocury WHERE nr_bandy=B.nr_bandy AND funkcja=F.funkcja AND plec=K.plec)) ile_myszy
--FROM Bandy B JOIN Funkcje F ON 1=1 JOIN Kocury K ON B.nr_bandy = K.nr_bandy
--GROUP BY B.nazwa, F.funkcja, K.plec
--ORDER BY B.nazwa, K.plec, F.funkcja;


-- Zad 44

CREATE OR REPLACE FUNCTION podatek(pseudonim Kocury.pseudo%TYPE) return NUMBER IS
ile_podatku NUMBER default 0;
ile_wystapien NUMBER default 0;
kot KOCURY%ROWTYPE;
BEGIN
    SELECT * INTO kot FROM Kocury WHERE pseudo=UPPER(pseudonim);
    ile_podatku := CEIL(0.05*(NVL(kot.przydzial_myszy, 0) + NVL(kot.myszy_extra, 0)));
    dbms_output.put_line(kot.pseudo || ' -> bazowy podatek = ' || ile_podatku);
    SELECT COUNT(*) INTO ile_wystapien FROM Kocury WHERE szef=kot.pseudo;
    IF (ile_wystapien = 0) THEN
        dbms_output.put_line(kot.pseudo || ' -> brak podwladnych (+ 2)');
        ile_podatku := ile_podatku + 2;
    END IF;
    
    SELECT COUNT(*) INTO ile_wystapien FROM Wrogowie_Kocurow WHERE pseudo=kot.pseudo;
    IF (ile_wystapien = 0) THEN
        dbms_output.put_line(kot.pseudo || ' -> brak wrogow (+ 1)');
        ile_podatku := ile_podatku + 1;
    END IF;
    
    SELECT REGEXP_COUNT(kot.imie, 'K') INTO ile_wystapien FROM dual;
    ile_podatku := ile_podatku + 5*ile_wystapien;
    dbms_output.put_line(kot.pseudo || ' -> ' || ile_wystapien || ' wystapien litery K w imieniu -> (+ ' || 5*ile_wystapien || ')');
    
    return ile_podatku;
EXCEPTION
    WHEN NO_DATA_FOUND THEN dbms_output.put_line('Nie znaleziono kota.'); return 0;
END;



CREATE OR REPLACE PACKAGE podatek_koty IS
    FUNCTION podatek(pseudonim Kocury.pseudo%TYPE) return NUMBER;
    PROCEDURE dodaj_bande(nr Bandy.nr_bandy%TYPE, nazwab Bandy.nazwa%TYPE, terenb Bandy.teren%TYPE);
END podatek_koty;


CREATE OR REPLACE PACKAGE BODY podatek_koty IS
    FUNCTION podatek(pseudonim Kocury.pseudo%TYPE) return NUMBER IS
        ile_podatku NUMBER default 0;
        ile_wystapien NUMBER default 0;
        kot KOCURY%ROWTYPE;
    BEGIN
        SELECT * INTO kot FROM Kocury WHERE pseudo=UPPER(pseudonim);
        ile_podatku := CEIL(0.05*(NVL(kot.przydzial_myszy, 0) + NVL(kot.myszy_extra, 0)));
        dbms_output.put_line(kot.pseudo || ' -> bazowy podatek = ' || ile_podatku);
        SELECT COUNT(*) INTO ile_wystapien FROM Kocury WHERE szef=kot.pseudo;
        IF (ile_wystapien = 0) THEN
            dbms_output.put_line(kot.pseudo || ' -> brak podwladnych (+ 2)');
            ile_podatku := ile_podatku + 2;
        END IF;
        
        SELECT COUNT(*) INTO ile_wystapien FROM Wrogowie_Kocurow WHERE pseudo=kot.pseudo;
        IF (ile_wystapien = 0) THEN
            dbms_output.put_line(kot.pseudo || ' -> brak wrogow (+ 1)');
            ile_podatku := ile_podatku + 1;
        END IF;
        
        SELECT REGEXP_COUNT(kot.imie, 'K') INTO ile_wystapien FROM dual;
        ile_podatku := ile_podatku + 5*ile_wystapien;
        dbms_output.put_line(kot.pseudo || ' -> ' || ile_wystapien || ' wystapien litery K w imieniu -> (+ ' || 5*ile_wystapien || ')');
        
        return ile_podatku;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN dbms_output.put_line('Nie znaleziono kota.'); return 0;
    END;
    
    PROCEDURE dodaj_bande(nr Bandy.nr_bandy%TYPE, nazwab Bandy.nazwa%TYPE, terenb Bandy.teren%TYPE) IS
        wiadomosc_wyjatku VARCHAR2(50):='';
        l_znalezionych NUMBER default 0;
        ISTNIEJE EXCEPTION;
        ZLY_NUMER EXCEPTION;
    BEGIN
        IF (nr < 0) THEN RAISE ZLY_NUMER;
        END IF;
        
        SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE nr_bandy=nr;
        IF (l_znalezionych > 0) THEN
            wiadomosc_wyjatku := wiadomosc_wyjatku || nr || ', ' ;
        END IF;
        
        SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE UPPER(nazwa)=UPPER(nazwab);
        
        IF (l_znalezionych > 0) THEN
            wiadomosc_wyjatku := wiadomosc_wyjatku || nazwab || ', ';
        END IF;
        
        SELECT COUNT(*) INTO l_znalezionych FROM Bandy WHERE UPPER(teren)=UPPER(terenb);
        IF (l_znalezionych > 0) THEN
            wiadomosc_wyjatku := wiadomosc_wyjatku || terenb || ', ' ;
        END IF;
        
        IF (LENGTH(wiadomosc_wyjatku) > 0) THEN
            RAISE ISTNIEJE;
        END IF;
        
        INSERT INTO BANDY(nr_bandy, nazwa, teren) VALUES(nr, nazwab, terenb);
    EXCEPTION
        WHEN ZLY_NUMER THEN dbms_output.put_line('Nalezy podac nieujemny numer bandy!!');
        WHEN ISTNIEJE THEN dbms_output.put_line(SUBSTR(wiadomosc_wyjatku, 0, LENGTH(wiadomosc_wyjatku) - 2) || ': juz istnieje');
        WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
    END;
END;

DECLARE
    podatek NUMBER;
    CURSOR koty_kursor IS
    SELECT pseudo FROM Kocury;
BEGIN
    FOR k IN koty_kursor
    LOOP
        podatek := podatek_koty.podatek(k.pseudo);
        dbms_output.put_line('Podatek dla ' || k.pseudo || ': ' || podatek);
    END LOOP;
END;


-- Zad 45
CREATE TABLE Dodatki_extra(
    pseudo VARCHAR2(15) CONSTRAINT dodatki_pseudo_fk REFERENCES Kocury(pseudo),
    dod_extra NUMBER(3) DEFAULT 0    
);
DROP TABLE Dodatki_extra;

CREATE OR REPLACE TRIGGER kontrola_milus
BEFORE UPDATE ON Kocury
FOR EACH ROW
DECLARE
    liczba_wystapien NUMBER;
    polecenie VARCHAR(1000);
    CURSOR milusie_kursor IS
    SELECT * FROM Kocury WHERE funkcja='MILUSIA';
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF (LOGIN_USER != 'TYGRYS' AND :NEW.funkcja='MILUSIA' AND :NEW.przydzial_myszy > :OLD.przydzial_myszy) THEN
        FOR m IN milusie_kursor
        LOOP
            SELECT COUNT(*) INTO liczba_wystapien FROM Dodatki_extra WHERE pseudo=m.pseudo;
            IF (liczba_wystapien > 0) THEN
                polecenie := 'UPDATE Dodatki_extra SET dod_extra=dod_extra-10 WHERE pseudo=:arg';
            ELSE
                polecenie := 'INSERT INTO Dodatki_extra (pseudo, dod_extra) VALUES(:arg, -10)';
            END IF;
            EXECUTE IMMEDIATE polecenie USING m.pseudo;
        END LOOP;
        COMMIT;
    END IF;
END;

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 100
WHERE funkcja = 'MILUSIA';


ROLLBACK;





-- Zad 46
CREATE TABLE Proby_wykroczenia 
(
    kto VARCHAR2(15) NOT NULL, 
    kiedy DATE NOT NULL,
    jakiemu VARCHAR2(15) CONSTRAINT fkj_pseudo REFERENCES KOCURY(PSEUDO),
    operacja VARCHAR2(15) NOT NULL
);

DROP TABLE Proby_wykroczenia;


CREATE OR REPLACE TRIGGER myszy_w_przedziale
BEFORE INSERT OR UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW
DECLARE
    minim Funkcje.min_myszy%TYPE;
    maxim Funkcje.max_myszy%TYPE;
    data_zdarzenia DATE DEFAULT SYSDATE;
    kto VARCHAR(15);
    operacja_info VARCHAR(15);
    poza_przedzialem EXCEPTION;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT min_myszy, max_myszy INTO minim, maxim FROM Funkcje WHERE funkcja = :NEW.funkcja;
    IF (:NEW.przydzial_myszy < minim OR :NEW.przydzial_myszy > maxim) THEN
        IF INSERTING THEN
            operacja_info := 'INSERT';
        ELSIF UPDATING THEN
            operacja_info := 'UPDATE';
        END IF;
        kto := LOGIN_USER;
        INSERT INTO Proby_wykroczenia(kto, kiedy, jakiemu, operacja) VALUES(kto, data_zdarzenia, :NEW.pseudo, operacja_info);
        COMMIT;
        RAISE poza_przedzialem;
    END IF;

EXCEPTION
    WHEN poza_przedzialem THEN :NEW.przydzial_myszy := :OLD.przydzial_myszy; dbms_output.put_line('Wartosc przydzialu wykracza poza zakres funkcji!');
    WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
END;



UPDATE Kocury
SET przydzial_myszy = 31
WHERE pseudo='LOLA';
ROLLBACK;