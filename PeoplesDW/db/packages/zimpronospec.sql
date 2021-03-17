--
-- $Id$
--
create or replace PACKAGE alps.zimportprocprono
IS

PROCEDURE import_prono
(in_carrier  IN varchar2
,in_zone     IN varchar2
,in_prono    IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

END zimportprocprono;
/
--exit;