create or replace PACKAGE BODY alps.zdocappointments
IS
--
-- $Id$
--


PROCEDURE get_next_aptid
(out_aptid OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select docappointmentseq.nextval
    into out_aptid
    from dual;
  select count(1)
    into currcount
    from docappointments
   where appointmentid = out_aptid;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_aptid;

PROCEDURE get_next_schedid
(out_schedid OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select docscheduleseq.nextval
      into out_schedid
		    from dual;
			   select count(1)
				    into currcount
					     from docschedule
						     where scheduleid = out_schedid;
end loop;

out_msg := 'OKAY';

exception when others then
     out_msg := sqlerrm;
end get_next_schedid;

PROCEDURE add_order_appointment
(in_orderid  IN number
,in_shipid   IN number
,in_aptid    IN number
,in_aptDate  IN date
,in_aptType  IN varchar2
,in_facility IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
)
is
begin

		update orderhdr set appointmentid = in_aptid,
			apptdate = in_aptDate, lastupdate = sysdate,
			lastuser = in_userid
		where orderid = in_orderid and
				shipid  = in_shipid;

		out_msg := 'OKAY';

exception when others then
	out_msg :=sqlerrm;
end add_order_appointment;

PROCEDURE update_order_appointment
(in_aptid    IN number
,in_aptDate  IN date
,in_aptType  IN varchar2
,in_facility IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
)
is
begin

		update orderhdr set apptdate = in_aptDate,
			lastupdate = sysdate,
			lastuser = in_userid
		where appointmentid = in_aptid;

		out_msg := 'OKAY';

exception when others then
	out_msg :=sqlerrm;
end update_order_appointment;



PROCEDURE add_load_appointment
(in_loadno   IN number
,in_aptid    IN number
,in_aptDate  IN date
,in_facility IN varchar2
,in_apttype  IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
)
is
begin


		update loads set appointmentid = in_aptid,
			apptdate = in_aptDate,lastupdate = sysdate,
			lastuser = in_userid
		where loadno = in_loadno;


		out_msg :='OKAY';

exception when others then
	out_msg := sqlerrm;
end add_load_appointment;

PROCEDURE add_order_apt_ok
(in_orderid  IN number
,in_shipid   IN number
,in_aptid    IN number
,in_facility IN varchar2
,in_apttype  IN varchar2
,out_custid  OUT varchar2
,out_msg     IN OUT varchar2
)
is

theToFacility varchar2(3);
theFromFacility varchar2(3);
theOrderType varchar2(3);
theOrderStatus varchar2(3);
theAptID number;
theAptLoad number;
theOrdLoad number;

begin

select custid,tofacility,fromfacility,ordertype,orderstatus,
		appointmentid,nvl(loadno,0) into
		out_custid,theToFacility,theFromFacility,
		theOrderType,theOrderStatus,theAptID, theOrdLoad
    from orderhdr where
			orderid = in_orderid and shipid=in_shipid;

select max(loadno) into theAptLoad
    from loads
	 	where appointmentid = in_aptid;

out_msg :='OKAY';

if theAptLoad > 0  and theAptLoad <> theOrdLoad then
   out_msg := 'Order not in load ' || to_char(theAptLoad) || '.';
end if;

if (in_apttype = 'I' and in_facility <> theToFacility) or
   (in_apttype = 'O' and in_facility <> theFromFacility) then
			 out_msg := 'Order not in current facility.';
end if;

if in_apttype = 'I' and (theOrderType not in ('R','Q','P','T','A','C','I','U')) then
		out_msg := 'Not and inbound order.';
end if;

if in_apttype = 'O' and (theOrderType in ('R','Q','P','A','C','I')) then
		out_msg := 'Not and outbound order.';
end if;

if theAptID is not null and theAptID > 0 and  (theAptId <> in_aptid) then
	out_msg :='Order already scheduled for APPT: ' || to_char(theAptid) || '.';
end if;

if theOrderStatus = 'R' then
	out_msg := 'Order Recieved.';
end if;

if theOrderStatus = '9' then
	out_msg := 'Order Shipped';
end if;

if theOrderStatus = 'X' then
	out_msg := 'Order Cancelled';
end if;

exception when others then
	out_msg := sqlerrm;
end add_order_apt_ok;

PROCEDURE add_load_apt_ok
(in_loadno   IN number
,in_aptid    IN number
,in_apttype  IN varchar2
,in_facility IN varchar2
,out_msg     IN OUT varchar2
)is

theFacility   varchar2(3);
theLoadType   varchar2(4);
theLoadStatus varchar2(1);
theAptID      number;
theLoad       number;
theCnt        number;

begin

select facility,loadstatus,loadtype,appointmentid into
	theFacility,theLoadStatus,theLoadType,theAptID
from loads where loadno = in_loadno;

select nvl(max(loadno),0),count(1) into theLoad,theCnt
   from (
		select loadno from orderhdr
	      where appointmentid = in_aptid
	   union
	  select loadno from loads
	     where appointmentid = in_aptid);

out_msg := 'OKAY';

if (theLoad > 0 or theCnt > 0) and theLoad <> in_loadno then
   out_msg := 'Apt scheduled for orders on load ' || to_char(theLoad) || '.';
end if;

if theFacility <> in_facility then
	out_msg := 'Load not in current facility.';
end if;

if theLoadStatus = '9' then
	out_msg := 'Load is shipped.';
end if;

if theLoadStatus = 'R' then
	out_msg := 'Load is received.';
end if;

if theLoadStatus = 'X' then
	out_msg := 'Load is cancelled.';
end if;

if theAptID is not null and theAptID > 0 and  (theAptID <> in_aptid) then
	out_msg := 'Load is already scheduled for APPT: ' || to_char(theAptID);
end if;

if (in_apttype = 'I' and (theLoadType = 'OUTC' or theLoadType = 'OUTTT')) then
	out_msg := 'Load must be inbound.';
end if;

if (in_apttype = 'O' and (theLoadType = 'INC' or theLoadType = 'INT')) then
	out_msg := 'Load must be outbound.';
end if;


exception when others then
	out_msg := sqlerrm;
end add_load_apt_ok;

PROCEDURE delete_order_apt_ok
(in_orderid IN number
,in_shipid  IN number
,out_msg    IN OUT varchar2
)
is
theToFacility varchar2(3);
theFromFacility varchar2(3);
theOrderType varchar2(3);
theOrderStatus varchar2(3);
theAptID number;
theCustid varchar(10);

begin

select custid,tofacility,fromfacility,ordertype,orderstatus,
		appointmentid into
		theCustid ,theToFacility,theFromFacility,
		theOrderType,theOrderStatus,theAptID
    from orderhdr where
			orderid = in_orderid and shipid=in_shipid;

out_msg :='OKAY';


if theOrderStatus = 'R' then
	out_msg := 'Order Recieved.';
end if;

if theOrderStatus = '9' then
	out_msg := 'Order Shipped';
end if;

exception when others then
	out_msg := sqlerrm;
end delete_order_apt_ok;

PROCEDURE delete_load_apt_ok
(in_loadno IN number
,out_msg   IN OUT varchar2
)
is
theFacility   varchar2(3);
theLoadType   varchar2(4);
theLoadStatus varchar2(1);
theAptID      number;

begin

select facility,loadstatus,loadtype,appointmentid into
	theFacility,theLoadStatus,theLoadType,theAptID
from loads where loadno = in_loadno;

out_msg := 'OKAY';


if theLoadStatus = '9' then
	out_msg := 'Load is shipped.';
end if;

if theLoadStatus = 'R' then
	out_msg := 'Load is received.';
end if;

exception when others then
	out_msg := sqlerrm;
end delete_load_apt_ok;

PROCEDURE doc_sched_overlap
(in_startdate IN varchar2
,in_starttime IN varchar2
,in_enddate   IN varchar2
,in_endtime   IN varchar2
,in_schedule  IN varchar2
,out_msg      IN OUT varchar2
)
is

cnt integer;

begin
   out_msg:='OKAY';

	select count(1) into cnt from docschedule where  apttype=in_schedule and
	 (not (to_date(in_startdate,'mm/dd/yyyy') = startdate and 
	      in_starttime = starttime and
	      to_date(in_enddate,'mm/dd/yyyy') = enddate and 
			in_endtime = endtime)) and
	  to_date(in_startdate || ' ' || in_starttime, 'mm/dd/yyyy hh24:mi') between
	   to_date(in_startdate || ' ' || starttime, 'mm/dd/yyyy hh24:mi') and
	   to_date(in_startdate || ' ' || endtime, 'mm/dd/yyyy hh24:mi') and
	     to_date(in_startdate,'mm/dd/yyyy') between startdate and enddate;


	if cnt > 0 then
		out_msg := 'Schedule entries cannot overlap';
	else


      	select count(1) into cnt from docschedule where  apttype=in_schedule and
	  		to_date(in_startdate,'mm/dd/yyyy') = startdate and 
	      	in_starttime = starttime and
	      	to_date(in_enddate,'mm/dd/yyyy') = enddate and 
			in_endtime = endtime;
      end if;


	if cnt > 1 and out_msg = 'OKAY' then
		out_msg := 'Schedule entries cannot be duplicated';
	end if;

	exception when others then
		out_msg :=sqlerrm;
end doc_sched_overlap;



end zdocappointments;
/
show errors package body zdocappointments;
exit;
