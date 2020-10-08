*********************************************************************
**     Program Name: /home/jhull/nangrong/prog_sas/p02_nets/1994/p02_94a4.sas
**     Programmer: james r. hull
**     Start Date: 2011 03 09
**     Purpose:
**        1.) Create A4 = UNPAID RICE NETWORKS TOTAL FLOWS IN BAHT
**
**     Input Data:
**        '/home/jhull/nangrong/data_sas/1994/current/indiv94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/hh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/comm94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/helprh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/sibs94.xpt'
**
**     Output Data:
**        1.) /home/jhull/nangrong/data_paj/1994/a4/vXX94a4
**            
**     Notes: 
**        1.) 
**
*********************************************************************;

***************
**  Options  **
***************;

options nocenter linesize=80 pagesize=60;

%let f=94a4;  ** names file (allows portability) **;
%let y=94; 

**********************
**  Data Libraries  **
**********************;

libname in&f.1 xport '/home/jhull/nangrong/data_sas/1994/current/indiv94.xpt';
libname in&f.2 xport '/home/jhull/nangrong/data_sas/1994/current/hh94.xpt';
libname in&f.3 xport '/home/jhull/nangrong/data_sas/1994/current/comm94.xpt';
libname in&f.4 xport '/home/jhull/nangrong/data_sas/1994/current/helprh94.xpt';
libname in&f.5 xport '/home/jhull/nangrong/data_sas/1994/current/sibs94.xpt';



******************************
**  Create Working Dataset  **
******************************;

* This code stacks the code 2&3 help into a child file *;
* It adds the location=9 variable and codes # helpers=1 for all *;

data work&f.01;
     set in&f.2.hh94(keep=hhid94 Q6_23A: Q6_23B: Q6_23C: Q6_23D:);
     keep HHID94 Q6_24A Q6_24B Q6_24C Q6_24D Q6_24E LOCATION;

          length Q6_24A $ 7;

          array a(1:5) Q6_23A1-Q6_23A5;
          array b(1:5) Q6_23B1-Q6_23B5;
          array c(1:5) Q6_23C1-Q6_23C5;
          array d(1:5) Q6_23D1-Q6_23D5;

          do i=1 to 5;
               Q6_24A=a(i);
               Q6_24B=1;
               Q6_24C=b(i);
               Q6_24D=c(i);
               Q6_24E=d(i);
               LOCATION=9;
               if Q6_24A ne '998' then output;  *Keep only those cases with data *;
          end;
run;

****************************************************************************
** This code collapses multiple code 2 & 3 workers from a household to    **
** a single observation and sums the values for each into summary counts. **
** For the "type of labor" variable, I use an "any paid --> paid" rule    **
** because paying a code 2 or 3 laborer is a rare behavior and distinct   **
****************************************************************************;

data work&f.01b;
     set work&f.01;
     if Q6_24E in(996,999) then Q6_24E=.;
run;

data work&f.01c;
     set work&f.01b;

     by HHID94;

     retain SUM_B SUM_C SUM_E SUM_TYPE SUM_LOC i;


     if first.HHID94 then do;
                            SUM_B=0;
                            SUM_C=0;
                            SUM_E=0;
                            SUM_TYPE=2; * Default is unpaid labor*;
                            SUM_LOC=9;
                            i=1;
                         end;

     SUM_B=SUM_B+Q6_24B;
     SUM_C=SUM_C+Q6_24C;
     SUM_E=SUM_E+Q6_24E;
     if Q6_24D=1 then SUM_TYPE=1;  * Any paid --> all paid *;
     SUM_LOC=9;
     i=i+1;

     if last.HHID94 then output;

run;

data work&f.01d (drop=SUM_B SUM_C SUM_E SUM_TYPE SUM_LOC i);
     set work&f.01c;

     Q6_24A="   ";
     Q6_24B=SUM_B;
     Q6_24C=(SUM_C/(i-1));
     Q6_24D=SUM_TYPE;
     Q6_24E=SUM_E;
     LOCATION=SUM_LOC;

