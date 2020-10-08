*********************************************************************
**     Program Name: /home/jhull/nangrong/prog_sas/p02_nets/1994/p02_94c.sas
**     Programmer: james r. hull
**     Start Date: 2011 03 09
**     Purpose:
**        1.) CREATE C - KNOW WHEREABOUTS OF MIGRANT NETWORKS
**     Input Data:
**        '/home/jhull/nangrong/data_sas/1994/current/indiv94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/hh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/comm94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/helprh94.xpt'
**        '/home/jhull/nangrong/data_sas/1994/current/sibs94.xpt'
**
**     Output Data:
**        1.) /home/jhull/nangrong/data_paj/1994/c/vXX94c.net
**            
**     Notes: 
**        1.) 
**
*********************************************************************;

***************
**  Options  **
***************;

options nocenter linesize=80 pagesize=60;

%let f=94c;  ** names file (allows portability) **;
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

**************************************************
**  Create Migrant Information Network Matrices **
**************************************************;

*******************************************************************************
**                                                                           **
** Coding for original location variables                                    **
**                                                                           **
**                                                                           **
*******************************************************************************;

******************************************************************************************
** Re-Sort by VILLAGE and BLT then merge to standard list to remove errors and mistakes **
******************************************************************************************;


*********************************************
** Reformat character variables to numeric **
*********************************************;

********************************************************
** Collapse non-ego HHs containing multiple instances **
********************************************************;

***********************************
** Unstack back to a mother file **
***********************************;

*******************************************
** merge in households with no relations **
*******************************************;


****************************************************
** Create separate village files for EACH VILLAGE **
****************************************************;

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


***************************************************************
** Create 51 VALUED adjacency matrices, one for each village **
***************************************************************;

%macro v_adj1 (numvill=);

%do i=1 %to &numvill;

proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
 
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1/v0);
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

quit;

%end;

%mend v_adj1;

%v_adj1(numvill=9);

%macro v_adj2 (numvill=);

%do i=10 %to &numvill;

proc iml;
     %include '/home/jhull/public/span/adjval.mod';
     %include '/home/jhull/public/span/pajwrite.mod';
 
     %let p1=%quote(/home/jhull/nangrong/data_paj/1994/b1/v);
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

quit;

%end;

%mend v_adj2;

%v_adj2(numvill=51);