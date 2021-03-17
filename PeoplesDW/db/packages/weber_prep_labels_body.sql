create or replace package body weber_prplbls as
--
-- $Id$
--

-- Types


type lbldatatype is record (
   lpid shippingplate.lpid%type,
   custid shippingplate.custid%type,
   item shippingplate.item%type,
   uom shippingplate.unitofmeasure%type,
   qty shippingplate.quantity%type,
   fromlpid shippingplate.fromlpid%type,
   orderlot shippingplate.orderlot%type,
   location shippingplate.location%type);
type lbldatacur is ref cursor return lbldatatype;


-- Private


function chkdigit
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
end chkdigit;


procedure verify_order
   (in_key      in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_orderid out number,
    out_shipid  out number,
    out_msg     out varchar2)
is
   l_pos number;
   l_cnt pls_integer := 0;
begin
   out_msg := null;

   l_pos := instr(in_key, '|');
   if l_pos != 0 then
      out_orderid := to_number(substr(in_key, 1, l_pos-1));
      out_shipid := to_number(substr(in_key, l_pos+1));
      if out_shipid != 0 then
         select count(1) into l_cnt
            from orderhdr
            where orderid = out_orderid
              and shipid = out_shipid;
      else
         select count(1) into l_cnt
            from orderhdr
            where wave = out_orderid;
      end if;
   end if;

   if l_cnt = 0 then
      if in_func = 'Q' then
         out_msg := 'Order not found';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      if in_action = 'A' then
         out_msg := 'OKAY';
      elsif in_action = 'P' then
         if out_shipid != 0 then
            select count(1) into l_cnt
               from weber_case_labels
               where orderid = out_orderid
                 and shipid = out_shipid;
         else
            select count(1) into l_cnt
               from weber_case_labels
               where wave = out_orderid;
         end if;
         if l_cnt = 0 then
            out_msg := 'Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      elsif in_action != 'C' then
         out_msg := 'Unsupported Action';
      end if;
      if out_msg is not null then
         return;
      end if;
   end if;

   if in_action not in ('A','P','C') then
      out_msg := 'Unsupported Action';
      return;
   end if;

   out_msg := 'Continue';

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end verify_order;


procedure verify_load
   (in_key     in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_loadno out number,
    out_msg    out varchar2)
is
   l_cnt pls_integer := 0;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_msg varchar2(255);
begin
   out_msg := null;

   out_loadno := to_number(in_key);
   select count(1) into l_cnt
      from loads
      where loadno = out_loadno;

   if l_cnt = 0 then
      if in_func = 'Q' then
         out_msg := 'Load not found';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      if in_action = 'A' then
         out_msg := 'OKAY';
      elsif in_action = 'P' then
         select count(1) into l_cnt
            from weber_case_labels
            where loadno = out_loadno;
         if l_cnt = 0 then
            out_msg := 'Nothing for Load';
         else
            out_msg := 'OKAY';
         end if;
      elsif in_action = 'N' then
         out_msg := 'Nothing for load';
         for oh in (select orderid||'|'||shipid as orderkey from orderhdr
                     where loadno = out_loadno) loop
            verify_order(oh.orderkey, in_func, 'P', l_orderid, l_shipid, l_msg);
            if l_msg = 'Nothing for order' then
               out_msg := 'OKAY';
               exit;
            end if;
         end loop;
      end if;
      if out_msg is not null then
         return;
      end if;
   end if;

   out_msg := 'Continue';

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end verify_load;


procedure verify_wave
   (in_key    in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_wave  out number,
    out_msg   out varchar2)
is
   l_cnt pls_integer := 0;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_msg varchar2(255);
begin
   out_msg := null;

   out_wave := to_number(in_key);
   select count(1) into l_cnt
      from waves
      where wave = out_wave;

   if l_cnt = 0 then
      if in_func = 'Q' then
         out_msg := 'Wave not found';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      if in_action = 'A' then
         out_msg := 'OKAY';
      elsif in_action = 'P' then
         select count(1) into l_cnt
            from weber_case_labels
            where wave = out_wave;
         if l_cnt = 0 then
            out_msg := 'Nothing for wave';
         else
            out_msg := 'OKAY';
         end if;
      elsif in_action = 'N' then
         out_msg := 'Nothing for wave';
         for oh in (select orderid||'|'||shipid as orderkey from orderhdr
                     where wave = out_wave) loop
            verify_order(oh.orderkey, in_func, 'P', l_orderid, l_shipid, l_msg);
            if l_msg = 'Nothing for order' then
               out_msg := 'OKAY';
               exit;
            end if;
         end loop;
      end if;
      if out_msg is not null then
         return;
      end if;
   end if;

   out_msg := 'Continue';

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end verify_wave;


