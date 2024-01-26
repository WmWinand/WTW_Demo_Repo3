/*******************************************************************************************/
/* SAS INSTITUTE INC. IS PROVIDING YOU WITH THE COMPUTER SOFTWARE CODE INCLUDED WITH THIS
AGREEMENT ("CODE") ON AN "AS IS" BASIS, AND AUTHORIZES YOU TO USE THE CODE SUBJECT TO
THE TERMS HEREOF.  BY USING THE CODE, YOU AGREE TO THESE TERMS.  YOUR USE OF THE CODE
IS AT YOUR OWN RISK.  SAS INSTITUTE INC. MAKES NO REPRESENTATION OR WARRANTY, EXPRESS OR
IMPLIED, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, NONINFRINGEMENT AND TITLE, WITH RESPECT TO THE CODE.

The Code is intended to be used solely as part of a product ("Software") you currently
have licensed from SAS Institute Inc. or one of its subsidiaries or authorized agents
("SAS"). The Code is designed to either correct an error in the Software or to add
functionality to the Software, but has not necessarily been tested.  Accordingly, SAS
makes no representation or warranty that the Code will operate error-free.  SAS is under
no obligation to maintain or support the Code.

Neither SAS nor its licensors shall be liable to you or any third party for any general,
special, direct, indirect, consequential, incidental or other damages whatsoever arising
out of or related to your use or inability to use the Code, even if SAS has been advised
of the possibility of such damages.

Except as otherwise provided above, the Code is governed by the same agreement that governs
the Software.  If you do not have an existing agreement with SAS governing the Software,
you may not use the Code. */
/*******************************************************************************************/
/* Purpose of this program is to demonstrate comparisons between different typs of procedures
in SAS (MVA and High Performance, as well as CAS-enabled procedures)
/

/* Generate data for MVS versus HPA versus CAS comparisons */
/* Code adapted from Cohen and Rodriguez 2013
http://support.sas.com/resources/papers/proceedings13/401-2013.pdf

Note: 2,000,000 obs is approximately 2GB
*/



* Start a CAS session called mySession;
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US" metrics=false);
*Generate SAS librefs for caslibs;
caslib _all_ assign;


libname hp "/innovationlab-export/innovationlab/homes/T.Winand@sas.com/Data";
%let data = hp.synthdata;
%let casdata= casuser.synthdata;
*macro variables below control size and nature of synthetic data ;
%let nObs = 5000000;
%let nContIn = 20;
%let nContOut = 80;
%let nClassIn = 5;
%let nClassOut = 5;
%let maxLevs = 5;

data &data;
	array xIn{&nContIn};
	array xOut{&nContOut};
	array cIn{&nClassIn};
	array cOut{&nClassOut};
	drop i j sign nLevs xBeta expXBeta logitXBeta;

	do i=1 to &nObs;
		sign=-1;
		xBeta=0;

		do j=1 to dim(xIn);
			xIn{j}=ranuni(1);
			xBeta=xBeta + j*sign*xIn{j};
			sign=-sign;
		end;

		do j=1 to dim(xOut);
			xOut{j}=ranuni(1);
		end;
		xSubtle=ranuni(1);
		xTiny=ranuni(1);
		xBeta=xBeta + 0.1*xSubtle + 0.05*xTiny;

		do j=1 to dim(cIn);
			nLevs=min(1+j, &maxlevs);
			cIn{j}=1+int(ranuni(1)*nLevs);
			xBeta=xBeta + j*sign*(cIn{j}-nLevs/2);
			sign=-sign;
		end;

		do j=1 to dim(cOut);
			nLevs=min(1+j, &maxlevs);
			cOut{j}=1+int(ranuni(1)*nLevs);
		end;
		expXBeta=exp(xBeta/20);
		yPoisson=ranpoi(1, expXBeta);
		yNormal=xBeta + 10*rannor(1);
		logitXBeta=expXBeta/(1+expXBeta);

		if ranuni(1) < logitXBeta then
			yBinary=0;
		else
			yBinary=1;
		output;
	end;
run;

/* load SAS7bdat to CAS */
proc casutil;
	load data=&data
   outcaslib="CASUSER" casout="synthdata";
	quit;

	/******************** TABLE CONTENTS ************************/
proc contents data=&data;
run;

/* CAS-Enabled Contents */
proc casutil incaslib=casuser;
	contents casdata="synthdata";
	quit;

	/******************** DESCRIPTIVE STATISTICS ************************/
proc means data=&data VARDEF=DF MEAN STD STDERR VAR MIN MAX N NMISS;
	;
	var x:;
run;

/* CAS-Enabled Procedure for Descriprive Statistics */
proc mdsummary data=&casdata;
	var x:;
	output out=casuser.synth_summary;
run;

proc print data=casuser.synth_summary;
	var _Column_ _NObs_ _Mean_ _Max_ _Min_ _Std_;
run;

/*********************** FREQUENCY TABLES *************************/
proc freq data=&data;
	tables c:;
run;

/* CAS-Enabled Frequency Tables */
proc freqtab data=&casdata;
	tables c:;
run;

/*********************** LOGISTIC REGRESSION MODELS *****************/
proc logistic data=&data;
	class c: / param=glm;
	model yBinary (event="1")=x: c:;
run;

/* Can we make this logistic regression faster using a high performance in-memory procedure? */
proc hplogistic data=&data;
	class c:;
	model yBinary  (event="1")=x: c:;
run;

/* CAS-Enabled Logistic Regression */
proc logselect data=&casdata;
	class c:;
	model yBinary  (event="1")=x: c:;
run;

/**************** POISSON REGRESSION MODELS *****************************/
proc genmod data=&data;
	class c:;
	model yPoisson=x: c: /dist=Poisson;
run;

/* Potentailly faster using a high-performance procedure? */
proc hpgenselect data=&data;
	class c:;
	model yPoisson=x: c: /dist=Poisson;
run;

/* CAS-Enabled Generalized Linear Model */
proc genselect data=&casdata;
	class c:;
	model yPoisson=x: c: /dist=Poisson;
run;

/* Clean-up Data Tables */
proc datasets library=hp;
	delete synthdata;
	run;

proc datasets library=casuser;
	delete synthdata;
	delete synth_summary;

* terminate connection to CAS;
cas mySession terminate;