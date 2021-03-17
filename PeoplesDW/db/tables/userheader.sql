--
-- $Id$
--
create table userheader (
	nameid			varchar2(12) constraint pk_userheader primary key
										using index tablespace indx
										storage (
											initial 16k
											next 16k
											maxextents 99
											pctincrease 0
										),
 username                                 varchar2(32),
 usertype                                 varchar2(1),
 facility                                 varchar2(3),
 groupid                                  varchar2(12),
 chgfacility                              varchar2(1),
 desc1                                    varchar2(32),
 desc2                                    varchar2(32),
 lastuser                                 varchar2(12),
 lastupdate                               date,
 lblprinter                               varchar2(5),
 rptprinter                               varchar2(5),
 lastlocation                             varchar2(10),
 custid                                   varchar2(10),
 equipment                                varchar2(2),
 opmode                                   varchar2(1),
 pickmode                                 varchar2(1),
 allcusts                                 varchar2(1)
)
tablespace data
storage (
	initial 16k
	next 16k
	maxextents 99
	pctincrease 0
);

exit;