run;

********************************************************************
**  Label helping households according to source of labor         **
********************************************************************;

********************************************************************
**  0 In this village Ban Lek Ti + 0000
**  2 In this village but blt is unknown 997 + 0000
**  1 In this split village Ban Lek Ti + Village #
**  3 In this split village but blt is unknown 997 + Village #
**  4 Another village in Nang Rong 000 + Village #
**  5 Another district in Buriram 000 + District #
**  6 Another province 000 + Province #
**  7 Another country 000 + Country #
**  8 Missing/Don't know 9999999
**  9 Code 2 or 3 Returning HH member
*******************************************************************;

data work&f.02;
     set in&f.4.helprh&y (keep=HHID&y Q6_24A Q6_24B Q6_24C Q6_24D Q6_24E);

     if Q6_24A in ('9999997','0009999','9999999') then LOCATION=8;                  *allmissing*;
        else if substr(Q6_24A,1,3)='000' and substr(Q6_24A,4,1)='5' then LOCATION=7;  *country*;
        else if substr(Q6_24A,1,3)='000' and substr(Q6_24A,4,1)='4' then LOCATION=6;  *province*;
        else if substr(Q6_24A,1,3)='000' and substr(Q6_24A,4,1)='3' then LOCATION=5;  *district*;
        else if substr(Q6_24A,1,3)='000' and substr(Q6_24A,4,1)='2' then LOCATION=4;  *othervill*;
        else if substr(Q6_24A,1,3)='997' and substr(Q6_24A,4,1)='2' then LOCATION=3;  *splitmissing*;
        else if substr(Q6_24A,1,3)='997' and substr(Q6_24A,4,1)='0' then LOCATION=2;  *samemissing*;
        else if substr(Q6_24A,4,4)='9999' then LOCATION=2;   *samemissing*;
        else if substr(Q6_24A,4,4)='0000' then LOCATION=0;   *samevill*;
        else if substr(Q6_24A,4,1)='2' then LOCATION=1;      *splitvill*;
        else if substr(Q6_24A,4,1)='0' then LOCATION=1;      *splitvill*;
        else LOCATION=.;                                     * LOGIC PROBLEMS IF . > 0 *;

        if Q6_24C=99 then Q6_24C=1;        *RECODES*;    *If number of days unknown, code as 1 *;
        if Q6_24B=99 then Q6_24B=1;                      *If number of workers unknown, code as 1 *;
                                                         *No recodes needed for Q6_24D *;
        if Q6_24E=996 then Q6_24E=.;                     *If wages unknown, code as "."  *;
           else if Q6_24E=998 then Q6_24E=.;             *The above recodes to 1 impact 22 and 12 helping hhs respectively *;
           else if Q6_24E=999 then Q6_24E=.;             *The logic is that if the hh was named then at least*;
run;                                                     * one person worked for at least 1 day *;

data work&f.03;
     set work&f.01d
         work&f.02;
run;

***************************************************************************
** Add V84 identifiers to 1994 data file as per Rick's comments on web   **
***************************************************************************;

proc sort data=work&f.03 out=work&f.04;
     by hhid94 q6_24a LOCATION;
run;

data vill_id_&f.01;
     set in&f.1.indiv94;
     keep HHID94 V84;
run;

proc sort data=vill_id_&f.01 out=vill_id_&f.02 nodupkey;
     by HHID94 v84;
run;

data vill_id_&f.03;
     merge work&f.04 (in=a)
           vill_id_&f.02 (in=b);
           if a=1 and b=1 then output;
     by HHID94;
run;

proc sort data=vill_id_&f.03 out=work&f.05;
     by V84 HHID94;
run;

