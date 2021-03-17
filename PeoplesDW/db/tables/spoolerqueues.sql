--
-- $Id$
--
create table spoolerqueues (
	prtqueue       varchar2(20),
   descr          varchar2(32),
   oraclepipe     varchar2(12),
	lastuser			varchar2(12),
	lastupdate   	date
);

exit;
