create or replace view wave_notify
(
    custid,
    orderid,
    shipid,
    reference,
    po,
    movement
)
as
select
    custid,
    orderid,
    shipid,
    reference,
    po,
    'movement'
  from orderhdr;

 exit;
