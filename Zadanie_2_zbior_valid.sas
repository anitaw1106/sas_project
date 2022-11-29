


/*tworzenie zbioru danych*/
data zbior_valid;
set project.abt_sam_beh_valid ;
run;


/*Ustalanie liczby brak�w danych za pomoc� 
najbardziej popularnej procedury do obliczania 
podstawowych statystyk opisowych zbior�w*/
ods exclude all; 
proc means data = zbior_valid N NMISS STACKODSOUTPUT;  
ods output Summary=miss_obs;  
run;
ods exclude none;          

 /*Procentowa liczba brak�w*/

data proc_miss;
set miss_obs; 
RENAME  N=l_obserwacji NMISS=na;
Odsetek_brak�w = NMISS/(N+NMISS);
format Odsetek_brak�w percent12.2;
run;
proc sort data=proc_miss;
by descending Odsetek_brak�w ;
run;

 
/*Dzielimy zmienne wed�ug nazw, gdzie separatorem jest "_"*/

data filtered;
set proc_miss;
first = scan(variable,1,'_'); 
second = scan(variable,2,'_');

/*��czymy zmienn� first ze zmienn� second 
separatorem "_" w celu dalszej analizy*/
first_second = catx('_', first, second);

third = scan(variable,3,'_');
fourth = scan(variable,4,'_');

/*Skracamy zmienn� do 3 znak�w, wed�ug 
klasyfikacji otrzymanej w pliku xls labels*/
var_labels=substr(variable,1,3);

/*Ekstrakcja liczb ze zmiennej first w celu 
analizy zmiany danych w czasie (podczas ostatniej agregacji)*/
last_agr= compress(first, ' ', 'A');
last_agr_num = input(last_agr, 3.); 

/*Ekstrakcja liczb ze zmiennej act
opisuj�cej jaki� stan z danego punktu czasowego*/
act_time= compress(third, ' ', 'A');
act_time_all = input(act_time, 3.); 

/*Dla brakuj�cych warto�ci timestamp_act zast�pujemy act_time_all*/
if missing(timestamp_act) and var_labels ='act' 
THEN timestamp_act=act_time_all;
run;


/*Dzielimy zmienne 
okre�laj�ce charakterystyki klienta na 
agreguj�ce informacje z wielu miesi�cy 
przed punktem obserwacji wg podzia�u na agr i ags*/

data filtered_agr;
set filtered;
WHERE substr (first,1,3) = 'ags' 
or substr (first,1,3) = 'agr';
run;
proc sort data=filtered_agr (keep=  na last_agr_num Variable) 
out=filtered_posort_agr;
by last_agr_num;
run;


data filtered_act;
set filtered;
WHERE substr (first,1,3) = "act";
run;


proc sort data=filtered_act
(keep= Variable na timestamp_act) 
out=v2_act_filtered; 
by timestamp_act;
run;

proc sort data=filtered_act 
(keep= Variable na act_time_all) 
out=all_act_sorted;
by act_time_all;
run;

proc sort data=v1_act_filtered
(keep= Variable na last_agr_num) 
out=filtered_act_v2; 
by last_agr_num;
run;

data v1_act_filtered;
set filtered;
WHERE substr (first,1,3) = "act" and timestamp_act is missing;
run;

proc print data=proc_miss;
title 'Odsetek liczby brak�w dla danej zmiennej';
run; 

/*Tworzymy makro do wyliczania �redniej, nast�pnie 
dane w zbiorze sql do wygenerowania tabel 
do raportu ko�cowego*/


%macro AVG(column, out);

proc sql 
noprint;
select distinct(&column) into :list separated " " 
from filtered;
quit;

%put &list;  
%let n=%sysfunc(countw(&list)); 
%do i=1 %to &n;
%let d = %scan(&list,&i); 
data testy;
set filtered;
WHERE &column= "&d";
run;




proc sql 
noprint;
create table &d as
select MAX(&column) as &column, 
sum(l_obserwacji) as l_obserwacji, sum(na) as na, 
avg(na) as AVG, sum(na)/sum(l_obserwacji+na) as Odsetek_brak�w from testy
where &column LIKE "&d.%" group by &column ;
    %end;

proc delete data = testy; 
run;
data &out;
set &list;
format Odsetek_brak�w percent12.2;
format avg 8.2;
run;




%put &list
*//;
%do i=1 %to &n; 
%let d = %scan(&list,&i);
proc delete data =  &d;
%end;
quit;

 

proc sort data=&out;
by descending Odsetek_brak�w ;
run;
proc print data=&out; 
title "Odsetek brak�w wraz ze �redni� dla: ";
title2 "Dla &out";
run; 
%mend;

 
%AVG(first_second, double_var);
%AVG(second, sec_var);
%AVG(var_labels, fir_var);



/*��czna suma brak�w dla zmiennej agr, tworzenie nowego zbioru
suma_agr, identyfiaktory czasowe pierwszej zmiennej, suma brak�w dla zmiennej
agreguj�cej */

data suma_agr
(Rename=(last_agr_num=var_time_agr));
retain miss_sum;
set filtered_posort_agr;
by last_agr_num;
if first.last_agr_num then miss_sum=na;
else miss_sum=sum(miss_sum,na);
if last.last_agr_num then output ;
drop na Variable;
run;

data suma_agr;
retain var_time_agr miss_sum;
set suma_agr;
run;

/*procentowy udzia� brak�w */
proc sql noprint  
undopolicy=none;
create table suma_agr as
select var_time_agr, miss_sum, 
miss_sum/SUM(miss_sum) as proc_miss_sum 
from suma_agr;

