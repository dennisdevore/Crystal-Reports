set heading on;
select name as dbname
from v$database;
select status as trigstat, count(1) as user_triggers
from user_triggers
group by status
order by status;
select status as idxstat, count(1) as user_indexes
from user_indexes
group by status
order by status;
select status as consstat, constraint_type,count(1) as user_constraints
from user_constraints
group by status,constraint_type
order by status,constraint_type;
select count(1) as tabledefs
from tabledefs;
select count(1) as customer
from customer;
break on report;
compute sum of count(1) on report;
select object_type as objtype, count(1) as user_objects
from user_objects
group by object_type
order by object_type;
select tablespace_name,count(1) as tables
  from user_tables
 group by tablespace_name
 order by tablespace_name;
select tablespace_name,count(1) as indexes
  from user_indexes
 group by tablespace_name
 order by tablespace_name;
select count(1) as histograms
  from user_histograms;
select name,queue_table,enqueue_enabled,dequeue_enabled
from user_queues
where name not like 'AQ$%'
order by name,queue_table;
select broken,count(1) as jobs
  from user_jobs
 group by broken
 order by broken;
exit;
