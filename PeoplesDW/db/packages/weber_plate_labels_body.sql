create or replace package body weber_platelbls as
--
-- $Id: weber_plate_labels_body.sql 10002 2013-05-15 12:31:57Z brianb $
--


--Types


type ohdata is record(
   custid orderhdr.custid%type,
   shiptoname orderhdr.shiptoname%type,
   shiptocontact orderhdr.shiptocontact%type,
   shiptoaddr1 consignee.addr1%type,
   shiptoaddr2 consignee.addr2%type,
   shiptocity consignee.city%type,
   shiptostate consignee.state%type,
   shiptopostalcode consignee.postalcode%type,
   shipdate orderhdr.shipdate%type,
   po orderhdr.po%type,
   reference orderhdr.reference%type,
   loadno orderhdr.loadno%type,
   shipto orderhdr.shipto%type,
   hdrpassthruchar01 orderhdr.hdrpassthruchar01%type,
   hdrpassthruchar02 orderhdr.hdrpassthruchar02%type,
   hdrpassthruchar03 orderhdr.hdrpassthruchar03%type,
   hdrpassthruchar04 orderhdr.hdrpassthruchar04%type,
   hdrpassthruchar05 orderhdr.hdrpassthruchar05%type,
   hdrpassthruchar06 orderhdr.hdrpassthruchar06%type,
   hdrpassthruchar07 orderhdr.hdrpassthruchar07%type,
   hdrpassthruchar08 orderhdr.hdrpassthruchar08%type,
   hdrpassthruchar09 orderhdr.hdrpassthruchar09%type,
   hdrpassthruchar10 orderhdr.hdrpassthruchar10%type,
   hdrpassthruchar11 orderhdr.hdrpassthruchar11%type,
   hdrpassthruchar12 orderhdr.hdrpassthruchar12%type,
   hdrpassthruchar13 orderhdr.hdrpassthruchar13%type,
   hdrpassthruchar14 orderhdr.hdrpassthruchar14%type,
   hdrpassthruchar15 orderhdr.hdrpassthruchar15%type,
   hdrpassthruchar16 orderhdr.hdrpassthruchar16%type,
   hdrpassthruchar17 orderhdr.hdrpassthruchar17%type,
   hdrpassthruchar18 orderhdr.hdrpassthruchar18%type,
   hdrpassthruchar19 orderhdr.hdrpassthruchar19%type,
   hdrpassthruchar20 orderhdr.hdrpassthruchar20%type,
   hdrpassthruchar21 orderhdr.hdrpassthruchar21%type,
   hdrpassthruchar22 orderhdr.hdrpassthruchar22%type,
   hdrpassthruchar23 orderhdr.hdrpassthruchar23%type,
   hdrpassthruchar24 orderhdr.hdrpassthruchar24%type,
   hdrpassthruchar25 orderhdr.hdrpassthruchar25%type,
   hdrpassthruchar26 orderhdr.hdrpassthruchar26%type,
   hdrpassthruchar27 orderhdr.hdrpassthruchar27%type,
   hdrpassthruchar28 orderhdr.hdrpassthruchar28%type,
   hdrpassthruchar29 orderhdr.hdrpassthruchar29%type,
   hdrpassthruchar30 orderhdr.hdrpassthruchar30%type,
   hdrpassthruchar31 orderhdr.hdrpassthruchar31%type,
   hdrpassthruchar32 orderhdr.hdrpassthruchar32%type,
   hdrpassthruchar33 orderhdr.hdrpassthruchar33%type,
   hdrpassthruchar34 orderhdr.hdrpassthruchar34%type,
   hdrpassthruchar35 orderhdr.hdrpassthruchar35%type,
   hdrpassthruchar36 orderhdr.hdrpassthruchar36%type,
   hdrpassthruchar37 orderhdr.hdrpassthruchar37%type,
   hdrpassthruchar38 orderhdr.hdrpassthruchar38%type,
   hdrpassthruchar39 orderhdr.hdrpassthruchar39%type,
   hdrpassthruchar40 orderhdr.hdrpassthruchar40%type,
   hdrpassthrunum01 orderhdr.hdrpassthrunum01%type,
   hdrpassthrunum02 orderhdr.hdrpassthrunum02%type,
   hdrpassthrunum03 orderhdr.hdrpassthrunum03%type,
   hdrpassthrunum04 orderhdr.hdrpassthrunum04%type,
   hdrpassthrunum05 orderhdr.hdrpassthrunum05%type,
   hdrpassthrunum06 orderhdr.hdrpassthrunum06%type,
   hdrpassthrunum07 orderhdr.hdrpassthrunum07%type,
   hdrpassthrunum08 orderhdr.hdrpassthrunum08%type,
   hdrpassthrunum09 orderhdr.hdrpassthrunum09%type,
   hdrpassthrunum10 orderhdr.hdrpassthrunum10%type,
   wave orderhdr.wave%type,
   shiptype orderhdr.shiptype%type,
   fa_name facility.name%type,
   fa_addr1 facility.addr1%type,
   fa_addr2 facility.addr2%type,
   fa_city facility.city%type,
   fa_state facility.state%type,
   fa_postalcode facility.postalcode%type,
   prono loads.prono%type,
   ca_name carrier.name%type,
   ca_carrier carrier.carrier%type,
   cu_name customer.name%type,
   cu_addr1 customer.addr1%type,
   cu_addr2 customer.addr2%type,
   cu_city customer.city%type,
   cu_state customer.state%type,
   cu_postalcode customer.postalcode%type,
   manufacturerucc customer.manufacturerucc%type,
   dc orderhdr.shiptoname%type,
   storecode consignee.storecode%type,
   glncode consignee.glncode%type,
   dunsnumber consignee.dunsnumber%type,
   conspassthruchar01 consignee.conspassthruchar01%type,
   conspassthruchar02 consignee.conspassthruchar02%type,
   conspassthruchar03 consignee.conspassthruchar03%type,
   conspassthruchar04 consignee.conspassthruchar04%type,
   conspassthruchar05 consignee.conspassthruchar05%type,
   conspassthruchar06 consignee.conspassthruchar06%type,
   conspassthruchar07 consignee.conspassthruchar07%type,
   conspassthruchar08 consignee.conspassthruchar08%type,
   conspassthruchar09 consignee.conspassthruchar09%type,
   conspassthruchar10 consignee.conspassthruchar10%type);


