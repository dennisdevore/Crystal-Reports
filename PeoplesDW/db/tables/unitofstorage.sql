--
-- $Id$
--
#include "size.h"

create table unitofstorage (
	unitofstorage  varchar2(SZuos) constraint pk_unitofstorage primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
	description		varchar2(30),
   depth          number(7,2),
   width          number(7,2),
   height         number(7,2),
   weightlimit    number(9,2),
   stdpallets     number(6,2),
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
