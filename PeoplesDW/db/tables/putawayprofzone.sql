--
-- $Id$
--
#include "size.h"

create table putawayprofzone (
	profid			varchar2(2),
   zone           varchar2(SZzone),
	lastuser			varchar2(SZuser),
	lastupdate   	date,
	constraint pk_putawayprofzone primary key (profid, zone)
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
