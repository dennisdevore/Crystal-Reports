--
-- $Id$
--
select to_char(whenoccurred, 'mm/dd/yy hh24:mi:ss') as time,
		 lpid,
		 lasttask,
		 location,
		 quantity
  from platehistory
 where item = '30113'
	and whenoccurred > to_date('042000', 'mmddyy')
 order by whenoccurred desc;
 exit;
