--
-- $Id$
--
create or replace PACKAGE alps.zapplocks
IS

PROCEDURE get_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE release_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE get_waveplan_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_wave IN number
,in_orderid IN number
,in_shipid IN number
,in_custid IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE release_waveplan_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_wave IN number
,in_orderid IN number
,in_shipid IN number
,in_custid IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

END zapplocks;
/

exit;
