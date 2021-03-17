--
-- $Id$
--
set serveroutput on
declare
errmsg varchar2(400);
action varchar2(400);
errno  integer;
warnno  integer;
rc integer;


begin

   dbms_output.enable(1000000);

--zim7.begin_shipnote945('ONE',null,770,1,null,null, errno, errmsg);

--zim7.end_shipnote945('ONE','1', errno, errmsg);

zut.prt('Errno:'||errno||' Msg:'||errmsg);

end;

/
exit;
