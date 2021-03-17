--
-- $Id$
--
drop table prodactivity852dtlex;
create table prodactivity852dtlex
(
    sessionid varchar2(12),   -- CUSTIDn  n = sequence
    custid          varchar2(10),
    warehouse_id    varchar2(3),
    item varchar2(50),
    activity_code   varchar2(2),
    sequence        number,
    quantity        number,
    uom             varchar2(4),
    ref_id_qualifier varchar2(2),
    ref_id          varchar2(30),
    qty_qualifier   varchar2(2),
    assigned_number varchar2(30),
    dt_qualifier    varchar2(3),
    activity_date   varchar2(8),
    activity_time   varchar2(8)
);

exit;

