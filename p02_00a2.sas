********************************************************************
**     Program Name: /home/jhull/nangrong/prog_sas/p02_nets/2000/p02_00a2.sas
**     Programmer: james r. hull
**     Start Date: 2011 03 09
**     Purpose:
**        1.) Create A2 = UNPAID LABOR NETWORKS # WORKERS
**
**     Input Data:
**        '/home/jhull/nangrong/data_sas/2000/current/indiv00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/hh00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/comm00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/sibs00.xpt'
**
**     Output Data:
**        1.) /home/jhull/nangrong/data_paj/2000/a2/vXX00a2.net
**
**     Notes: 
**        1.)
**
*********************************************************************;

***************
**  Options  **
***************;

options nocenter linesize=80 pagesize=60;

%let f=00a2;  ** names file (allows portability) **;
%let y=00; 

**********************
**  Data Libraries  **
**********************;

libname in&f.1 xport '/home/jhull/nangrong/data_sas/2000/current/indiv00.xpt';
libname in&f.2 xport '/home/jhull/nangrong/data_sas/2000/current/hh00.xpt';
libname in&f.3 xport '/home/jhull/nangrong/data_sas/2000/current/comm00.xpt';
libname in&f.4 xport '/home/jhull/nangrong/data_sas/2000/current/sibs00.xpt';

******************************
**  Create Working Dataset  **
******************************;

********************************************************************
**  Length 10
**  0 In this 1984 village                2 + Village # + House #
**  2 In this village but blt             2 + Village # + 999
**  Length 7 
**  4 Another village in Nang Rong        3 + Village #
**  8 Unknown village in Nang Rong        3 + 999999
**  5 Another district in Buriram         4 + District # + 0000
**  6 Another province                    5 + District # + 0000
**  7 Another country 
**  8 Missing/Don't know                  9999999999 or 9999999
**  Length 9
**  9 Code 2 or 3 Returning HH member
*******************************************************************;

***************************************************************************
** Stack rice harvest labor data into a child file and label by location **
***************************************************************************;

data work&f.01a;
     set in&f.2.hh00 (keep=HHID00 X6_84C: X6_84W:);
     keep HHID00 X6_86L X6_86N X6_86W LOCATION;

     length X6_86L $ 10;

     array a(1:7) X6_84C1-X6_84C7;
     array b(1:7) X6_84W1-X6_84W7;

     do i=1 to 7;
          X6_86L=a(i);
          X6_86N=1;
          X6_86W=b(i);
          LOCATION=9;
          if a(i) ne " ." then output;  * Keep only those cases with data *;
     end;
run;

data work&f.01b;
     set in&f.2.hh00 (keep=HHID00 X6_85H: X6_85N: X6_85W:);
     keep HHID00 X6_86L X6_86N X6_86W LOCATION;

     length X6_86L $ 10;

     array a(1:13) X6_85H1-X6_85H13;
     array b(1:13) X6_85N1-X6_85N13;
     array c(1:13) X6_85W1-X6_85W13;

     do i=1 to 13;
 
          ** FIX ANOTHER CRAZY ERROR IN ORIGINAL DATA WITH REVERSED CODING FOR IN-VILLAGE LABOR **;
         
          if substr(a(i),5,3) in ('020','021','170','180') then a(i)=cat("2",substr(a(i),5,6),substr(a(i),2,3));

          if a(i)="9999999999" then LOCATION=8;
             else if substr(a(i),8,3)='999' then LOCATION=2;
             else LOCATION=0;

          X6_86L=a(i);
          X6_86N=b(i);
          X6_86W=c(i);

          if a(i) ne "         ." then output;  * Keep only those cases with data *;
     end;
run;

data work&f.01c;
     set in&f.2.hh00 (keep=HHID00 X6_86L: X6_86N: X6_86W:);
     keep HHID00 X6_86L X6_86N X6_86W LOCATION;

     length X6_86L $ 10;

     array a(1:10) X6_86L1-X6_86L10;
     array b(1:10) X6_86N1-X6_86N10;
     array c(1:10) X6_86W1-X6_86W10;

     do i=1 to 10;
          X6_86L=a(i);
          X6_86N=b(i);
          X6_86W=c(i);
          if a(i)='9999999' then LOCATION=8;
             else if substr(a(i),1,1)='5' then LOCATION=6;
             else if substr(a(i),1,1)='4' then LOCATION=5;
             else if substr(a(i),1,2)='39' then LOCATION=8;
             else LOCATION=4;
          if a(i) ne "      ." then output;  * Keep only those cases with data *;
     end;

run;

*********************************************************
** Take Care of Missing Data Issues - Recodes at least **
*********************************************************;

data work&f.02a;
     set work&f.01a;

     if X6_86W=9 then X6_86W=.;
     if X6_86N=99 then X6_86N=1; * Assume at least 1 person worked *;

run;

****************************************************************************
** This code collapses multiple code 2 & 3 workers from a household to    **
** a single observation and sums the values for each into summary counts. **
** For the "type of labor" variable, I use an "any paid --> paid" rule    **
** because paying a code 2 or 3 laborer is a rare behavior and distinct   **
****************************************************************************;

 data work&f.02a2;
     set work&f.02a;

     by HHID00;

     retain SUM_N SUM_TYPE SUM_LOC i;


     if first.HHID00 then do;
                            SUM_N=0;
                            SUM_TYPE=2; * Default is unpaid labor*;
                            SUM_LOC=9;
                            i=1;
                         end;

     SUM_N=SUM_N+X6_86N;
     if X6_86W=1 then SUM_TYPE=1;  * Any paid --> all paid *;
     SUM_LOC=9;
     i=i+1;

     if last.HHID00 then output;

