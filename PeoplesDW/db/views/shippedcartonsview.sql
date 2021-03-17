CREATE OR REPLACE VIEW ALPS.SHIPPEDCARTONSVIEW
(
    LPID,
    ITEM,
    CUSTID,
    FACILITY,
    LOCATION,
    STATUS,
    UNITOFMEASURE,
    QUANTITY,
    TYPE,
    FROMLPID,
    SERIALNUMBER,
    LOTNUMBER,
    LOTNUMBERNOTNULL,
    PARENTLPID,
    ORDERID,
    SHIPID,
    WEIGHT,
    TRACKINGNO,
    RMATRACKINGNO
)
AS
select
sp.LPID,
sp.ITEM,
sp.CUSTID,
sp.FACILITY,
sp.LOCATION,
sp.STATUS,
sp.UNITOFMEASURE,
sp.QUANTITY,
sp.TYPE,
sp.FROMLPID,
sp.SERIALNUMBER,
sp.LOTNUMBER,
nvl(sp.LOTNUMBER,'(none)'),
sp.PARENTLPID,
sp.ORDERID,
sp.SHIPID,
sp.WEIGHT,
nvl(sp.trackingno,(select sp1.trackingno from shippingplate sp1 where sp1.lpid = sp.parentlpid)),
nvl(sp.rmatrackingno,(select sp1.rmatrackingno from shippingplate sp1 where sp1.lpid = sp.parentlpid))
from shippingplate sp
where sp.type in('F','P');
  
comment on table SHIPPEDCARTONSVIEW  is '$Id: shippedcartonsview.sql 1416 2006-12-19 23:11:38Z ed $';
  
exit;