******************************************************************************
** This step removes all cases about which there is no information about    **
** how their laborers were compensated. This is my fix for the time being.  **
** Note: in doing so, I lose 11 cases (a case here is a helper group)        **
******************************************************************************;

data work&f.06;
     set work&f.05;

     rename Q6_24A=HELPHHID;
     HHID94_C=put(HHID94,z8.);

     if Q6_24D ^in (.,9) then output;

run;

************************************************************************************
** The steps below convert the ban lek ti information on the helping household    **
** into the standard HHID##, as a preparatory step to creating network datafiles. **
************************************************************************************;

data work&f.07;
     set work&f.06;

     length HELPVILL $ 4;
     length HELP_LEK $ 3;
     length VILL_LEK $ 7;

     *Fix data coding errors*;

     if HELPHHID="0220162" then HELPHHID="0222016"; 
     if HELPHHID="0412057" then HELPHHID="0412059"; 
     if HELPHHID="0262041" then HELPHHID="0262014"; 
     if HELPHHID="0742014" then HELPHHID="0742041"; 
     if HELPHHID="1012014" then HELPHHID="1012041"; 
     if HELPHHID="0392053" then HELPHHID="0392056"; 
     if HELPHHID="0502039" then HELPHHID="0502036"; 
     if HELPHHID="0242031" then HELPHHID="0242044"; 

     if HELPHHID="   " then HELPHH94=HHID94;
        else HELPHH94=.;

     if HELPHH94=. then do;
                          HELPVILL=substr(HELPHHID,4,4);
                          if HELPVILL="0000" then HELPVILL=substr(HHID94_C,1,4);
                          HELP_LEK=substr(HELPHHID,1,3);
                          VILL_LEK=cats(HELPVILL,HELP_LEK);
                        end;

run;

data work&f.08;

     set in&f.1.indiv94 (keep=HHID94 LEKTI94 VILL94);

     length VILL_LEK $ 7;

     VILL_LEK=cat(VILL94,LEKTI94);

     rename HHID94=HHID94_2;
run;

*********************************
** Clean HELPHHID of BAD CODES **
*********************************; 

proc sort data=work&f.07 out=work&f.09a;
     by VILL_LEK;
run;

proc sort data=work&f.08 out=work&f.09b nodupkey;
     by VILL_LEK;
run;

data work&f.10;
     merge work&f.09a (in=a)
           work&f.09b (in=b);
     by VILL_LEK;
     if a=1 then output;

run;

************************************************************************
**input average village wages during high demand from community survey**
************************************************************************;

data work&f.vill_wages_01 (drop=BSY76_1 NBSY76_1);

    set in&f.3.comm&y (keep=VILL94 VILL84 BSY76_1 NBSY76_1);

    if BSY76_1=998 then BSY76_1=.;    ** USING ONLY MAKES B/C MALE AND FEMALE WAGES IDENTICAL **;
    if NBSY76_1=998 then NBSY76_1=.;
   
    if BSY76_1=. then RICEWAGH=57.75;  ** Mean value for variable in 1994 **;    
       else RICEWAGH=BSY76_1;
    if NBSY76_1=. then RICEWAGN= 50.79;
       else RICEWAGN=NBSY76_1;
run;

proc sort data=in&f.1.indiv&y out=work&f.vill_wages_02 (keep=VILL&y HHID&y) nodupkey;
     by HHID&y;
run;

proc sort data=work&f.vill_wages_02 out=work&f.vill_wages_03;
     by VILL&y HHID&y;
run;

data work&f.vill_wages_04;
     merge work&f.vill_wages_01 (in=a)
           work&f.vill_wages_03 (in=b);
     by VILL&y;
     if b=1 then output;
run;

proc sort data=work&f.vill_wages_04 out=work&f.vill_wages_05;
     by HHID&y;
run;

proc sort data=work&f.10 out=work&f.vill_wages_06;
     by HHID&y;
run;

