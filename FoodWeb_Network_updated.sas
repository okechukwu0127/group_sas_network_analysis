cas mysess;



libname tinubu cas sessref=mysess;

/*Locate the dataset CSV File path*/
FILENAME REFFILE FILESRVC FOLDERPATH='/Users/o.g.eze@wlv.ac.uk/My Folder'  FILENAME='foodweb-baywet.csv';

/* Import dataset to SAS*/
PROC IMPORT DATAFILE=REFFILE
            dbms=csv
            out=tinubu.foodweb_baywet; 
    getnames=yes;
run;


PROC CONTENTS  DATA=tinubu.foodweb_baywet; run;

/*Print first 10 records from table*/
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



/* 
Let's apply the bipartite projection idea to your food web

STEP 1: Create list of unique nodes and assign partitionFlag
Option A — Predator Projection (Shared prey)

Create a network where nodes are predators, and there’s a link 
between predators if they share the same prey.

Option B — Prey Projection (Shared predator)
Create a network where nodes are prey/species, linked if 
they are eaten by the same predator.

*/
data tinubu.Projection;
    set tinubu.CacheNetwrok(keep=From rename=(From=node));
    partitionFlag = 1; /* Keep these in the projected network */
    output;

    set tinubu.CacheNetwrok(keep=To rename=(To=node));
    partitionFlag = 0; /* These are the shared nodes */
    output;
run;

/* Remove duplicates */
proc sort data=tinubu.Projection nodupkey;
    by node;
run;


/* 
The projection analysis offers a powerful lens into how predators
 are ecologically related based on shared prey. It highlights:
•	Critical prey nodes (resources)
•	Competition clusters among predators
•	Specialist vs. generalist predators
•	Potential vulnerabilities in the food network

*/

/* Now run same PROC NETWORK */
proc network
    links = tinubu.CacheNetwrok
    nodes = tinubu.Projection;
    projection
        partition = partitionFlag
        outProjectionLinks = tinubu.Projection_Link
        outNeighborsList = tinubu.Projection_Link_Neighbors
        commonNeighbors = true;
run;

/*
These pairs indicate predators with overlapping 
diets and thus shared ecological roles.
Predators 1 and 2 share 1 common neighbor (prey).
Predators 1 and 3 share 1 common neighbor.
Predators 1 and 4 share 1 common neighbor.
Predators 2 and 3 share 1 common neighbor. e.t.c

In summary, any pair of predators with a commonNeighbors 
value greater than zero, can be considered to share 
ecological roles due to their shared prey.


Here are some predator nodes share common prey
Predators 1 and 2 share prey node 3.
Predators 1 and 3 share prey node 4.
Predators 1 and 4 share prey node 5.
Predators 2 and 3 share prey node 6.

*/




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





proc sql;
create table Max_Degree as 
  select node, centr_degree_wt as max_degree
  from tinubu.Degree_Centrality
  where centr_degree_wt = (
    select max(centr_degree_wt)
    from tinubu.Degree_Centrality
  );
quit;


proc sql;
create table Max_Avg_Degree as 
  select 
    avg(centr_degree_wt) as Avg_Degree,
    max(centr_degree_wt) as Max_Degree
  from tinubu.Degree_Centrality; /* Replace with your actual table name */
quit;



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


/*
COMMUNITY Detection
*/

proc network
   links             = tinubu.CacheNetwrok
   outNodes          = tinubu.NodeSetOut;
   community
      resolutionList = 1.0 0.5 /* Adjust resolution for finer communities */
      outLevel       = tinubu.CommLevelOut /* Provides hierarchical levels of detected communities. */
      outCommunity   = tinubu.CommOut /*Gives community assignments for each node*/
      outOverlap     = tinubu.CommOverlapOut /* Identifies nodes belonging to multiple communities. */
      outCommLinks   = tinubu.CommLinksOut; /* Shows how different communities interact*/
run;


/*



proc optgraph
   links = tinubu.CacheNetwrok
   outNodes = tinubu.EIGEN_CENTRALITY;
   centrality
      eigen   = Weight;
run;

*/








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
FLOW ON THE NETWORK

This SQL aggregates all flows from each 
prey to each predator:

In a food web, flows typically represent the transfer 
of energy, biomass, or nutrients from one 
organism (prey) to another (predator).
*/


proc sql;
    create table FlowSummary as
    select 
        From, 
        To, 
        sum(Weight) as TotalFlow format=8.2
    from tinubu.CacheNetwrok
    group by From, To;
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




/* Count degree of each node */
proc sql;
create table node_degrees as select From as Node from tinubu.CacheNetwrok union all select To as Node from tinubu.CacheNetwrok;
quit;

proc sql;
create table degree_count as select Node, count(*) as Degree from node_degrees group by Node;
quit;



/* Keep only nodes with degree > 1 */
proc sql;
create table core_nodes as select Node from degree_count where Degree > 1;
quit;


/* Filter original edges to keep only those between core nodes */
proc sql;
create table core_edges as select a.* from tinubu.CacheNetwrok a inner join core_nodes b on a.From = b.Node inner join core_nodes c on a.To = c.Node;
quit;


proc casutil;
   load data=core_edges casout="core_edges" outcaslib="tinubu" promote;
quit;

proc casutil;
   list tables incaslib="tinubu";
quit;



/*Get Diameter*/
proc network
   direction      = directed
      links          = tinubu.core_edges;
     summary 
      shortestPath = Weight
      out          = tinubu.Diameter;
run;

proc sql;
select max(Distance) as DiameterValue from tinubu.Diameter;
quit;

PROC PRINT  data=DiameterValue; run;