-- Don't call with a consolidated order
procedure order_labels     -- Q/C, X/A, X/P, or X/C
   (in_orderid      in number,
    in_shipid       in number,
    in_func         in varchar2,
    in_action       in varchar2,
    out_disposition out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.custid as custid,
             nvl(CN.name,OH.shiptoname) as shiptoname,
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
   oh c_oh%rowtype;
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
   cursor c_wv(p_orderid number, p_shipid number) is
      select WV.picktype, WV.consolidated
         from waves WV, orderhdr OH
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and WV.wave = OH.wave;
   wv c_wv%rowtype;
   cursor c_alt(p_rowid varchar2) is
      select *
         from weber_case_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   c_lbldata lbldatacur;
   ld lbldatatype;

   l_cnt pls_integer;
   l_type varchar2(1) := '?';
   l_minorderid orderhdr.orderid%type;
   l_asn_no weber_case_labels.asn_no%type;
   l_seq pls_integer;
   l_seqof pls_integer := 0;
   l_bigseq pls_integer := 0;
   l_bigseqof pls_integer := 0;
   l_qty shippingplate.quantity%type;
   l_sscc varchar2(20);
   l_rowid varchar2(20);
   l_match varchar2(1);
   l_lbluomqty number;
   l_remqty number;
begin
   out_disposition := 'null';

   if in_action = 'P' then
      out_disposition := 'select';
      return;
   end if;

-- Q/C, X/A and X/C remain
   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   if c_oh%notfound then
      oh := null;
   end if;
   close c_oh;

   select count(1) into l_cnt
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid;

   if l_cnt != 0 then            -- order with shippingplates
      l_type := 'O';

   else
      open c_wv(in_orderid, in_shipid);
      fetch c_wv into wv;
      if c_wv%notfound then
         wv := null;
      end if;
      close c_wv;

      if nvl(wv.picktype,'??') = 'BAT' then
         l_type := 'B';          -- batch picking with no shippingplates

      elsif nvl(wv.consolidated,'N') = 'Y' then
         l_type := 'C';          -- part of a consolidated order before picking

      end if;
   end if;

   if l_type not in ('B', 'C', 'O') then
      if in_func = 'Q' then
         out_disposition := 'nothing';
      end if;
      return;
   end if;

   if in_action != 'C' then
      delete from caselabels
         where orderid = in_orderid
           and shipid = in_shipid;
      delete from weber_case_labels
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;

   select nvl(min(orderid),0) into l_minorderid
      from orderhdr
      where loadno = oh.loadno
        and shipto = oh.shipto;

   l_asn_no := substr(chkdigit(lpad(nvl(substr(oh.manufacturerucc, 1, 7), '0400000'), 7, '0')
      || lpad(l_minorderid, 9, '0')), 1, 17);

   if l_type = 'O' then
      for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and type in ('F','P')
                  group by custid, item, unitofmeasure) loop
         l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item, sp.unitofmeasure,
               sp.quantity);
      end loop;
      open c_lbldata for
         select lpid, custid, item, unitofmeasure, sum(quantity), fromlpid, orderlot, location
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid
              and type in ('F','P')
            group by lpid, custid, item, unitofmeasure, fromlpid, orderlot, location
            order by item, orderlot, lpid;
   else
      for bt in (select custid, item, uom, sum(qty) as qty
                  from batchtasks
                  where orderid = in_orderid
                    and shipid = in_shipid
                  group by custid, item, uom) loop
         l_bigseqof := l_bigseqof + lbl_remainder_qty(bt.custid, bt.item, bt.uom, bt.qty);
      end loop;
      open c_lbldata for
         select null, custid, item, uom, sum(qty), lpid, orderlot, fromloc
            from batchtasks
            where orderid = in_orderid
              and shipid = in_shipid
            group by null, custid, item, uom, lpid, orderlot, fromloc
            order by item, orderlot;
   end if;

   loop
      fetch c_lbldata into ld;
      exit when c_lbldata%notfound;

      open c_od(in_orderid, in_shipid, ld.item, ld.orderlot);
      fetch c_od into od;
      if c_od%notfound then
         od := null;
      end if;
      close c_od;

      lbluom_qtys(ld.custid, ld.item, ld.uom, ld.qty, l_lbluomqty, l_remqty);
      l_seqof := greatest(l_lbluomqty+l_remqty, 1);

      for l_seq in 1..l_seqof loop

