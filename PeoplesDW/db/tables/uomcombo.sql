--
-- $Id$
--
#include "size.h"

create table uomcombos (
   custid         varchar2(SZcust),
	item			   varchar2(SZitem),
	fromuom	      varchar2(SZuom),
   qty            number(7),
	touom	         varchar2(SZuom),
	constraint pk_uomcombos primary key (custid, item, fromuom, touom)
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
