--
-- $Id$
--
create table xferfiles (
 oservername                              varchar2(30) not null,
 ofilename                                varchar2(30) not null,
 odirname                                 varchar2(30) not null,
 dservername                              varchar2(30),
 dfilename                                varchar2(30),
 ddirname                                 varchar2(30),
 dtrigproc                                varchar2(30),
 freqday                                  number(5),
 freqhour                                 number(5),
 attempts                                 number(5),
 interval                                 number(5),
	constraint pk_xferfiles primary key (oservername, ofilename,
							odirname)
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