data work&f.vill_wages_06;
     merge work&f.vill_wages_05 (in=a)
           work&f.vill_wages_06 (in=b);
     by HHID&y;
     if b=1 then output;
run;

proc sort data=work&f.vill_wages_06 out=work&f.10B;
     by HHID&y;
run;

data work&f.11 (drop=HHID94_2 HELPHHID HHID94_C HELPVILL HELP_LEK VILL94 LEKTI94 V84);
     set work&f.10B;

     if HELPHH94=. then do;
                          if LOCATION in (0,1) then HELPHH94=HHID94_2;
                             else if LOCATION in (9) then HELPHH94=HHID94;        
                             else if LOCATION in (4) then HELPHH94=input(HELPVILL,best12.);
                             else HELPHH94=.;
                        end;

     if Q6_24D=3 then PAIDHH94=2;
        else PAIDHH94=Q6_24D;

     if Q6_24D=1 then do;                                                  ** ACTUAL DAYS WORKED*AVG WAGES IN VILL**;
                        if Q6_24E=. then ALLWAGE=round(1*RICEWAGH,.01);               ** Uses 1 day when days working is missing **;
                           else ALLWAGE=round(Q6_24B*RICEWAGH,.01);                   
                      end;
        else ALLWAGE=0;                                             

     ** alternate measures only available in 1994 **;

*     if Q6_24D=1 then do;                                                 ** ACTUAL PERSONS*ACTUAL DAYS*AVG WAGES IN VILL **;
*                        if Q6_24C=. then ALLWAGE2=round(Q6_24B*1*RICEWAGH,.01);      ** Uses 1 day when days working is missing **;
*                        else ALLWAGE2=round(Q6_24B*Q6_24C*RICEWAGH,.01);
*                      end;
*        else ALLWAGE2=0;

*     if Q6_24D=1 then do;                                                  ** ACTUAL DAYS WORKED*ACTUAL PERSONS*ACTUAL WAGES (94 ONLY) **;
*                        if Q6_24E=. then ALLWAGE3=round(Q6_24B*Q6_24C*57,.01);        **Uses 57 baht as wage for missing in  1994**;
*                           else if Q6_24C=. then ALLWAGE3=round(Q6_24B*1*Q6_24E,.01); ** Uses 1 day when days working is missing **;
*                           else ALLWAGE3=round(Q6_24B*Q6_24C*Q6_24E,.01);  
*                      end;
*        else ALLWAGE3=0;                                             

     NUMWRKS=Q6_24B;
  
     V84N=input(V84,2.0);
run;

data work&f.12 (keep=HHID94 PAIDHH94 HELPHH94 ALLWAGE LOCATION NUMWRKS V84N);
     set work&f.11;
run;

proc sort data=work&f.12 out=work&f.13;                 ** MAJOR CHECKPOINT - TOTAL LABOR CHILD FILE **;
     by HHID&y V84N;
run;

*****************************************************************************************************************************;

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
** This is mostly pro forma in 1994 as there were no HHs with labor from multiple villages **;

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

data work&f._&p._add_rice_hh (drop=Q6_16);
     set in&f.2.hh&y (keep=HHID&y Q6_16);

     if Q6_16 in (.,2) then RICE=0;
        else RICE=1;

     IS_HH=1;
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
** This is mostly pro forma in 1994 as there were no HHs with labor from multiple villages **;

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

data work&f._&p._add_rice_hh (drop=Q6_16);
     set in&f.2.hh&y (keep=HHID&y Q6_16);

     if Q6_16 in (.,2) then RICE=0;
        else RICE=1;

     IS_HH=1;
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

************************************************
** Create separate village files EACH VILLAGE **
************************************************;

%macro v_split (numvill=);  %* macro splits villages *;

       %* NUMVILL=Number of Unique Villages in file *;

%do i=1 %to &numvill;

    data r94_u&i (drop=V84N);
         set r&y._all;
         if V84N=&i;
    run;

