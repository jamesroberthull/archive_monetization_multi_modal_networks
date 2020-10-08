*********************************************************************
**     Program Name: /home/jhull/nangrong/prog_sas/p02_nets/1994/p02_94b1.sas
**     Programmer: james r. hull
**     Start Date: 2011 03 09
**     Purpose:
**        1.) CREATE B1 - Male Sibling Networks
**     Input Data:
**        '/home/jhull/nangrong/data_sas/1994/current/indiv94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/hh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/comm94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/helprh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/sibs94.xpt'
**
**     Output Data:
**        1.) /home/jhull/nangrong/data_paj/1994/b1/vXX94b1.net
**            
**     Notes: 
**        1.) 
**
*********************************************************************;

***************
**  Options  **
***************;

options nocenter linesize=80 pagesize=60;

%let f=94b1;  ** names file (allows portability) **;
%let y=94; 

**********************
**  Data Libraries  **
**********************;

libname in&f.1 xport '/home/jhull/nangrong/data_sas/1994/current/indiv94.xpt';
libname in&f.2 xport '/home/jhull/nangrong/data_sas/1994/current/hh94.xpt';
libname in&f.3 xport '/home/jhull/nangrong/data_sas/1994/current/comm94.xpt';
libname in&f.4 xport '/home/jhull/nangrong/data_sas/1994/current/helprh94.xpt';
libname in&f.5 xport '/home/jhull/nangrong/data_sas/1994/current/sibs94.xpt';

*************************************************************************************************************************;

*************************************************
**  Create Sibling and Parent Network Matrices **
*************************************************;

**************
** SIBLINGS **
**************;

*******************************************************************************
**                                                                           **
** Coding for original location variables for siblings not in HH             **
**                                                                           **
** In this village                            1 + 0 + Ban Lek Ti + 0000      **
** In this split village                      1 + 0 + Ban Lek Ti + Village # **
** Temple in this village                     1 + 0 + 996        + 0000      **
** Temple in this split village               1 + 0 + 996        + Village # **
** In this village but ban lek ti unknown     1 + 0 + 999        + 0000      **
** In this split village but blt unknown      1 + 0 + 999        + Village # **
** Another village in Nang Rong               2 + Village #      + 0000      **
** Another village but village # is unknown   2 + 9999           + 0000      **
** Another district of Buriram                3 + District #     + 0000      **
** Another district but district # is unknown 3 + 9999           + 0000      **
** Another province                           4 + Province #     + 0000      **
** Another province but province # is unknown 4 + 9999           + 0000      **
** Another country                            5 + Country #      + 0000      **
** N/A                                        9 + 9999           + 9998      **
** Missing/Don?t know                         9 + 9999           + 9999      **
**                                                                           **
*******************************************************************************;

data work&f.31 (keep=HHID94 sex age place);
     set in&f.5.sibs94 (keep=HHID94 Q4_5P: Q4_5S: Q4_5A:);

     length place $9;

     array a(1:12) Q4_5A1-Q4_5A12;
     array s(1:12) Q4_5S1-Q4_5S12;
     array p(1:12) Q4_5P1-Q4_5P12;

     do i=1 to 12;
        SEX=s(i);
        AGE=a(i);
        PLACE=p(i);
        if PLACE ^in ('999999999','999999998')  then output;
     end;
run;

data work&f.32 (drop=HHID94C VILLAGE BLT94 LOCATION SEX) work&f.33 (drop=HHID94C BLT94 VILLBLT);
     set work&f.31;

     HHID94C=put(HHID94,z8.);


     if AGE in (98,99) then AGE=.;
     if SEX in (8,9) then SEX=.;

     if SEX=2 then MALE=0;
        else if SEX=1 then MALE=1;
        else MALE=.;

     if substr(PLACE,1,1)='1' then LOCATION=1;
     if substr(PLACE,1,1)='2' then LOCATION=2;
     if substr(PLACE,1,1)='3' then LOCATION=3;
     if substr(PLACE,1,1)='4' then LOCATION=4;
     if substr(PLACE,1,1)='5' then LOCATION=5;

     if LOCATION=1 then do;
                           if substr(PLACE,6,4)='0000' then VILLAGE=substr(HHID94C,1,4);
                              else VILLAGE=substr(PLACE,6,4);
                        end;

     if LOCATION=2 then do;
                           if substr(PLACE,2,4) ne '9999' then VILLAGE=substr(PLACE,2,4);
                        end;


     if LOCATION=1 and substr(PLACE,3,2) ne '99' then BLT94=substr(PLACE,3,3);


     if VILLAGE ne "    " and BLT94 ne "   " then VILLBLT=trim(VILLAGE)||BLT94;

     ** All Identifiable In-Village Sibling Ties **;

     if LOCATION in (1,2) and VILLAGE ne '    ' and BLT94 ne '   ' then output work&f.32;

     ** All Identifiable Sibling Ties in Nang Rong (Excludes other Provinces, etc.) **;

     if LOCATION in (1,2) and VILLAGE ne '    ' then output work&f.33;

