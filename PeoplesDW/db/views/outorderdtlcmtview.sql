create or replace view outorderdtlcmtview(
    orderid,
    shipid,
    item,
    lotnumber,
    orddtl_comment
)
as
select orderid, shipid, item, nvl(lotnumber,'(none)'), 
    zpk.item_packing_comments(orderid, shipid, item, lotnumber)
 from orderdtl;

exit;
