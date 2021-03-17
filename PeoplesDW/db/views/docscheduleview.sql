drop view docscheduleview;

create view docscheduleview as
select scheduleid,facility,apttype,startdate,enddate,
     starttime,endtime,maxappointments,lastuser,lastupdate,
     to_date(to_char(startdate)||' ' ||starttime,'dd-mon-yy hh24:mi') as startdatetime,
to_date(to_char(enddate)||' ' ||endtime,'dd-mon-yy hh24:mi') as enddatetime
from docschedule;

comment on table docscheduleview is '$Id$';

exit;
