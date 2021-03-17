--
-- $Id$
--
#include "size.h"

create table zone (
	zoneid			varchar2(SZzone) constraint pk_zone primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
	description		varchar2(30),
	panddlocation	varchar2(SZloc),
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