run;

data work&f.02a3 (drop=SUM_N SUM_TYPE SUM_LOC i);
     set work&f.02a2;

     X6_86L="   ";
     X6_86N=SUM_N;
     X6_86W=SUM_TYPE;
     LOCATION=SUM_LOC;

run;

*********************************************************
** Take Care of Missing Data Issues - Recodes at least **
*********************************************************;

data work&f.02b;
     set work&f.01b;

     if X6_86W=9 then X6_86W=.;
     if X6_86N=99 then X6_86N=1; * Assume at least 1 person worked *;
run;

data work&f.02c;
     set work&f.01c;

     if X6_86W=9 then X6_86W=.;
     if X6_86N=99 then X6_86N=1; * Assume at least 1 person worked *;
run;

**************************
** Merge files together **
**************************;

data work&f.03;
     set work&f.02a3
         work&f.02b
         work&f.02c;
run;

***************************************************************************
** Add V84 identifiers to 2000 data file as per Rick's suggestion on web **
***************************************************************************;



proc sort data=work&f.03 out=work&f.04;
     by HHID00 X6_86L LOCATION;
run;

data vill_id_&f.01;
     set in&f.1.indiv00;
     keep HHID00 V84;
run;

proc sort data=vill_id_&f.01 out=vill_id_&f.02 nodupkey;
     by HHID00 v84;
run;

data vill_id_&f.03;
     merge work&f.04 (in=a)
           vill_id_&f.02 (in=b);
           if a=1 and b=1 then output;
     by HHID00;
run;

proc sort data=vill_id_&f.03 out=work&f.05;
     by V84;
run;

******************************************************************************
** This step removes all cases about which there is no information about    **
** how their laborers were compensated. This is my fix for the time being.  **
** Note: in doing so, I lose 7 cases (a case here is a helper group)        **
******************************************************************************;

data work&f.06;
     set work&f.05;

     rename X6_86L=HELPHHID;

     if X6_86W ^in (.,9) then output;

run;

************************************************************************************
** The steps below convert the ban lek ti information on the helping household    **
** into the standard HHID##, as a preparatory step to creating network datafiles. **
************************************************************************************;

data work&f.07;
     set work&f.06;

     if LOCATION=9 then do;
                           HELPHHID=HHID00;
                        end;
        else if LOCATION in(0,4) then do;
                                  HELPHHID=substr(HELPHHID,2,9);
                                end;
        else if LOCATION in (2) then do;
                                    HELPHHID=substr(HELPHHID,2,6);
                                end;
        else HELPHHID=".";
run;

*********************************
** Clean HELPHH00 of BAD CODES **
*********************************; 

data work&f.08a (drop=HHID&y.C);
     set work&f.07 (rename=(HHID&y=HHID&y.C));
     HELPHH00=input(HELPHHID,9.0);
     V84N=input(V84,2.0);
     HHID00=input(HHID&y.C,9.);
run;

data work&f.08b (drop=HHID00 V84);
     set in&f.1.indiv00 (keep=HHID00 V84);
     HELPHH00=input(HHID00,9.0);
     V84N=input(V84,2.0);
run;

proc sort data=work&f.08a out=work&f.09a;
     by V84N HELPHH00;
run;

proc sort data=work&f.08b out=work&f.09b nodupkey;
     by V84N HELPHH00;
run;

data work&f.10 aonly bonly;
     merge work&f.09a (in=a)
           work&f.09b (in=b);
     by V84N HELPHH00;
     if a=1 and b=1 then output work&f.10;
     if a=1 and b=0 then output aonly;
     if a=0 and b=1 then output bonly;
run;


** This step removes the HELPHH00 codes from a number of HHs **;
** that had non-existent or incorrect HHs listed as helping  **;

data aonly_fix;
     set aonly;
     if HELPHH00>999999 then do;     
                               HELPHH00=".";
                               HELPHHID=".";
                             end;
run;
 
data work&f.11;
     set work&f.10 (in=a)
         aonly_fix (in=b);
run;

************************************************************************
**input average village wages during high demand from community survey**
************************************************************************;

data work&f.vill_wages_01a (drop=X45MHIGH X45MTYP);  
    set in&f.3.comm&y (keep=VILL00 X45MHIGH X45MTYP);

    if X45MHIGH=9999998 then X45MHIGH=.; ** USING ONLY MALES B/C MALE AND FEMALE WAGES IDENTICAL **;
    if X45MTYP=9999998 then X45MTYP=.;

    if X45MHIGH=. then RICEWAGH=125.77;
       else RICEWAGH=X45MHIGH;
    if X45MTYP=. then RICEWAGN=105.29;
       else RICEWAGN=X45MTYP;
run;

proc sort data=work&f.vill_wages_01a out=work&f.vill_wages_01b nodupkey;
     by VILL&y;
run;

proc sort data=in&f.1.indiv&y  out=work&f.vill_wages_02a nodupkey;
     by HHID&y;
run;

data work&f.make_vill;
     set work&f.vill_wages_02a (keep=HHID&y);
     length VILL&y $ 6;

     VILL&y=substr(HHID&y,1,6);
run;

