--
-- $Id$
--
#include "size.h"

create table equiptask (
	equipid			varchar2(2),
   tasktype       varchar2(2),
	lastuser			varchar2(SZuser),
	lastupdate   	date,
	constraint pk_equiptask primary key (equipid, tasktype)
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
