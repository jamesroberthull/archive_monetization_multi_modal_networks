********************************************************************
**     Program Name: /home/jhull/nangrong/prog_sas/p02_nets/2000/p02_00b1.sas
**     Programmer: james r. hull
**     Start Date: 2011 03 09
**     Purpose:
**        1.) Create B1 = MALE SIBLING NETWORKS
**
**     Input Data:
**        '/home/jhull/nangrong/data_sas/2000/current/indiv00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/hh00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/comm00.xpt'
**        '/home/jhull/nangrong/data_sas/2000/current/sibs00.xpt'
**
**     Output Data:
**        1.) /home/jhull/nangrong/data_paj/2000/b1/vXX00b1.net
**
**     Notes: 
**        1.) 
**
*********************************************************************;

***************
**  Options  **
***************;

options nocenter linesize=80 pagesize=60;

%let f=00b1;  ** names file (allows portability) **;
%let y=00; 

**********************
**  Data Libraries  **
**********************;

libname in&f.1 xport '/home/jhull/nangrong/data_sas/2000/current/indiv00.xpt';
libname in&f.2 xport '/home/jhull/nangrong/data_sas/2000/current/hh00.xpt';
libname in&f.3 xport '/home/jhull/nangrong/data_sas/2000/current/comm00.xpt';
libname in&f.4 xport '/home/jhull/nangrong/data_sas/2000/current/sibs00.xpt';


*****************************************************************************************************;

*************************************************
**  Create Sibling and Parent Network Matrices **
*************************************************;

**************
** SIBLINGS **
**************;

**********************************************************************************
**                                                                              **
** In this (1984) village                     2 + Village #  + House #          **
** In this (1984) village, house # is unknown 2 + Village #  + 999              **
** Another village in Nang Rong               3 + 000            + Village #    **
** In Nang Rong, but village # is unknown     3 + 000            + 999999       **
** Outside Nang Rong, but within Buriram      4 + 0 + District # + 000000       **
** Another province                           5 + 0 + Province # + 000000       **
** Another country                            6 + 0 + Country #  + 000000       **
** N/A                                        [ ]                               **
** Missing/Don?t know                         9 + 999            + 999999       **
**                                                                              **
**********************************************************************************;

data work&f.31 (keep=HHID00 SEX AGE PLACE);
     set in&f.4.sibs00 (keep=HHID00 X4_5A: X4_5S: X4_5R:);

     length place $10.;

     array a(1:16) X4_5A1-X4_5A16;
     array s(1:16) X4_5S1-X4_5S16;
     array p(1:16) X4_5R1-X4_5R16;

     do i=1 to 16;
        SEX=s(i);
        AGE=a(i);
        PLACE=p(i);
        if PLACE ^in ("9999999999","          ")  then output;
     end;
run;

data work&f.32 (drop=HHID00C VILLAGE BLT00 LOCATION SEX) work&f.33 (drop=HHID00C BLT00 VILLBLT);
     set work&f.31;

     HHID00C=put(HHID00,$9.);


     if AGE in (99,.) then AGE=.;
     if SEX in (9,.) then SEX=.;

     if SEX=2 then MALE=0;
        else if SEX=1 then MALE=1;
        else MALE=.;

     if substr(PLACE,1,1)="2" then LOCATION=1;
     if substr(PLACE,1,1)="3" then LOCATION=2;
     if substr(PLACE,1,1)="4" then LOCATION=3;
     if substr(PLACE,1,1)="5" then LOCATION=4;
     if substr(PLACE,1,1)="6" then LOCATION=5;

     if LOCATION=1 then VILLAGE=substr(PLACE,2,6);

     if LOCATION=2 then do;
                           if substr(PLACE,5,6) ne "999999" then VILLAGE=substr(PLACE,5,6);
                        end;


     if LOCATION=1 and substr(PLACE,8,3) ne "999" then BLT00=substr(PLACE,8,3);


     if VILLAGE ne "      " and BLT00 ne "   " then VILLBLT=trim(VILLAGE)||BLT00;

     ** All Identifiable In-Village Sibling Ties **;

     if LOCATION in (1,2) and VILLAGE ne "      " and BLT00 ne "   " then output work&f.32;

     ** All Identifiable Sibling Ties in Nang Rong (Excludes other Provinces, etc.) **;

     if LOCATION in (1,2) and VILLAGE ne "      " then output work&f.33;

