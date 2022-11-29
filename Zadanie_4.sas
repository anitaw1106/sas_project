

/* ---------------------PRZYGOTOWANIE DANYCH--------------------- */
/* ---------------------DANE TRAIN--------------------- */

/*Stworzenie tabeli wynikowej dla wyliczonej kurtozy
oraz wskaünika zmiennoúci dla danych wartoúci period - dane train*/
proc means data=project.abt_sam_beh_train kurt cv maxdec=2 noprint;
	var act_: app_income app_number_of_children app_spendings;
	class period;
	output out=project.statystyki_treningowe
			kurt= cv= / autoname;
run;


/* KURTOZA */
/* Przygotowanie tabeli wynikowej z kurtozπ dla kaødej ze zmiennych
oraz dla wszystkich okresÛw, posortowanej malejπco pod wzglÍdem
wartoúci kurtozy - dane train */
proc sql;
	select name into :lista_zmiennych seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="STATYSTYKI_TRENINGOWE" and (name LIKE "period" or name LIKE "_FREQ_" or name LIKE "_TYPE_" or name LIKE "%Kurt");
quit;

proc sql;
	create table project.kurtoza_dla_train as
	select &lista_zmiennych
	from project.statystyki_treningowe
	where period="";
quit;

proc sql;
	select name into :lista_zmiennych2 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="KURTOZA_DLA_TRAIN" and name LIKE "%Kurt";
quit;

proc sql;
	create table project.suma_kurtoza_train as
	select &lista_zmiennych2
	from project.kurtoza_dla_train;
quit;

proc transpose data=project.suma_kurtoza_train
	out=project.suma_kurtoza_train;
run;

proc sql;
	create table project.all_kurtoza_train as
	select _NAME_ as Variable, round(COL1, 0.01) as Kurtoza
	from project.suma_kurtoza_train
	order by Kurtoza desc;
quit;

/* WSKAèNIK ZMIENNOåCI */
/* Przygotowanie tabeli wynikowej z wskaünikiem zmiennoúci dla kaødej ze zmiennych
oraz dla wszystkich okresÛw, posortowanej malejπco pod wzglÍdem
wskaünika zmiennoúci - dane train */
proc sql;
	select name into :lista_zmiennych4 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="STATYSTYKI_TRENINGOWE" and (name LIKE "period" or name LIKE "_FREQ_" or name LIKE "_TYPE_" or name LIKE "%CV");
quit;

proc sql;
	create table project.wsk_zmiennosci_train as
	select &lista_zmiennych4
	from project.statystyki_treningowe
	where period="";
quit;

proc sql;
	select name into :lista_zmiennych5 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="WSK_ZMIENNOSCI_TRAIN" and name LIKE "%CV";
quit;

proc sql;
	create table project.suma_wsk_zmiennosci_train as
	select &lista_zmiennych5
	from project.wsk_zmiennosci_train;
quit;

proc transpose data=project.suma_wsk_zmiennosci_train
	out=project.suma_wsk_zmiennosci_train;
run;

proc sql;
	create table project.all_wsk_zmiennosci_train as
	select _NAME_ as Variable, round(COL1, 0.01) as CV
	from project.suma_wsk_zmiennosci_train
	order by CV desc;
quit;


/* ---------------------DANE VALID--------------------- */
/*Stworzenie tabeli wynikowej dla wyliczonej kurtozy
oraz wskaünika zmiennoúci dla danych wartoúci period - dane valid*/
proc means data=project.abt_sam_beh_valid kurt cv maxdec=2 noprint;
	var act_: app_income app_number_of_children app_spendings;
	class period;
	output out=project.statystyki_walidacyjne
			kurt= cv= / autoname;
run;

/* KURTOZA */
/* Przygotowanie tabeli wynikowej z kurtozπ dla kaødej ze zmiennych
oraz dla wszystkich okresÛw, posortowanej malejπco pod wzglÍdem
wartoúci kurtozy - dane valid */
proc sql;
	select name into :lista_zmiennych3 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="STATYSTYKI_WALIDACYJNE" and (name LIKE "period" or name LIKE "_FREQ_" or name LIKE "_TYPE_" or name LIKE "%Kurt");
quit;