data suma_agr;
retain var_time_agr miss_sum proc_miss_sum;
set suma_agr;
format proc_miss_sum percent12.2;
run;
proc sort data=suma_agr;
by descending proc_miss_sum ;
run;

proc print data=suma_agr; 
title '��czna liczba brak�w dla zmiennej agreguj�cej w okre�lonym momencie czasowym';
title2 'Warto�ci zmiennej first: agr, ags';
run; 





/*��czna liczba brak�w za dany okres dla opisowaych zmiennych */

data suma_act (rename=(act_time_all=timestamp_desc_var));
set all_act_sorted;
retain miss_sum;
drop na Variable;
by act_time_all;
if first.act_time_all then miss_sum = na;
else miss_sum = sum(miss_sum,na);
if last.act_time_all then output ;
run;

data suma_act;
retain timestamp_desc_var miss_sum;
set suma_act;
run;

proc sql noprint  
undopolicy=none;
create table suma_act as
select timestamp_desc_var, miss_sum, 
miss_sum/SUM(miss_sum) as proc_num_desc_var
from suma_act;

data suma_act;
retain timestamp_desc_var miss_sum proc_num_desc_var;
set suma_act;
format proc_num_desc_var percent7.2;
run;
proc sort data=suma_act;
by descending proc_num_desc_var ;
run;

 
proc print data=suma_act;
title 'Liczba brak�w  dla czasu dla zmiennych opisuj�cych stan z danego punktu czasowego ';
title2 "(ACT)";
run; 



/*suma brak�w per dany okres dla opisuj�cych typu act_state_12_CMax_Days */

data sum_act (Rename=(timestamp_act=timestamp_desc_var));
set v2_act_filtered;
retain miss_sum;
by timestamp_act;
if first.timestamp_act then miss_sum=na;
else miss_sum=sum(miss_sum,na);
if last.timestamp_act then output ;
drop na Variable;
run;

data sum_act;
retain timestamp_desc_var miss_sum;
set sum_act;
run;

proc sql noprint  
undopolicy=none;
create table sum_act as
select timestamp_desc_var, miss_sum, 
miss_sum/SUM(miss_sum) as proc_num_desc_var
from sum_act ;

data sum_act;
retain timestamp_desc_var miss_sum;
set suma_act;
format proc_num_desc_var percent12.2;
run;
proc sort data=sum_act;
by descending proc_num_desc_var ;
run;

proc print data = sum_act; 
title 'Liczba brak�w  w czasie dla zmiennych opisuj�cych stan z danego punktu czasowego';
run; 

 



/*WYKRESY*/
data zbior_valid;
set project.abt_sam_beh_valid ;
run;


/* Wykres 4 */

title "Udzia� brak�w danych dla zmiennych, kt�re opisuj� stan w danym punktcie czasu dla zbioru valid";
title2 "dla act, min, max, ncr";
proc sgplot data=work.suma_act noborder;
vbar timestamp_desc_var / 
response=proc_num_desc_var 
fillattrs=(color=orange);
VLINE timestamp_desc_var / 
response=miss_sum y2axis ;
xaxis label="Czasowe zmienne opisuj�cce";
yaxis label="Udzia� procentowy brak�w";
y2axis label="Suma brak�w";
run; quit; 


* wykres 12 ;
title "Ilo�� brak�w dla agr, act, ags, app, def dla zbioru valid";
proc sgplot data=work.fir_var noborder; 
vbar var_labels / 
response=na 
fillattrs=(color=orange) CATEGORYORDER=RESPdesc;
xaxis label="Zmienne";
yaxis label="Liczba brak�w";
run; quit;


/* Wykres 14*/


title "Ilo�� brak�w oraz �rednia ilo�� brak�w dla zbioru valid";
proc sgplot data=work.sec_var noborder; 
vbar second / 
response=na 
fillattrs=(color=orange);
vline second / 
response=avg y2axis CATEGORYORDER=RESPdesc;
xaxis label="Zmienne";
yaxis label="Liczba brak�w";
y2axis label="�rednia liczba brak�w";
run; quit;

/* Wykres 6*/ 

title "Ilo�� zmiennych w zale�no�ci od udzia�u brakuj�cych warto�ci dla zbioru valid";
axis label=none;
pattern color=orange;
proc gchart data=work.proc_miss;
hbar 'Odsetek_brak�w'n / type=sum
space=1 width=5 outside=freq levels=10 
range noframe;
run; quit;
/* Wykres 8*/
TITLE 'Rozk�ad procentowy zmiennych na podstawie brak�w danych ze zbioru valid';
proc univariate data=proc_miss NOPRINT;
histogram Odsetek_brak�w / midpoints = 0 to 1 by 0.1 barlabel = percent;
run;
title;
/*Wykres 10*/
TITLE 'Procentowy brak zmiennych dla poszczeg�lnych typ�w zmiennych ze zbioru valid';
proc sgplot data=fir_var;
vbar var_labels / response=Odsetek_brak�w datalabel
fillattrs=(color=orange) categoryorder=RESPdesc;
yaxis values=(0 to 1 by 0.1);
run;
title;

data valid;
set project.abt_sam_beh_valid;
missingvar = cmiss(of _all_) -1;
run;

proc sql;
create table Braki_miesi�c_valid as
select period as Miesi�c, sum(missingvar) as Braki
from valid
group by period;
quit;
/*Wykres 2*/
TITLE 'Miesi�czny szereg danych czasowych zawieraj�cy informacje o brakach danych ze zbioru valid';
proc sgplot data=Braki_miesi�c_valid;
series x=Miesi�c y=Braki / lineattrs=(color=orange);
xaxis display=(NOVALUES NOTICKS);
run;
title;