--
-- $Id$
--
create or replace PACKAGE alps.zimportprocinvadj
IS

PROCEDURE import_inventory_status
(in_facility    IN varchar2
,in_custid      IN varchar2
,in_item        IN varchar2
,in_lotnumber   IN varchar2
,in_status      IN varchar2
,in_reason      IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

END zimportprocinvadj;
/
exit;
