--
-- $Id$
--
select lpid from platehistory
where whenoccurred > to_date('20000805121000','yyyymmddhh24miss')
  and whenoccurred < to_date('20000805121102', 'yyyymmddhh24miss');
exit;
