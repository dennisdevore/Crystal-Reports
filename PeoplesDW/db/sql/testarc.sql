--
-- $Id$
--
ALTER SESSION 
   SET NLS_DATE_FORMAT = 'YYYY MM DD HH24:MI:SS';
set serveroutput on size 200000;
declare


out_msg           varchar2(255);
out_errorno integer;



begin


   
out_msg :=  null;


   
zarc.dropArchiveTables;



zut.prt('msg: ' || out_msg);


end;
/

