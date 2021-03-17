--
-- $Id$
--
alter table orderhdr add
(cancel_id number(8)
,cancelled_date date
,cancel_user_id varchar2(12)
);
exit;
