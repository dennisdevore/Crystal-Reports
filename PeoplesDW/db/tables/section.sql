--
-- $Id$
--
#include "size.h"

create table section (
	sectionid		varchar2(SZsect) constraint pk_section primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
	facility 		varchar2(SZfac),
	sectionn			varchar2(SZsect),
	sectionne		varchar2(SZsect),
	sectione			varchar2(SZsect),
	sectionse		varchar2(SZsect),
	sections			varchar2(SZsect),
	sectionsw		varchar2(SZsect),
	sectionw			varchar2(SZsect),
	sectionnw		varchar2(SZsect),
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