data work&f.numeric (drop=HHID&y.C);
     set work&f.make_vill (rename=(HHID&y=HHID&y.C));

     HHID&y=input(HHID&y.C,best9.);
run;

proc sort data=work&f.numeric out=work&f.vill_wages_02b;
     by VILL&y HHID&y;
run;

data work&f.vill_wages_03;
     merge work&f.vill_wages_01b (in=a)
           work&f.vill_wages_02b (in=b);
     by VILL&y;
     if b=1 then output;
run;

proc sort data=work&f.vill_wages_03 out=work&f.vill_wages_04;
     by HHID&y;
run;

proc sort data=work&f.11 out=work&f.vill_wages_05;
     by HHID&y;
run;

data work&f.vill_wages_06;
     merge work&f.vill_wages_04 (in=a)
           work&f.vill_wages_05 (in=b);
     by HHID&y;
     if b=1 then output;
run;

proc sort data=work&f.vill_wages_06 out=work&f.11B;
     by HHID&y;
run;

data work&f.11C;
     set work&f.11B;

     if X6_86W=3 then PAIDHH00=2;
        else PAIDHH00=X6_86W;

     if X6_86W=1 then ALLWAGE=round(X6_86N*RICEWAGH,.01);   ** ACTUAL DAYS WORKED*AVG WAGES IN VILL**;
        else ALLWAGE=0;                                             

     NUMWRKS=X6_86N;
  
run;

data work&f.12 (keep=HHID00 PAIDHH00 HELPHH00 LOCATION ALLWAGE NUMWRKS V84N);
     set work&f.11C;
run;

proc sort data=work&f.12 out=work&f.13;              ** MAJOR CHECKPOINT - TOTAL LABOR CHILD FILE **;
     by HHID&y HELPHH&y;
run;

*******************************************************************************************************************************;

***********************************************
** Separate Paid and Unpaid Labor into Files **
***********************************************;

** Note, all code below must be repeated for paid and then unpaid labor **;

**************************************************************************
** PAID: Create Village Aggregate Measures for Help from Beyond Village **
**************************************************************************;

%let p=paid;    *** saves keystrokes ***;

data work&f.14_&p (drop=PAIDHH&y);
     set work&f.13;
     if PAIDHH&y=1;
run;

** SPLIT DATA INTO 3 GROUPS - SAME VILL, OTH VILL, ALL OTHER **;

data work&f.15_&p._othvill (drop=LOCATION);   ** 1 **;
     set work&f.14_&p;
     if LOCATION in (4);
     if HELPHH&y ne .;
run;

data work&f.15_&p._vill (drop=LOCATION);      ** 2 **;
     set work&f.14_&p;
     if LOCATION in (0,1);
     if HELPHH&y ne .;
run;

data work&f.15_&p._other (drop=LOCATION);     ** 3 **;
     set work&f.14_&p;
     if (LOCATION in (2,3,5,6,7,8,9) OR HELPHH&y=.);
run;

****************************************************
** (1) OTHVILL: PROCESS LABOR FROM OTHER VILLAGES **
****************************************************;

** Collapse Labor from the same 84 village **;

data work&f.16_&p._othvill (keep=HHID&y V84N TOT_WRKS TOT_WAGE);
     set work&f.15_&p._othvill;

     retain TOT_WRKS TOT_WAGE;

     by HHID&y V84N;

     if first.V84N then do;
                          TOT_WRKS=0;
                          TOT_WAGE=0;
                        end;
     if NUMWRKS ne . then TOT_WRKS=TOT_WRKS+NUMWRKS;
     if ALLWAGE ne . then TOT_WAGE=TOT_WAGE+ALLWAGE;

    if last.V84N then output;
 
run;

** Merge with all rice-growing households **;

data work&f.add_all_01 (drop=HHID&y.C); 
     set vill_id_&f.02 (rename=(HHID&y=HHID&y.C));
     HHID&y=input(HHID&y.C,best12.);
run;

proc sort data=work&f.add_all_01 out=work&f.add_all_02;
     by HHID&y;
run;

