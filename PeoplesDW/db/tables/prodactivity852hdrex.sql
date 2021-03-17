--
-- $Id$
--
drop table prodactivity852hdrex;
create table prodactivity852hdrex
(
    sessionid varchar2(12),   -- CUSTIDn  n = sequence
    custid          varchar2(10),
    start_date      date,
    end_date        date,
    warehouse_name  varchar2(40),
    warehouse_id    varchar2(3)
);

exit;