-- Cursors


cursor c_oh(p_orderid number, p_shipid number) is
   select OH.custid as custid,
          nvl(CN.name,OH.shiptoname) as shiptoname,
          nvl(CN.contact,OH.shiptocontact) as shiptocontact,
          nvl(CN.addr1,OH.shiptoaddr1) as shiptoaddr1,
          nvl(CN.addr2,OH.shiptoaddr2) as shiptoaddr2,
          nvl(CN.city,OH.shiptocity) as shiptocity,
          nvl(CN.state,OH.shiptostate) as shiptostate,
          nvl(CN.postalcode,OH.shiptopostalcode) as shiptopostalcode,
          OH.shipdate as shipdate,
          OH.po as po,
          OH.reference as reference,
          OH.loadno as loadno,
          OH.shipto as shipto,
          rtrim(OH.hdrpassthruchar01) as hdrpassthruchar01,
          rtrim(OH.hdrpassthruchar02) as hdrpassthruchar02,
          rtrim(OH.hdrpassthruchar03) as hdrpassthruchar03,
          rtrim(OH.hdrpassthruchar04) as hdrpassthruchar04,
          rtrim(OH.hdrpassthruchar05) as hdrpassthruchar05,
          rtrim(OH.hdrpassthruchar06) as hdrpassthruchar06,
          rtrim(OH.hdrpassthruchar07) as hdrpassthruchar07,
          rtrim(OH.hdrpassthruchar08) as hdrpassthruchar08,
          rtrim(OH.hdrpassthruchar09) as hdrpassthruchar09,
          rtrim(OH.hdrpassthruchar10) as hdrpassthruchar10,
          rtrim(OH.hdrpassthruchar11) as hdrpassthruchar11,
          rtrim(OH.hdrpassthruchar12) as hdrpassthruchar12,
          rtrim(OH.hdrpassthruchar13) as hdrpassthruchar13,
          rtrim(OH.hdrpassthruchar14) as hdrpassthruchar14,
          rtrim(OH.hdrpassthruchar15) as hdrpassthruchar15,
          rtrim(OH.hdrpassthruchar16) as hdrpassthruchar16,
          rtrim(OH.hdrpassthruchar17) as hdrpassthruchar17,
          rtrim(OH.hdrpassthruchar18) as hdrpassthruchar18,
          rtrim(OH.hdrpassthruchar19) as hdrpassthruchar19,
          rtrim(OH.hdrpassthruchar20) as hdrpassthruchar20,
          rtrim(OH.hdrpassthruchar21) as hdrpassthruchar21,
          rtrim(OH.hdrpassthruchar22) as hdrpassthruchar22,
          rtrim(OH.hdrpassthruchar23) as hdrpassthruchar23,
          rtrim(OH.hdrpassthruchar24) as hdrpassthruchar24,
          rtrim(OH.hdrpassthruchar25) as hdrpassthruchar25,
          rtrim(OH.hdrpassthruchar26) as hdrpassthruchar26,
          rtrim(OH.hdrpassthruchar27) as hdrpassthruchar27,
          rtrim(OH.hdrpassthruchar28) as hdrpassthruchar28,
          rtrim(OH.hdrpassthruchar29) as hdrpassthruchar29,
          rtrim(OH.hdrpassthruchar30) as hdrpassthruchar30,
          rtrim(OH.hdrpassthruchar31) as hdrpassthruchar31,
          rtrim(OH.hdrpassthruchar32) as hdrpassthruchar32,
          rtrim(OH.hdrpassthruchar33) as hdrpassthruchar33,
          rtrim(OH.hdrpassthruchar34) as hdrpassthruchar34,
          rtrim(OH.hdrpassthruchar35) as hdrpassthruchar35,
          rtrim(OH.hdrpassthruchar36) as hdrpassthruchar36,
          rtrim(OH.hdrpassthruchar37) as hdrpassthruchar37,
          rtrim(OH.hdrpassthruchar38) as hdrpassthruchar38,
          rtrim(OH.hdrpassthruchar39) as hdrpassthruchar39,
          rtrim(OH.hdrpassthruchar40) as hdrpassthruchar40,
          OH.hdrpassthrunum01 as hdrpassthrunum01,
          OH.hdrpassthrunum02 as hdrpassthrunum02,
          OH.hdrpassthrunum03 as hdrpassthrunum03,
          OH.hdrpassthrunum04 as hdrpassthrunum04,
          OH.hdrpassthrunum05 as hdrpassthrunum05,
          OH.hdrpassthrunum06 as hdrpassthrunum06,
          OH.hdrpassthrunum07 as hdrpassthrunum07,
          OH.hdrpassthrunum08 as hdrpassthrunum08,
          OH.hdrpassthrunum09 as hdrpassthrunum09,
          OH.hdrpassthrunum10 as hdrpassthrunum10,
          OH.wave as wave,
          zcord.cons_shiptype(OH.orderid, OH.shipid) as shiptype,
          FA.name as fa_name,
          FA.addr1 as fa_addr1,
          FA.addr2 as fa_addr2,
          FA.city as fa_city,
          FA.state as fa_state,
          FA.postalcode as fa_postalcode,
          nvl(LD.prono, OH.prono) as prono,
          CA.name as ca_name,
          CA.carrier as carrier,
          CU.name as cu_name,
          CU.addr1 as cu_addr1,
          CU.addr2 as cu_addr2,
          CU.city as cu_city,
          CU.state as cu_state,
          CU.postalcode as cu_postalcode,
          CU.manufacturerucc as manufacturerucc,
          substr(decode(CN.consignee, null, OH.shiptoname, CN.name),
               instr(decode(CN.consignee, null, OH.shiptoname, CN.name), 'DC', -1)) as dc,
          CN.storecode as storecode,
          CN.glncode as glncode,
          CN.dunsnumber as dunsnumber,
          CN.conspassthruchar01 as conspassthruchar01,
          CN.conspassthruchar02 as conspassthruchar02,
          CN.conspassthruchar03 as conspassthruchar03,
          CN.conspassthruchar04 as conspassthruchar04,
          CN.conspassthruchar05 as conspassthruchar05,
          CN.conspassthruchar06 as conspassthruchar06,
          CN.conspassthruchar07 as conspassthruchar07,
          CN.conspassthruchar08 as conspassthruchar08,
          CN.conspassthruchar09 as conspassthruchar09,
          CN.conspassthruchar10 as conspassthruchar10
      from orderhdr OH, facility FA, loads LD, carrier CA, consignee CN, customer CU
      where OH.orderid = p_orderid
        and OH.shipid = p_shipid
        and FA.facility = OH.fromfacility
        and LD.loadno (+) = OH.loadno
        and CA.carrier (+) = OH.carrier
        and CN.consignee (+) = OH.shipto
        and CU.custid = OH.custid;


