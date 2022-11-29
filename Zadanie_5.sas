*Wczytywanie danych;


*Zbiór train;
data dane_train; 
set Projekt.abt_sam_beh_train ;
where default_cus12 = 1 or default_cus12 = 0;
run;



*Zbiór valid;
data dane_valid; 
set Projekt.abt_sam_beh_valid ;
where default_cus12 = 1 or default_cus12 = 0;
run;

*/ tylko zmienne numeryczne;
data num_train;
set dane_train(keep=_NUMERIC_ default_cus12);
run;

*/Czy s¹ jakieœ zmienne tekstowe?;
data char_train;
set dane_train(keep=_character_ default_cus12);
run;


*SQL - do sprawdzania ró¿noœci;
proc sql;
	create table check as
	select distinct(default_cus12)  from dane_train;
quit;


*/ Wy³¹czenie ze zbioru zmiennych agreguj¹cych - train;

data dane_model_p;
set dane_train;
keep
default_cus12 
act_CMax_Due 
act_cus_dueutl
act_CMin_Due 
act_cus_n_loans_act 
act_cus_cc 
act_Cncr
act_CMax_Days
app_char_home_status
act_cus_n_statB
app_number_of_children 
app_char_marital_status
act_cus_n_loans_hist
act_CMin_Days
act_cus_loan_number 
app_income
app_spendings 
act_cus_seniority 
app_char_city
act_age
act_cus_n_statC
act_cus_pins
app_char_cars
app_char_job_code
act_cus_utl
;
run;

*/ Wy³¹czenie ze zbioru zmiennych agreguj¹cych - valid;

data dane_model_v;
set dane_valid;
keep
default_cus12 
act_CMax_Due 
act_cus_dueutl
act_CMin_Due 
act_cus_n_loans_act 
act_cus_cc 
act_Cncr
act_CMax_Days
app_char_home_status
act_cus_n_statB
app_number_of_children 
app_char_marital_status
act_cus_n_loans_hist
act_CMin_Days
act_cus_loan_number 
app_income
app_spendings 
act_cus_seniority 
app_char_city
act_age
act_cus_n_statC
act_cus_pins
app_char_cars
app_char_job_code
act_cus_utl
;
run;








*Rekategoryzacja zmiennych - wykresy dla kategorii ;

*Dane do makra;
%let var_char=app_char_job_code 
	app_char_marital_status
	app_char_city
	app_char_home_status
	app_char_cars;
	%let var_dependant =default_cus12 ;


*makro generuj¹ce histogramy wraz z udzia³em zdarzenia default;
%macro make_distribution(input_data, variables, target);
	%local i var;

	%do i=1 %to %sysfunc(countw(&variables));
		%let var = %scan(&variables, &i);
		proc sgplot data=&input_data;
		vbar &var /group=&target seglabel datalabel;
		xaxis fitpolicy=rotatethin;
		run;
	%end;
%mend;

*wywo³aj makro;
%make_distribution(dane_model_p, &var_char, &var_dependant)



*Rekategoryzacja zmiennych tekstowych z app_ w celu utworzenia monotonicznych binów;
data dane_train_reko;

set dane_model_p;
*brak posiadania auta zwiêksza szansê na default;

if app_char_cars="No" then app_num_cars=0;
else if app_char_cars="Owner" then app_num_cars=1;


*Kontrakt najbardziej podatny na default, podczas gdy retired najmniej;
*Stabilnoœæ przychodów dzia³a pozytywnie na wyp³acalnoœæ;

if app_char_job_code="Contract" then app_num_job_code=0;
else if app_char_job_code="Owner company" then app_num_job_code=1;
else if app_char_job_code="Permanent" then app_num_job_code=2;
else if app_char_job_code="Retired" then app_num_job_code=3;

*Married bardziej podatny na default ni¿ single;

if app_char_marital_status="Single" then app_num_marital_status=0;
else if app_char_marital_status="Maried" then app_num_marital_status=1;

*im mniejsze miasto tymn wiêksza szansa na default;

if app_char_city="Small" then app_num_city=0;
else if app_char_city="Medium" then app_num_city=1;
else if app_char_city="Large"  then app_num_city=2;
else if app_char_city="Big" then app_num_city=2;

* im mniejsza niezale¿noœc mieszkaniowa tym wiêksza szansa na default;

if app_char_home_status="Owner" then app_num_home_status=0;
else if app_char_home_status="Rental" then app_num_home_status=1;
else if app_char_home_status="With parents" then app_num_home_status=2;

run;

*rekategoryzacja dla zbioru valid;
data dane_valid_reko;

set dane_model_v;

if app_char_cars="No" then app_num_cars=0;
else if app_char_cars="Owner" then app_num_cars=1;

if app_char_job_code="Contract" then app_num_job_code=0;
else if app_char_job_code="Owner company" then app_num_job_code=1;
else if app_char_job_code="Permanent" then app_num_job_code=2;
else if app_char_job_code="Retired" then app_num_job_code=3;

if app_char_marital_status="Single" then app_num_marital_status=0;
else if app_char_marital_status="Maried" then app_num_marital_status=1;

if app_char_city="Small" then app_num_city=0;
else if app_char_city="Medium" then app_num_city=1;
else if app_char_city="Large"  then app_num_city=2;
else if app_char_city="Big" then app_num_city=2;


if app_char_home_status="Owner" then app_num_home_status=0;
else if app_char_home_status="Rental" then app_num_home_status=1;
else if app_char_home_status="With parents" then app_num_home_status=2;

run;





*Upewnienie siê ¿e zostan¹ tylko zmienne numeryczne - train;
data num_train;
set dane_train_reko(keep=_NUMERIC_ default_cus12);
run;



*Upewnienie siê ¿e zostan¹ tylko zmienne numeryczne - valid;
data num_valid;
set dane_valid_reko(keep=_NUMERIC_ default_cus12);
run;


*korelacje dla zbioru train;

/*Pearson app train*/

proc corr nosimple data= num_train pearson;
var default_cus12;
with app:;
ods output pearsoncorr=p;
run;


/*Pearson act train*/

proc corr nosimple data= num_train pearson;
var default_cus12;
with act:;
ods output pearsoncorr=p;
run;


*korelacje dla zbioru valid;

/*Pearson app valid*/

proc corr nosimple data= num_valid pearson;
var default_cus12;
with app:;
ods output pearsoncorr=p;
run;



/*Pearson act valid*/

proc corr nosimple data= num_valid pearson;
var default_cus12;
with act:;
ods output pearsoncorr=p;
run;


*/czêœæ z budow¹ modelu - poni¿ej ju¿ model po naszym w³¹czaniu zmiennych /;


ods graphics on;



PROC LOGISTIC DATA=num_train
		PLOTS(only)=ROC
	;
	
	MODEL default_cus12 (Event = '1')=
	act_CMax_Due
	act_cus_n_loans_act
	act_cus_utl
	act_cus_cc

	app_num_job_code
	app_num_cars
	app_num_city
	app_num_marital_status
	app_num_home_status
	 

/
		SELECTION=NONE
		NOINT
		CORRB
		COVB
		LACKFIT
		AGGREGATE SCALE=NONE
		RSQUARE
		CTABLE
		LINK=LOGIT
		CLPARM=WALD
		CLODDS=WALD
		ALPHA=0.05
	;
RUN;


ods graphics off;