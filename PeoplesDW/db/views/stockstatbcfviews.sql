create or replace view stock_stat_bcf_dtl
(
    facility,
    custid,
    item,
    uom,
    quantity
)
as
 select
    facility,
    custid,
    item,
    uom,
    zit.alloc_qty(custid,item,facility)
 from custitemtotsumview
 group by facility,custid,item, uom;

comment on table stock_stat_bcf_dtl is '$Id: stockstatbcfviews.sql 3837 2009-09-03 13:09:07Z ron $';

create or replace view stock_stat_bcf_hdr
(
    facility,
    custid,
    currentdate,
    currenttime
)
as
select distinct
    facility,
    custid,
    to_char(sysdate, 'MM/DD/YYYY'),
    to_char(sysdate, 'HH24:MI')
  from stock_stat_bcf_dtl;

 comment on table stock_stat_bcf_hdr is '$Id: stockstatbcfviews.sql 3837 2009-09-03 13:09:07Z ron $';

create or replace view stock_stat_bcf_trl
(
    facility,
    custid,
    currentdate,
    currenttime
)
as
select distinct
    facility,
    custid,
    to_char(sysdate, 'MM/DD/YYYY'),
    to_char(sysdate, 'HH24:MI')
  from stock_stat_bcf_dtl;

comment on table stock_stat_bcf_trl is '$Id: stockstatbcfviews.sql 3837 2009-09-03 13:09:07Z ron $';



-- exit;
