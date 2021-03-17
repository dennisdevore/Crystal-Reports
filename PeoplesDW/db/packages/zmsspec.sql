--
-- $Id$
--
create or replace PACKAGE alps.zappmsgs
IS

PROCEDURE log_autonomous_msg
(in_author varchar2
,in_facility varchar2
,in_custid varchar2
,in_msgtext varchar2
,in_msgtype varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE log_msg
(in_author varchar2
,in_facility varchar2
,in_custid varchar2
,in_msgtext varchar2
,in_msgtype varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE reset_profile_sequence
(in_facility varchar2
,in_profid varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE set_to_reviewed
(in_rowid varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE set_alert_to_reviewed
(in_alertid number
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE compute_shipdate
(in_facility varchar2
,in_shipto varchar2
,in_arrivaldate varchar2
,out_shipdate  OUT date
,out_msg  OUT varchar2
);


PROCEDURE compute_arrivaldate
(in_facility varchar2
,in_shipto varchar2
,in_shipdate varchar2
,out_arrivaldate IN OUT date
,out_msg IN OUT varchar2
);

PROCEDURE rf_debug_msg
(in_author varchar2
,in_facility varchar2
,in_custid varchar2
,in_msgtext varchar2
,in_msgtype varchar2
,in_userid varchar2
);
END zappmsgs;
/
exit;