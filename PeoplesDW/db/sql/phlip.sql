--
-- $Id$
--
select to_char(whenoccurred, 'mm/dd/yy hh24:mi:ss') as time,
		 lpid,
		 lasttask,
		 location,
		 quantity
  from platehistory
 where lpid = '100000000004690' 
 order by whenoccurred desc;
 exit;