--       adjust quantity based upon remainders
         if l_lbluomqty != 0 then
            l_qty := zlbl.uom_qty_conv(ld.custid, ld.item, 1, od.labeluom, ld.uom);
            if l_qty = 0 then
               l_qty := ld.qty;
            end if;
            l_lbluomqty := l_lbluomqty - 1;
         else
            l_qty := 1;
         end if;

         if in_action != 'C' then
            l_bigseq := l_bigseq + 1;
            l_sscc := zlbl.caselabel_barcode(ld.custid, '0');

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
                location,
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
                conspassthruchar10)
            values
               (ld.lpid,
                l_sscc,
                '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
                zedi.get_sscc14_code('1', od.dtlpassthruchar09),
                oh.shiptoname,
                oh.shiptoaddr1,
                oh.shiptoaddr2,
                oh.shiptocity,
                oh.shiptostate,
                oh.shiptopostalcode,
                oh.shiptopostalcode,
                oh.dc,
                oh.ca_name,
                oh.carrier,
                oh.shipdate,
                in_orderid,
                in_shipid,
                ld.item,
                od.descr,
                od.abbrev,
                nvl(od.consigneesku, ld.item),
                oh.po,
                oh.reference,
                oh.loadno,
                oh.prono,
                in_orderid||'-'||in_shipid,
                oh.cu_name,
                oh.cu_addr1,
                oh.cu_addr2,
                oh.cu_city,
                oh.cu_state,
                oh.cu_postalcode,
                oh.fa_name,
                oh.fa_addr1,
                oh.fa_addr2,
                oh.fa_city,
                oh.fa_state,
                oh.fa_postalcode,
                substr(to_char(l_qty),1,4),
                od.upc,
                od.countryof,
                od.countryofabbrev,
                oh.hdrpassthruchar01,
                oh.hdrpassthruchar02,
                oh.hdrpassthruchar03,
                oh.hdrpassthruchar04,
                oh.hdrpassthruchar05,
                oh.hdrpassthruchar06,
                oh.hdrpassthruchar07,
                oh.hdrpassthruchar08,
                oh.hdrpassthruchar09,
                oh.hdrpassthruchar10,
                oh.hdrpassthruchar11,
                oh.hdrpassthruchar12,
                oh.hdrpassthruchar13,
                oh.hdrpassthruchar14,
                oh.hdrpassthruchar15,
                oh.hdrpassthruchar16,
                oh.hdrpassthruchar17,
                oh.hdrpassthruchar18,
                oh.hdrpassthruchar19,
                oh.hdrpassthruchar20,
                oh.hdrpassthruchar21,
                oh.hdrpassthruchar22,
                oh.hdrpassthruchar23,
                oh.hdrpassthruchar24,
                oh.hdrpassthruchar25,
                oh.hdrpassthruchar26,
                oh.hdrpassthruchar27,
                oh.hdrpassthruchar28,
                oh.hdrpassthruchar29,
                oh.hdrpassthruchar30,
                oh.hdrpassthruchar31,
                oh.hdrpassthruchar32,
                oh.hdrpassthruchar33,
                oh.hdrpassthruchar34,
                oh.hdrpassthruchar35,
                oh.hdrpassthruchar36,
                oh.hdrpassthruchar37,
                oh.hdrpassthruchar38,
                oh.hdrpassthruchar39,
                oh.hdrpassthruchar40,
                oh.hdrpassthrunum01,
                oh.hdrpassthrunum02,
                oh.hdrpassthrunum03,
                oh.hdrpassthrunum04,
                oh.hdrpassthrunum05,
                oh.hdrpassthrunum06,
                oh.hdrpassthrunum07,
                oh.hdrpassthrunum08,
                oh.hdrpassthrunum09,
                oh.hdrpassthrunum10,
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
                '0'||oh.hdrpassthruchar10,
                oh.hdrpassthruchar04,
                l_seq,
                l_seqof,
                l_bigseq,
                l_bigseqof,
                od.weight,
                od.cube,
                decode(oh.hdrpassthruchar01,
                  'PH1', oh.hdrpassthruchar01,
                         decode(oh.hdrpassthruchar01,
                           'PH2', oh.hdrpassthruchar01,
                                  null)),
                l_asn_no,
                decode(od.hazardous,'Y', 'HAZARDOUS MATERIAL',null),
                oh.wave,
                ld.fromlpid,
                null,
                ld.location,
                oh.storecode,
                oh.glncode,
                oh.dunsnumber,
                oh.conspassthruchar01,
                oh.conspassthruchar02,
                oh.conspassthruchar03,
                oh.conspassthruchar04,
                oh.conspassthruchar05,
                oh.conspassthruchar06,
                oh.conspassthruchar07,
                oh.conspassthruchar08,
                oh.conspassthruchar09,
                oh.conspassthruchar10);

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
                oh.custid,
                ld.item,
                ld.orderlot,
                ld.lpid,
                l_sscc,
                l_seq,
                l_seqof,
                sysdate,
                'weber_case_labels',
                'sscc18',
                decode(l_seq, l_seqof, ld.qty, l_qty),
                'PP');
         else
            insert into weber_case_labels_temp
               (lpid,
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
                location,
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
                conspassthruchar10)
            values
               (ld.lpid,
                zedi.get_sscc14_code('1', od.dtlpassthruchar09),
                oh.shiptoname,
                oh.shiptoaddr1,
                oh.shiptoaddr2,
                oh.shiptocity,
                oh.shiptostate,
                oh.shiptopostalcode,
                oh.shiptopostalcode,
                oh.dc,
                oh.ca_name,
                oh.carrier,
                oh.shipdate,
                in_orderid,
                in_shipid,
                ld.item,
                od.descr,
                od.abbrev,
                nvl(od.consigneesku, ld.item),
                oh.po,
                oh.reference,
                oh.loadno,
                oh.prono,
                in_orderid||'-'||in_shipid,
                oh.cu_name,
                oh.cu_addr1,
                oh.cu_addr2,
                oh.cu_city,
                oh.cu_state,
                oh.cu_postalcode,
                oh.fa_name,
                oh.fa_addr1,
                oh.fa_addr2,
                oh.fa_city,
                oh.fa_state,
                oh.fa_postalcode,
                substr(to_char(l_qty),1,4),
                od.upc,
                od.countryof,
                od.countryofabbrev,
                oh.hdrpassthruchar01,
                oh.hdrpassthruchar02,
                oh.hdrpassthruchar03,
                oh.hdrpassthruchar04,
                oh.hdrpassthruchar05,
                oh.hdrpassthruchar06,
                oh.hdrpassthruchar07,
                oh.hdrpassthruchar08,
                oh.hdrpassthruchar09,
                oh.hdrpassthruchar10,
                oh.hdrpassthruchar11,
                oh.hdrpassthruchar12,
                oh.hdrpassthruchar13,
                oh.hdrpassthruchar14,
                oh.hdrpassthruchar15,
                oh.hdrpassthruchar16,
                oh.hdrpassthruchar17,
                oh.hdrpassthruchar18,
                oh.hdrpassthruchar19,
                oh.hdrpassthruchar20,
                oh.hdrpassthruchar21,
                oh.hdrpassthruchar22,
                oh.hdrpassthruchar23,
                oh.hdrpassthruchar24,
                oh.hdrpassthruchar25,
                oh.hdrpassthruchar26,
                oh.hdrpassthruchar27,
                oh.hdrpassthruchar28,
                oh.hdrpassthruchar29,
                oh.hdrpassthruchar30,
                oh.hdrpassthruchar31,
                oh.hdrpassthruchar32,
                oh.hdrpassthruchar33,
                oh.hdrpassthruchar34,
                oh.hdrpassthruchar35,
                oh.hdrpassthruchar36,
                oh.hdrpassthruchar37,
                oh.hdrpassthruchar38,
                oh.hdrpassthruchar39,
                oh.hdrpassthruchar40,
                oh.hdrpassthrunum01,
                oh.hdrpassthrunum02,
                oh.hdrpassthrunum03,
                oh.hdrpassthrunum04,
                oh.hdrpassthrunum05,
                oh.hdrpassthrunum06,
                oh.hdrpassthrunum07,
                oh.hdrpassthrunum08,
                oh.hdrpassthrunum09,
                oh.hdrpassthrunum10,
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
                '0'||oh.hdrpassthruchar10,
                oh.hdrpassthruchar04,
                l_seq,
                l_seqof,
                l_bigseq,
                l_bigseqof,
                od.weight,
                od.cube,
                decode(oh.hdrpassthruchar01,
                  'PH1', oh.hdrpassthruchar01,
                         decode(oh.hdrpassthruchar01,
                           'PH2', oh.hdrpassthruchar01,
                                  null)),
                l_asn_no,
                decode(od.hazardous,
                  'Y', 'HAZARDOUS MATERIAL',
                        null),
                oh.wave,
                ld.fromlpid,
                ld.location,
                oh.storecode,
                oh.glncode,
                oh.dunsnumber,
                oh.conspassthruchar01,
                oh.conspassthruchar02,
                oh.conspassthruchar03,
                oh.conspassthruchar04,
                oh.conspassthruchar05,
                oh.conspassthruchar06,
                oh.conspassthruchar07,
                oh.conspassthruchar08,
                oh.conspassthruchar09,
                oh.conspassthruchar10)
            returning rowid into l_rowid;

            insert into caselabels_temp
               (orderid,
                shipid,
                custid,
                item,
                lotnumber,
                lpid,
                seq,
                seqof,
                quantity,
                labeltype,
                barcodetype,
                auxrowid,
                matched)
            values
               (in_orderid,
                in_shipid,
                oh.custid,
                ld.item,
                ld.orderlot,
                ld.lpid,
                l_seq,
                l_seqof,
                decode(l_seq, l_seqof, ld.qty, l_qty),
                'PP',
                '0',
                l_rowid,
                'N');
         end if;

         ld.qty := ld.qty - l_qty;
      end loop;
   end loop;

   if in_action != 'C' then
      commit;
      out_disposition := 'select';
      return;
   end if;

   if in_func = 'Q' then