run;

******************************************************************************************
** Re-Sort by VILLAGE and BLT then merge to standard list to remove errors and mistakes **
******************************************************************************************;

* Add V84 so that data can be sorted by both V84 and HHID00 before merging *;

data vill_id_&f.01;
     set in&f.1.indiv94;
     keep HHID94 V84;
run;

proc sort data=vill_id_&f.01 out=vill_id_&f.02 nodupkey;
     by HHID94 v84;
run;

data work&f.32b;
     merge work&f.32 (in=a)
           vill_id_&f.02 (in=b);
     by HHID94;
     if a=1 then output;
run;

data work&f.34 (drop=VILL94 LEKTI94);
     set in&f.2.hh94 (keep=HHID94 VILL94 LEKTI94);

     SIBHH94=HHID94;

     VILLBLT=VILL94||LEKTI94;
run;

data work&f.34b (drop=HHID94);
     merge work&f.34 (in=a)
           vill_id_&f.02 (in=b);
     by HHID94;
     if a=1 then output;
run;

proc sort data=work&f.32b out=work&f.35;
     by V84 VILLBLT;
run;

proc sort data=work&f.34b out=work&f.36;
     by V84 VILLBLT;
run;

data work&f.37 (drop=PLACE VILLBLT);
     merge work&f.35 (in=a)
           work&f.36 (in=b);
     by V84 VILLBLT;
     if a=1 and b=1 then output;
run;

proc sort data=work&f.37 out=work&f.38;                 
     by HHID94;
run;                                      


*********************************************
** Reformat character variables to numeric **
*********************************************;

data work&f.40 (drop=SIBHH94 HHID94 V84);
     set work&f.38;

     SIBHH94N=input(strip(SIBHH94),9.);
     HHID94N=input(strip(HHID94),9.);
     V84N=input(V84,2.);
run;

data work&f.41 (drop=SIBHH94N HHID94N V84N);
     set work&f.40;

     SIBHH94=SIBHH94N;
     HHID94=HHID94N;
     V84=V84N;
run;                                   ** Major Checkpoint - Village Sibling "Child" File **;

****************************************************************************
** MALES: Separate Males from Females to Create Separate Sibling Networks **
****************************************************************************;

%let g=male;

data work&f.41_&g;
     set work&f.41;
     if MALE=1;
run;

**************************************************************
** MALES: Collapse non-ego HHs containing multiple siblings **
**************************************************************;

proc sort data=work&f.41_&g out=work&f.42_&g;
     by HHID94 SIBHH94;
run;

data work&f.43_&g;
     set work&f.42_&g;

     HHSIB94=trim(HHID94)||strip(SIBHH94);
run;

data work&f.44_&g (drop=MALE AGE HHSIB94 i);
     set work&f.43_&g;

     by HHSIB94;

     retain SUM_SEX SUM_AGE SUM_SIB MIS_SIB i;


     if first.HHSIB94 then do;
                             SUM_SEX=0;
                             SUM_AGE=0;
                             SUM_SIB=0;
                             MIS_SIB=0;
                             i=1;
                           end;

     if MALE ne . then SUM_SEX=SUM_SEX+MALE;
     if AGE ne . then SUM_AGE=SUM_AGE+AGE;
     if AGE ne . then MIS_SIB=MIS_SIB+1;
     SUM_SIB=SUM_SIB+1;
     i=i+1;

    if last.HHSIB94 then output;

run;

data work&f.45_&g (drop=SUM_SEX SUM_AGE MIS_SIB);
     set work&f.44_&g;

     RAT_M=round(SUM_SEX/SUM_SIB,.01);
     if MIS_SIB=0 then AVG_A=round(SUM_AGE/SUM_SIB,.01);
        else AVG_A=round(SUM_AGE/MIS_SIB,.01);
run;

******************************************
** MALES: Unstack back to a mother file **
******************************************;

