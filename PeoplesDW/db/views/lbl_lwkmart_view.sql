create or replace view lbl_lwkmart_view
(
   sscc,
   ssccfmt,
   lpid,
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
   fromaddr1,
   fromcity,
   fromstate,
   fromzip,
   scac,
   lotnumber,
   shippingtype,
   facility,
   markforname,
   storenum,
   markforaddr1,
   dtlpasschar09,
   zipcodebar,
   zipcodehuman,
   part,
   custname,
   reference,
   po,
   itf14,
   itf14fmt
) as
SELECT
   U.sscc,
   U.ssccfmt,
   U.lpid,
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
   U.fromaddr1,
   U.fromcity,
   U.fromstate,
   U.fromzip,
   U.scac,
   U.lotnumber,
   U.shippingtype,
   U.facility,
   U.hdrpasschar01,
   U.hdrpasschar20,
   U.hdrpasschar03,
   U.dtlpasschar09,
   U.zipcodebar,
   U.zipcodehuman,
   U.part,
   C.name,
   U.reference,
   U.po,
   U.dtlpasschar09,
   (select zlbl.format_string(U.dtlpasschar09, '? ?? ????? ????? ?') from dual)
     from ucc_standard_labels U, customer C
    where U.custid = C.custid(+);

comment on table lbl_lwkmart_view is '$Id';

exit;
