--drop table toteorders;
create global temporary table toteorders
(
    totelpid    varchar2(15),
    orderid     number(9),
    shipid      number(2)
) on commit preserve rows;

exit;