run;

******************************************************************************************
** Re-Sort by VILLAGE and BLT then merge to standard list to remove errors and mistakes **
******************************************************************************************;

data vill_id_&f.01;
     set in&f.1.indiv00;
     keep HHID00 V84;
run;

proc sort data=vill_id_&f.01 out=vill_id_&f.02 nodupkey;
     by HHID00 v84;
run;

data work&f.32b;
     merge work&f.32 (in=a)
           vill_id_&f.02 (in=b);
     by HHID00;
     if a=1 then output;
run;


data work&f.34 (drop=VILL00 HOUSE00);
     set in&f.2.hh00 (keep=HHID00 VILL00 HOUSE00);

     SIBHH00=HHID00;

     VILLBLT=VILL00||HOUSE00;
run;

data work&f.34b (drop=HHID00);
     merge work&f.34 (in=a)
           vill_id_&f.02 (in=b);
     by HHID00;
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
     by HHID00;
run;


*********************************************
** Reformat character variables to numeric **
*********************************************;

data work&f.40 (drop=SIBHH00 HHID00 V84);
     set work&f.38;

     SIBHH00N=input(strip(SIBHH00),9.);
     HHID00N=input(strip(HHID00),9.);
     V84N=input(V84,2.);
run;

data work&f.41 (drop=SIBHH00N HHID00N V84N);
     set work&f.40;

     SIBHH00=SIBHH00N;
     HHID00=HHID00N;
     V84=V84N;
run;                                     ** Major Checkpoint - Village Sibling "Child" File **;

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
     by HHID00 SIBHH00;
run;

data work&f.43_&g;
     set work&f.42_&g;

     HHSIB00=trim(HHID00)||strip(SIBHH00);
run;

data work&f.44_&g (drop=MALE AGE HHSIB00 i);
     set work&f.43_&g;

     by HHSIB00;

     retain SUM_SEX SUM_AGE SUM_SIB MIS_SIB i;

     if first.HHSIB00 then do;
                             SUM_SEX=0;
                             SUM_AGE=0;
                             SUM_SIB=0;
                             MIS_SIB=0;
                             i=1;
                           end;

     SUM_SEX=SUM_SEX+MALE;
     if AGE ne . then SUM_AGE=SUM_AGE+AGE;
     if AGE ne . then MIS_SIB=MIS_SIB+1;
     SUM_SIB=SUM_SIB+1;
     i=i+1;

    if last.HHSIB00 then output;

run;

data work&f.45_&g(drop=SUM_SEX SUM_AGE MIS_SIB);
     set work&f.44_&g;

     RAT_M=round(SUM_SEX/SUM_SIB,.01);
     if MIS_SIB=0 then AVG_A=round(SUM_AGE/SUM_SIB,.01);
        else AVG_A=round(SUM_AGE/MIS_SIB,.01);
run;

******************************************
** MALES: Unstack back to a mother file **
******************************************;

data work&f.46_&g (keep= HHID00 V84 MALE01-MALE16 AGE01-AGE16 NUM01-NUM16 SIBHH01-SIBHH16);
     set work&f.45_&g;
     by HHID00;

     retain MALE01-MALE16 AGE01-AGE16 NUM01-NUM16 SIBHH01-SIBHH16 i;


     array s(1:16) MALE01-MALE16;
     array a(1:16) AGE01-AGE16;
     array t(1:16) NUM01-NUM16;
     array p(1:16) SIBHH01-SIBHH16;

     if first.HHID00 then do;
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
     p(i)=SIBHH00;

     i=i+1;

     if last.HHID00 then output;
run;

*************************************************
** MALES: merge in households with no siblings **
*************************************************;

