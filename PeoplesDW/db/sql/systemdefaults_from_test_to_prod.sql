set heading off;
set pagesize 0;
set linesize 32000;
set trimspool on;
spool sd.out;
select
defaultid,defaultvalue
from systemdefaults@test st
where not exists
  (select 1
     from systemdefaults@prod sp
    where st.defaultid = sp.defaultid)
 order by defaultid;
insert into systemdefaults@prod
select
defaultid,defaultvalue,lastuser,lastupdate
from systemdefaults@test st
where not exists
  (select 1
     from systemdefaults@prod sp
    where st.defaultid = sp.defaultid)
 order by defaultid;
exit;