-- Private functions


function calc_bigseqof
   (in_orderid    in number,
    in_shipid     in number)
return pls_integer
is
   l_bigseqof pls_integer := 0;
   l_lbluomqty number;
   l_remqty number;
begin
   for od in (select custid, item, uom, sum(nvl(qtytotcommit,0)) as qtytotcommit
      from orderdtl
      where orderid = in_orderid
        and shipid = in_shipid
      group by custid, item, uom) loop

      weber_prplbls.lbluom_qtys(od.custid, od.item, od.uom, od.qtytotcommit,
            l_lbluomqty, l_remqty);
      l_bigseqof := l_bigseqof + greatest(l_lbluomqty+l_remqty, 1);
   end loop;

   return l_bigseqof;
end calc_bigseqof;


function calccheckdigit
   (in_data in varchar2)
return char
is
   cc integer := 0;
   cnt integer;
   ix integer;
begin
   for cnt in 1..length(in_data) loop
      ix := substr(in_data, cnt, 1);

      if mod(cnt, 2) = 0 then
         cc := cc + ix;
      else
         cc := cc + (3 * ix);
      end if;
   end loop;
   return in_data || to_char(mod(10 - mod(cc, 10), 10));

exception
   when OTHERS then
      return '99999999999999999';
end calccheckdigit;