data work&f.17_&p._othvill;
     merge work&f.16_&p._othvill (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;

data work&f.18_&p._othvill (drop=V84N TOT_WRKS TOT_WAGE i j);
     set work&f.17_&p._othvill;

     retain PID_H01-PID_H10 PWRK_H01-PWRK_H10 PWAG_H01-PWAG_H10 i;

     length PID_H01-PID_H10 8;             * 10 for good measure *;
     length PWRK_H01-PWRK_H10 8;             * 10 for good measure *;
     length PWAG_H01-PWAG_H10 8;             * 10 for good measure *;

     array id(1:10) PID_H01-PID_H10;
     array wk(1:10) PWRK_H01-PWRK_H10;
     array wg(1:10) PWAG_H01-PWAG_H10;
 
     by HHID&y;

     if first.HHID&y then do;
                            do j= 1 to 10;
                                id(j)=.;
                                wk(j)=.;
                                wg(j)=.;
                             end;
                             i=1;
                          end;

     id(i)=V84N;
     wk(i)=TOT_WRKS;
     wg(i)=TOT_WAGE;
     i=i+1;

    if last.HHID&y then output;
 
run;

***********************************************
** (2) VILL: PROCESS LABOR FROM SAME VILLAGE **
***********************************************;

** Placeholder for consistency **;

data work&f.16_&p._vill (keep=HHID&y HELPHH&y TOT_WRKS TOT_WAGE);
     set work&f.15_&p._vill;

     TOT_WRKS=NUMWRKS;
     TOT_WAGE=ALLWAGE;
RUN;

** Merge with all rice-growing households **;

data work&f.17_&p._vill;
     merge work&f.16_&p._vill (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;

data work&f.18_&p._vill (drop=HELPHH&y TOT_WRKS TOT_WAGE i j);
     set work&f.17_&p._vill;

     retain PID_H11-PID_H60 PWRK_H11-PWRK_H60 PWAG_H11-PWAG_H60 i;    ** Starts at 11 to leave room for village **; 

     length PID_H11-PID_H60 8;                 * 50 for good measure *;
     length PWRK_H11-PWRK_H60 8;             * 50 for good measure *;
     length PWAG_H11-PWAG_H60 8;             * 50 for good measure *;

     array id(1:50) PID_H11-PID_H60;
     array wk(1:50) PWRK_H11-PWRK_H60;
     array wg(1:50) PWAG_H11-PWAG_H60;
 
     by HHID&y;

     if first.HHID&y then do;
                            do j= 1 to 50;
                                id(j)=.;
                                wk(j)=.;
                                wg(j)=.;
                             end;
                             i=1;
                          end;

     id(i)=HELPHH&y;
     wk(i)=TOT_WRKS;
     wg(i)=TOT_WAGE;
     i=i+1;

    if last.HHID&y then output;
run;

****************************************
** (3) OTHER: PROCESS ALL OTHER LABOR **
****************************************;

** This labor is aggregated and included in an attribute file **;

** Placeholder for consistency **;

data work&f.16_&p._other (keep=HHID&y HELPHH&y NUMWRKS ALLWAGE);
     set work&f.15_&p._other;

RUN;

** Merge with all rice-growing households **;

data work&f.17_&p._other;
     merge work&f.16_&p._other (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;
** THIS FILE TO BE MERGED BELOW WITH OTHER ATTRIBUTES **;

data work&f.18_&p._other (drop=HELPHH&y NUMWRKS ALLWAGE);
     set work&f.17_&p._other;

     retain OTH_PWRK OTH_PWAG;
 
     by HHID&y;

     if first.HHID&y then do;
                            OTH_PWRK=0;
                            OTH_PWAG=0;
                          end;

     if NUMWRKS ne . then OTH_PWRK=OTH_PWRK+NUMWRKS;
     if ALLWAGE ne . then OTH_PWAG=OTH_PWAG+ALLWAGE;

    if last.HHID&y then output;
run;                                                             


***********************************
** Add other attribute variables ** 
***********************************;

** HH-LEVEL ATTRIBUTES **;

data work&f._&p._add_rice_hh (drop=HHID&y.C);
     set in&f.2.hh&y (keep=HHID&y RICE rename=(HHID&y=HHID&y.C));

     if RICE in (.,2,8) then RICE=0;

     IS_HH=1;

     HHID&y=input(HHID&y.C,best12.);
    
run;

** Merge with all rice-growing households **;

data work&f._&p._add_all_hh (drop=V84N LOCATION HELPHH&y);
     merge work&f.14_&p (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
                          
     if b=1 then output;
run;

data work&f._&p._add_tot_hh (drop=NUMWRKS ALLWAGE); **Generate Count Vars for ALL labor **;
     set work&f._&p._add_all_hh;

     retain ALL_PWRK ALL_PWAG;
 
     by HHID&y;

     if first.HHID&y then do;
                            ALL_PWRK=0;
                            ALL_PWAG=0;
                          end;

     if NUMWRKS ne . then ALL_PWRK=ALL_PWRK+NUMWRKS;
     if ALLWAGE ne . then ALL_PWAG=ALL_PWAG+ALLWAGE;

    if last.HHID&y then output;
run;                           

** MERGE **;

data work&f.19_&p._all_hh;
     merge work&f._&p._add_rice_hh (in=a)
           work&f._&p._add_tot_hh (in=b)
           work&f.18_&p._other (in=c);
     by HHID&y;
     if c=1 then output;
run;

data work&f.19_&p._all_hh_2 (drop=V84);
     set work&f.19_&p._all_hh;
     V84N=input(V84,2.0);
run;

** VILLAGE-LEVEL ATTRIBUTES **;

data work&f._&p._add_rice_vill (drop=V84 HHID&y);
     set work&f.add_all_02;
     RICE=1;
     IS_HH=0;
     OTH_PWRK=0;
     OTH_PWAG=0;
     V84N=input(V84,2.0);
run;

** Prep for merge **;

proc sort data=work&f._&p._add_rice_vill out=work&f._&p._add_rice_vill_2 nodupkey;
     by V84N;
run;

proc sort data=work&f.14_&p out=work&f.14_&p._by_v84;
     by V84N;
run;

**Generate Count Vars for ALL labor **;

data work&f._&p._add_tot_vill (drop=HHID&y HELPHH&y NUMWRKS ALLWAGE); 
     set work&f.14_&p._by_v84;

     retain ALL_PWRK ALL_PWAG;
 
     by V84N;

     if first.V84N then do;
                            ALL_PWRK=0;
                            ALL_PWAG=0;
                          end;

     if NUMWRKS ne . then ALL_PWRK=ALL_PWRK+NUMWRKS;
     if ALLWAGE ne . then ALL_PWAG=ALL_PWAG+ALLWAGE;

     if last.V84N then output;
run;                           

data work&f.19_&p._all_vill;
     merge work&f._&p._add_rice_vill_2 (in=a)
           work&f._&p._add_tot_vill (in=b);
     by V84N;

     HHID&y=V84N;
     if b=1 then output;
run;

***************************************
** Merge HH and VILL Attribute Files **
***************************************;

data work&f.19_&p._attrib;
     set work&f.19_&p._all_vill (drop=LOCATION)
         work&f.19_&p._all_hh_2;
run;

**********************************************
** Merge Same and Other Village Labor Files **
**********************************************;

data work&f.19_&p._adjlist;
     merge work&f.18_&p._othvill (in=b)
           work&f.18_&p._vill (in=a);
     by HHID&y;

     if a=1 and b=1 then output;
run;

***********************************************************
** Add Villages to adjacency matrix - all missing values **
***********************************************************;

proc sort data=vill_id_&f.02 out=add_vill_&p._&f._01 nodupkey;
     by V84;
run;

data add_vill_&p._&f._02 (drop=V84 j);
     set add_vill_&p._&f._01 (drop=HHID&y);

     length PID_H01-PID_H60 8;                 
     length PWRK_H01-PWRK_H60 8;             
     length PWAG_H01-PWAG_H60 8;             

     array id(1:60) PID_H01-PID_H60;
     array wk(1:60) PWRK_H01-PWRK_H60;
     array wg(1:60) PWAG_H01-PWAG_H60;
 
     do j= 1 to 60;
        id(j)=.;
        wk(j)=.;
        wg(j)=.;
     end;
 
     HHID&y=input(V84,best12.);    
     V84N=input(V84,2.);    

run;   

data add_vill_&p._&f._03 (drop=V84);
     set work&f.19_&p._adjlist;
     V84N=input(V84,2.0);
run;
 
data add_vill_&p._&f._04;
     set add_vill_&p._&f._02 
         add_vill_&p._&f._03;
run;


****************************************************************************
** UNPAID: Create Village Aggregate Measures for Help from Beyond Village **
****************************************************************************;

%let p=unpaid;    *** saves keystrokes ***;

data work&f.14_unpaid (drop=PAIDHH&y);
     set work&f.13;
     if PAIDHH&y=2;
run;

** SPLIT DATA INTO 3 GROUPS - SAME VILL, OTH VILL, ALL OTHER **;

data work&f.15_&p._othvill (drop=LOCATION);   ** 1 **;
     set work&f.14_&p;
     if LOCATION in (4);
     if HELPHH&y ne .;
run;

data work&f.15_&p._vill (drop=LOCATION);      ** 2 **;
     set work&f.14_&p;
     if LOCATION in (0,1);
     if HELPHH&y ne .;
run;

data work&f.15_&p._other (drop=LOCATION);     ** 3 **;
     set work&f.14_&p;
     if (LOCATION in (2,3,5,6,7,8,9) OR HELPHH&y=.);
run;

****************************************************
** (1) OTHVILL: PROCESS LABOR FROM OTHER VILLAGES **
****************************************************;

** Collapse Labor from the same 84 village **;

data work&f.16_&p._othvill (keep=HHID&y V84N TOT_WRKS TOT_WAGE);
     set work&f.15_&p._othvill;

     retain TOT_WRKS TOT_WAGE;

     by HHID&y V84N;

     if first.V84N then do;
                          TOT_WRKS=0;
                          TOT_WAGE=0;
                        end;
     if NUMWRKS ne . then TOT_WRKS=TOT_WRKS+NUMWRKS;
     if ALLWAGE ne . then TOT_WAGE=TOT_WAGE+ALLWAGE;

    if last.V84N then output;
 
run;

** Merge with all rice-growing households **;

data work&f.add_all_01 (drop=HHID&y.C); 
     set vill_id_&f.02 (rename=(HHID&y=HHID&y.C));
     HHID&y=input(HHID&y.C,best12.);
run;

proc sort data=work&f.add_all_01 out=work&f.add_all_02;
     by HHID&y;
run;

data work&f.17_&p._othvill;
     merge work&f.16_&p._othvill (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;


data work&f.18_&p._othvill (drop=V84N TOT_WRKS TOT_WAGE i j);
     set work&f.17_&p._othvill;

     retain UID_H01-UID_H10 UWRK_H01-UWRK_H10 UWAG_H01-UWAG_H10 i;

     length UID_H01-UID_H10 8;             * 10 for good measure *;
     length UWRK_H01-UWRK_H10 8;             * 10 for good measure *;
     length UWAG_H01-UWAG_H10 8;             * 10 for good measure *;

     array id(1:10) UID_H01-UID_H10;
     array wk(1:10) UWRK_H01-UWRK_H10;
     array wg(1:10) UWAG_H01-UWAG_H10;
 
     by HHID&y;

     if first.HHID&y then do;
                            do j= 1 to 10;
                                id(j)=.;
                                wk(j)=.;
                                wg(j)=.;
                             end;
                             i=1;
                          end;

     id(i)=V84N;
     wk(i)=TOT_WRKS;
     wg(i)=TOT_WAGE;
     i=i+1;

    if last.HHID&y then output;
 
run;

***********************************************
** (2) VILL: PROCESS LABOR FROM SAME VILLAGE **
***********************************************;

** Placeholder for consistency **;

data work&f.16_&p._vill (keep=HHID&y HELPHH&y TOT_WRKS TOT_WAGE);
     set work&f.15_&p._vill;

     TOT_WRKS=NUMWRKS;
     TOT_WAGE=ALLWAGE;
RUN;

** Merge with all rice-growing households **;

data work&f.17_&p._vill;
     merge work&f.16_&p._vill (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;

data work&f.18_&p._vill (drop=HELPHH&y TOT_WRKS TOT_WAGE i j);
     set work&f.17_&p._vill;

     retain UID_H11-UID_H60 UWRK_H11-UWRK_H60 UWAG_H11-UWAG_H60 i;    ** Starts at 11 to leave room for village **; 

     length UID_H11-UID_H60 8;                 * 50 for good measure *;
     length UWRK_H11-UWRK_H60 8;             * 50 for good measure *;
     length UWAG_H11-UWAG_H60 8;             * 50 for good measure *;

     array id(1:50) UID_H11-UID_H60;
     array wk(1:50) UWRK_H11-UWRK_H60;
     array wg(1:50) UWAG_H11-UWAG_H60;
 
     by HHID&y;

     if first.HHID&y then do;
                            do j= 1 to 50;
                                id(j)=.;
                                wk(j)=.;
                                wg(j)=.;
                             end;
                             i=1;
                          end;

     id(i)=HELPHH&y;
     wk(i)=TOT_WRKS;
     wg(i)=TOT_WAGE;
     i=i+1;

    if last.HHID&y then output;
run;

****************************************
** (3) OTHER: PROCESS ALL OTHER LABOR **
****************************************;

** This labor is aggregated and included in an attribute file **;

** Placeholder for consistency **;

data work&f.16_&p._other (keep=HHID&y HELPHH&y NUMWRKS ALLWAGE);
     set work&f.15_&p._other;

RUN;

** Merge with all rice-growing households **;

data work&f.17_&p._other;
     merge work&f.16_&p._other (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
     if b=1 then output;
run;

** Unstack data from child file to mother (household) file **;
** THIS FILE TO BE MERGED BELOW WITH OTHER ATTRIBUTES **;

data work&f.18_&p._other (drop=HELPHH&y NUMWRKS ALLWAGE);
     set work&f.17_&p._other;

     retain OTH_UWRK OTH_UWAG;
 
     by HHID&y;

     if first.HHID&y then do;
                            OTH_UWRK=0;
                            OTH_UWAG=0;
                          end;

     if NUMWRKS ne . then OTH_UWRK=OTH_UWRK+NUMWRKS;
     if ALLWAGE ne . then OTH_UWAG=OTH_UWAG+ALLWAGE;

    if last.HHID&y then output;
run;                                                             


***********************************
** Add other attribute variables ** 
***********************************;

** HH-LEVEL ATTRIBUTES **;

data work&f._&p._add_rice_hh (drop=HHID&y.C);
     set in&f.2.hh&y (keep=HHID&y RICE rename=(HHID&y=HHID&y.C));

     if RICE in (.,2,8) then RICE=0;

     IS_HH=1;

     HHID&y=input(HHID&y.C,best12.);

run;

** Merge with all rice-growing households **;

data work&f._&p._add_all_hh (drop=V84N LOCATION HELPHH&y);
     merge work&f.14_&p (in=a)
           work&f.add_all_02 (in=b);
     by HHID&y;
                          
     if b=1 then output;
run;

data work&f._&p._add_tot_hh (drop=NUMWRKS ALLWAGE); **Generate Count Vars for ALL labor **;
     set work&f._&p._add_all_hh;

     retain ALL_UWRK ALL_UWAG;
 
     by HHID&y;

     if first.HHID&y then do;
                            ALL_UWRK=0;
                            ALL_UWAG=0;
                          end;

     if NUMWRKS ne . then ALL_UWRK=ALL_UWRK+NUMWRKS;
     if ALLWAGE ne . then ALL_UWAG=ALL_UWAG+ALLWAGE;

    if last.HHID&y then output;
run;                           

** MERGE **;

data work&f.19_&p._all_hh;
     merge work&f._&p._add_rice_hh (in=a)
           work&f._&p._add_tot_hh (in=b)
           work&f.18_&p._other (in=c);
     by HHID&y;
     if c=1 then output;
run;

data work&f.19_&p._all_hh_2 (drop=V84);
     set work&f.19_&p._all_hh;
     V84N=input(V84,2.0);
run;

** VILLAGE-LEVEL ATTRIBUTES **;

data work&f._&p._add_rice_vill (drop=V84 HHID&y);
     set work&f.add_all_02;
     RICE=1;
     IS_HH=0;
     OTH_UWRK=0;
     OTH_UWAG=0;
     V84N=input(V84,2.0);
run;

** Prep for merge **;

proc sort data=work&f._&p._add_rice_vill out=work&f._&p._add_rice_vill_2 nodupkey;
     by V84N;
run;

proc sort data=work&f.14_&p out=work&f.14_&p._by_v84;
     by V84N;
run;

**Generate Count Vars for ALL labor **;

data work&f._&p._add_tot_vill (drop=HHID&y HELPHH&y NUMWRKS ALLWAGE); 
     set work&f.14_&p._by_v84;

     retain ALL_UWRK ALL_UWAG;
 
     by V84N;

     if first.V84N then do;
                            ALL_UWRK=0;
                            ALL_UWAG=0;
                          end;

     if NUMWRKS ne . then ALL_UWRK=ALL_UWRK+NUMWRKS;
     if ALLWAGE ne . then ALL_UWAG=ALL_UWAG+ALLWAGE;

     if last.V84N then output;
run;                           

data work&f.19_&p._all_vill;
     merge work&f._&p._add_rice_vill_2 (in=a)
           work&f._&p._add_tot_vill (in=b);
     by V84N;

     HHID&y=V84N;
     if b=1 then output;
run;

***************************************
** Merge HH and VILL Attribute Files **
***************************************;

data work&f.19_&p._attrib;
     set work&f.19_&p._all_vill (drop=LOCATION)
         work&f.19_&p._all_hh_2;
run;

**********************************************
** Merge Same and Other Village Labor Files **
**********************************************;

data work&f.19_&p._adjlist;
     merge work&f.18_&p._othvill (in=b)
           work&f.18_&p._vill (in=a);
     by HHID&y;

     if a=1 and b=1 then output;
run;

***********************************************************
** Add Villages to adjacency matrix - all missing values **
***********************************************************;

proc sort data=vill_id_&f.02 out=add_vill_&p._&f._01 nodupkey;
     by V84;
run;

data add_vill_&p._&f._02 (drop=V84 j);
     set add_vill_&p._&f._01 (drop=HHID&y);

     length UID_H01-UID_H60 8;                 
     length UWRK_H01-UWRK_H60 8;             
     length UWAG_H01-UWAG_H60 8;             

     array id(1:60) UID_H01-UID_H60;
     array wk(1:60) UWRK_H01-UWRK_H60;
     array wg(1:60) UWAG_H01-UWAG_H60;
 
     do j= 1 to 60;
        id(j)=.;
        wk(j)=.;
        wg(j)=.;
     end;
 
     HHID&y=input(V84,best12.);    
     V84N=input(V84,2.);    

run;   

data add_vill_&p._&f._03 (drop=V84);
     set work&f.19_&p._adjlist;
     V84N=input(V84,2.0);
run;
 
data add_vill_&p._&f._04;
     set add_vill_&p._&f._02 
         add_vill_&p._&f._03;
run;


*******************************************************************************************************************;

*********************************************************************
** Temporarily Merge Together All 4 Final Files to purge ID errors **
*********************************************************************;

proc sort data=add_vill_paid_&f._04 out=work&f.20_paid_adj;
     by HHID&y V84N;
run;

proc sort data=add_vill_unpaid_&f._04 out=work&f.20_unpaid_adj;
     by HHID&y V84N;
run;

proc sort data=work&f.19_paid_attrib out=work&f.20_paid_att;
     by HHID&y V84N;
run;

proc sort data=work&f.19_unpaid_attrib out=work&f.20_unpaid_att;
     by HHID&y V84N;
run;


data work&f.21_all_files;
     merge work&f.20_paid_adj (in=a)
           work&f.20_unpaid_adj (in=b)
           work&f.20_paid_att (in=c)
           work&f.20_unpaid_att (drop=RICE IS_HH in=d);
     by HHID&y V84N;
     if a=1 and b=1 and c=1 and d=1 then output;
run;  

*******************************************
** Format files to be exported to UCINET **
*******************************************;

** I have decided to revert these matrices back to hh-only - 2011 02 07 **;
** These changes are reflected only in the four data steps below **;
** The village-level information still exists in all prior data steps **;
** In the future, I'd like to add a village-level only analysis **;

** I have also re-combined all files into a single one as of 2011 02 09 **;

data r&y._all (drop=PID_H01-PID_H10 PWRK_H01-PWRK_H10 PWAG_H01-PWAG_H10
                    UID_H01-UID_H10 UWRK_H01-UWRK_H10 UWAG_H01-UWAG_H10);
     set work&f.21_all_files;

     ALL_WRKS=ALL_PWRK+ALL_UWRK;
     ALL_WAGE=ALL_PWAG+ALL_UWAG;

     if HHID&y>100;               * Remove village datalines *;
run;

**************************************************************************************************;

***************************************************************************************
* 8 ** VILLAGE NETWORKS: RICE UNPAID ** Create VALUED adjacency matrices: # WORKERS  **
***************************************************************************************;

** Use transpose in final step to reverse direction of ties, indicating labor movement **;

************************************************
** Create separate village files EACH VILLAGE **
************************************************;

%macro v_split (numvill=);  %* macro splits villages *;

       %* NUMVILL=Number of Unique Villages in file *;

%do i=1 %to &numvill;

    data r00_u&i (drop=V84N);
         set r&y._all;
         if V84N=&i;
    run;

%end;

%mend v_split;

%v_split (numvill=51);

%macro v_adj1 (numvill=);
%do i=1 %to &numvill;
proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/2000/a2-net/v0);
     %let p2=%quote(00a2.net);
     use r00_u&i;
     read all var{
                  UID_H11 UID_H12 UID_H13 UID_H14 UID_H15
                  UID_H16 UID_H17 UID_H18 UID_H19 UID_H20
                  UID_H21 UID_H22 UID_H23 UID_H24 UID_H25
                  UID_H26 UID_H27 UID_H28 UID_H29 UID_H30
                  UID_H31 UID_H32 UID_H33 UID_H34 UID_H35
                  UID_H36 UID_H37 UID_H38 UID_H39 UID_H40
                  UID_H41 UID_H42 UID_H43 UID_H44 UID_H45
                  UID_H46 UID_H47 UID_H48 UID_H49 UID_H50
                  UID_H51 UID_H52 UID_H53 UID_H54 UID_H55
                  UID_H56 UID_H57 UID_H58 UID_H59 UID_H60} into rcv;
     read all var{
                  UWRK_H11 UWRK_H12 UWRK_H13 UWRK_H14 UWRK_H15
                  UWRK_H16 UWRK_H17 UWRK_H18 UWRK_H19 UWRK_H20
                  UWRK_H21 UWRK_H22 UWRK_H23 UWRK_H24 UWRK_H25
                  UWRK_H26 UWRK_H27 UWRK_H28 UWRK_H29 UWRK_H30
                  UWRK_H31 UWRK_H32 UWRK_H33 UWRK_H34 UWRK_H35
                  UWRK_H36 UWRK_H37 UWRK_H38 UWRK_H39 UWRK_H40
                  UWRK_H41 UWRK_H42 UWRK_H43 UWRK_H44 UWRK_H45
                  UWRK_H46 UWRK_H47 UWRK_H48 UWRK_H49 UWRK_H50
                  UWRK_H51 UWRK_H52 UWRK_H53 UWRK_H54 UWRK_H55
                  UWRK_H56 UWRK_H57 UWRK_H58 UWRK_H59 UWRK_H60} into val;
     read all var{HHID00} into snd;
     r00_u=adjval(snd,rcv,val);
     id=r00_u[,1];
     r00_u=r00_u[,2:ncol(r00_u)];
     adj=r00_u;
     file "&p1.&i.&p2";
     call pajwrite(adj`,id,2);
     adjinv=adj`;
     create adj0&i from adjinv;
            append from adjinv;
     idinv=id`;
     create id0&i from idinv;
            append from idinv;
quit;
%end;
%mend v_adj1;

%v_adj1(numvill=9);


%macro v_adj2 (numvill=);
%do i=10 %to &numvill;
proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/2000/a2-net/v);
     %let p2=%quote(00a2.net);
     use r00_u&i;
     read all var{
                  UID_H11 UID_H12 UID_H13 UID_H14 UID_H15
                  UID_H16 UID_H17 UID_H18 UID_H19 UID_H20
                  UID_H21 UID_H22 UID_H23 UID_H24 UID_H25
                  UID_H26 UID_H27 UID_H28 UID_H29 UID_H30
                  UID_H31 UID_H32 UID_H33 UID_H34 UID_H35
                  UID_H36 UID_H37 UID_H38 UID_H39 UID_H40
                  UID_H41 UID_H42 UID_H43 UID_H44 UID_H45
                  UID_H46 UID_H47 UID_H48 UID_H49 UID_H50
                  UID_H51 UID_H52 UID_H53 UID_H54 UID_H55
                  UID_H56 UID_H57 UID_H58 UID_H59 UID_H60} into rcv;
     read all var{
                  UWRK_H11 UWRK_H12 UWRK_H13 UWRK_H14 UWRK_H15
                  UWRK_H16 UWRK_H17 UWRK_H18 UWRK_H19 UWRK_H20
                  UWRK_H21 UWRK_H22 UWRK_H23 UWRK_H24 UWRK_H25
                  UWRK_H26 UWRK_H27 UWRK_H28 UWRK_H29 UWRK_H30
                  UWRK_H31 UWRK_H32 UWRK_H33 UWRK_H34 UWRK_H35
                  UWRK_H36 UWRK_H37 UWRK_H38 UWRK_H39 UWRK_H40
                  UWRK_H41 UWRK_H42 UWRK_H43 UWRK_H44 UWRK_H45
                  UWRK_H46 UWRK_H47 UWRK_H48 UWRK_H49 UWRK_H50
                  UWRK_H51 UWRK_H52 UWRK_H53 UWRK_H54 UWRK_H55
                  UWRK_H56 UWRK_H57 UWRK_H58 UWRK_H59 UWRK_H60} into val;
     read all var{HHID00} into snd;
     r00_u=adjval(snd,rcv,val);
     id=r00_u[,1];
     r00_u=r00_u[,2:ncol(r00_u)];
     adj=r00_u;
     file "&p1.&i.&p2";
     call pajwrite(adj`,id,2);
     adjinv=adj`;
     create adj&i from adjinv;
            append from adjinv;
     idinv=id`;
     create id&i from idinv;
            append from idinv;
quit;
%end;
%mend v_adj2;

%v_adj2(numvill=51);

%macro v_adj3(numvill=);
%do i=1 %to &numvill;
    data _null_ ;
         %let p1=%quote(/home/jhull/nangrong/data_paj/2000/a2-adj/v0);
         %let p2=%quote(00a2.adj);
         set adj0&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/2000/a2-id/v0);
         %let p4=%quote(00a2.id);
         set id0&i;
         file "&p3.&i.&p4"  lrecl=10000;
         put (_ALL_) (+0);
run;

%end;
%mend v_adj3;

%v_adj3(numvill=9);

%macro v_adj4(numvill=);
%do i=10 %to &numvill;  
    data _null_ ;
         %let p1=%quote(/home/jhull/nangrong/data_paj/2000/a2-adj/v);
         %let p2=%quote(00a2.adj);
         set adj&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/2000/a2-id/v);
         %let p4=%quote(00a2.id);
         set id&i;
         file "&p3.&i.&p4"  lrecl=10000;
         put (_ALL_) (+0);
run;
%end;
%mend v_adj4;

%v_adj4(numvill=51);





