create or replace view outordercmtview(
    orderid,
    shipid,
    ord_comment
)
as
select orderid, shipid, zpk.packing_comments(orderid, shipid)
 from orderhdr;

exit;