-- Private procedures


procedure add_label
   (in_lpid       in varchar2,
    in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_uom        in varchar2,
    in_quantity   in number,
    in_lotnumber  in varchar2,
    in_orderitem  in varchar2,
    in_orderlot   in varchar2,
    in_fromlpid   in varchar2,
    in_bigseqof   in number,
    in_oh         in ohdata,
    in_type       in varchar2,
    in_pickuom    in varchar2,
    in_topslip    in varchar2,
    io_bigseq     in out number)
is
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotno varchar2) is
      select OD.consigneesku as consigneesku,
             rtrim(OD.dtlpassthruchar01) as dtlpassthruchar01,
             rtrim(OD.dtlpassthruchar02) as dtlpassthruchar02,
             rtrim(OD.dtlpassthruchar03) as dtlpassthruchar03,
             rtrim(OD.dtlpassthruchar04) as dtlpassthruchar04,
             rtrim(OD.dtlpassthruchar05) as dtlpassthruchar05,
             rtrim(OD.dtlpassthruchar06) as dtlpassthruchar06,
             rtrim(OD.dtlpassthruchar07) as dtlpassthruchar07,
             rtrim(OD.dtlpassthruchar08) as dtlpassthruchar08,
             rtrim(OD.dtlpassthruchar09) as dtlpassthruchar09,
             rtrim(OD.dtlpassthruchar10) as dtlpassthruchar10,
             rtrim(OD.dtlpassthruchar11) as dtlpassthruchar11,
             rtrim(OD.dtlpassthruchar12) as dtlpassthruchar12,
             rtrim(OD.dtlpassthruchar13) as dtlpassthruchar13,
             rtrim(OD.dtlpassthruchar14) as dtlpassthruchar14,
             rtrim(OD.dtlpassthruchar15) as dtlpassthruchar15,
             rtrim(OD.dtlpassthruchar16) as dtlpassthruchar16,
             rtrim(OD.dtlpassthruchar17) as dtlpassthruchar17,
             rtrim(OD.dtlpassthruchar18) as dtlpassthruchar18,
             rtrim(OD.dtlpassthruchar19) as dtlpassthruchar19,
             rtrim(OD.dtlpassthruchar20) as dtlpassthruchar20,
             OD.dtlpassthrunum01 as dtlpassthrunum01,
             OD.dtlpassthrunum02 as dtlpassthrunum02,
             OD.dtlpassthrunum03 as dtlpassthrunum03,
             OD.dtlpassthrunum04 as dtlpassthrunum04,
             OD.dtlpassthrunum05 as dtlpassthrunum05,
             OD.dtlpassthrunum06 as dtlpassthrunum06,
             OD.dtlpassthrunum07 as dtlpassthrunum07,
             OD.dtlpassthrunum08 as dtlpassthrunum08,
             OD.dtlpassthrunum09 as dtlpassthrunum09,
             OD.dtlpassthrunum10 as dtlpassthrunum10,
             OD.dtlpassthrudoll01 as dtlpassthrudoll01,
             OD.dtlpassthrudoll02 as dtlpassthrudoll02,
             rtrim(CI.descr) as descr,
             rtrim(CI.abbrev) as abbrev,
             CI.countryof as countryof,
             CI.weight as weight,
             CI.cube as cube,
             CI.hazardous as hazardous,
             nvl(CI.labeluom, 'CS') as labeluom,
             substr(CIA.itemalias,1,12) as upc,
             CC.abbrev as countryofabbrev
         from orderdtl OD, custitem CI, custitemalias CIA, countrycodes CC
         where OD.orderid = p_orderid
           and OD.shipid = p_shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotno, '(none)')
           and CI.custid = OD.custid
           and CI.item = OD.item
           and CIA.custid (+) = OD.custid
           and CIA.item (+) = OD.item
           and CIA.aliasdesc (+) = 'UPC'
           and CC.code (+) = CI.countryof;
   od c_od%rowtype;

   l_lbluomqty number;
   l_remqty number;
   l_seq pls_integer;
   l_seqof pls_integer;
   l_totalcases number;
   l_sscc varchar2(20);
   l_minorderid orderhdr.orderid%type;
   l_asn_no weber_case_labels.asn_no%type;
   l_qty shippingplate.quantity%type;
   l_carton boolean;
   l_quantity number := in_quantity;
   l_lblcnt pls_integer;
   l_lbltotal pls_integer;