proc sql;
	create table project.kurtoza_dla_valid as
	select &lista_zmiennych3
	from project.statystyki_walidacyjne
	where period="";
quit;

proc sql;
	select name into :lista_zmiennych4 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="KURTOZA_DLA_VALID" and name LIKE "%Kurt";
quit;

proc sql;
	create table project.suma_kurtoza_valid as
	select &lista_zmiennych4
	from project.kurtoza_dla_valid;
quit;

proc transpose data=project.suma_kurtoza_valid
	out=project.suma_kurtoza_valid;
run;

proc sql;
	create table project.all_kurtoza_valid as
	select _NAME_ as Variable, round(COL1, 0.01) as Kurtoza
	from project.suma_kurtoza_valid
	order by Kurtoza desc;
quit;


/* WSKAèNIK ZMIENNOåCI */
/* Przygotowanie tabeli wynikowej z wskaünikiem zmiennoúci dla kaødej ze zmiennych
oraz dla wszystkich okresÛw, posortowanej malejπco pod wzglÍdem
wskaünika zmiennoúci - dane valid */
proc sql;
	select name into :lista_zmiennych6 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="STATYSTYKI_WALIDACYJNE" and (name LIKE "period" or name LIKE "_FREQ_" or name LIKE "_TYPE_" or name LIKE "%CV");
quit;

proc sql;
	create table project.wsk_zmiennosci_valid as
	select &lista_zmiennych6
	from project.statystyki_walidacyjne
	where period="";
quit;

proc sql;
	select name into :lista_zmiennych7 seperated by ","
	from sashelp.vcolumn
	where libname="PROJECT" and memname="WSK_ZMIENNOSCI_VALID" and name LIKE "%CV";
quit;

proc sql;
	create table project.suma_wsk_zmiennosci_valid as
	select &lista_zmiennych7
	from project.wsk_zmiennosci_valid;
quit;

proc transpose data=project.suma_wsk_zmiennosci_valid
	out=project.suma_wsk_zmiennosci_valid;
run;

proc sql;
	create table project.all_wsk_zmiennosci_valid as
	select _NAME_ as Variable, round(COL1, 0.01) as CV
	from project.suma_wsk_zmiennosci_valid
	order by CV desc;
quit;


/* Usuwam tabele, ktÛre nie bÍdπ juø potrzebne w dalszym procesie*/
proc sql;
	drop table PROJECT.WSK_ZMIENNOSCI_TRAIN, PROJECT.SUMA_WSK_ZMIENNOSCI_TRAIN, PROJECT.KURTOZA_DLA_TRAIN, PROJECT.SUMA_KURTOZA_TRAIN, PROJECT.KURTOZA_DLA_VALID, PROJECT.SUMA_KURTOZA_VALID, PROJECT.WSK_ZMIENNOSCI_VALID, PROJECT.SUMA_WSK_ZMIENNOSCI_VALID;
quit;


/* ---------------------WYKRESY--------------------- */
/* ---------------------DANE TRAIN--------------------- */

/* KURTOZA */
pattern color=lime;
proc univariate data=project.all_kurtoza_train;
	var Kurtoza;
	histogram Kurtoza / normal nmidpoints=8;
	title "Rozk≥ad procentowy wartoúci kurtozy na zbiorze train";
run;

proc sql;
create table project.kurtoza_dodatnia_train as
select *
from project.all_kurtoza_train
where Kurtoza > 0;
quit;

title "Dodatnie wartoúci kurtozy na zbiorze train";
proc sgplot data=project.kurtoza_dodatnia_train;
	vbox Kurtoza / 
	fillattrs=(color=lime);
	yaxis type=log logbase=10 logstyle=logexpand;
run;

title "Wykres kube≥kowy dla wszystkich wartoúci kurtozy na zbiorze train";
proc sgplot data=project.all_kurtoza_train;
	vbox Kurtoza / 
	fillattrs=(color=lime);
	yaxis type=log logbase=10 logstyle=logexpand;
run;

/* WSKAèNIK ZMIENNOåCI */
pattern color=lime;
proc univariate data=project.all_wsk_zmiennosci_train;
	var CV;
	histogram CV / normal nmidpoints=8;
	title "Rozk≥ad procentowy wartoúci CV na zbiorze train";
