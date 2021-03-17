create or replace view orderacksumview(
    custid,
    importfileid,
    total_orders,
    process_date
)
as
select custid, importfileid, count(1), sysdate
  from orderhdr
group by custid, importfileid, sysdate;

comment on table orderacksumview is '$Id: orderacksumview.sql 50 2005-08-24 09:12:44Z ron $';

-- exit;