begin

   open c_od(in_orderid, in_shipid, in_orderitem, in_orderlot);
   fetch c_od into od;
   if c_od%notfound then
      od := null;
   end if;
   close c_od;

   weber_prplbls.lbluom_qtys(in_oh.custid, in_item, in_uom, in_quantity,
         l_lbluomqty, l_remqty);
   l_lbltotal := greatest(l_lbluomqty+l_remqty, 1);

   l_seqof := l_lbltotal;

   l_seq := 0;

   l_totalcases := in_bigseqof;

   select nvl(min(orderid),0) into l_minorderid
      from orderhdr
      where loadno = in_oh.loadno
        and shipto = in_oh.shipto;
   l_asn_no := substr(calccheckdigit(nvl(substr(in_oh.manufacturerucc, 1, 7), '0400000')
         || lpad(l_minorderid, 9, '0')), 1, 17);

   for l_lblcnt in 1..l_lbltotal loop

      io_bigseq := io_bigseq + 1;
      l_seq := l_seq + 1;

      l_sscc := zlbl.caselabel_barcode(in_oh.custid, '0');

      l_carton := false;
      if in_type = 'M' then
         if in_oh.shiptype = 'S' then
            l_carton := true;
         end if;
      else
         if in_type = 'C' then
            if zcord.cons_orderid(in_orderid, in_shipid) = 0 then
               l_carton := true;
            end if;
         elsif zci.picktotype(in_oh.custid, in_item, in_pickuom) = 'PACK' then
            l_carton := true;
         end if;
      end if;

      if (l_lbluomqty != 0) and (not l_carton) then
         l_qty := zlbl.uom_qty_conv(in_oh.custid, in_item, 1, od.labeluom, in_uom);
         if l_qty = 0 then
            l_qty := l_quantity;
         end if;
         l_lbluomqty := l_lbluomqty - 1;
      elsif (l_lbluomqty = 0) and (not l_carton) then
         l_qty := 1;
      else
         l_qty := l_quantity;
      end if;

      insert into weber_case_labels
         (lpid,
          sscc18,
          sscc18_formatted,
          scc14,
          shiptoname,
          shiptoaddr1,
          shiptoaddr2,
          shiptocity,
          shiptostate,
          shiptopostalcode,
          shiptopostalcode2,
          dc,
          carriername,
          carrierscac,
          shipdate,
          orderid,
          shipid,
          item,
          itemdescr,
          itemabbrev,
          wmit,
          po,
          reference,
          loadno,
          prono,
          bol,
          custname,
          custaddr1,
          custaddr2,
          custcity,
          custstate,
          custpostalcode,
          whsename,
          whseaddr1,
          whseaddr2,
          whsecity,
          whsestate,
          whsepostalcode,
          labeluom,
          upc,
          countryof,
          countryofabbrev,
          hdrpassthruchar01,
          hdrpassthruchar02,
          hdrpassthruchar03,
          hdrpassthruchar04,
          hdrpassthruchar05,
          hdrpassthruchar06,
          hdrpassthruchar07,
          hdrpassthruchar08,
          hdrpassthruchar09,
          hdrpassthruchar10,
          hdrpassthruchar11,
          hdrpassthruchar12,
          hdrpassthruchar13,
          hdrpassthruchar14,
          hdrpassthruchar15,
          hdrpassthruchar16,
          hdrpassthruchar17,
          hdrpassthruchar18,
          hdrpassthruchar19,
          hdrpassthruchar20,
          hdrpassthruchar21,
          hdrpassthruchar22,
          hdrpassthruchar23,
          hdrpassthruchar24,
          hdrpassthruchar25,
          hdrpassthruchar26,
          hdrpassthruchar27,
          hdrpassthruchar28,
          hdrpassthruchar29,
          hdrpassthruchar30,
          hdrpassthruchar31,
          hdrpassthruchar32,
          hdrpassthruchar33,
          hdrpassthruchar34,
          hdrpassthruchar35,
          hdrpassthruchar36,
          hdrpassthruchar37,
          hdrpassthruchar38,
          hdrpassthruchar39,
          hdrpassthruchar40,
          hdrpassthrunum01,
          hdrpassthrunum02,
          hdrpassthrunum03,
          hdrpassthrunum04,
          hdrpassthrunum05,
          hdrpassthrunum06,
          hdrpassthrunum07,
          hdrpassthrunum08,
          hdrpassthrunum09,
          hdrpassthrunum10,
          dtlpassthruchar01,
          dtlpassthruchar02,
          dtlpassthruchar03,
          dtlpassthruchar04,
          dtlpassthruchar05,
          dtlpassthruchar06,
          dtlpassthruchar07,
          dtlpassthruchar08,
          dtlpassthruchar09,
          dtlpassthruchar10,
          dtlpassthruchar11,
          dtlpassthruchar12,
          dtlpassthruchar13,
          dtlpassthruchar14,
          dtlpassthruchar15,
          dtlpassthruchar16,
          dtlpassthruchar17,
          dtlpassthruchar18,
          dtlpassthruchar19,
          dtlpassthruchar20,
          dtlpassthrunum01,
          dtlpassthrunum02,
          dtlpassthrunum03,
          dtlpassthrunum04,
          dtlpassthrunum05,
          dtlpassthrunum06,
          dtlpassthrunum07,
          dtlpassthrunum08,
          dtlpassthrunum09,
          dtlpassthrunum10,
          jcpbcstore,
          finaldestzip,
          seq,
          seqof,
          bigseq,
          bigseqof,
          itemweight,
          itemcube,
          storecategory,
          asn_no,
          hazardous,
          wave,
          fromlpid,
          changed,
          storecode,
          glncode,
          dunsnumber,
          conspassthruchar01,
          conspassthruchar02,
          conspassthruchar03,
          conspassthruchar04,
          conspassthruchar05,
          conspassthruchar06,
          conspassthruchar07,
          conspassthruchar08,
          conspassthruchar09,
          conspassthruchar10,
          totalcases,
          dtlpassthrudoll01,
          dtlpassthrudoll02,
          shiptocontact,
          case_height,
          case_length,
          case_weight,
          case_width,
          quantity)
      values
         (in_lpid,
          l_sscc,
          '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
          zedi.get_sscc14_code('1', od.dtlpassthruchar09),
          in_oh.shiptoname,
          in_oh.shiptoaddr1,
          in_oh.shiptoaddr2,
          in_oh.shiptocity,
          in_oh.shiptostate,
          in_oh.shiptopostalcode,
          in_oh.shiptopostalcode,
          in_oh.dc,
          in_oh.ca_name,
          in_oh.ca_carrier,
          in_oh.shipdate,
          in_orderid,
          in_shipid,
          in_item,
          od.descr,
          od.abbrev,
          nvl(od.consigneesku,in_item),
          in_oh.po,
          in_oh.reference,
          in_oh.loadno,
          in_oh.prono,
          in_orderid||'-'||in_shipid,
          in_oh.cu_name,
          in_oh.cu_addr1,
          in_oh.cu_addr2,
          in_oh.cu_city,
          in_oh.cu_state,
          in_oh.cu_postalcode,
          in_oh.fa_name,
          in_oh.fa_addr1,
          in_oh.fa_addr2,
          in_oh.fa_city,
          in_oh.fa_state,
          in_oh.fa_postalcode,
          substr(to_char(l_qty),1,4),
          od.upc,
          od.countryof,
          od.countryofabbrev,
          in_oh.hdrpassthruchar01,
          in_oh.hdrpassthruchar02,
          in_oh.hdrpassthruchar03,
          in_oh.hdrpassthruchar04,
          in_oh.hdrpassthruchar05,
          in_oh.hdrpassthruchar06,
          in_oh.hdrpassthruchar07,
          in_oh.hdrpassthruchar08,
          in_oh.hdrpassthruchar09,
          in_oh.hdrpassthruchar10,
          in_oh.hdrpassthruchar11,
          in_oh.hdrpassthruchar12,
          in_oh.hdrpassthruchar13,
          in_oh.hdrpassthruchar14,
          in_oh.hdrpassthruchar15,
          in_oh.hdrpassthruchar16,
          in_oh.hdrpassthruchar17,
          in_oh.hdrpassthruchar18,
          in_oh.hdrpassthruchar19,
          in_oh.hdrpassthruchar20,
          in_oh.hdrpassthruchar21,
          in_oh.hdrpassthruchar22,
          in_oh.hdrpassthruchar23,
          in_oh.hdrpassthruchar24,
          in_oh.hdrpassthruchar25,
          in_oh.hdrpassthruchar26,
          in_oh.hdrpassthruchar27,
          in_oh.hdrpassthruchar28,
          in_oh.hdrpassthruchar29,
          in_oh.hdrpassthruchar30,
          in_oh.hdrpassthruchar31,
          in_oh.hdrpassthruchar32,
          in_oh.hdrpassthruchar33,
          in_oh.hdrpassthruchar34,
          in_oh.hdrpassthruchar35,
          in_oh.hdrpassthruchar36,
          in_oh.hdrpassthruchar37,
          in_oh.hdrpassthruchar38,
          in_oh.hdrpassthruchar39,
          in_oh.hdrpassthruchar40,
          in_oh.hdrpassthrunum01,
          in_oh.hdrpassthrunum02,
          in_oh.hdrpassthrunum03,
          in_oh.hdrpassthrunum04,
          in_oh.hdrpassthrunum05,
          in_oh.hdrpassthrunum06,
          in_oh.hdrpassthrunum07,
          in_oh.hdrpassthrunum08,
          in_oh.hdrpassthrunum09,
          in_oh.hdrpassthrunum10,
          od.dtlpassthruchar01,
          od.dtlpassthruchar02,
          od.dtlpassthruchar03,
          od.dtlpassthruchar04,
          od.dtlpassthruchar05,
          od.dtlpassthruchar06,
          od.dtlpassthruchar07,
          od.dtlpassthruchar08,
          od.dtlpassthruchar09,
          od.dtlpassthruchar10,
          od.dtlpassthruchar11,
          od.dtlpassthruchar12,
          od.dtlpassthruchar13,
          od.dtlpassthruchar14,
          od.dtlpassthruchar15,
          od.dtlpassthruchar16,
          od.dtlpassthruchar17,
          od.dtlpassthruchar18,
          od.dtlpassthruchar19,
          od.dtlpassthruchar20,
          od.dtlpassthrunum01,
          od.dtlpassthrunum02,
          od.dtlpassthrunum03,
          od.dtlpassthrunum04,
          od.dtlpassthrunum05,
          od.dtlpassthrunum06,
          od.dtlpassthrunum07,
          od.dtlpassthrunum08,
          od.dtlpassthrunum09,
          od.dtlpassthrunum10,
          '0'||in_oh.hdrpassthruchar10,
          in_oh.hdrpassthruchar04,
          l_seq,
          l_seqof,
          io_bigseq,
          in_bigseqof,
          od.weight,
          od.cube,
          decode(in_oh.hdrpassthruchar01,
            'PH1', in_oh.hdrpassthruchar01,
                   decode(in_oh.hdrpassthruchar01,
                     'PH2', in_oh.hdrpassthruchar01,
                            null)),
          l_asn_no,
          decode(od.hazardous,'Y', 'HAZARDOUS MATERIAL',null),
          in_oh.wave,
          in_fromlpid,
          null,
          in_oh.storecode,
          in_oh.glncode,
          in_oh.dunsnumber,
          in_oh.conspassthruchar01,
          in_oh.conspassthruchar02,
          in_oh.conspassthruchar03,
          in_oh.conspassthruchar04,
          in_oh.conspassthruchar05,
          in_oh.conspassthruchar06,
          in_oh.conspassthruchar07,
          in_oh.conspassthruchar08,
          in_oh.conspassthruchar09,
          in_oh.conspassthruchar10,
          l_totalcases,
          od.dtlpassthrudoll01,
          od.dtlpassthrudoll02,
          in_oh.shiptocontact,
          zci.item_uom_height(in_oh.custid, in_item, 'CS'),
          zci.item_uom_length(in_oh.custid, in_item, 'CS'),
          zci.item_weight(in_oh.custid, in_item, 'CS'),
          zci.item_uom_width(in_oh.custid, in_item, 'CS'),
          in_quantity);

      insert into caselabels
         (orderid,
          shipid,
          custid,
          item,
          lotnumber,
          lpid,
          barcode,
          seq,
          seqof,
          created,
          auxtable,
          auxkey,
          quantity,
          labeltype)
      values
         (in_orderid,
          in_shipid,
          in_oh.custid,
          in_item,
          in_lotnumber,
          in_topslip,
          l_sscc,
          l_seq,
          l_seqof,
          sysdate,
          'weber_case_labels',
          'sscc18',
          decode(l_seq, l_seqof, l_quantity, l_qty),
          'CQ');

      l_quantity := l_quantity - l_qty;

   end loop;