--    match caselabels with temp ignoring barcode
      for lbl in (select * from caselabels
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and labeltype = 'PP') loop

         l_match := 'N';
         for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                        where matched = 'N') loop

            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
            and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
            and nvl(tmp.seq,0) = nvl(lbl.seq,0)
            and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
            and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
            and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then

               l_match := 'Y';
               update caselabels_temp
                  set matched = l_match
                  where rowid = tmp.rowid;
               exit;
            end if;
         end loop;

         if l_match = 'N' then
            out_disposition := 'okay';
            exit;
         end if;
      end loop;

--    each caselabel is also in temp, check for extras in temp
      if out_disposition = 'null' then
         select count(1) into l_cnt
            from caselabels_temp
            where matched = 'N';
         if l_cnt > 0 then
            out_disposition := 'okay';
         end if;
      end if;

      if out_disposition = 'null' then
         out_disposition := 'nothing';
      end if;

      delete caselabels_temp;
      delete weber_case_labels_temp;
      commit;
      return;
   end if;

-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and labeltype = 'PP') loop
      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
         and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
         and nvl(tmp.seq,0) = nvl(lbl.seq,0)
         and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
         and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
         and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then

            l_match := 'Y';
            update caselabels_temp
               set matched = l_match
               where rowid = tmp.rowid;
            exit;
         end if;
      end loop;

      update caselabels
         set matched = l_match
         where rowid = lbl.rowid;
   end loop;

