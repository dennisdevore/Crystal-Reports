--
-- $Id$
--
set scan off;
insert into LocationAttributes values('RA','Same receipt any product','SameReceipt','N','SUP',sysdate);
insert into LocationAttributes values('RP','Same receipt & product','SameRcptProd','N','SUP',sysdate);
commit;

exit;
