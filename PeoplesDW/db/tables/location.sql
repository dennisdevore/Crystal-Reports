--
-- $Id$
--
create table new_location (
 locid                                    varchar2(10) not null,
 facility                                 varchar2(3) not null,
 custid                                   varchar2(10),
 loctype                                  varchar2(3),
 storagetype                              varchar2(2),
 section                                  varchar2(10),
 checkdigit                               varchar2(2),
 status                                   varchar2(2),
 pickingseq                               number(5),
 pickingzone                              varchar2(10),
 putawayseq                               number(5),
 putawayzone                              varchar2(10),
 inboundzone                              varchar2(10),
 outboundzone                             varchar2(10),
 panddlocation                            varchar2(10),
 equipprof                                varchar2(2),
 velocity                                 varchar2(1),
 mixeditemsok                             varchar2(1),
 mixedlotsok                              varchar2(1),
 mixeduomok                               varchar2(1),
 dropcount                                number(9),
 pickcount                                number(9),
 dedicateditem varchar2(50),
 lastcounted                              date,
 countinterval                            number(4),
 lastuser                                 varchar2(12),
 lastupdate                               date,
 unitofstorage                            varchar2(4),
	constraint pk_new_location primary key (facility, locid)
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
