--
-- $Id$
--
#include "size.h"

create table equipprofequip (
	profid			varchar2(2),
   equipid        varchar2(2),
	lastuser			varchar2(SZuser),
	lastupdate   	date,
	constraint pk_equipprofequip primary key (profid, equipid)
		using index tablespace indx
			storage (
				initial 16k
				next 16k
				maxextents 99
				pctincrease 0
			)
)
tablespace data
storage (
	initial 16k
	next 16k
	maxextents 99
	pctincrease 0
);

exit;