-- delete unmatched old data
   delete weber_case_labels
      where orderid = in_orderid
        and shipid = in_shipid
        and sscc18 in (select barcode from caselabels
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and matched = 'N');
   delete caselabels
      where orderid = in_orderid
        and shipid = in_shipid
        and matched = 'N';

-- add new data
   update weber_case_labels
      set changed = 'N'
      where orderid = in_orderid
        and shipid = in_shipid;

   for tmp in (select * from caselabels_temp
                  where matched = 'N') loop

      l_sscc := zlbl.caselabel_barcode(tmp.custid, tmp.barcodetype);
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
         (tmp.orderid,
          tmp.shipid,
          tmp.custid,
          tmp.item,
          tmp.lotnumber,
          tmp.lpid,
          l_sscc,
          tmp.seq,
          tmp.seqof,
          sysdate,
          'weber_case_labels',
          'sscc18',
          tmp.quantity,
          'PP');

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;

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
          location,
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
          conspassthruchar10)
      values
         (alt.lpid,
          l_sscc,
          '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
          alt.scc14,
          alt.shiptoname,
          alt.shiptoaddr1,
          alt.shiptoaddr2,
          alt.shiptocity,
          alt.shiptostate,
          alt.shiptopostalcode,
          alt.shiptopostalcode2,
          alt.dc,
          alt.carriername,
          alt.carrierscac,
          alt.shipdate,
          alt.orderid,
          alt.shipid,
          alt.item,
          alt.itemdescr,
          alt.itemabbrev,
          alt.wmit,
          alt.po,
          alt.reference,
          alt.loadno,
          alt.prono,
          alt.bol,
          alt.custname,
          alt.custaddr1,
          alt.custaddr2,
          alt.custcity,
          alt.custstate,
          alt.custpostalcode,
          alt.whsename,
          alt.whseaddr1,
          alt.whseaddr2,
          alt.whsecity,
          alt.whsestate,
          alt.whsepostalcode,
          alt.labeluom,
          alt.upc,
          alt.countryof,
          alt.countryofabbrev,
          alt.hdrpassthruchar01,
          alt.hdrpassthruchar02,
          alt.hdrpassthruchar03,
          alt.hdrpassthruchar04,
          alt.hdrpassthruchar05,
          alt.hdrpassthruchar06,
          alt.hdrpassthruchar07,
          alt.hdrpassthruchar08,
          alt.hdrpassthruchar09,
          alt.hdrpassthruchar10,
          alt.hdrpassthruchar11,
          alt.hdrpassthruchar12,
          alt.hdrpassthruchar13,
          alt.hdrpassthruchar14,
          alt.hdrpassthruchar15,
          alt.hdrpassthruchar16,
          alt.hdrpassthruchar17,
          alt.hdrpassthruchar18,
          alt.hdrpassthruchar19,
          alt.hdrpassthruchar20,
          alt.hdrpassthruchar21,
          alt.hdrpassthruchar22,
          alt.hdrpassthruchar23,
          alt.hdrpassthruchar24,
          alt.hdrpassthruchar25,
          alt.hdrpassthruchar26,
          alt.hdrpassthruchar27,
          alt.hdrpassthruchar28,
          alt.hdrpassthruchar29,
          alt.hdrpassthruchar30,
          alt.hdrpassthruchar31,
          alt.hdrpassthruchar32,
          alt.hdrpassthruchar33,
          alt.hdrpassthruchar34,
          alt.hdrpassthruchar35,
          alt.hdrpassthruchar36,
          alt.hdrpassthruchar37,
          alt.hdrpassthruchar38,
          alt.hdrpassthruchar39,
          alt.hdrpassthruchar40,
          alt.hdrpassthrunum01,
          alt.hdrpassthrunum02,
          alt.hdrpassthrunum03,
          alt.hdrpassthrunum04,
          alt.hdrpassthrunum05,
          alt.hdrpassthrunum06,
          alt.hdrpassthrunum07,
          alt.hdrpassthrunum08,
          alt.hdrpassthrunum09,
          alt.hdrpassthrunum10,
          alt.dtlpassthruchar01,
          alt.dtlpassthruchar02,
          alt.dtlpassthruchar03,
          alt.dtlpassthruchar04,
          alt.dtlpassthruchar05,
          alt.dtlpassthruchar06,
          alt.dtlpassthruchar07,
          alt.dtlpassthruchar08,
          alt.dtlpassthruchar09,
          alt.dtlpassthruchar10,
          alt.dtlpassthruchar11,
          alt.dtlpassthruchar12,
          alt.dtlpassthruchar13,
          alt.dtlpassthruchar14,
          alt.dtlpassthruchar15,
          alt.dtlpassthruchar16,
          alt.dtlpassthruchar17,
          alt.dtlpassthruchar18,
          alt.dtlpassthruchar19,
          alt.dtlpassthruchar20,
          alt.dtlpassthrunum01,
          alt.dtlpassthrunum02,
          alt.dtlpassthrunum03,
          alt.dtlpassthrunum04,
          alt.dtlpassthrunum05,
          alt.dtlpassthrunum06,
          alt.dtlpassthrunum07,
          alt.dtlpassthrunum08,
          alt.dtlpassthrunum09,
          alt.dtlpassthrunum10,
          alt.jcpbcstore,
          alt.finaldestzip,
          alt.seq,
          alt.seqof,
          alt.bigseq,
          alt.bigseqof,
          alt.itemweight,
          alt.itemcube,
          alt.storecategory,
          alt.asn_no,
          alt.hazardous,
          alt.wave,
          alt.fromlpid,
          'Y',
          alt.location,
          alt.storecode,
          alt.glncode,
          alt.dunsnumber,
          alt.conspassthruchar01,
          alt.conspassthruchar02,
          alt.conspassthruchar03,
          alt.conspassthruchar04,
          alt.conspassthruchar05,
          alt.conspassthruchar06,
          alt.conspassthruchar07,
          alt.conspassthruchar08,
          alt.conspassthruchar09,
          alt.conspassthruchar10);
   end loop;

   commit;
   out_disposition := 'changes';