data work&f.46_&g (keep= HHID94 V84 MALE01-MALE16 AGE01-AGE16 NUM01-NUM16 SIBHH01-SIBHH16);
     set work&f.45_&g;
     by HHID94;

     retain MALE01-MALE16 AGE01-AGE16 NUM01-NUM16 SIBHH01-SIBHH16 i;


     array s(1:16) MALE01-MALE16;
     array a(1:16) AGE01-AGE16;
     array t(1:16) NUM01-NUM16;
     array p(1:16) SIBHH01-SIBHH16;

     if first.HHID94 then do;
                            do j=1 to 16;
                                        s(j)=.;
                                        a(j)=.;
                                        t(j)=.;
                                        p(j)=.;
                            end;
                            i=1;
                          end;

     s(i)=RAT_M;
     a(i)=AVG_A;
     t(i)=SUM_SIB;
     p(i)=SIBHH94;

     i=i+1;

     if last.HHID94 then output;
run;

*************************************************
** MALES: merge in households with no siblings **
*************************************************;


data vill_id&f.43_&g (drop=V84 HHID94);
     set vill_id_&f.02;
     V84N=input(V84,2.0);
     HHID94N=input(strip(HHID94),9.0);
run;

data vill_id&f.44_&g (drop=V84N HHID94N);
     set vill_id&f.43_&g;
     V84=V84N;
     HHID94=HHID94N;
run;

data work&f.47_&g;
     merge work&f.46_&g (in=a)
           vill_id&f.44_&g (in=b);
     by HHID94;
     if b=1 then output;
run;


***********************************************************
** MALES: Create separate village files for EACH VILLAGE **
***********************************************************;

proc sort data=work&f.47_&g out=work&f.48_&g;
     by V84 HHID94;
run;

%macro v_split (numvill=);  %* macro splits villages *;

       %* NUMVILL=Number of Unique Villages in file *;

%do i=1 %to &numvill;

    data v94_ms&i (drop=V84);
         set work&f.48_&g;
         if V84=&i;
    run;

%end;

%mend v_split;

%v_split (numvill=51);


*********************************************************************************
** MALES: Create 51 VALUED adjacency matrices, one for each village - siblings **
*********************************************************************************;

%macro v_adj1 (numvill=);
%do i=1 %to &numvill;
proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
     %include '/home/jhull/public/span/uciwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1-net/v0);
     %let p2=%quote(94b1.net);
     use v94_ms&i;
     read all var{SIBHH01 SIBHH02 SIBHH03 SIBHH04 SIBHH05
                  SIBHH06 SIBHH07 SIBHH08 SIBHH09 SIBHH10
                  SIBHH11 SIBHH12 SIBHH13 SIBHH14 SIBHH15
                  SIBHH16} into rcv;
     read all var{NUM01 NUM02 NUM03 NUM04 NUM05
                  NUM06 NUM07 NUM08 NUM09 NUM10
                  NUM11 NUM12 NUM13 NUM14 NUM15
                  NUM16} into val;
     read all var{HHID94} into snd;
     r94_ms=adjval(snd,rcv,val);
     id=r94_ms[,1];
     r94_ms=r94_ms[,2:ncol(r94_ms)];
     adj=r94_ms;
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
     %include '/home/jhull/public/span/uciwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1-net/v);
     %let p2=%quote(94b1.net);
     use v94_ms&i;
     read all var{SIBHH01 SIBHH02 SIBHH03 SIBHH04 SIBHH05
                  SIBHH06 SIBHH07 SIBHH08 SIBHH09 SIBHH10
                  SIBHH11 SIBHH12 SIBHH13 SIBHH14 SIBHH15
                  SIBHH16} into rcv;
     read all var{NUM01 NUM02 NUM03 NUM04 NUM05
                  NUM06 NUM07 NUM08 NUM09 NUM10
                  NUM11 NUM12 NUM13 NUM14 NUM15
                  NUM16} into val;
     read all var{HHID94} into snd;
     r94_ms=adjval(snd,rcv,val);
     id=r94_ms[,1];
     r94_ms=r94_ms[,2:ncol(r94_ms)];
     adj=r94_ms;
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1-adj/v0);
         %let p2=%quote(94b1.adj);
         set adj0&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/1994/b1-id/v0);
         %let p4=%quote(94b1.id);
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1-adj/v);
         %let p2=%quote(94b1.adj);
         set adj&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/1994/b1-id/v);
         %let p4=%quote(94b1.id);
         set id&i;
         file "&p3.&i.&p4"  lrecl=10000;
         put (_ALL_) (+0);
run;
%end;
%mend v_adj4;

%v_adj4(numvill=51);