--
-- $Id$
--
#include "size.h"

create table printer (
	prtid				varchar2(SZprt) constraint pk_printer primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
	description		varchar2(30),
	type    			varchar2(SZprttype),
	queue				varchar2(20),
	stock				varchar2(2),
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
