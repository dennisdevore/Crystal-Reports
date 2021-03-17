--
-- $Id$
--
create table putawayprofline
(
   facility          varchar2(3) not null,
	profid			   varchar2(2) not null,
   priority          number(4) not null,
	minuom				number(4),
	maxuom				number(4),
	uom					varchar2(4),
   invstatus   		varchar2(50),
   inventoryclass    varchar2(50),
   zoneid         	varchar2(10) not null,
   locattribute      varchar2(2),
   usevelocity       varchar2(1),
   fitmethod         varchar2(2),
	lastuser			   varchar2(12),
	lastupdate   		date
);

create unique index putawayprofline_idx
   on putawayprofline (facility, profid, priority);
