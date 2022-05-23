/*set path variable*/

%let path=/home/u60602026/ECRB94/data;

/*library*/
libname tsa "&path";

options validvarname=v7;

/*import*/
proc import datafile="&path/TSAClaims2002_2017.csv" dbms=csv out=tsa.claimsimport replace;
guessingrows=max;
run;

/*
proc contents data=tsa.claimsimport varnum;
run;

proc freq data=tsa.claimsimport;
	tables Claim_Site
			Disposition
			Claim_Type
			Date_Received
			Incident_Date / nocum nopercent;
run;
*/

/*sort nodups order*/
proc sort data=tsa.claimsimport out=tsa.claimsnodups noduprecs;
	by _all_;
run;

proc sort data=tsa.claimsnodups;
	by Incident_Date;
run;

/* clean data */
data tsa.claims_cleaned;
	set tsa.claimsnodups;

/* correcting claim type misspellings */
if Claim_Type in ("-", "") then Claim_Type="Unknown";
else if Claim_Type="Property Damage/Personal Injury" then Claim_Type = "Property Damage";
else if Claim_Type="Passenger Property Loss/Personal Injur" then Claim_Type="Passenger Property Loss";
else if Claim_Type="Passenger Property Loss/Personal Injury" then Claim_Type="Passenger Property Loss";

if Claim_Site in ("-", "") then Claim_Site="Unknown";

/* correcting disposition misspellings */
if Disposition in ("-", "") then Disposition="Unknown";
else if Disposition="Closed: Canceled" then Disposition="Closed:Canceled";
else if Disposition="losed: Contractor Claim" then Disposition="Closed:Contractor Claim";

/* standardizing state name */
StateName=propcase(StateName);
State=upcase(State);

/* setting dates to be reviewed */
if (Incident_Date > Date_Received or
Incident_Date= "." or
Date_Received= "." or
year(Incident_Date) < 2002 or 
year(Incident_Date) > 2017 or
year(Date_Received) < 2002 or 
year(Incident_Date) > 2017) then Date_Issues="Needs Review";

drop County City;

/* formatting */
format Close_Amount dollar9.;
format Date_Received Incident_Date date9.;

label Claim_Number = 'Claim Number'
Date_Received = 'Date Received'
Incident_Date = 'Incident Date'
Airport_Code ='Airport Code'
Airport_Name='Airport Name'
Claim_Type='Claim Type'
Claim_Site='Claim Site'
Item_Category='Item Category'
Close_Amount='Close Amount';
run;

/* freq date issues*/
title "Frequency of Date Issues";
proc freq data=tsa.claims_cleaned;
	table Date_Issues / missing nocum nopercent;
run;
title;

/* plot trends */
ods graphics on;
title "Incident Date Trends";
proc freq data=tsa.claims_cleaned;
	where Date_Issues ^= "Needs Review";
	tables Incident_Date /nocum nopercent plots=freqplot;
	format Incident_Date year9.;
run;
title;

/* frequency by any state */
title "Claim Information for State";
%let state=HI;
proc freq data=tsa.claims_cleaned;
	where Date_Issues is null;
	where StateName="Hawaii";
	/*where State="&state";*/
	tables Claim_Type Claim_Site Disposition / nocum nopercent;
run;
title;

/* close amount statistics for any state */
title "Close Amount Statistics";
proc means data=tsa.claims_cleaned mean min max sum maxdec=0;
	 var Close_Amount;
	 format Close_Amount dollar9.;
	 where State="&state";
run;
title;