end order_labels;


procedure do_labels
   (in_auxdata in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_orderby in varchar2,
    out_stmt   out varchar2)
is
   l_pos number;
   l_obj varchar2(255);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_loadno loads.loadno%type;
   l_wave waves.wave%type;
   l_disposition varchar2(80);
   l_disp varchar2(80);
   l_msg varchar2(80);
begin
   out_stmt := 'Unknown request';

   l_pos := instr(in_auxdata, '|');
   if l_pos != 0 then
      l_obj := upper(substr(in_auxdata, 1, l_pos-1));
      if l_obj = 'ORDER' then
         verify_order(substr(in_auxdata, l_pos+1), in_func, in_action, l_orderid,
               l_shipid, out_stmt);
      elsif l_obj = 'LOAD' then
         verify_load(substr(in_auxdata, l_pos+1), in_func, in_action, l_loadno, out_stmt);
      elsif l_obj = 'WAVE' then
         verify_wave(substr(in_auxdata, l_pos+1), in_func, in_action, l_wave, out_stmt);
      end if;
   end if;

   if out_stmt != 'Continue' then
      return;
   end if;

   if (l_obj = 'ORDER') and (l_shipid != 0) then
      order_labels(l_orderid, l_shipid, in_func, in_action, l_disposition);
      if l_disposition = 'nothing' then
         out_stmt := 'Nothing for order';
      elsif l_disposition = 'okay' then
         out_stmt := 'OKAY';
      elsif l_disposition = 'select' then
         out_stmt := 'select * from weber_case_labels where orderid = ' || l_orderid
               || ' and shipid = ' || l_shipid || ' order by ' || in_orderby;
      elsif l_disposition = 'changes' then
         out_stmt := 'select * from weber_case_labels where orderid = ' || l_orderid
               || ' and shipid = ' || l_shipid
               || ' and nvl(changed,''N'') = ''Y'' order by ' || in_orderby;
      else
         out_stmt := null;
      end if;
      return;
   end if;

   if l_obj = 'LOAD' then
      for oh in (select orderid, shipid from orderhdr
                  where loadno = l_loadno) loop
         if in_action = 'N' then
            verify_order(oh.orderid||'|'||oh.shipid, 'Q', 'P', l_orderid, l_shipid, l_msg);
            if l_msg = 'Nothing for order' then
               order_labels(oh.orderid, oh.shipid, 'X', 'A', l_disp);
            end if;
         else
            order_labels(oh.orderid, oh.shipid, in_func, in_action, l_disp);
         end if;
         if l_disp != 'null' then
            l_disposition := l_disp;
         end if;
         exit when l_disposition = 'okay';
      end loop;
      if l_disposition = 'nothing' then
         out_stmt := 'Nothing for load';
      elsif l_disposition = 'okay' then
         out_stmt := 'OKAY';
      elsif l_disposition = 'select' then
         out_stmt := 'select * from weber_case_labels where loadno = '
               || l_loadno || ' order by ' || in_orderby;
      elsif l_disposition = 'changes' then
         out_stmt := 'select * from weber_case_labels where loadno = '
               || l_loadno || ' and nvl(changed,''N'') = ''Y'' order by ' || in_orderby;
      else
         out_stmt := null;
      end if;
      return;
   end if;

   if (l_obj = 'ORDER') and (l_shipid = 0) then
      l_wave := l_shipid;
   end if;
   for oh in (select orderid, shipid from orderhdr
               where wave = l_wave) loop
      if in_action = 'N' then
         verify_order(oh.orderid||'|'||oh.shipid, 'Q', 'P', l_orderid, l_shipid, l_msg);
         if l_msg = 'Nothing for order' then
            order_labels(oh.orderid, oh.shipid, 'X', 'A', l_disp);
         end if;
      else
         order_labels(oh.orderid, oh.shipid, in_func, in_action, l_disp);
      end if;
      if l_disp != 'null' then
         l_disposition := l_disp;
      end if;
      exit when l_disposition = 'okay';
   end loop;
   if l_disposition = 'nothing' then
      out_stmt := 'Nothing for wave';
   elsif l_disposition = 'okay' then
      out_stmt := 'OKAY';
   elsif l_disposition = 'select' then
      out_stmt := 'select * from weber_case_labels where wave = '
            || l_wave || ' order by ' || in_orderby;
   elsif l_disposition = 'changes' then
      out_stmt := 'select * from weber_case_labels where wave = '
            || l_wave || ' and nvl(changed,''N'') = ''Y'' order by ' || in_orderby;
   else
      out_stmt := null;
   end if;

