--
-- $Id$
--
#include "size.h"

create table putawayprof (
	profid			varchar2(2) constraint pk_putawayprof primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
	description		varchar2(30),
   disposition    varchar2(2),
	lastuser			varchar2(SZuser),
	lastupdate   	date
)
tablespace data
storage (
	initial 16k
	next 16k
	maxextents 99
	pctincrease 0
);

exit;