run;

title "Wykres kube≥kowy dla wszystkich wartoúci CV na zbiorze train";
proc sgplot data=project.all_wsk_zmiennosci_train;
	vbox CV / 
	fillattrs=(color=lime);
run;

/* rozk≥ad zmiennej o najwiekszej kurtozie dla zbioru train */
proc sql noprint;
	select Variable as Variable, Kurtoza
	from project.all_kurtoza_train;
quit;

pattern color=lime;
proc univariate data=project.abt_sam_beh_train;
	title "Rozk≥ad act_state_21_Cncr - Kurtoza train";
	var act_state_21_Cncr;
	histogram act_state_21_Cncr / normal nmidpoints=8;
run;

/* rozk≥ad zmiennej o najwiekszym wspÛ≥czynniku zmiennoúci dla zbioru train */
pattern color=lime;
proc univariate data=project.abt_sam_beh_train;
	title "Rozk≥ad act_state_16_CMin_Due - CV train";
	var act_state_16_CMin_Due;
	histogram act_state_16_CMin_Due / normal nmidpoints=8;
run;


/* ---------------------WYKRESY--------------------- */
/* ---------------------DANE VALID--------------------- */

/* KURTOZA */
pattern color=orange;
proc univariate data=project.all_kurtoza_valid;
	var Kurtoza;
	histogram Kurtoza / normal nmidpoints=8;
	title "Rozk≥ad procentowy wartoúci kurtozy na zbiorze valid";
run;

proc sql;
create table project.kurtoza_dodatnia_valid as
select *
from project.all_kurtoza_valid
where Kurtoza > 0;
quit;

title "Dodatnie wartoúci kurtozy na zbiorze valid";
proc sgplot data=project.kurtoza_dodatnia_valid;
	vbox Kurtoza / 
	fillattrs=(color=orange);
	yaxis type=log logbase=10 logstyle=logexpand;
run;

title "Wykres kube≥kowy dla wszystkich wartoúci kurtozy na zbiorze valid";
proc sgplot data=project.all_kurtoza_valid;
	vbox Kurtoza / 
	fillattrs=(color=orange);
	yaxis type=log logbase=10 logstyle=logexpand;
run;

/* WSKAèNIK ZMIENNOåCI */
pattern color=orange;
proc univariate data=project.all_wsk_zmiennosci_valid;
	var CV;
	histogram CV / normal nmidpoints=8;
	title "Rozk≥ad procentowy wartoúci CV na zbiorze valid";
run;

title "Wykres kube≥kowy dla wszystkich wartoúci CV na zbiorze valid";
proc sgplot data=project.all_wsk_zmiennosci_valid;
	vbox CV / 
	fillattrs=(color=orange);
run;

/* rozk≥ad zmiennej o najwiekszej kurtozie dla zbioru valid */
proc sql noprint;
	select Variable as Variable, Kurtoza
	from project.all_kurtoza_valid;
quit;

pattern color=orange;
proc univariate data=project.abt_sam_beh_valid;
	title "Rozk≥ad act_state_10_Cncr - Kurtoza valid";
	var act_state_10_Cncr;
	histogram act_state_10_Cncr / normal nmidpoints=8;
run;

/* rozk≥ad zmiennej o najwiÍkszym wspÛ≥czynniku zmiennoúci dla zbioru valid */
pattern color=orange;
proc univariate data=project.abt_sam_beh_valid;
	title "Rozk≥ad act_state_18_CMin_Due - CV valid";
	var act_state_18_CMin_Due;
	histogram act_state_18_CMin_Due / normal nmidpoints=8;
run;



data train;
set project.abt_sam_beh_train;
missingvar = cmiss(of _all_) -1;
run;

proc sql;
create table Braki_miesiπc_train as
select period as Miesiπc, sum(missingvar) as Braki
from train
group by period;
quit;

TITLE 'MiesiÍczny szereg danych czasowych zawierajπcy informacje o brakach danych ze zbioru train';
proc sgplot data=Braki_miesiπc_train;
series x=Miesiπc y=Braki / lineattrs=(color=lime);
xaxis display=(NOVALUES NOTICKS);
run;
title;