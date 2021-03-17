--
-- $Id$
--
#include "size.h"

create table custitemuomuos (
   custid         varchar2(SZcust),
	item			   varchar2(SZitem),
   uomseq         number(3),
	unitofmeasure	varchar2(SZuom),
   uosseq         number(3),
	unitofstorage  varchar2(SZuos),
   uominuos	      number(7,2),
	lastuser			varchar2(SZuser),
	lastupdate   	date,
	constraint pk_custitemuomuos primary key (custid, item, uomseq, uosseq)
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