data vill_id_&f.03_&g (drop=V84 HHID00);
     set vill_id_&f.02;
     V84N=input(V84,2.0);
     HHID00N=input(HHID00,9.0);
run;

data vill_id_&f.04_&g (drop=V84N HHID00N);
     set vill_id_&f.03_&g;
     V84=V84N;
     HHID00=HHID00N;
run;

data work&f.47_&g;
     merge work&f.46_&g (in=a)
           vill_id_&f.04_&g (in=b);
     by HHID00;
     if b=1 then output;
run;


***********************************************************
** MALES: Create separate village files for EACH VILLAGE **
***********************************************************;

proc sort data=work&f.47_&g out=work&f.48_&g;
     by V84 HHID00;
run;

%macro v_split (numvill=);  %* macro splits villages *;

       %* NUMVILL=Number of Unique Villages in file *;

%do i=1 %to &numvill;

    data v00_ms&i (drop=V84);
         set work&f.48_&g;
         if V84=&i;
    run;

%end;

%mend v_split;

%v_split (numvill=51);


*******************************************************************************
** MALES: Create 51 VALUED adjacency matrices, one for each village -sibling **
*******************************************************************************;

%macro v_adj1 (numvill=);

%do i=1 %to &numvill;

proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
     %include '/home/jhull/public/span/uciwrite.mod';
     %let p1=%quote(/home/jhull/nangrong/data_paj/2000/b1-net/v0);
     %let p2=%quote(00b1.net);
     use v00_ms&i;
     read all var{SIBHH01 SIBHH02 SIBHH03 SIBHH04 SIBHH05
                  SIBHH06 SIBHH07 SIBHH08 SIBHH09 SIBHH10
                  SIBHH11 SIBHH12 SIBHH13 SIBHH14 SIBHH15
                  SIBHH16} into rcv;
     read all var{NUM01 NUM02 NUM03 NUM04 NUM05
                  NUM06 NUM07 NUM08 NUM09 NUM10
                  NUM11 NUM12 NUM13 NUM14 NUM15
                  NUM16} into val;

     read all var{HHID00} into snd;
     r00_ms=adjval(snd,rcv,val);
     id=r00_ms[,1];
     r00_ms=r00_ms[,2:ncol(r00_ms)];
     adj=r00_ms;
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
     %let p1=%quote(/home/jhull/nangrong/data_paj/2000/b1-net/v);
     %let p2=%quote(00b1.net);
     use v00_ms&i;
     read all var{SIBHH01 SIBHH02 SIBHH03 SIBHH04 SIBHH05
                  SIBHH06 SIBHH07 SIBHH08 SIBHH09 SIBHH10
                  SIBHH11 SIBHH12 SIBHH13 SIBHH14 SIBHH15
                  SIBHH16} into rcv;
     read all var{NUM01 NUM02 NUM03 NUM04 NUM05
                  NUM06 NUM07 NUM08 NUM09 NUM10
                  NUM11 NUM12 NUM13 NUM14 NUM15
                  NUM16} into val;
     read all var{HHID00} into snd;
     r00_ms=adjval(snd,rcv,val);
     id=r00_ms[,1];
     r00_ms=r00_ms[,2:ncol(r00_ms)];
     adj=r00_ms;
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/2000/b1-adj/v0);
         %let p2=%quote(00b1.adj);
         set adj0&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/2000/b1-id/v0);
         %let p4=%quote(00b1.id);
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
         %let p1=%quote(/home/jhull/nangrong/data_paj/2000/b1-adj/v);
         %let p2=%quote(00b1.adj);
         set adj&i;
         file "&p1.&i.&p2"  lrecl=1000;
         put (_ALL_) (+0);
run;
    data _null_ ;
         %let p3=%quote(/home/jhull/nangrong/data_paj/2000/b1-id/v);
         %let p4=%quote(00b1.id);
         set id&i;
         file "&p3.&i.&p4"  lrecl=10000;
         put (_ALL_) (+0);
run;
%end;
%mend v_adj4;

%v_adj4(numvill=51);