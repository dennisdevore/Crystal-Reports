--
-- $Id$
--
create or replace PACKAGE alps.zdocappointments
IS

PROCEDURE get_next_aptid
(out_aptid OUT number
,out_msg IN OUT varchar2
);

PROCEDURE get_next_schedid
(out_schedid OUT number
,out_msg IN OUT varchar2
);

PROCEDURE add_order_appointment
(in_orderid  IN number
,in_shipid   IN number
,in_aptid    IN number
,in_aptDate  IN date
,in_aptType  IN varchar2
,in_facility IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
);

PROCEDURE update_order_appointment
(in_aptid    IN number
,in_aptDate  IN date
,in_aptType  IN varchar2
,in_facility IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
);

PROCEDURE add_load_appointment
(in_loadno   IN number
,in_aptid    IN number
,in_aptDate  IN date
,in_facility IN varchar2
,in_apttype  IN varchar2
,in_userid   IN varchar2
,out_msg     IN OUT varchar2
);

PROCEDURE add_order_apt_ok
(in_orderid  IN number
,in_shipid   IN number
,in_aptid    IN number
,in_facility IN varchar2
,in_apttype  IN varchar2
,out_custid  OUT varchar2
,out_msg     IN OUT varchar2
);

PROCEDURE add_load_apt_ok
(in_loadno   IN number
,in_aptid    IN number
,in_apttype  IN varchar2
,in_facility IN varchar2
,out_msg     IN OUT varchar2
);


PROCEDURE delete_order_apt_ok
(in_orderid IN number
,in_shipid  IN number
,out_msg    IN OUT varchar2
);

PROCEDURE delete_load_apt_ok
(in_loadno IN number
,out_msg   IN OUT varchar2
);

PROCEDURE doc_sched_overlap
(in_startdate IN varchar2
,in_starttime IN varchar2
,in_enddate   IN varchar2
,in_endtime   IN varchar2
,in_schedule  IN varchar2
,out_msg      IN OUT varchar2
);


END zdocappointments;
/
exit;
