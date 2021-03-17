create or replace view lbl_genericucc_view
(
   sscc,
   ssccfmt,
   lpid,
   picktolp,
   orderid,
   shipid,
   loadno,
   wave,
   item,
   itemdescr,
   quantity,
   weight,
   seq,
   seqof,
   lbltype,
   created,
   shiptoname,
   shiptocontact,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptozip,
   shiptocountrycode,
   fromfacility,
   fromaddr1,
   fromaddr2,
   fromcity,
   fromstate,
   fromzip,
   shipfromcountrycode,
   pro,
   bol,
   po,
   reference,
   carriername,
   scac,
   lotnumber,
   shippingtype,
   custid,
   facility,
   markforname,
   storenum,
   markforaddr1,
   markforaddr2,
   markforcity,
   markforstate,
   markforzip,
   markforcountrycode,
   department,
   division,
   hdrpasschar11,
   hdrpasschar12,
   hdrpasschar13,
   hdrpasschar14,
   hdrpasschar15,
   hdrpasschar16,
   hdrpasschar17,
   hdrpasschar18,
   hdrpasschar19,
   hdrpasschar20,
   hdrpassnum01,
   hdrpassnum02,
   hdrpassnum03,
   hdrpassnum04,
   hdrpassnum05,
   hdrpassnum06,
   hdrpassnum07,
   hdrpassnum08,
   hdrpassnum09,
   hdrpassnum10,
   hdrpassdate01,
   hdrpassdate02,
   hdrpassdate03,
   hdrpassdate04,
   hdrpassdoll01,
   hdrpassdoll02,
   upccode,
   custitem,
   itemsize,
   dtlpasschar04,
   style,
   dtlpasschar06,
   dtlpasschar07,
   dtlpasschar08,
   dtlpasschar09,
   dtlpasschar10,
   dtlpasschar11,
   dtlpasschar12,
   dtlpasschar13,
   dtlpasschar14,
   dtlpasschar15,
   dtlpasschar16,
   dtlpasschar17,
   dtlpasschar18,
   dtlpasschar19,
   dtlpasschar20,
   dtlpassnum01,
   dtlpassnum02,
   dtlpassnum03,
   dtlpassnum04,
   dtlpassnum05,
   dtlpassnum06,
   dtlpassnum07,
   dtlpassnum08,
   dtlpassnum09,
   dtlpassnum10,
   dtlpassdate01,
   dtlpassdate02,
   dtlpassdate03,
   dtlpassdate04,
   dtlpassdoll01,
   dtlpassdoll02,
   vendoritem,
   upc,
   zipcodebar,
   zipcodehuman,
   storebarcode,
   storehuman,
   vendorbar,
   vendorhuman,
   shiptocsz,
   shipfromcsz,
   changed,
   lbltypedesc,
   part,
   custname
) as
SELECT
  U.sscc,
  U.ssccfmt,
  U.lpid,
  U.picktolp,
  U.orderid,
  U.shipid,
  U.loadno,
  U.wave,
  U.item,
  U.itemdescr,
  U.quantity,
  U.weight,
  U.seq,
  U.seqof,
  U.lbltype,
  U.created,
  U.shiptoname,
  U.shiptocontact,
  U.shiptoaddr1,
  U.shiptoaddr2,
  U.shiptocity,
  U.shiptostate,
  U.shiptozip,
  U.shiptocountrycode,
  U.fromfacility,
  U.fromaddr1,
  U.fromaddr2,
  U.fromcity,
  U.fromstate,
  U.fromzip,
  U.shipfromcountrycode,
  U.pro,
  U.bol,
  U.po,
  U.reference,
  U.carriername,
  U.scac,
  U.lotnumber,
  U.shippingtype,
  U.custid,
  U.facility,
  U.hdrpasschar01,
  U.hdrpasschar20,
  U.hdrpasschar03,
  U.hdrpasschar04,
  U.hdrpasschar05,
  U.hdrpasschar06,
  U.hdrpasschar07,
  U.hdrpasschar08,
  U.hdrpasschar08,
  U.hdrpasschar10,
  U.hdrpasschar11,
  U.hdrpasschar12,
  U.hdrpasschar13,
  U.hdrpasschar14,
  U.hdrpasschar15,
  U.hdrpasschar16,
  U.hdrpasschar17,
  U.hdrpasschar18,
  U.hdrpasschar19,
  U.hdrpasschar20,
  U.hdrpassnum01,
  U.hdrpassnum02,
  U.hdrpassnum03,
  U.hdrpassnum04,
  U.hdrpassnum05,
  U.hdrpassnum06,
  U.hdrpassnum07,
  U.hdrpassnum08,
  U.hdrpassnum09,
  U.hdrpassnum10,
  U.hdrpassdate01,
  U.hdrpassdate02,
  U.hdrpassdate03,
  U.hdrpassdate04,
  U.hdrpassdoll01,
  U.hdrpassdoll02,
  U.dtlpasschar01,
  U.dtlpasschar02,
  U.dtlpasschar03,
  U.dtlpasschar04,
  U.dtlpasschar05,
  U.dtlpasschar06,
  U.dtlpasschar07,
  U.dtlpasschar08,
  U.dtlpasschar09,
  U.dtlpasschar10,
  U.dtlpasschar11,
  U.dtlpasschar12,
  U.dtlpasschar13,
  U.dtlpasschar14,
  U.dtlpasschar15,
  U.dtlpasschar16,
  U.dtlpasschar17,
  U.dtlpasschar18,
  U.dtlpasschar19,
  U.dtlpasschar20,
  U.dtlpassnum01,
  U.dtlpassnum02,
  U.dtlpassnum03,
  U.dtlpassnum04,
  U.dtlpassnum05,
  U.dtlpassnum06,
  U.dtlpassnum07,
  U.dtlpassnum08,
  U.dtlpassnum09,
  U.dtlpassnum10,
  U.dtlpassdate01,
  U.dtlpassdate02,
  U.dtlpassdate03,
  U.dtlpassdate04,
  U.dtlpassdoll01,
  U.dtlpassdoll02,
  U.consigneesku,
  U.upc,
  U.zipcodebar,
  U.zipcodehuman,
  '91'||U.hdrpasschar20,
  '(91)'||U.hdrpasschar20,
  '90'||U.hdrpasschar01,
  '(90)'||U.hdrpasschar01,
  U.shiptocsz,
  U.shipfromcsz,
  U.changed,
  U.lbltypedesc,
  U.part,
  C.name
  from ucc_standard_labels U, customer C
    where U.custid = C.custid(+);

comment on table lbl_genericucc_view is '$Id';

exit;