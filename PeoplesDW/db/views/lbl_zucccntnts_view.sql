create or replace view lbl_zucccntnts_view
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
   hdrpasschar01,
   hdrpasschar02,
   hdrpasschar03,
   hdrpasschar04,
   hdrpasschar05,
   hdrpasschar06,
   hdrpasschar07,
   hdrpasschar08,
   hdrpasschar09,
   hdrpasschar10,
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
   hdrpasschar21,
   hdrpasschar22,
   hdrpasschar23,
   hdrpasschar24,
   hdrpasschar25,
   hdrpasschar26,
   hdrpasschar27,
   hdrpasschar28,
   hdrpasschar29,
   hdrpasschar30,
   hdrpasschar31,
   hdrpasschar32,
   hdrpasschar33,
   hdrpasschar34,
   hdrpasschar35,
   hdrpasschar36,
   hdrpasschar37,
   hdrpasschar38,
   hdrpasschar39,
   hdrpasschar40,
   hdrpasschar41,
   hdrpasschar42,
   hdrpasschar43,
   hdrpasschar44,
   hdrpasschar45,
   hdrpasschar46,
   hdrpasschar47,
   hdrpasschar48,
   hdrpasschar49,
   hdrpasschar50,
   hdrpasschar51,
   hdrpasschar52,
   hdrpasschar53,
   hdrpasschar54,
   hdrpasschar55,
   hdrpasschar56,
   hdrpasschar57,
   hdrpasschar58,
   hdrpasschar59,
   hdrpasschar60,
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
   dtlpasschar01,
   dtlpasschar02,
   dtlpasschar03,
   dtlpasschar04,
   dtlpasschar05,
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
   dtlpasschar21,
   dtlpasschar22,
   dtlpasschar23,
   dtlpasschar24,
   dtlpasschar25,
   dtlpasschar26,
   dtlpasschar27,
   dtlpasschar28,
   dtlpasschar29,
   dtlpasschar30,
   dtlpasschar31,
   dtlpasschar32,
   dtlpasschar33,
   dtlpasschar34,
   dtlpasschar35,
   dtlpasschar36,
   dtlpasschar37,
   dtlpasschar38,
   dtlpasschar39,
   dtlpasschar40,
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
   dtlpassnum11,
   dtlpassnum12,
   dtlpassnum13,
   dtlpassnum14,
   dtlpassnum15,
   dtlpassnum16,
   dtlpassnum17,
   dtlpassnum18,
   dtlpassnum19,
   dtlpassnum20,
   dtlpassdate01,
   dtlpassdate02,
   dtlpassdate03,
   dtlpassdate04,
   dtlpassdoll01,
   dtlpassdoll02,
   itmpasschar01,
   itmpasschar02,
   itmpasschar03,
   itmpasschar04,
   itmpassnum01,
   itmpassnum02,
   itmpassnum03,
   itmpassnum04,
   vendorupc,
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
   custname,
   casepack,
   blnumber,
   color,
   custitem,
   customercode,
   customeritem,
   custpartno,
   department,
   division,
   dpci,
   fhskustyle,
   itemno,
   itemsize,
   itemupc,
   itf14,
   itf14fmt,
   lhproduct,
   makrforstate,
   markforaddr1,
   markforaddr2,
   markforcity,
   markforcountrycode,
   markforidcode,
   markformaddr1,
   markformaddr2,
   markforname,
   markforstate,
   markforzip,
   part,
   qtystring,
   shipto,
   sizestring,
   storenum,
   stornum,
   style,
   subdesc,
   subno,
   upccode,
   vendor,
   vendoritem,
   gs1sscc,
   dept,
   dc,
   wmit,
   dptchar01_01,
   dptchar02_01,
   dptchar03_01,
   itemqty_01,
   dptchar01_02,
   dptchar02_02,
   dptchar03_02,
   itemqty_02,
   dptchar01_03,
   dptchar02_03,
   dptchar03_03,
   itemqty_03,
   dptchar01_04,
   dptchar02_04,
   dptchar03_04,
   itemqty_04,
   dptchar01_05,
   dptchar02_05,
   dptchar03_05,
   itemqty_05,
   dptchar01_06,
   dptchar02_06,
   dptchar03_06,
   itemqty_06,
   dptchar01_07,
   dptchar02_07,
   dptchar03_07,
   itemqty_07,
   dptchar01_08,
   dptchar02_08,
   dptchar03_08,
   itemqty_08,
   dptchar01_09,
   dptchar02_09,
   dptchar03_09,
   itemqty_09,
   dptchar01_10,
   dptchar02_10,
   dptchar03_10,
   itemqty_10,
   dptchar01_11,
   dptchar02_11,
   dptchar03_11,
   itemqty_11,
   dptchar01_12,
   dptchar02_12,
   dptchar03_12,
   itemqty_12,
   dptchar01_13,
   dptchar02_13,
   dptchar03_13,
   itemqty_13,
   dptchar01_14,
   dptchar02_14,
   dptchar03_14,
   itemqty_14,
   shipto_master
) as
SELECT
    decode( nvl(SL.hdrpasschar13,'(none)'),
        'LWDT2ST', substr(SL.sscc,3),
        'LWBSTBY', substr(SL.sscc,3),
        'LWSTPL', substr(SL.sscc,3),
        '66133', substr(SL.sscc,3),
        'LWMICR', substr(SL.sscc,3),
        'LWBBBD2S', substr(SL.sscc,3),
        '0097642', '10'||SL.dtlpasschar01,
        '0005000', '10'||SL.dtlpasschar01,
        SL.sscc),
    decode( nvl(SL.hdrpasschar13,'(none)'),
        '0097642', zlbl.format_string('10'||SL.dtlpasschar01, '(??) ? ???????? ???????? ?'),
        SL.ssccfmt),
   SL.lpid,
   SL.picktolp,
   SL.orderid,
   SL.shipid,
   SL.loadno,
   SL.wave,
   SL.item,
   SL.itemdescr,
   SL.quantity,
   SL.weight,
   SL.seq,
   SL.seqof,
   SL.lbltype,
   SL.created,
   SL.shiptoname,
   SL.shiptocontact,
   SL.shiptoaddr1,
   SL.shiptoaddr2,
   SL.shiptocity,
   SL.shiptostate,
   SL.shiptozip,
   SL.shiptocountrycode,
   SL.fromfacility,
   SL.fromaddr1,
   SL.fromaddr2,
   SL.fromcity,
   SL.fromstate,
   SL.fromzip,
   SL.shipfromcountrycode,
   SL.pro,
   SL.bol,
   SL.po,
   SL.reference,
   SL.carriername,
   SL.scac,
   SL.lotnumber,
   SL.shippingtype,
   SL.custid,
   SL.facility,
   SL.hdrpasschar01,
   SL.hdrpasschar02,
   SL.hdrpasschar03,
   SL.hdrpasschar04,
   SL.hdrpasschar05,
   SL.hdrpasschar06,
   SL.hdrpasschar07,
   SL.hdrpasschar08,
   SL.hdrpasschar09,
   SL.hdrpasschar10,
   SL.hdrpasschar11,
   SL.hdrpasschar12,
   SL.hdrpasschar13,
   SL.hdrpasschar14,
   SL.hdrpasschar15,
   SL.hdrpasschar16,
   SL.hdrpasschar17,
   SL.hdrpasschar18,
   SL.hdrpasschar19,
   SL.hdrpasschar20,
   SL.hdrpasschar21,
   SL.hdrpasschar22,
   SL.hdrpasschar23,
   SL.hdrpasschar24,
   SL.hdrpasschar25,
   SL.hdrpasschar26,
   SL.hdrpasschar27,
   SL.hdrpasschar28,
   SL.hdrpasschar29,
   SL.hdrpasschar30,
   SL.hdrpasschar31,
   SL.hdrpasschar32,
   SL.hdrpasschar33,
   SL.hdrpasschar34,
   SL.hdrpasschar35,
   SL.hdrpasschar36,
   SL.hdrpasschar37,
   SL.hdrpasschar38,
   SL.hdrpasschar39,
   SL.hdrpasschar40,
   SL.hdrpasschar41,
   SL.hdrpasschar42,
   SL.hdrpasschar43,
   SL.hdrpasschar44,
   SL.hdrpasschar45,
   SL.hdrpasschar46,
   SL.hdrpasschar47,
   SL.hdrpasschar48,
   SL.hdrpasschar49,
   SL.hdrpasschar50,
   SL.hdrpasschar51,
   SL.hdrpasschar52,
   SL.hdrpasschar53,
   SL.hdrpasschar54,
   SL.hdrpasschar55,
   SL.hdrpasschar56,
   SL.hdrpasschar57,
   SL.hdrpasschar58,
   SL.hdrpasschar59,
   SL.hdrpasschar60,
   SL.hdrpassnum01,
   SL.hdrpassnum02,
   SL.hdrpassnum03,
   SL.hdrpassnum04,
   SL.hdrpassnum05,
   SL.hdrpassnum06,
   SL.hdrpassnum07,
   SL.hdrpassnum08,
   SL.hdrpassnum09,
   SL.hdrpassnum10,
   SL.hdrpassdate01,
   SL.hdrpassdate02,
   SL.hdrpassdate03,
   SL.hdrpassdate04,
   SL.hdrpassdoll01,
   SL.hdrpassdoll02,
   SL.dtlpasschar01,
   SL.dtlpasschar02,
   SL.dtlpasschar03,
   SL.dtlpasschar04,
   SL.dtlpasschar05,
   SL.dtlpasschar06,
   SL.dtlpasschar07,
   SL.dtlpasschar08,
   SL.dtlpasschar09,
   SL.dtlpasschar10,
   SL.dtlpasschar11,
   SL.dtlpasschar12,
   SL.dtlpasschar13,
   SL.dtlpasschar14,
   SL.dtlpasschar15,
   SL.dtlpasschar16,
   SL.dtlpasschar17,
   SL.dtlpasschar18,
   SL.dtlpasschar19,
   SL.dtlpasschar20,
   SL.dtlpasschar21,
   SL.dtlpasschar22,
   SL.dtlpasschar23,
   SL.dtlpasschar24,
   SL.dtlpasschar25,
   SL.dtlpasschar26,
   SL.dtlpasschar27,
   SL.dtlpasschar28,
   SL.dtlpasschar29,
   SL.dtlpasschar30,
   SL.dtlpasschar31,
   SL.dtlpasschar32,
   SL.dtlpasschar33,
   SL.dtlpasschar34,
   SL.dtlpasschar35,
   SL.dtlpasschar36,
   SL.dtlpasschar37,
   SL.dtlpasschar38,
   SL.dtlpasschar39,
   SL.dtlpasschar40,
   SL.dtlpassnum01,
   SL.dtlpassnum02,
   SL.dtlpassnum03,
   SL.dtlpassnum04,
   SL.dtlpassnum05,
   SL.dtlpassnum06,
   SL.dtlpassnum07,
   SL.dtlpassnum08,
   SL.dtlpassnum09,
   SL.dtlpassnum10,
   SL.dtlpassnum11,
   SL.dtlpassnum12,
   SL.dtlpassnum13,
   SL.dtlpassnum14,
   SL.dtlpassnum15,
   SL.dtlpassnum16,
   SL.dtlpassnum17,
   SL.dtlpassnum18,
   SL.dtlpassnum19,
   SL.dtlpassnum20,
   SL.dtlpassdate01,
   SL.dtlpassdate02,
   SL.dtlpassdate03,
   SL.dtlpassdate04,
   SL.dtlpassdoll01,
   SL.dtlpassdoll02,
   SL.itmpasschar01,
   SL.itmpasschar02,
   SL.itmpasschar03,
   SL.itmpasschar04,
   SL.itmpassnum01,
   SL.itmpassnum02,
   SL.itmpassnum03,
   SL.itmpassnum04,
   SL.dtlpasschar01,
   SL.upc,
   SL.zipcodebar,
   SL.zipcodehuman,
   SL.storebarcode,
   SL.storehuman,
   SL.vendorbar,
   SL.vendorhuman,
   SL.shiptocsz,
   SL.shipfromcsz,
   SL.changed,
   SL.lbltypedesc,
   CU.name,
   IU.qty,
   SL.orderid,
   SL.color,
   SL.dtlpasschar02,
   SL.hdrpasschar14,
   SL.customeritem,
   SL.dtlpasschar02,
   SL.department,
   SL.division,
   SL.dtlpasschar02,
   SL.dtlpasschar02,
   SL.dtlpasschar02,
   SL.itemsize,
   SL.upc,
   SL.dtlpasschar09,
   zlbl.format_string(SL.dtlpasschar09, '? ?? ????? ????? ?'),
   SL.item,
   SL.makrforstate,
   SL.markforaddr1,
   SL.markforaddr2,
   SL.markforcity,
   SL.markforcountrycode,
   SL.hdrpasschar02,
   SL.hdrpasschar03,
   SL.hdrpasschar04,
   SL.markforname,
   SL.markforstate,
   SL.markforzip,
   SL.part,
   SL.dtlpasschar08,
   SL.hdrpasschar14,
   SL.dtlpasschar07,
   SL.storenum,
   SL.hdrpasschar02,
   SL.style,
   SL.dtlpasschar04,
   SL.hdrpasschar08,
   SL.dtlpasschar01,
   CU.name,
   SL.vendoritem,
   substr(SL.sscc,3),
   SL.hdrpasschar08,
   SL.hdrpasschar01,
   SL.dtlpasschar02,
   SL.dptchar01_01,
   SL.dptchar02_01,
   SL.dptchar03_01,
   SL.itemqty_01,
   SL.dptchar01_02,
   SL.dptchar02_02,
   SL.dptchar03_02,
   SL.itemqty_02,
   SL.dptchar01_03,
   SL.dptchar02_03,
   SL.dptchar03_03,
   SL.itemqty_03,
   SL.dptchar01_04,
   SL.dptchar02_04,
   SL.dptchar03_04,
   SL.itemqty_04,
   SL.dptchar01_05,
   SL.dptchar02_05,
   SL.dptchar03_05,
   SL.itemqty_05,
   SL.dptchar01_06,
   SL.dptchar02_06,
   SL.dptchar03_06,
   SL.itemqty_06,
   SL.dptchar01_07,
   SL.dptchar02_07,
   SL.dptchar03_07,
   SL.itemqty_07,
   SL.dptchar01_08,
   SL.dptchar02_08,
   SL.dptchar03_08,
   SL.itemqty_08,
   SL.dptchar01_09,
   SL.dptchar02_09,
   SL.dptchar03_09,
   SL.itemqty_09,
   SL.dptchar01_10,
   SL.dptchar02_10,
   SL.dptchar03_10,
   SL.itemqty_10,
   SL.dptchar01_11,
   SL.dptchar02_11,
   SL.dptchar03_11,
   SL.itemqty_11,
   SL.dptchar01_12,
   SL.dptchar02_12,
   SL.dptchar03_12,
   SL.itemqty_12,
   SL.dptchar01_13,
   SL.dptchar02_13,
   SL.dptchar03_13,
   SL.itemqty_13,
   SL.dptchar01_14,
   SL.dptchar02_14,
   SL.dptchar03_14,
   SL.itemqty_14,
   SL.shipto_master
  from ucc_standard_labels SL, customer CU, custitemuom IU
  where CU.custid = SL.custid
    and IU.custid(+) = SL.custid
    and IU.item(+) = SL.item
    and IU.fromuom(+) = 'PCS'
    and IU.touom(+) = 'CS';

comment on table lbl_zucclabels_view is '$Id';

exit;
