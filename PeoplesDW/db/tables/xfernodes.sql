--
-- $Id$
--
create table xfernodes (
 server                                   varchar2(30) not null,
 userid                                   varchar2(30) not null,
 userpwd                                  varchar2(30) not null,
	constraint pk_xfernodes primary key (server)
		using index tablespace indx
			storage (
				initial 100k
				next 100k
				maxextents 99
				pctincrease 0
			)
)
tablespace data
storage (
	initial 100k
	next 100k
	maxextents 99
	pctincrease 0
);

exit;
