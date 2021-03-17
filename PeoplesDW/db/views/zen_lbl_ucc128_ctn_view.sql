
  CREATE OR REPLACE FORCE VIEW ZEN_LBL_UCC128_CTN_VIEW
  ("LPID",
   "SSCC18",
   "SHIPTONAME",
   "SHIPTOADDR1",
   "SHIPTOADDR2",
   "SHIPTOCITY",
   "SHIPTOSTATE",
   "SHIPTOPSTLCD",
   "DC",
   "CARRIERNAME",
   "SHIPDATE",
   "ORDERID",
   "SHIPID",
   "ITEM",
   "WMIT",
   "DESCR",
   "PO",
   "REFERENCE",
   "LOADNO",
   "PRONO",
   "BOL",
   "CUSTNAME",
   "CUSTADDR1",
   "CUSTADDR2",
   "CUSTCITY",
   "CUSTSTATE",
   "CUSTPSTLCD",
   "WHSENAME",
   "WHSEADDR1",
   "WHSEADDR2",
   "WHSECITY",
   "WHSESTATE",
   "WHSEPSTLCD",
   "BARPSTLCD",
   "CUSTNAME_BIG",
   "LABEL_DAT",
   "COMMENT1",
   "SEQ",
   "SEQOF") AS
  select SP.lpid,
         zedi.get_ucc128_code(OH.custid,'0',SP.lpid, Z.seq),
         decode(CN.consignee, null, OH.shiptoname, CN.name),
         decode(CN.consignee, null, OH.shiptoaddr1, CN.addr1),
         decode(CN.consignee, null, OH.shiptoaddr2, CN.addr2),
         decode(CN.consignee, null, OH.shiptocity, CN.city),
         decode(CN.consignee, null, OH.shiptostate, CN.state),
         decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
         substr(decode(CN.consignee, null, OH.shiptoname, CN.name),
         instr(decode(CN.consignee, null, OH.shiptoname, CN.name),'DC',-1)),
         CA.name,
         OH.shipdate,
         SP.orderid,
         SP.shipid,
         SP.item,
         nvl(OD.consigneesku, WM.wmit),
         CI.descr,
         OH.po,
         OH.reference,
         OH.loadno,
         L.prono,
         SP.orderid||'-'||SP.shipid,
         CU.name,
         CU.addr1,
         CU.addr2,
         CU.city,
         CU.state,
         CU.postalcode,
         FA.name,
         FA.addr1,
         FA.addr2,
         FA.city,
         FA.state,
         FA.postalcode,
         decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
         CU.name,
         OH.comment1,
         to_char(sysdate, 'MM/DD/YY'),
         zenith_lbl_ucc128_ctn.get_seq(SP.lpid),
         zenith_lbl_ucc128_ctn.get_seqof(SP.lpid)
         /* row_number() over (partition by SP.orderid, SP.shipid order by null),
         count(*) over (partition by SP.orderid, SP.shipid) */
   from orderhdr OH,
        orderdtl OD,
        custitem CI,
        loads L,
        carrier CA,
        consignee CN,
        customer CU,
        facility FA,
        custitemwmitview WM,
        shippingplate SP,
        zseq Z
 where OH.shipto = CN.consignee(+)
   and OH.orderid = SP.orderid
   and OH.shipid = SP.shipid
   and OH.ordertype = 'O'
   and SP.type in ('P','F')
   and SP.loadno = L.loadno(+)
   and SP.orderid = OD.orderid(+)
   and SP.shipid = OD.shipid(+)
   and SP.orderitem = OD.item(+)
   and SP.custid = WM.custid(+)
   and OD.custid = CI.custid(+)
   and OD.item = CI.item(+)
   and SP.item = WM.item(+)
   and nvl(SP.orderlot,'<none>') = nvl(OD.lotnumber(+),'<none>')
   and OH.carrier = CA.carrier(+)
   and OH.custid = CU.custid(+)
   and OH.fromfacility = FA.facility(+)
   and Z.seq <= SP.quantity
 --and not exists (select from shippingplate where orderid = OH.orderid
 -- and shipid = OH.shipid and status in ('U', 'P'))
 --** ABOVE COMMENTED OUT TO ALLOW FOR ALL STATUS TO RETURN ENTRY -
 --** ZENITH NEEDS THESE LABELS TO PRINT OUT WHEN EACH LP IS PICKED ;

 comment on table zen_lbl_ucc128_ctn_view is '$Id';

 exit;
