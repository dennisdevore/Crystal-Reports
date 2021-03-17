
CREATE OR REPLACE VIEW ORDERHDRSHIPTOVIEW ( ORDERID,   SHIPID, CUSTID, ENTRYDATE, PO,   CARRIER, REFERENCE, DELIVERYSERVICE, REQUESTED_SHIP,   NAME, ADDR1, ADDR2, PHONE,   CITY, STATE, POSTALCODE, COUNTRYCODE,   COMMENT1 ) AS     
SELECT 
  orderid,
  shipid,
  orderhdr.custid,
  orderhdr.entrydate,
  orderhdr.po,
  orderhdr.carrier,
  orderhdr.reference,
  orderhdr.deliveryservice,
  orderhdr.requested_ship,
  nvl(custconsigneeview.name,
  orderhdr.shiptoname) as name,
  nvl(custconsigneeview.addr1,
  orderhdr.shiptoaddr1) as addr1,
  nvl(custconsigneeview.addr2,
  orderhdr.shiptoaddr2) as addr2,
  nvl(custconsigneeview.phone,
  orderhdr.shiptophone) as phone,
  nvl(custconsigneeview.city,
  orderhdr.shiptocity) as city,
  nvl(custconsigneeview.state,
  orderhdr.shiptostate) as state,
  nvl(custconsigneeview.postalcode,
  orderhdr.shiptopostalcode) as postalcode,
  nvl(custconsigneeview.countrycode,
  orderhdr.shiptocountrycode) as countrycode,
  orderhdr.comment1
FROM 
  orderhdr,
  custconsigneeview
WHERE 
  orderhdr.custid = custconsigneeview.custid (+)     and
  orderhdr.shipto = custconsigneeview.consignee (+);

comment on table orderhdrshiptoview is '$Id$';

exit;
