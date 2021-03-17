
CREATE OR REPLACE VIEW PENDINGWAVEVIEW
 ( CODE,DESCR, ABBREV ) AS 
select substr(to_char(wave),1,12) as code,
	substr(descr,1,32) as descr,
	substr(descr,1,12) as abbrev from waves 
where wavestatus between 1 and 3;

comment on table PENDINGWAVEVIEW is '$Id$';

exit;
