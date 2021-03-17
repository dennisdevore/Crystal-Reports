--
-- $Id$
--
#include "size.h"

create table plate (
	lpid				   varchar2(SZlpid) constraint pk_plate primary key
										using index tablespace indx
										storage (
											initial 100k
											next 100k
											maxextents 99
											pctincrease 0
										),
	item				   varchar2(SZitem),
	custid			   varchar2(SZcust),
	facility			   varchar2(SZfac),
	location			   varchar2(SZloc),
	status			   varchar2(2),
	holdreason			varchar2(2),
	unitofmeasure	   varchar2(SZuom),
	quantity				number(7,0),
	type				   varchar2(2),
	serialnumber	   varchar2(SZserial),
	lotnumber		   varchar2(SZlotno),
	creationdate	   date,
   manufacturedate   date,
	expirationdate		date,
	expiryaction		varchar2(2),
	lastcountdate		date,
	po             	varchar2(SZpo),
   recmethod      	varchar2(2),
	condition			varchar2(2),
	lastoperator		varchar2(SZuser),
	lasttask				varchar2(2),
	fifodate       	date,
	destlocation		varchar2(SZloc),
	destfacility		varchar2(SZfac),
	countryof			varchar2(SZcntry),
	parentlpid     	varchar2(SZlpid),
   useritem1      	varchar2(20),
   useritem2      	varchar2(20),
   useritem3      	varchar2(20),
   disposition       varchar2(4),
	lastuser				varchar2(SZuser),
	lastupdate   		date
)
tablespace data
storage (
	initial 100k
	next 100k
	maxextents 99
	pctincrease 0
);

exit;
