--
-- $Id$
--
create or replace PACKAGE alps.zallocrules
IS

PROCEDURE reset_allocrule_sequence
(in_facility varchar2
,in_allocrule varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

END zallocrules;
/
exit;