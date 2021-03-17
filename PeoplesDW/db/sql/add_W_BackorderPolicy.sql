--
-- $Id$
--
set scan off;
insert into BackorderPolicy values('W','Await CSR Confirmation','AwaitCSR','N','SUP',sysdate);
commit;

exit;
