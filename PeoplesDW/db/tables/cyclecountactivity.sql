--
-- $Id$
--
drop table cyclecountactivity;

create table cyclecountactivity
(
	facility 		varchar2(3) not null,
	location 		varchar2(10),
	lpid  			varchar2(15),
	custid 			varchar2(10),
	item varchar2(50),
	lotnumber 		varchar2(30),
	uom 				varchar2(4),
	quantity 		number(7),
	entlocation 	varchar2(10),
	entcustid 		varchar2(10),
	entitem varchar2(50),
	entlotnumber 	varchar2(30),
	entquantity 	number(7),
	taskid 			varchar2(15),
	adjustmenttype varchar2(3),
	whenoccurred 	date,
	lastuser 		varchar2(12),
	lastupdate  	date
);
exit;