end add_label;


procedure build_lplbl
   (in_lpid       in varchar2,
    in_orderid    in number,
    in_shipid     in number,
    in_fromlpid   in varchar2,
    in_bigseqof   in number,
    in_oh         in ohdata,
    in_type       in varchar2,
    in_topslip    in varchar2,
    io_bigseq     in out number)
is
begin
   for cp in (select item, unitofmeasure, lotnumber, orderitem, orderlot, pickuom,
                     sum(quantity) as quantity
               from shippingplate
               where lpid = in_lpid
               group by item, unitofmeasure, lotnumber, orderitem, orderlot, pickuom
               order by item) loop
      add_label(in_lpid, in_orderid, in_shipid, cp.item, cp.unitofmeasure, cp.quantity,
                   cp.lotnumber, cp.orderitem, cp.orderlot, in_fromlpid, in_bigseqof,
                   in_oh, in_type, cp.pickuom, in_topslip, io_bigseq);
   end loop;
end build_lplbl;


-- Public Procedures


procedure caseqty
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   type lptbltype is table of shippingplate.lpid%type index by binary_integer;
   l_lptbl lptbltype;

   cursor c_sp(p_lpid varchar2) is
      select orderid, shipid, status, type, fromlpid, parentlpid
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype := null;
   pp c_sp%rowtype := null;
   oh ohdata;
   l_cnt pls_integer;
   l_bigseq pls_integer;
   l_bigseqof pls_integer;
   l_err number;
   i binary_integer;
