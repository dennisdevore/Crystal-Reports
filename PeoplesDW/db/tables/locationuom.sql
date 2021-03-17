--
-- $Id$
--
#include "size.h"

create table locationuom (
	facility			varchar2(SZfac),
	locid				varchar2(SZloc),
	unitofmeasure	varchar2(SZuom),
   qtyhere        number(7),
   qtycoming      number(7),
   qtyavailable   number(7),
   qtyused        number(7),
   qtyqa          number(7),
   emergreplqty   number(7),
   batchreplqty   number(7),
   autocountqty   number(7),   
	lastuser			varchar2(SZuser),
	lastupdate   	date,
	constraint pk_locationuom primary key (facility, locid, unitofmeasure)
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
