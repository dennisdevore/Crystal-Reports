create or replace view order_ack
(
    importfileid,
    custid,
    po,
    reference,
    orderid,
    shipid,
    status,
    ackcomment,
    lastupdate
)
as
select
    importfileid,
    custid,
    po,
    reference,
    orderid,
    shipid,
    status,
    ackcomment,
    lastupdate
  from import_order_acknowledgment;


exit
