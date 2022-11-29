LIBNAME project  "C:\Users\Admin\Desktop\SAS_projekt" ;


/*tworzenie zbioru danych*/
data zbior_valid;
set project.abt_sam_beh_valid ;
run;


/*Ustalanie liczby braków danych za pomoc¹ 
najbardziej popularnej procedury do obliczania 
podstawowych statystyk opisowych zbiorów*/
ods exclude all; 
proc means data = zbior_valid N NMISS STACKODSOUTPUT;  
ods output Summary=miss_obs;  
run;
ods exclude none;          

 /*Procentowa liczba braków*/

data proc_miss;
set miss_obs; 
RENAME  N=l_obserwacji NMISS=na;
Odsetek_braków = NMISS/(N+NMISS);
format Odsetek_braków percent12.2;
run;
proc sort data=proc_miss;
by descending Odsetek_braków ;
run;

 
/*Dzielimy zmienne wed³ug nazw, gdzie separatorem jest "_"*/

data filtered;
set proc_miss;
first = scan(variable,1,'_'); 
second = scan(variable,2,'_');

/*£¹czymy zmienn¹ first ze zmienn¹ second 
separatorem "_" w celu dalszej analizy*/
first_second = catx('_', first, second);

third = scan(variable,3,'_');
fourth = scan(variable,4,'_');

/*Skracamy zmienn¹ do 3 znaków, wed³ug 
klasyfikacji otrzymanej w pliku xls labels*/
var_labels=substr(variable,1,3);

/*Ekstrakcja liczb ze zmiennej first w celu 
analizy zmiany danych w czasie (podczas ostatniej agregacji)*/
last_agr= compress(first, ' ', 'A');
last_agr_num = input(last_agr, 3.); 

/*Ekstrakcja liczb ze zmiennej act
opisuj¹cej jakiœ stan z danego punktu czasowego*/
act_time= compress(third, ' ', 'A');
act_time_all = input(act_time, 3.); 

/*Dla brakuj¹cych wartoœci timestamp_act zastêpujemy act_time_all*/
if missing(timestamp_act) and var_labels ='act' 
THEN timestamp_act=act_time_all;
run;


/*Dzielimy zmienne 
okreœlaj¹ce charakterystyki klienta na 
agreguj¹ce informacje z wielu miesiêcy 
przed punktem obserwacji wg podzia³u na agr i ags*/

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
title 'Odsetek liczby braków dla danej zmiennej';
run; 

/*Tworzymy makro do wyliczania œredniej, nastêpnie 
dane w zbiorze sql do wygenerowania tabel 
do raportu koñcowego*/


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
avg(na) as AVG, sum(na)/sum(l_obserwacji+na) as Odsetek_braków from testy
where &column LIKE "&d.%" group by &column ;
    %end;

proc delete data = testy; 
run;
data &out;
set &list;
format Odsetek_braków percent12.2;
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
by descending Odsetek_braków ;
run;
proc print data=&out; 
title "Odsetek braków wraz ze œredni¹ dla: ";
title2 "Dla &out";
run; 
%mend;

 
%AVG(first_second, double_var);
%AVG(second, sec_var);
%AVG(var_labels, fir_var);



/*£¹czna suma braków dla zmiennej agr, tworzenie nowego zbioru
suma_agr, identyfiaktory czasowe pierwszej zmiennej, suma braków dla zmiennej
agreguj¹cej */

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

/*procentowy udzia³ braków */
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
title '£¹czna liczba braków dla zmiennej agreguj¹cej w okreœlonym momencie czasowym';
title2 'Wartoœci zmiennej first: agr, ags';
run; 





/*£¹czna liczba braków za dany okres dla opisowaych zmiennych */

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
title 'Liczba braków  dla czasu dla zmiennych opisuj¹cych stan z danego punktu czasowego ';
title2 "(ACT)";
run; 



/*suma braków per dany okres dla opisuj¹cych typu act_state_12_CMax_Days */

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
title 'Liczba braków  w czasie dla zmiennych opisuj¹cych stan z danego punktu czasowego';
run; 

 