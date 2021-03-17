--
-- $Id$
--
drop table docappointments;

create table docappointments(
	appointmentID 	number(7) not null,
	aptType        varchar2(1),
	facility 		varchar2(3),
	startTime 		date,
	endTime 			date,
	appointmentNum number(7),
	subject			varchar2(30),
	notes				varchar2(500),
	loadno			number(7),
	lastuser			varchar2(12),
	lastupdate   	date
);

exit;
