/*
Bipartite projection setup from FoodWeb_Network_updated.sas.

Builds the unique node list for a bipartite projection of the food web:
predator endpoints (From) are flagged partitionFlag=1 and prey endpoints
(To) partitionFlag=0, then duplicates are collapsed by node. This is the
node table the project feeds into its projection analysis.

The edge list below is a small sample of the project's foodweb-baywet.csv
(Source, Target, Weight) loaded as CacheNetwrok.
*/

data CacheNetwrok;
    infile datalines dsd dlm=' ';
    input From To Weight;
    datalines;
1 2 5.217257
1 3 73.88673
1 4 0.085891
1 5 0.445422
1 6 0.613985
1 7 0.713598
1 8 0.015419
1 9 10.5
1 10 280.0
1 11 33.0
1 12 20.0
1 13 111.0
1 14 74.0
1 15 110.0
1 16 0.0547
1 17 0.00101
1 18 6.0
1 19 13.0
10 20 1.999959
11 20 0.1999924
12 20 9.499484
14 20 1.440117
21 20 0.2131198
22 20 0.009545992
23 20 0.02771646
17 20 0.0000004560008
24 20 0.003898825
25 20 0.008164008
26 20 0.00004154908
27 20 0.00224752
28 20 0.000001213773
29 20 0.00000412874
30 20 0.000001892561
31 20 0.001244717
32 20 0.0000004530201
33 20 0.000175455
34 20 0.0000580193
35 20 0.0001261102
36 20 0.0003741038
37 20 0.0002614266
;
run;

data Projection;
    set CacheNetwrok(keep=From rename=(From=node));
    partitionFlag = 1; /* Keep these in the projected network */
    output;

    set CacheNetwrok(keep=To rename=(To=node));
    partitionFlag = 0; /* These are the shared nodes */
    output;
run;

/* Remove duplicates */
proc sort data=Projection nodupkey;
    by node;
run;

proc print data=Projection(obs=15); run;
proc freq data=Projection; tables partitionFlag; run;
