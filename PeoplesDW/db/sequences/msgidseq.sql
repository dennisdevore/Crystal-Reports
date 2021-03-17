--
-- $Id
--
---- drop sequence msgidseq;

set serveroutput on
set verify off

declare
  msgcount number(10);
  
begin
	select count(1)
	  into msgcount
	  from appmsgs;
	  
	msgcount := msgcount + 1;
	
	EXECUTE IMMEDIATE 'create sequence msgidseq increment by 1 start with ' || msgcount || ' maxvalue 9999999999 minvalue 1 nocache cycle';
end;
/


exit;