end do_labels;


-- Public


function lbl_remainder_qty
   (in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2,
    in_qty    in number)
return number
is
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select nvl(labeluom,'CS') as labeluom,
             nvl(treat_labeluom_separate,'N') as treat_labeluom_separate
         from custitem
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype := null;
   l_qty pls_integer := 0;
   l_tmp pls_integer := 0;
begin
   open c_ci(in_custid, in_item);
   fetch c_ci into ci;
   close c_ci;
   l_qty := zlbl.uom_qty_conv(in_custid, in_item, in_qty, in_uom, ci.labeluom);

   if ci.treat_labeluom_separate = 'Y' then
      l_tmp := zlbl.uom_qty_conv(in_custid, in_item, l_qty, ci.labeluom, in_uom);
      if l_tmp != in_qty then
         l_qty := l_qty + (in_qty - zlbl.uom_qty_conv(in_custid, in_item,
               l_qty-1, ci.labeluom, in_uom)) - 1;
      end if;
   end if;

   return l_qty;
exception
   when OTHERS then
      return in_qty;
end lbl_remainder_qty;


procedure lbluom_qtys
   (in_custid     in varchar2,
    in_item       in varchar2,
    in_uom        in varchar2,
    in_qty        in number,
    out_lbluomqty out number,
    out_remqty    out number)
