ALTER TABLE Bandy
DISABLE CONSTRAINT Bandy_szb_fk;

INSERT ALL
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('SZEFUNIO',90,110)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('BANDZIOR',70,90)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('LOWCZY',60,70)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('LAPACZ',50,60)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('KOT',40,50)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('MILUSIA',20,30)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('DZIELCZY',45,55)
INTO Funkcje(funkcja,min_myszy,max_myszy) VALUES('HONOROWA',6,25)
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('KAZIO',10,'CZLOWIEK','FLASZKA')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('GLUPIA ZOSKA',1,'CZLOWIEK','KORALIK')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('SWAWOLNY DYZIO',7,'CZLOWIEK','GUMA DO ZUCIA')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BUREK',4,'PIES','KOSC')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('DZIKI BILL',10,'PIES',NULL)
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('REKSIO',2,'PIES','KOSC')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BETHOVEN',1,'PIES','PEDIGRIPALL')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('CHYTRUSEK',5,'LIS','KURCZAK')
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('SMUKLA',1,'SOSNA',NULL)
INTO Wrogowie(imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BAZYLI',3,'KOGUT','KURA DO STADA')
INTO Bandy(nr_bandy,nazwa,teren,szef_bandy) VALUES(1,'SZEFOSTWO','CALOSC','TYGRYS')
INTO Bandy(nr_bandy,nazwa,teren,szef_bandy) VALUES(2,'CZARNI RYCERZE','POLE','LYSY')
INTO Bandy(nr_bandy,nazwa,teren,szef_bandy) VALUES(3,'BIALI LOWCY','SAD','ZOMBI')
INTO Bandy(nr_bandy,nazwa,teren,szef_bandy) VALUES(4,'LACIACI MYSLIWI','GORKA','RAFA')
INTO Bandy(nr_bandy,nazwa,teren,szef_bandy) VALUES(5,'ROCKERSI','ZAGRODA',NULL)
SELECT * FROM DUAL;

ALTER TABLE Kocury
DISABLE CONSTRAINT Kocury_sz_fk;

INSERT ALL
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('JACEK','M','PLACEK','LOWCZY','LYSY','2008-12-01',67,NULL,2)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('BARI','M','RURA','LAPACZ','LYSY','2009-09-01',56,NULL,2)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('MICKA','D','LOLA','MILUSIA','TYGRYS','2009-10-14',25,47,1)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('LUCEK','M','ZERO','KOT','KURKA','2010-03-01',43,NULL,3)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('SONIA','D','PUSZYSTA','MILUSIA','ZOMBI','2010-11-18',20,35,3)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('LATKA','D','UCHO','KOT','RAFA','2011-01-01',40,NULL,4)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('DUDEK','M','MALY','KOT','RAFA','2011-05-15',40,NULL,4)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('CHYTRY','M','BOLEK','DZIELCZY','TYGRYS','2002-05-05',50,NULL,1)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('KOREK','M','ZOMBI','BANDZIOR','TYGRYS','2004-03-16',75,13,3)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('BOLEK','M','LYSY','BANDZIOR','TYGRYS','2006-08-15',72,21,2)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('ZUZIA','D','SZYBKA','LOWCZY','LYSY','2006-07-21',65,NULL,2)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('RUDA','D','MALA','MILUSIA','TYGRYS','2006-09-17',22,42,1)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('PUCEK','M','RAFA','LOWCZY','TYGRYS','2006-10-15',65,NULL,4)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('PUNIA','D','KURKA','LOWCZY','ZOMBI','2008-01-01',61,NULL,3)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('BELA','D','LASKA','MILUSIA','LYSY','2008-02-01',24,28,2)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('KSAWERY','M','MAN','LAPACZ','RAFA','2008-07-12',51,NULL,4)
INTO Kocury(imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES('MELA','D','DAMA','LAPACZ','RAFA','2008-11-01',51,NULL,4)
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('TYGRYS','KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('ZOMBI','SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('BOLEK','KAZIO','2005-03-29','POSZCZUL BURKIEM')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('SZYBKA','GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('MALA','CHYTRUSEK','2007-03-07','ZALECAL SIE')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('TYGRYS','DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('BOLEK','DZIKI BILL','2007-11-10','ODGRYZL UCHO')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('LASKA','DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('LASKA','KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('DAMA','KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('MAN','REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('LYSY','BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('RURA','DZIKI BILL','2009-09-03','ODGRYZL OGON')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('PLACEK','BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('PUSZYSTA','SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('KURKA','BUREK','2010-12-14','POGONIL')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('MALY','CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA')
INTO Wrogowie_kocurow(pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES('UCHO','SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI')
SELECT * FROM DUAL;

ALTER TABLE Bandy
ENABLE CONSTRAINT Bandy_szb_fk;

ALTER TABLE Kocury
ENABLE CONSTRAINT Kocury_sz_fk;

COMMIT;