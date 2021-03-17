--
-- $Id$
--
drop table invadjactivity;

create table invadjactivity
(
whenoccurred 	  date,
lpid  		  varchar2(15) not null,
facility          varchar2(3) not null,
custid 	          varchar2(10) not null,
item varchar2(50),
lotnumber         varchar2(30),
inventoryclass    varchar2(2),
invstatus         varchar2(2),
uom 		  varchar2(4),
adjqty            number(7),
adjreason         varchar2(2),
tasktype          varchar2(4),
adjuser           varchar2(12),
lastuser 	  varchar2(12),
lastupdate  	  date
);
exit;

