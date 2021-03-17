CREATE OR REPLACE VIEW MBOLDTL ( SP_ORDERID,SP_SHIPID,
SP_STOPNO, SP_COUNT, SP_WEIGHT, SP_QUANTITY_CASE, SP_QUANTITY_ROLL ) AS select
    SP.orderid,
    SP.shipid,
    SP.stopno,
    sum(nvl(quantity,0)),
    sum(nvl(weight,0)),
    sum(nvl(zbut.translate_uom_function(custid,item,quantity,unitofmeasure,
        nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)),
    sum(nvl(zbut.translate_uom_function(custid,item,quantity,unitofmeasure,
        nvl((select min(code) from unitsofmeasure where abbrev='Roll'),'ROLL')),0))
from
    shippingplate SP
where type in ('F','P')
group by SP.orderid,SP.shipid, SP.stopno;

comment on table MBOLDTL is '$Id$';

exit;
