CREATE OR REPLACE VIEW LBL_ADDR_SHIP_D2K_VIEW
(LPID, FROMLPID, FROMLPIDTXT,SHIPTONAME, SHIPTOADDR1, SHIPTOADDR2,
 SHIPTOCSZ, ORDERID, SHIPID, PO, POTEXT, REFERENCE,
 WHSENAME, WHSEADDR1, WHSEADDR2, WHSECSZ, OFCOUNT, PALLETCOUNT)
 --, LPCOUNTOF, LPCOUNT)
AS
SELECT
   SP.lpid,
--   '>6' || SP.fromlpid,
   SP.fromlpid,
   SP.fromlpid,
   DECODE(OH.shiptoname, NULL, CN.name, OH.shiptoname),
   DECODE(OH.shiptoname, NULL, CN.addr1, OH.shiptoaddr1),
   DECODE(OH.shiptoname, NULL, CN.addr2, OH.shiptoaddr2),
   RTRIM(DECODE(OH.shiptoname, NULL, CN.city, OH.shiptocity)) || ', '||
      RTRIM(DECODE(OH.shiptoname, NULL, CN.state, OH.shiptostate))|| ' ' ||
      DECODE(OH.shiptoname, NULL, CN.postalcode, OH.shiptopostalcode),
   OH.orderid,
   OH.shipid,
   --'>6' || OH.po,
   OH.po,
   OH.po,
   to_char(OH.orderid,'FM0999999') || '-' || to_char(oh.shipid,'FM9'),
   FA.name,
   FA.addr1,
   FA.addr2,
   RTRIM(FA.city) || ', ' || RTRIM(FA.state) || ' ' || RTRIM(FA.postalcode),
   (select count(1)
      from shippingplate
      where orderid = OH.orderid
        and shipid = OH.shipid
        and parentlpid is null),
    (select count(1) + 1
      from shippingplate
      where orderid = OH.orderid
        and shipid = OH.shipid
        and parentlpid is null
        and lpid < SP.LPID)
FROM ORDERHDR OH,
     SHIPPINGPLATE SP,
     CONSIGNEE CN,
     FACILITY FA
WHERE OH.shipto = CN.CONSIGNEE(+)
  AND OH.orderid = SP.orderid
  AND OH.shipid = SP.shipid
  AND OH.ordertype = 'O'
  AND SP.parentlpid IS NULL
  AND OH.fromfacility = FA.FACILITY(+)
/

exit;
