--
-- $Id$
--
alter table facility add
(
   order_completion_profid    varchar2(4),
   order_completion_prtid     varchar2(5)
);

exit;
