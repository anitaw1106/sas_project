

/*tworzenie zbioru train*/
data zbior_train;
set project.abt_sam_beh_train ;
run;

/*tworzenie zbioru valid*/
data zbior_valid;
set project.abt_sam_beh_valid ;
run;

/* Punkt 3
Analiza wartoœci nietypowych, odstaj¹cych lub ogólnie nieregularnoœci rozk³adów, ich
udzia³ów w czasie (czyli stabilnoœci w czasie) i porównywania udzia³ów pomiêdzy zbiorami
train i valid (czyli stabilnoœci na zbiorach) w postaci szczegó³owego raportu tabelarycznego */

/* podstawowe statystyki na zbiorach */

proc means data=work.zbior_train N NMISS MEAN STD MIN MAX STD CV SKEW KURT;
output out=stat_train;
run;

proc means data=work.zbior_valid N NMISS MEAN STD MIN MAX STD CV SKEW KURT;
output out=stat_valid;
run;


/* makro zliczaj¹ce obserwacje odstaj¹ce dla wszystkich zmiennych */

%macro count_outliers(input, obs, output);

proc means data=&input noprint;
output out=statistics(drop=_TYPE_ _FREQ_);
run;

proc transpose data=statistics out=stat_T;
id _STAT_;
run;

proc transpose data=&input out=data_T;
run;

/* regu³a 3 odchyleñ standardowych */

 data boundries;
 set stat_T;
 top = MEAN + 3*STD;
 bottom = MEAN - 3*STD;
 rename N = non_missing;
 run;

 proc sort data = boundries;
 by _name_;
 run;

 proc sort data = data_T;
 by _name_;
 run;

data merge0;
merge boundries(in=a) data_T(in=b);
by _name_;
if a and b;
run;

/* liczenie obserwacji odstaj¹cych */

data merge1;
set merge0;
array values{&obs} col1--col&obs;
do i=1 to &obs;
  if values{i} > top then powyzej=sum(powyzej,1);
end;
run;

data merge2;
set merge1;
array values{&obs} col1--col&obs;
do i=1 to &obs;
  if values{i} < bottom then ponizej=sum(ponizej,1);
end;
run;

/* procentowy udzia³ odstaj¹cych */

data odstajace&output;
set merge2;
array change _numeric_;
        do over change;
            if change=. then change=0;
        end;
odst = powyzej + ponizej;
odstajace_procentowo= odst/non_missing;
format odstajace_procentowo percent8.2;
keep _NAME_ non_missing odst odstajace_procentowo;
rename _NAME_ = zmienna non_missing = non_missing_&output odst = odstajace_&output odstajace_procentowo = odstajace_procentowo_&output;
run;

proc print;
run;

%mend count_outliers;


%count_outliers(work.zbior_train, 52841, train);
%count_outliers(work.zbior_valid, 53070, valid);


/* Porównanie liczby obserwacji odst¹j¹cych w zbiorach train i valid */

data odstajace_train_valid;
merge odstajacetrain(in=a) odstajacevalid(in=b);
by zmienna;
if a and b;
keep zmienna odstajace_procentowo_train odstajace_procentowo_valid porownanie;
porownanie = odstajace_procentowo_train / odstajace_procentowo_valid;
run;


/* posortowane tabele

proc sort data=work.odstajacetrain;
by descending odstajace_procentowo_train;
run;

proc sort data=work.odstajacevalid;
by descending odstajace_procentowo_valid;
run;

proc sort data=work.odstajace_train_valid;
by descending porownanie;
run;

*/

/* zmiana udzia³u obserwacji odstaj¹cych miêdzy 2004 a 2018 rokiem */

data t2004;
set zbior_train;
where period contains "2004";
run;

data t2011;
set zbior_train;
where period contains "2011";
run;

data t2018;
set zbior_train;
where period contains "2018";
run;

%count_outliers(work.t2004, 3217, train_2004);
%count_outliers(work.t2011, 2162, train_2011);
%count_outliers(work.t2018, 2162, train_2018);

data odstajace_train_czas;
merge odstajacetrain_2004(in=a) odstajacetrain_2011(in=b) odstajacetrain_2018(in=c);
by zmienna;
if a and b and c;
keep zmienna odstajace_procentowo_train_2004 odstajace_procentowo_train_2011 odstajace_procentowo_train_2018;
run;


/* analogicznie dla zbioru valid */

data v2004;
set zbior_valid;
where period contains "2004";
run;

data v2011;
set zbior_valid;
where period contains "2011";
run;

data v2018;
set zbior_valid;
where period contains "2018";
run;

%count_outliers(work.v2004, 3143, valid_2004);
%count_outliers(work.v2011, 3718, valid_2011);
%count_outliers(work.v2018, 2227, valid_2018);

data odstajace_valid_czas;
merge odstajacevalid_2004(in=a) odstajacevalid_2011(in=b) odstajacevalid_2018(in=c);
by zmienna;
if a and b and c;
keep zmienna odstajace_procentowo_valid_2004 odstajace_procentowo_valid_2011 odstajace_procentowo_valid_2018;
run;
