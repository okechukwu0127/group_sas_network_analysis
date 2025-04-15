cas mysess;


libname tinubu cas sessref=mysess;


FILENAME REFFILE FILESRVC FOLDERPATH='/Users/o.g.eze@wlv.ac.uk/My Folder'  FILENAME='foodweb-baywet.csv';

PROC IMPORT DATAFILE=REFFILE
            dbms=csv
            out=tinubu.foodweb_baywet; 
    getnames=yes;
run;

PROC CONTENTS  DATA=tinubu.foodweb_baywet; run;
PROC PRINT  data=tinubu.foodweb_baywet (obs=10); run;



/* Rename Source and Target columns to FROM and TO */
data tinubu.foodweb_baywet;
    set tinubu.foodweb_baywet;
    rename Source = From;
    rename Target = To;
run;


/* Create a copy of the dataset with the expected name for proc network */
data tinubu.CacheNetwrok;
    set tinubu.foodweb_baywet;
run;


/* Run network Summary analysis */
proc network
   direction      = directed
   links          = tinubu.CacheNetwrok;
   summary 
      shortestPath = Weight
      out          = tinubu.Summary;
run;

/*
SHORTEST PATH ON THE NETWORK
This calculates shortest paths between 
all species pairs (based on weight).
*/
proc optnetwork 
  links = tinubu.CacheNetwrok;
    shortestPath 
      outPaths = tinubu.Shortest_Path;
run;


/* 
CALCULATES WEIGHTED DEGREE CENTRALITY
It specifies the species  that participate 
in a lot of feeding relationships.

The sum of weights of edges connected 
to a node (species)
 */
proc network
   direction	= directed
   links       	= tinubu.CacheNetwrok
   outNodes 	= tinubu.Degree_Centrality;
      centrality
        degree = weight;
run;

/*
CALCULATES WEIGHTED BETWEENNESS CENTRALITY
This tells us how "strong" the links are on the network

This would highlight keystone species that connect different parts of the ecosystem.

Think of it as a bridge species — if it's removed, 
information (or energy flow) between others is disrupted.

A species like a mid-level predator that both eats 
smaller prey and gets eaten by a top predator might 
show high betweenness.

If it disappears, the energy flow between producers 
and top predators might break.



node: This is the species ID 
centr_between_wt: This is the weighted betweenness centrality score

*/
proc network
  links = tinubu.CacheNetwrok
  outNodes = tinubu.Food_BetweenNodes;
  centrality
    between = weight;
run;

/* Create a copy of the Betweenness network */
data tinubu.Sorted_Food_BetweenNodes;
    set tinubu.Food_BetweenNodes;
run;


/* Sort the nodes by centr_between_wt in descending order*/
proc sort data=tinubu.Sorted_Food_BetweenNodes nodupkey;
    by descending centr_between_wt;
run;

/*PROC PRINT  data=tinubu.Food_BetweenNodes (obs=10); run;*/



/*
Closeness centrality measures how close (in steps or 
energy flow) a species is to all others

A top predator or primary producer may have low closeness 
because they’re endpoints in the energy flow.

Species with high closeness can quickly influence 
others in the network (e.g., spread changes 
through the food chain fast).

Species with low closeness may be isolated — 
like top predators or basal producers.

*/
proc network
  direction = directed
  links = tinubu.CacheNetwrok
  outNodes = tinubu.Close_Centrality;

    linksVar weight = Weight;

    centrality
        close = weight;
run;

/* Create a copy of the Close Centrality network */
data tinubu.Sorted_Close_Centrality;
    set tinubu.Close_Centrality;
run;


/* Sort the nodes by centr_close_wt in descending order*/
proc sort data=tinubu.Sorted_Close_Centrality nodupkey;
    by descending centr_close_wt;
run;



/*
CALCULATING THE DIAMETER
You're identifying the two most distant species 
in terms of energy transfer.

This computes shortest paths between all species pairs.

In a food web, this is the longest number of steps 
energy needs to travel to go from one species 
to another, through the shortest path
*/

data _null_;
 set tinubu.Summary;
  call symputx('diameter',diameter_wt);
run;

%put diameter = &diameter;



proc sql;
 select *
  from tinubu.Shortest_Path
   where source < sink /* avoids duplicate reverse paths (like 3 → 8 and 8 → 3) */
    group by source, sink /* groups full paths */
   having sum(Weight) = &diameter /* filters to only those shortest paths that match the diameter */
 order by source, sink, order; /* displays the full sequence of nodes along each diameter path */
quit;


/*
proc sql;
  create table top_longest_paths as
  select source, sink, sum(weight) as total_path_weight
  from tinubu.foodweb_paths
  group by source, sink
  having calculated total_path_weight is not missing
  order by total_path_weight desc;
quit;


proc print data=top_longest_paths (obs=5);
run;


proc optnetwork
  links = tinubu.CacheNetwrok;
  concomp direction = directed out = tinubu.Optimed;
run;
*/









