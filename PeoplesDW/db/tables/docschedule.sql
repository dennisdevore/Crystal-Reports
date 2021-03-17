--
-- $Id$
--
drop table docschedule;

create table docschedule (
	scheduleID 			number(7) not null,
	facility 			varchar2(3) not null,
	aptType     		varchar2(1),
	startDate 			date,
	endDate				date,
	startTime			varchar2(5),
	endTime				varchar2(5),
	maxAppointments	number(4),
	lastuser				varchar2(12),
	lastupdate  		date
);

exit;