is
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select nvl(labeluom,'CS') as labeluom,
             nvl(treat_labeluom_separate,'N') as treat_labeluom_separate
         from custitem
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype := null;
   l_tmp pls_integer := 0;
begin
   out_lbluomqty := in_qty;
   out_remqty := 0;

   open c_ci(in_custid, in_item);
   fetch c_ci into ci;
   close c_ci;
   out_lbluomqty := zlbl.uom_qty_conv(in_custid, in_item, in_qty, in_uom, ci.labeluom);

   if ci.treat_labeluom_separate = 'Y' then
      l_tmp := zlbl.uom_qty_conv(in_custid, in_item, out_lbluomqty, ci.labeluom, in_uom);
      if l_tmp != in_qty then
         out_lbluomqty := out_lbluomqty - 1;
         out_remqty := in_qty - zlbl.uom_qty_conv(in_custid, in_item, out_lbluomqty,
               ci.labeluom, in_uom);
      end if;
   end if;
end lbluom_qtys;


procedure lbl_ord_itm
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
begin
   do_labels(in_auxdata, in_func, in_action, 'orderid, shipid, item', out_stmt);
end lbl_ord_itm;


procedure lbl_itm_ord
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
begin
   do_labels(in_auxdata, in_func, in_action, 'item, orderid, shipid', out_stmt);
end lbl_itm_ord;


procedure lbl_loc
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
begin
   do_labels(in_auxdata, in_func, in_action, 'location', out_stmt);
end lbl_loc;


end weber_prplbls;
/

show errors package body weber_prplbls;
exit;
