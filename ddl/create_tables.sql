-- Tablespace config

CREATE TABLESPACE USERS
DATAFILE 'users01.dbf'
SIZE 100M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;

ALTER USER wiktor DEFAULT TABLESPACE USERS;

-- TABLE Funkcje

CREATE TABLE Funkcje
(
    funkcja VARCHAR2(10) CONSTRAINT funkcje_pk PRIMARY KEY,
    min_myszy NUMBER(3) CONSTRAINT funkcje_min_my_ch CHECK(min_myszy > 5),
    max_myszy NUMBER(3),
    CONSTRAINT funkcje_max_my_ch CHECK(max_myszy BETWEEN min_myszy AND 199)
);

-- TABLE Wrogowie

CREATE TABLE Wrogowie
(
    imie_wroga VARCHAR2(15) CONSTRAINT wrogowie_pk PRIMARY KEY,
    stopien_wrogosci NUMBER(2) CONSTRAINT wrogowie_st_wr_ch CHECK(stopien_wrogosci BETWEEN 1 AND 10),
    gatunek VARCHAR2(15),
    lapowka VARCHAR2(20)
);

-- TABLE Bandy

CREATE TABLE Bandy
(
    nr_bandy NUMBER(2) CONSTRAINT bandy_pk PRIMARY KEY,
    nazwa VARCHAR2(20) CONSTRAINT bandy_na_nn NOT NULL,
    teren VARCHAR2(15) CONSTRAINT bandy_te_uq UNIQUE,
    szef_bandy VARCHAR(15) CONSTRAINT bandy_szb_uq UNIQUE
);

-- TABLE Kocury

CREATE TABLE Kocury
(
    imie VARCHAR2(15) CONSTRAINT kocury_im_nn NOT NULL,
    plec VARCHAR2(1) CONSTRAINT kocury_pl_ch CHECK(plec IN ('M', 'D')),
    pseudo VARCHAR2(15) CONSTRAINT kocury_pk PRIMARY KEY,
    funkcja VARCHAR2(10) CONSTRAINT kocury_fu_fk REFERENCES Funkcje(funkcja),
    szef VARCHAR(15) CONSTRAINT kocury_sz_fk REFERENCES KOCURY(pseudo),
    w_stadku_od DATE DEFAULT SYSDATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2) CONSTRAINT kocury_nrb_fk REFERENCES Bandy(nr_bandy)
);

-- ALTER TABLE Bandy - Kocury now exist so there can be a foreign key to Kocury

ALTER TABLE Bandy
ADD CONSTRAINT bandy_szb_fk FOREIGN KEY(szef_bandy) REFERENCES Kocury(pseudo);

-- CREATE TABLE Wrogowie_kocurow

CREATE TABLE Wrogowie_kocurow
(
    pseudo VARCHAR2(15) CONSTRAINT wrogowie_kocurow_ps_fk REFERENCES Kocury(pseudo),
    imie_wroga VARCHAR2(15) CONSTRAINT wrogowie_kocurow_im_wr_fk REFERENCES Wrogowie(imie_wroga),
    data_incydentu DATE CONSTRAINT wrogowie_kocurow_di_nn NOT NULL,
    opis_incydentu VARCHAR2(50),
    CONSTRAINT wrogowie_kocurow_pk PRIMARY KEY(pseudo, imie_wroga)
);