begin
   out_stmt := null;

   if in_action not in ('A','P') then
      if in_func = 'Q' then
         out_stmt := 'Unsupported Action';
      end if;
      return;
   end if;

   open c_sp(in_lpid);
   fetch c_sp into sp;
   close c_sp;

   -- no labels for non-existent plates
   if sp.status is null then
      if in_func = 'Q' then
         out_stmt := 'Plate not found';
      end if;
      return;
   end if;

   -- no labels for Unpicked picks
   if sp.status = 'U' then
      if in_func = 'Q' then
         out_stmt := 'Plate Unpicked';
      end if;
      return;
   end if;

   if sp.type in ('P', 'F') then
      select count(1) into l_cnt
         from weber_case_labels
         where lpid = in_lpid;

      if l_cnt > 0 then
         if in_func = 'Q' then
            out_stmt := 'OKAY';
         else
            out_stmt := 'select * from weber_case_labels where lpid = ''' || in_lpid
                  || ''' order by bigseq';
         end if;
         return;
      end if;

      if in_func = 'Q' then
         if in_action = 'A' then
            out_stmt := 'OKAY';
         else
            out_stmt := 'Nothing for plate';
         end if;
         return;
      end if;

      open c_oh(sp.orderid, sp.shipid);
      fetch c_oh into oh;
      if c_oh%notfound then
         oh := null;
      end if;
      close c_oh;

      -- orderid as the lockid, the lock will be released on the commit
      l_err := dbms_lock.request(sp.orderid, dbms_lock.x_mode, dbms_lock.maxwait, true);
      if l_err = 0 then
         select nvl(max(bigseq),0) into l_bigseq
            from weber_case_labels
            where orderid = sp.orderid
              and shipid = sp.shipid;

         l_bigseqof := calc_bigseqof(sp.orderid, sp.shipid);

         if sp.parentlpid is not null then
            open c_sp(sp.parentlpid);
            fetch c_sp into pp;
            close c_sp;
         else
            pp := sp;
         end if;

         build_lplbl(in_lpid, sp.orderid, sp.shipid, pp.fromlpid, l_bigseqof,
               oh, pp.type, nvl(sp.parentlpid,in_lpid), l_bigseq);

         commit;

         out_stmt := 'select * from weber_case_labels where lpid = ''' || in_lpid
               || ''' order by bigseq';

      end if;
      return;
   end if;

   -- we have either a master or carton, need to check each child separately
   l_lptbl.delete;
   for cp in (select lpid
               from shippingplate
               where parentlpid = in_lpid) loop

      select count(1) into l_cnt
         from weber_case_labels
         where lpid = cp.lpid;

      if l_cnt = 0 then
         l_lptbl(l_lptbl.count+1) := cp.lpid;
      end if;
   end loop;

   -- every child accounted for
   if l_lptbl.count = 0 then
      if in_func = 'Q' then
         out_stmt := 'OKAY';
      else
         out_stmt := 'select W.* from weber_case_labels W, shippingplate S'
               || ' where S.parentlpid = ''' || in_lpid || ''''
               || ' and W.lpid = S.lpid order by bigseq';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      if in_action = 'A' then
         out_stmt := 'OKAY';
      else
         out_stmt := 'Incomplete plate';
      end if;
      return;
   end if;

   open c_oh(sp.orderid, sp.shipid);
   fetch c_oh into oh;
   if c_oh%notfound then
      oh := null;
   end if;
   close c_oh;

   -- orderid as the lockid, the lock will be released on the commit
   l_err := dbms_lock.request(sp.orderid, dbms_lock.x_mode, dbms_lock.maxwait, true);
   if l_err = 0 then
      select nvl(max(bigseq),0) into l_bigseq
         from weber_case_labels
         where orderid = sp.orderid
           and shipid = sp.shipid;

      l_bigseqof := calc_bigseqof(sp.orderid, sp.shipid);

      -- only generate data for missing child plates
      for i in 1..l_lptbl.count loop
         build_lplbl(l_lptbl(i), sp.orderid, sp.shipid, sp.fromlpid, l_bigseqof,
               oh, sp.type, in_lpid, l_bigseq);
      end loop;

      commit;

      out_stmt := 'select W.* from weber_case_labels W, shippingplate S'
            || ' where S.parentlpid = ''' || in_lpid || ''''
            || ' and W.lpid = S.lpid order by bigseq';
   end if;

end caseqty;


end weber_platelbls;
/

show errors package body weber_platelbls;
exit;
