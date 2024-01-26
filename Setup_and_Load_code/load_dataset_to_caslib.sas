/* SET MACRO VARIABLES: PATH TO SOURCE DATA, DESTINATION CASLIB, & NAME OF TABLE TO LOAD */
/* CHANGE VALUES AS NEEDED */
%let datapath=/innovationlab-export/innovationlab/homes/T.Winand@sas.com/Data/CSV_Files;


/* START CAS SESSION */
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");


/* SET LIBNAME FOR SOURCE DATA TO LOAD AND SET CAS ENGINE LIBRARY FOR DESTINATION CASLIB */
/* libname mydata "&datapath"; */
/* libname casuser cas caslib="casuser"; */

/* CHECK IF CAS TABLE ALREADY EXISTS - IF IT DOES DROP FROM MEMORY */
%if %sysfunc(exist(casuser.hmeq)) %then %do;
  proc casutil;
    droptable incaslib="casuser" casdata="hmeq";
  run;
%end;

/* LOAD XLS FILE TO CAS USING PROC CASUTIL */
proc casutil;
    load file="&datapath/hmeq.csv"
    casout='hmeq'
    outcaslib='casuser'
    importoptions=(filetype='csv' getnames=true)
    replace;

    list tables;
quit; 


/* LOAD DATASET INTO CASLIB AND PROMOTE */
/* proc casutil; */
/*   load data=mydata.&tblname outcaslib="&mycaslib" casout="&tblname" promote; */
/*   list tables incaslib="&mycaslib";   */
/* quit; */

proc contents data=casuser.hmeq;
run;

/* LIST FIRST 10 ROWS TO VALIDATE */
proc print data=casuser.hmeq (obs=10);
run;

proc casutil;
  promote casdata="hmeq" incaslib="casuser" outcaslib="casuser";
quit;


/* TERMINATE CAS SESSION */
cas mySession terminate;
