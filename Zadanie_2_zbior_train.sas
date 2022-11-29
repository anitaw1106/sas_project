


/*tworzenie zbioru danych*/
data zbior_train;
set project.abt_sam_beh_train ;
run;


/*Ustalanie liczby brakow danych za pomoca
najbardziej popularnej procedury do obliczania 
podstawowych statystyk opisowych zbiorow*/
ods exclude all; 
proc means data = zbior_train N NMISS STACKODSOUTPUT;  
ods output Summary = miss_obs;  
run;
ods exclude none;          

 /*Procentowa liczba brakow*/

data proc_miss;
set miss_obs; 
RENAME  N=l_obserwacji NMISS=na;
Odsetek_brakow = NMISS/(N+NMISS);
format Odsetek_brakow percent12.2;
run;
proc sort data=proc_miss;
by descending Odsetek_brakow ;
run;

 
/*Dzielimy zmienne wedï¿½ug nazw, gdzie separatorem jest "_"*/

data filtered;
set proc_miss;
first = scan(variable,1,'_'); 
second = scan(variable,2,'_');

/*ï¿½ï¿½czymy zmiennï¿½ first ze zmiennï¿½ second 
separatorem "_" w celu dalszej analizy*/
first_second = catx('_', first, second);

third = scan(variable,3,'_');
fourth = scan(variable,4,'_');

/*Skracamy zmiennï¿½ do 3 znakï¿½w, wedï¿½ug 
klasyfikacji otrzymanej w pliku xls labels*/
var_labels=substr(variable,1,3);

/*Ekstrakcja liczb ze zmiennej first w celu 
analizy zmiany danych w czasie (podczas ostatniej agregacji)*/
last_agr= compress(first, ' ', 'A');
last_agr_num = input(last_agr, 3.); 

/*Ekstrakcja liczb ze zmiennej act
opisujï¿½cej jakiï¿½ stan z danego punktu czasowego*/
act_time= compress(third, ' ', 'A');
act_time_all = input(act_time, 3.); 

/*Dla brakujï¿½cych wartoï¿½ci timestamp_act zastï¿½pujemy act_time_all*/
if missing(timestamp_act) and var_labels ='act' 
THEN timestamp_act=act_time_all;
run;


/*Dzielimy zmienne 
okreï¿½lajï¿½ce charakterystyki klienta na 
agregujï¿½ce informacje z wielu miesiï¿½cy 
przed punktem obserwacji wg podziaï¿½u na agr i ags*/

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
title 'Odsetek liczby brakï¿½w dla danej zmiennej';
run; 

/*Tworzymy makro do wyliczania ï¿½redniej, nastï¿½pnie 
dane w zbiorze sql do wygenerowania tabel 
do raportu koï¿½cowego*/


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
avg(na) as AVG, sum(na)/sum(l_obserwacji+na) as Odsetek_brakow from testy
where &column LIKE "&d.%" group by &column ;
    %end;

proc delete data = testy; 
run;
data &out;
set &list;
format Odsetek_brakow percent12.2;
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
by descending Odsetek_brakow ;
run;
proc print data=&out; 
title "Odsetek brakï¿½w wraz ze ï¿½redniï¿½ dla: ";
title2 "Dla &out";
run; 
%mend;

 
%AVG(first_second, double_var);
%AVG(second, sec_var);
%AVG(var_labels, fir_var);



/*ï¿½ï¿½czna suma brakï¿½w dla zmiennej agr, tworzenie nowego zbioru
suma_agr, identyfiaktory czasowe pierwszej zmiennej, suma brakï¿½w dla zmiennej
agregujï¿½cej */

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

/*procentowy udziaï¿½ brakï¿½w */
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
title 'ï¿½ï¿½czna liczba brakï¿½w dla zmiennej agregujï¿½cej w okreï¿½lonym momencie czasowym';
title2 'Wartoï¿½ci zmiennej first: agr, ags';
run; 





/*ï¿½ï¿½czna liczba brakï¿½w za dany okres dla opisowaych zmiennych */

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
title 'Liczba brakï¿½w  dla czasu dla zmiennych opisujï¿½cych stan z danego punktu czasowego ';
title2 "(ACT)";
run; 



/*suma brakï¿½w per dany okres dla opisujï¿½cych typu act_state_12_CMax_Days */

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
title 'Liczba brakï¿½w  w czasie dla zmiennych opisujï¿½cych stan z danego punktu czasowego';
run; 





/*WYKRESY*/
data zbior_train;
set project.abt_sam_beh_train ;
run;


/* Wykres 3*/

title "Udzia³ braków danych dla zmiennych, które opisuj¹ stan w danym punktcie czasu dla zbioru train";
title2 "dla act, min, max, ncr";
proc sgplot data=work.suma_act noborder;
vbar timestamp_desc_var / 
response=proc_num_desc_var 
fillattrs=(color=lime);
VLINE timestamp_desc_var / 
response=miss_sum y2axis ;
xaxis label="Czasowe zmienne opisuj¹cce";
yaxis label="Udzia³ procentowy braków";
y2axis label="Suma braków";
run; quit; 


* wykres 11 ;
title "Iloœæ braków dla agr, act, ags, app, def dla zbioru train";
proc sgplot data=work.fir_var noborder; 
vbar var_labels / 
response=na 
fillattrs=(color=lime) CATEGORYORDER=RESPdesc;

xaxis label="Zmienne";
yaxis label="Liczba braków";

run; quit;




* Wykres 13;
title "Iloœæ braków oraz œrednia iloœæ braków dla zbioru train";
proc sgplot data=work.sec_var noborder; 
vbar second / 
response=na 
fillattrs=(color=lime);
vline second / 
response=avg y2axis CATEGORYORDER=RESPdesc;
xaxis label="Zmienne";
yaxis label="Liczba braków";
y2axis label="Œrednia liczba braków";
run; quit;

/* Wykres 5*/ 

title "Iloœæ zmiennych w zale¿noœci od udzia³u brakuj¹cych wartoœci dla zbioru train";
axis label=none;
pattern color=lime;
proc gchart data=work.proc_miss;
hbar 'Odsetek_brakow'n / type=sum
space=1 width=5 outside=freq levels=10 
range noframe;
run; quit;
/*Wykres 7 */
TITLE 'Rozk³ad procentowy zmiennych na podstawie braków danych ze zbioru train';
proc univariate data=proc_miss NOPRINT;
histogram Odsetek_brakow / midpoints = 0 to 1 by 0.1 barlabel = percent;
run;
title;
/* Wykres 9 */
TITLE 'Procentowy brak zmiennych dla poszczególnych typów zmiennych ze zbioru train';
proc sgplot data=fir_var;
vbar var_labels / response=Odsetek_brakow datalabel
fillattrs=(color=lime) categoryorder=RESPdesc;
yaxis values=(0 to 1 by 0.1);
run;
title;

data train;
set project.abt_sam_beh_train;
missingvar = cmiss(of _all_) -1;
run;

proc sql;
create table Braki_miesi¹c_train as
select period as Miesi¹c, sum(missingvar) as Braki
from train
group by period;
quit;
/*Wykres 1*/
TITLE 'Miesiêczny szereg danych czasowych zawieraj¹cy informacje o brakach danych ze zbioru train';
proc sgplot data=Braki_miesi¹c_train;
series x=Miesi¹c y=Braki / lineattrs=(color=lime);
xaxis display=(NOVALUES NOTICKS);
run;
title;


 