--
-- $Id$
--
alter table invadj947dtlex
add (
    newlotno varchar2 (30),
	 oldinvstatus  varchar2 (2),
	 oldinventoryclass   varchar2 (2),
	 oldtaxcode varchar2 (2),
	 newtaxcode varchar2 (2),
	 newinventoryclass varchar2 (2),
	 newinvstatus  varchar2 (2),
	 sapmovecode varchar2 (3),
	 custreference  varchar2 (32));
exit;