%end;

%mend v_split;

%v_split (numvill=51);

***************************************************************************************
* 9 ** VILLAGE NETWORKS: RICE UNPAID ** Create VALUED adjacency matrices: TOT WAGES  **
***************************************************************************************;

%macro v_adj1 (numvill=);
%do i=1 %to &numvill;
proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/a4-net/v0);
     %let p2=%quote(94a4.net);
     use r94_u&i;
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
                  UWAG_H11 UWAG_H12 UWAG_H13 UWAG_H14 UWAG_H15
                  UWAG_H16 UWAG_H17 UWAG_H18 UWAG_H19 UWAG_H20
                  UWAG_H21 UWAG_H22 UWAG_H23 UWAG_H24 UWAG_H25
                  UWAG_H26 UWAG_H27 UWAG_H28 UWAG_H29 UWAG_H30
                  UWAG_H31 UWAG_H32 UWAG_H33 UWAG_H34 UWAG_H35
                  UWAG_H36 UWAG_H37 UWAG_H38 UWAG_H39 UWAG_H40
                  UWAG_H41 UWAG_H42 UWAG_H43 UWAG_H44 UWAG_H45
                  UWAG_H46 UWAG_H47 UWAG_H48 UWAG_H49 UWAG_H50
                  UWAG_H51 UWAG_H52 UWAG_H53 UWAG_H54 UWAG_H55
                  UWAG_H56 UWAG_H57 UWAG_H58 UWAG_H59 UWAG_H60} into val;
     read all var{HHID94} into snd;
     r94_n=adjval(snd,rcv,val);
     id=r94_n[,1];
     r94_n=r94_n[,2:ncol(r94_n)];
     adj=r94_n;
     file "&p1.&i.&p2";
     call pajwrite(adj,id,2);
     create adj0&i from adj;
            append from adj;
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
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/a4-net/v);
     %let p2=%quote(94a4.net);
     use r94_u&i;
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
                  UWAG_H11 UWAG_H12 UWAG_H13 UWAG_H14 UWAG_H15
                  UWAG_H16 UWAG_H17 UWAG_H18 UWAG_H19 UWAG_H20
                  UWAG_H21 UWAG_H22 UWAG_H23 UWAG_H24 UWAG_H25
                  UWAG_H26 UWAG_H27 UWAG_H28 UWAG_H29 UWAG_H30
                  UWAG_H31 UWAG_H32 UWAG_H33 UWAG_H34 UWAG_H35
                  UWAG_H36 UWAG_H37 UWAG_H38 UWAG_H39 UWAG_H40
                  UWAG_H41 UWAG_H42 UWAG_H43 UWAG_H44 UWAG_H45
                  UWAG_H46 UWAG_H47 UWAG_H48 UWAG_H49 UWAG_H50
                  UWAG_H51 UWAG_H52 UWAG_H53 UWAG_H54 UWAG_H55
                  UWAG_H56 UWAG_H57 UWAG_H58 UWAG_H59 UWAG_H60} into val;
     read all var{HHID94} into snd;
     r94_n=adjval(snd,rcv,val);
     id=r94_n[,1];
     r94_n=r94_n[,2:ncol(r94_n)];
     adj=r94_n;
     file "&p1.&i.&p2";
     call pajwrite(adj,id,2);
     create adj&i from adj;
            append from adj;
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/1994/a4-adj/v0);
         %let p2=%quote(94a4.adj);
         set adj0&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/1994/a4-id/v0);
         %let p4=%quote(94a4.id);
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/1994/a4-adj/v);
         %let p2=%quote(94a4.adj);
         set adj&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/1994/a4-id/v);
         %let p4=%quote(94a4.id);
         set id&i;
         file "&p3.&i.&p4"  lrecl=10000;
         put (_ALL_) (+0);
run;
%end;
%mend v_adj4;

%v_adj4(numvill=51);