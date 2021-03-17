create or replace package body weber_pltlbls as
--
-- $Id$
--
strDebugYN char(1) := 'N';

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


procedure verify_order
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_orderid   out number,
    out_shipid    out number,
    out_order_cnt out number,
    out_label_cnt out number)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct orderid, shipid
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   l_lpid shippingplate.lpid%type := in_lpid;
begin
   out_orderid := 0;
   out_shipid := 0;
   out_order_cnt := 0;
   out_label_cnt := 0;

   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then
            out_order_cnt := 1;
            out_orderid := inp.orderid;
            out_shipid := inp.shipid;
            fetch c_inf into inp;
            if c_inf%found then  -- orderid/shipid not unique
               out_order_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         out_order_cnt := 1;
         out_orderid := inp.orderid;
         out_shipid := inp.shipid;
      end if;
      close c_inp;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from weber_pallet_labels
         where orderid = inp.orderid
           and shipid = inp.shipid;
   end if;

end verify_order;


procedure verify_load
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_loadno    out number,
    out_load_cnt  out number,
    out_label_cnt out number)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select nvl(loadno, 0) as loadno
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct nvl(loadno, 0) as loadno
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   l_lpid shippingplate.lpid%type := in_lpid;
begin
   out_loadno := 0;
   out_load_cnt := 0;
   out_label_cnt := 0;

   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then
            out_load_cnt := 1;
            out_loadno := inp.loadno;
            fetch c_inf into inp;
            if c_inf%found then  -- orderid/shipid not unique
               out_load_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         out_load_cnt := 1;
         out_loadno := inp.loadno;
      end if;
      close c_inp;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from weber_pallet_labels
         where loadno = inp.loadno;
   end if;

end verify_load;


procedure verify_wave
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_wave      out number,
    out_wave_cnt  out number,
    out_label_cnt out number)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select H.wave
         from shippingplate S, orderhdr H
         where S.lpid = p_lpid
           and H.orderid = S.orderid
           and H.shipid = S.shipid;
   cursor c_inf(p_lpid varchar2) is
      select distinct H.wave
         from shippingplate S, orderhdr H
         where S.fromlpid = p_lpid
           and H.orderid = S.orderid
           and H.shipid = S.shipid;
   inp c_inp%rowtype;
   l_lpid shippingplate.lpid%type := in_lpid;
begin
   out_wave := 0;
   out_wave_cnt := 0;
   out_label_cnt := 0;

   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then
            out_wave_cnt := 1;
            out_wave := inp.wave;
            fetch c_inf into inp;
            if c_inf%found then  -- orderid/shipid not unique
               out_wave_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         out_wave_cnt := 1;
         out_wave := inp.wave;
      end if;
      close c_inp;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from weber_pallet_labels
         where wave = inp.wave;
   end if;

end verify_wave;

procedure debugmsg(in_text varchar2) is

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;


function top_lpid
   (in_lpid in varchar2)
return varchar2
is
   l_lptype plate.type%type := null;
   l_xrefid plate.lpid%type := null;
   l_xreftype plate.type%type := null;
   l_parentid plate.lpid%type := null;
   l_parenttype plate.type%type := null;
   l_topid plate.lpid%type := null;
   l_toptype plate.type%type := null;
   l_msg varchar2(80);
begin
   zrf.identify_lp(in_lpid, l_lptype, l_xrefid, l_xreftype, l_parentid, l_parenttype,
         l_topid, l_toptype, l_msg);
   return nvl(l_topid, nvl(l_parentid, nvl(l_xrefid, in_lpid)));

end top_lpid;


-- Public


procedure ord_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
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
             OD.dtlpassthruchar01 as dtlpassthruchar01,
             OD.dtlpassthruchar02 as dtlpassthruchar02,
             OD.dtlpassthruchar03 as dtlpassthruchar03,
             OD.dtlpassthruchar04 as dtlpassthruchar04,
             OD.dtlpassthruchar05 as dtlpassthruchar05,
             OD.dtlpassthruchar06 as dtlpassthruchar06,
             OD.dtlpassthruchar07 as dtlpassthruchar07,
             OD.dtlpassthruchar08 as dtlpassthruchar08,
             OD.dtlpassthruchar09 as dtlpassthruchar09,
             OD.dtlpassthruchar10 as dtlpassthruchar10,
             OD.dtlpassthruchar11 as dtlpassthruchar11,
             OD.dtlpassthruchar12 as dtlpassthruchar12,
             OD.dtlpassthruchar13 as dtlpassthruchar13,
             OD.dtlpassthruchar14 as dtlpassthruchar14,
             OD.dtlpassthruchar15 as dtlpassthruchar15,
             OD.dtlpassthruchar16 as dtlpassthruchar16,
             OD.dtlpassthruchar17 as dtlpassthruchar17,
             OD.dtlpassthruchar18 as dtlpassthruchar18,
             OD.dtlpassthruchar19 as dtlpassthruchar19,
             OD.dtlpassthruchar20 as dtlpassthruchar20,
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
             substr(nvl(OD.dtlpassthruchar09,CIA.itemalias),1,12) as upc
         from orderdtl OD, custitem CI, custitemalias CIA
         where OD.orderid = p_orderid
           and OD.shipid = p_shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotno, '(none)')
           and CI.custid = OD.custid
           and CI.item = OD.item
           and CIA.custid (+) = OD.custid
           and CIA.item (+) = OD.item
           and CIA.aliasdesc (+) = 'UPC';
   od c_od%rowtype;
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select labeluom
         from custitem
         where custid = p_custid
           and item = p_item;
   cursor c_alt(p_rowid varchar2) is
      select *
         from weber_case_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   l_rowid varchar2(20);

   ci c_ci%rowtype;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_sscc varchar2(20);
   l_qty shippingplate.quantity%type;
   l_item shippingplate.item%type;
   l_cnt pls_integer;
   l_found boolean;
   nSeq number;
   nSeqof number;
   nBigseq number;
   nBigseqof number;
   l_minorderid orderhdr.orderid%type;
   l_match varchar2(1);
   l_asn_no weber_case_labels.asn_no%type;
   mopd char(1);
   rowCnt integer;
   cntPallets integer;
   strMsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);

   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         else
            out_stmt := 'Order not unique';
         end if;
      end if;
      return;
   end if;

   if in_func = 'Q' then
      out_stmt := 'OKAY';
      return;
   end if;
   debugmsg('action func ' || in_action || ' ' || in_func);
   if (in_action != 'P') then
      if in_action != 'C' then
         delete from caselabels
            where orderid = l_orderid
              and shipid = l_shipid;
         delete from weber_pallet_labels
            where orderid = l_orderid
              and shipid = l_shipid;
         begin
            delete from weber_pallet_labels
               where lpid in (select lpid
                              from caselabels
                              where mixedorderorderid = l_orderid
                                and mixedordershipid = l_shipid);
         exception when no_data_found then
            null;
         end;
         begin
            delete from caselabels
               where mixedorderorderid = l_orderid
                and mixedordershipid = l_shipid;
         exception when no_data_found then
            null;
         end;
         commit;
      end if;

      open c_oh(l_orderid, l_shipid);
      fetch c_oh into oh;
      if c_oh%notfound then
         oh := null;
      end if;
      close c_oh;

      select nvl(min(orderid),0) into l_minorderid
         from orderhdr
         where loadno = oh.loadno
           and shipto = oh.shipto;
      l_asn_no := substr(calccheckdigit(nvl(substr(oh.manufacturerucc, 1, 7), '0400000')
            || lpad(l_minorderid, 9, '0')), 1, 17);

      for mp in (select lpid, item, lotnumber, fromlpid
                  from shippingplate
                  where orderid = l_orderid
                    and shipid = l_shipid
                    and status != 'U'
                    and parentlpid is null) loop

         open c_od(l_orderid, l_shipid, mp.item, mp.lotnumber);
         fetch c_od into od;
         l_found := c_od%found;
         close c_od;
         if not l_found then
            open c_od(l_orderid, l_shipid, mp.item, null);
            fetch c_od into od;
            if c_od%notfound then
               od := null;
            end if;
            close c_od;
         end if;

         l_qty := 0;
         for sp in (select item, unitofmeasure, sum(quantity) as quantity
                     from shippingplate
                     where type in ('F','P')
                       and status != 'U'
                     start with lpid = mp.lpid
                     connect by prior lpid = parentlpid
                     group by item, unitofmeasure) loop

            open c_ci(oh.custid, sp.item);
            fetch c_ci into ci;
            if c_ci%found then
               l_qty := l_qty + zlbl.uom_qty_conv(oh.custid, sp.item, sp.quantity,
                     sp.unitofmeasure, ci.labeluom);
            end if;
            close c_ci;
         end loop;

         select count(distinct item) into l_cnt
            from shippingplate
            where status != 'U'
            start with lpid = mp.lpid
            connect by prior lpid = parentlpid;
         if l_cnt > 1 then
            l_item := 'Mixed';
         else
            l_item := mp.item;
         end if;
         select count(1) into nBigseqof
           from shippingplate
           where orderid = l_orderid
             and shipid = l_shipid
             and status != 'U'
             and parentlpid is null;

         select nvl(max(bigseq),0) + 1 into nBigseq
            from weber_pallet_labels
            where orderid = l_orderid
              and shipid = l_shipid;
         select count(1) into nSeqof
           from shippingplate
           where orderid = l_orderid
             and shipid = l_shipid
             and status != 'U'
             and nvl(item, 'Mixed') = l_item
             and parentlpid is null;

         select nvl(max(seq),0) + 1 into nSeq
            from weber_pallet_labels
            where orderid = l_orderid
              and shipid = l_shipid
              and item = l_item;

         if in_action != 'C' then
             l_sscc := zlbl.caselabel_barcode(oh.custid, '1');
             insert into weber_pallet_labels
                (lpid,
                 sscc18,
                 sscc18_formatted,
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
                 wave,
                 seq,
                 seqof,
                 bigseq,
                 bigseqof,
                 asn_no,
                 fromlpid,
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
                (mp.lpid,
                 l_sscc,
                 '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
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
                 l_orderid,
                 l_shipid,
                 l_item,
                 od.descr,
                 nvl(od.consigneesku,l_item),
                 oh.po,
                 oh.reference,
                 oh.loadno,
                 oh.prono,
                 l_orderid||'-'||l_shipid,
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
                 oh.wave,
                 nSeq,
                 nSeqof,
                 nBigseq,
                 nBigseqof,
                 l_asn_no,
                 mp.fromlpid,
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
                (l_orderid,
                 l_shipid,
                 oh.custid,
                 mp.item,
                 mp.lotnumber,
                 mp.lpid,
                 l_sscc,
                 null,
                 null,
                 sysdate,
                 'weber_pallet_labels',
                 'sscc18',
                 l_qty,
                 'PL');
         else
            insert into weber_pallet_labels_temp
               (lpid,
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
                wave,
                seq,
                seqof,
                bigseq,
                bigseqof,
                asn_no,
                fromlpid,
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
               (mp.lpid,
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
                l_orderid,
                l_shipid,
                l_item,
                od.descr,
                nvl(od.consigneesku,l_item),
                oh.po,
                oh.reference,
                oh.loadno,
                oh.prono,
                l_orderid||'-'||l_shipid,
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
                oh.wave,
                nSeq,
                nSeqof,
                nBigseq,
                nBigseqof,
                l_asn_no,
                mp.fromlpid,
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
               (l_orderid,
                l_shipid,
                oh.custid,
                mp.item,
                mp.lotnumber,
                mp.lpid,
                null,
                null,
                l_qty,
                'PL',
                '0',
                l_rowid,
                'N');
         end if;
      end loop;
/*--------------------------------------------------------------------------------------------*/
      select nvl(mixed_order_pallet_dimensions, 'N') into mopd
         from customer_aux
         where custid = oh.custid;
      if mopd = 'Y' then

         for mp in (select lpid, item, lotnumber, fromlpid
                     from shippingplate
                     where orderid = 0
                       and shipid = 0
                       and lpid in (select parentlpid
                                      from shippingplate
                                       where orderid = l_orderid
                                         and shipid = l_shipid
                                         and status != 'U'
                                         and parentlpid is not null)) loop

            select count(1) into cntPallets /* check to see if created by another order */
               from caselabels
               where lpid = mp.lpid;
            if cntPallets = 0 then
               od := null;
               l_qty := 0;
               for sp in (select item, unitofmeasure, sum(quantity) as quantity
                           from shippingplate
                           where type in ('F','P')
                             and status != 'U'
                           start with lpid = mp.lpid
                           connect by prior lpid = parentlpid
                           group by item, unitofmeasure) loop

                  open c_ci(oh.custid, sp.item);
                  fetch c_ci into ci;
                  if c_ci%found then
                     l_qty := l_qty + zlbl.uom_qty_conv(oh.custid, sp.item, sp.quantity,
                           sp.unitofmeasure, ci.labeluom);
                  end if;
                  close c_ci;
               end loop;

               select count(distinct item) into l_cnt
                  from shippingplate
                  where status != 'U'
                  start with lpid = mp.lpid
                  connect by prior lpid = parentlpid;
               if l_cnt > 1 then
                  l_item := 'Mixed';
               else
                  l_item := mp.item;
               end if;
               select count(1) + 1 into nBigseqof
                 from shippingplate
                 where orderid = l_orderid
                   and shipid = l_shipid
                   and status != 'U'
                   and parentlpid is null;

               select nvl(max(bigseq),0) + 1 into nBigseq
                  from weber_pallet_labels
                  where orderid = l_orderid
                    and shipid = l_shipid;
               select count(1) + 1 into nSeqof
                 from shippingplate
                 where orderid = l_orderid
                   and shipid = l_shipid
                   and status != 'U'
                   and nvl(item, 'Mixed') = l_item
                   and parentlpid is null;

               select nvl(max(seq),0) + 1 into nSeq
                  from weber_pallet_labels
                  where orderid = l_orderid
                    and shipid = l_shipid
                    and item = l_item;

               if in_action != 'C' then
                   l_sscc := zlbl.caselabel_barcode(oh.custid, '1');
                   insert into weber_pallet_labels
                      (lpid,
                       sscc18,
                       sscc18_formatted,
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
                       wave,
                       seq,
                       seqof,
                       bigseq,
                       bigseqof,
                       asn_no,
                       fromlpid,
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
                       mixedorderorderid,
                       mixedordershipid)
                   values
                      (mp.lpid,
                       l_sscc,
                       '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
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
                       0,
                       0,
                       l_item,
                       od.descr,
                       nvl(od.consigneesku,l_item),
                       oh.po,
                       oh.reference,
                       oh.loadno,
                       oh.prono,
                       l_orderid||'-'||l_shipid,
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
                       oh.wave,
                       nSeq,
                       nSeqof,
                       nBigseq,
                       nBigseqof,
                       l_asn_no,
                       mp.fromlpid,
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
                       oh.conspassthruchar10,
                       l_orderid,
                       l_shipid);

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
                       labeltype,
                       mixedorderorderid,
                       mixedordershipid)
                   values
                      (0,
                       0,
                       oh.custid,
                       mp.item,
                       mp.lotnumber,
                       mp.lpid,
                       l_sscc,
                       null,
                       null,
                       sysdate,
                       'weber_pallet_labels',
                       'sscc18',
                       l_qty,
                       'PL',
                       l_orderid,
                       l_shipid);
               else
                  insert into weber_pallet_labels_temp
                     (lpid,
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
                      wave,
                      seq,
                      seqof,
                      bigseq,
                      bigseqof,
                      asn_no,
                      fromlpid,
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
                      mixedorderorderid,
                      mixedordershipid)
            values
                     (mp.lpid,
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
                      0,
                      0,
                      l_item,
                      od.descr,
                      nvl(od.consigneesku,l_item),
                      oh.po,
                      oh.reference,
                      oh.loadno,
                      oh.prono,
                      l_orderid||'-'||l_shipid,
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
                      oh.wave,
                      nSeq,
                      nSeqof,
                      nBigseq,
                      nBigseqof,
                      l_asn_no,
                      mp.fromlpid,
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
                      oh.conspassthruchar10,
                      l_orderid,
                l_shipid)
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
                      matched,
                      mixedorderorderid,
                      mixedordershipid)
                  values
                     (0,
                      0,
                      oh.custid,
                mp.item,
                mp.lotnumber,
                mp.lpid,
                null,
                null,
                l_qty,
                'PL',
                '0',
                l_rowid,
                'N',
                      l_orderid,
                      l_shipid);
               end if;
         end if;
      end loop; /* for mp in */
      end if;

/*--------------------------------------------------------------------------------------------*/
      if in_action != 'C' then
         commit;
      end if;
   end if;
   if in_action != 'C' then
      out_stmt := 'select A.bigseq bso, A.* from weber_pallet_labels A where orderid = ' || l_orderid
            || ' and shipid = ' || l_shipid || ' union '
            || ' select B.bigseq bso, B.* from weber_pallet_labels B where mixedorderorderid = ' || l_orderid
            || ' and mixedordershipid = ' || l_shipid
            || ' order by bso';
      return;
   end if;
   select count(1) into rowcnt from caselabels
      where orderid = l_orderid
        and shipid = l_shipid;
   debugmsg('caselabels count ' || rowcnt);

   if in_func = 'Q' then
--    match caselabels with temp ignoring barcode
      for lbl in (select * from caselabels
                     where orderid = l_orderid
                       and shipid = l_shipid) loop

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
            out_stmt := 'OKAY';
            exit;
         end if;
      end loop;

--    each caselabel is also in temp, check for extras in temp
      if out_stmt is null then
         select count(1) into l_label_cnt
            from caselabels_temp
            where matched = 'N';
         if l_label_cnt > 0 then
            out_stmt := 'OKAY';
         end if;
      end if;

      if out_stmt is null then
         out_stmt := 'Nothing for order';
      end if;

      delete caselabels_temp;
      delete weber_case_labels_temp;
      return;
   end if;

-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = l_orderid
                    and shipid = l_shipid) loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         debugmsg('1' || tmp.orderid || ' <> ' ||lbl.orderid);
         debugmsg('2' || tmp.shipid || ' <> ' ||lbl.shipid);
         debugmsg('3' || tmp.custid || ' <> ' ||lbl.custid);
         debugmsg('4' || tmp.item || ' <> ' ||lbl.item);
         debugmsg('5' || tmp.lotnumber || ' <> ' ||lbl.lotnumber);
         debugmsg('6' || tmp.lpid || ' <> ' ||lbl.lpid);
         debugmsg('7' || tmp.seq || ' <> ' ||lbl.seq);
         debugmsg('8' || tmp.seqof || ' <> ' ||lbl.seqof);
         debugmsg('9' || tmp.quantity || ' <> ' ||lbl.quantity);
         debugmsg('0' || tmp.labeltype || ' <> ' ||lbl.labeltype);

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
      where orderid = l_orderid
        and shipid = l_shipid
        and sscc18 in (select barcode from caselabels
                     where orderid = l_orderid
                       and shipid = l_shipid
                       and matched = 'N');
   delete caselabels
      where orderid = l_orderid
        and shipid = l_shipid
        and matched = 'N';

-- add new data
   update weber_case_labels
      set changed = 'N'
      where orderid = l_orderid
        and shipid = l_shipid;
   select count(1) into rowcnt from caselabels_temp;
   debugmsg('count ' || rowcnt);
   for tmp in (select * from caselabels_temp
                  where matched = 'N') loop

      l_sscc := zlbl.caselabel_barcode(tmp.custid, '1');
      debugmsg(tmp.custid || ' ' || tmp.barcodetype || ' ' || l_sscc);
      debugmsg('cl o ' || tmp.orderid || ' s ' || tmp.shipid || ' c ' || tmp.custid ||
               ' l ' || tmp.lotnumber || ' p ' || tmp.lpid  || ' s ' || l_sscc ||
               ' q ' || tmp.seq || ' o ' || tmp.seqof || ' q ' || tmp.quantity);
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
          'weber_pallet_labels',
          'sscc18',
          tmp.quantity,
          'PL');

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;
      debugmsg('wcl');
      insert into weber_pallet_labels
         (lpid,
          sscc18,
          sscc18_formatted,
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
          wave,
          seq,
          seqof,
          bigseq,
          bigseqof,
          asn_no,
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
          conspassthruchar10)
      values
         (alt.lpid,
          l_sscc,
          '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
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
          alt.wave,
          alt.seq,
          alt.seqof,
          alt.bigseq,
          alt.bigseqof,
          alt.asn_no,
          alt.fromlpid,
          'Y',
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
   out_stmt := 'select A.bigseq bso, A.* from weber_pallet_labels A where orderid = ' || l_orderid
         || ' and shipid = ' || l_shipid || ' union '
         || ' select B.bigseq bso, B.* from weber_pallet_labels B where mixedorderorderid = ' || l_orderid
         || ' and mixedordershipid = ' || l_shipid
         || ' order by bso';

end ord_lbl;


procedure lod_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   cursor c_sp(p_orderid number, p_shipid number) is
      select lpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and status != 'U'
           and parentlpid is null;
   cursor c_sp_mixedorder(p_orderid number, p_shipid number) is
      select lpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and status != 'U'
           and parentlpid is not null;
   sp c_sp%rowtype;
   spfound boolean;
   l_loadno orderhdr.loadno%type;
   l_load_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_mixed_cnt pls_integer := 0;
   l_msg varchar2(1024);
   mopd char(1);
begin
   out_stmt := null;

   verify_load(in_lpid, in_func, in_action, l_loadno, l_load_cnt, l_label_cnt);

   if l_load_cnt != 1 then
      if in_func = 'Q' then
         if l_load_cnt = 0 then
            out_stmt := 'Load not found';
         else
            out_stmt := 'Load not unique';
         end if;
      end if;
      return;
   end if;

   if l_loadno = 0 then
      if in_func = 'Q' then
         out_stmt := 'No load assigned';
      end if;
      return;
    end if;

   if in_func = 'Q' then
      if (in_action = 'P') and (l_label_cnt = 0) then
         out_stmt := 'Nothing for load';
         return;
      end if;

      out_stmt := 'NoWay';
      for oh in (select orderid, shipid, custid from orderhdr
                     where loadno = l_loadno) loop
         select nvl(mixed_order_pallet_dimensions, 'N') into mopd
            from customer_aux
            where custid = oh.custid;

         open c_sp(oh.orderid, oh.shipid);
         fetch c_sp into sp;
         spfound := c_sp%found;
         close c_sp;
         if spfound then
            ord_lbl(sp.lpid, in_func, in_action, l_msg);
            if l_msg = 'OKAY' then
               out_stmt := l_msg;
               exit;
            end if;
         else
            if mopd = 'Y' then
               open c_sp_mixedorder(oh.orderid, oh.shipid);
               fetch c_sp into sp;
               spfound := c_sp_mixedorder%found;
               close c_sp_mixedorder;
         if spfound then
            ord_lbl(sp.lpid, in_func, in_action, l_msg);
            if l_msg = 'OKAY' then
               out_stmt := l_msg;
               exit;
                  end if;
         end if;
         end if;
      end if;
      end loop;
      return;
   end if;

   if in_action != 'P' then
      for oh in (select orderid, shipid, custid from orderhdr
                  where loadno = l_loadno
                  order by orderid, shipid) loop

         select nvl(mixed_order_pallet_dimensions, 'N') into mopd
            from customer_aux
            where custid = oh.custid;

         open c_sp(oh.orderid, oh.shipid);
         fetch c_sp into sp;
         spfound := c_sp%found;
         close c_sp;
         if spfound then
            if in_action = 'N' then
               select count(1) into l_cnt
                  from weber_pallet_labels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
               select count(1) into l_mixed_cnt
                  from weber_pallet_labels
                  where mixedorderorderid = oh.orderid
                    and mixedordershipid = oh.shipid;
               l_cnt := l_cnt + l_mixed_cnt;
            else
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl(sp.lpid, in_func, in_action, l_msg);
            end if;
         else
            if mopd = 'Y' then
               open c_sp_mixedorder(oh.orderid, oh.shipid);
               fetch c_sp_mixedorder into sp;
               spfound := c_sp_mixedorder%found;
               close c_sp_mixedorder;
         if spfound then
            if in_action = 'N' then
               select count(1) into l_cnt
                  from weber_pallet_labels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
                     select count(1) into l_mixed_cnt
                        from weber_pallet_labels
                        where mixedorderorderid = oh.orderid
                          and mixedordershipid = oh.shipid;
                     l_cnt := l_cnt + l_mixed_cnt;
            else
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl(sp.lpid, in_func, in_action, l_msg);
            end if;
         end if;
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from weber_pallet_labels where loadno = ' || l_loadno
         || ' order by orderid, shipid, bigseq';

end lod_lbl;


procedure wav_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   cursor c_sp(p_orderid number, p_shipid number) is
      select lpid
        from shippingplate
        where orderid = p_orderid
          and shipid = p_shipid
          and status != 'U'
          and parentlpid is null;
   sp c_sp%rowtype;
   spfound boolean;
   l_wave orderhdr.wave%type;
   l_wave_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
begin
   out_stmt := null;

   verify_wave(in_lpid, in_func, in_action, l_wave, l_wave_cnt, l_label_cnt);

   if l_wave_cnt != 1 then
      if in_func = 'Q' then
         if l_wave_cnt = 0 then
            out_stmt := 'Wave not found';
         else
            out_stmt := 'Wave not unique';
         end if;
      end if;
      return;
   end if;

   if l_wave = 0 then
      if in_func = 'Q' then
         out_stmt := 'No wave assigned';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      if (in_action = 'P') and (l_label_cnt = 0) then
         out_stmt := 'Nothing for wave';
         return;
      end if;

      out_stmt := 'NoWay';
      for oh in (select orderid, shipid from orderhdr
                     where wave = l_wave) loop
         open c_sp(oh.orderid, oh.shipid);
         fetch c_sp into sp;
         spfound := c_sp%found;
         close c_sp;
         if spfound then
            ord_lbl(sp.lpid, in_func, in_action, l_msg);
            if l_msg = 'OKAY' then
               out_stmt := l_msg;
               exit;
            end if;
         end if;
      end loop;
      return;
   end if;

   if in_action != 'P' then
      for oh in (select orderid, shipid from orderhdr
                     where wave = l_wave
                     order by orderid, shipid) loop
         open c_sp(oh.orderid, oh.shipid);
         fetch c_sp into sp;
         spfound := c_sp%found;
         close c_sp;
         if spfound then
            if in_action = 'N' then
               select count(1) into l_cnt
                  from weber_pallet_labels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
            else
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl(sp.lpid, in_func, in_action, l_msg);
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from weber_pallet_labels where wave = ' || l_wave
         || ' order by orderid, shipid, bigseq';

end wav_lbl;


procedure lpid_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_termid in varchar2,          -- Terminal ID
    out_stmt  out varchar2)
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
             OD.dtlpassthruchar01 as dtlpassthruchar01,
             OD.dtlpassthruchar02 as dtlpassthruchar02,
             OD.dtlpassthruchar03 as dtlpassthruchar03,
             OD.dtlpassthruchar04 as dtlpassthruchar04,
             OD.dtlpassthruchar05 as dtlpassthruchar05,
             OD.dtlpassthruchar06 as dtlpassthruchar06,
             OD.dtlpassthruchar07 as dtlpassthruchar07,
             OD.dtlpassthruchar08 as dtlpassthruchar08,
             OD.dtlpassthruchar09 as dtlpassthruchar09,
             OD.dtlpassthruchar10 as dtlpassthruchar10,
             OD.dtlpassthruchar11 as dtlpassthruchar11,
             OD.dtlpassthruchar12 as dtlpassthruchar12,
             OD.dtlpassthruchar13 as dtlpassthruchar13,
             OD.dtlpassthruchar14 as dtlpassthruchar14,
             OD.dtlpassthruchar15 as dtlpassthruchar15,
             OD.dtlpassthruchar16 as dtlpassthruchar16,
             OD.dtlpassthruchar17 as dtlpassthruchar17,
             OD.dtlpassthruchar18 as dtlpassthruchar18,
             OD.dtlpassthruchar19 as dtlpassthruchar19,
             OD.dtlpassthruchar20 as dtlpassthruchar20,
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
             substr(nvl(OD.dtlpassthruchar09,CIA.itemalias),1,12) as upc
         from orderdtl OD, custitem CI, custitemalias CIA
         where OD.orderid = p_orderid
           and OD.shipid = p_shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotno, '(none)')
           and CI.custid = OD.custid
           and CI.item = OD.item
           and CIA.custid (+) = OD.custid
           and CIA.item (+) = OD.item
           and CIA.aliasdesc (+) = 'UPC';
   od c_od%rowtype;
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select labeluom
         from custitem
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype;
   cursor c_mp(p_lpid varchar2) is
      select item, lotnumber, fromlpid
         from shippingplate
         where lpid = p_lpid;
   mp c_mp%rowtype := null;

   l_lpid shippingplate.lpid%type;
   l_cnt pls_integer;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_minorderid orderhdr.orderid%type;
   l_asn_no weber_pallet_labels.asn_no%type;
   l_qty shippingplate.quantity%type;
   l_sscc varchar2(20);
   l_item shippingplate.item%type;
   l_found boolean;
   nSeq number;
   nSeqof number;
   nBigseq number;
   nBigseqof number;
   errmsg varchar2(255);

begin
   out_stmt := null;

   if in_action not in ('A','P') then
      if in_func = 'Q' then
         out_stmt := 'Unsupported Action';
      end if;
      return;
   end if;

   l_lpid := top_lpid(in_lpid);

-- use any existing labels regardless of the in_action
   select count(1) into l_cnt
      from weber_pallet_labels
      where lpid = l_lpid;

   if l_cnt > 0 then
      if in_func = 'Q' then
         out_stmt := 'OKAY';
      else
         out_stmt := 'select * from weber_pallet_labels where lpid = ''' || l_lpid
               || ''' order by orderid, shipid, bigseq';
      end if;
      return;
   end if;

   verify_order(l_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);
   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         else
            out_stmt := 'Order not unique';
         end if;
      end if;
      return;
   end if;

   if in_func = 'Q' then
      out_stmt := 'OKAY';
      return;
   end if;

   if (in_action != 'P') then
      open c_oh(l_orderid, l_shipid);
      fetch c_oh into oh;
      if c_oh%notfound then
         oh := null;
      end if;
      close c_oh;

      select nvl(min(orderid),0) into l_minorderid
         from orderhdr
         where loadno = oh.loadno
           and shipto = oh.shipto;
      l_asn_no := substr(calccheckdigit(nvl(substr(oh.manufacturerucc, 1, 7), '0400000')
            || lpad(l_minorderid, 9, '0')), 1, 17);

      open c_mp(l_lpid);
      fetch c_mp into mp;
      close c_mp;

      open c_od(l_orderid, l_shipid, mp.item, mp.lotnumber);
      fetch c_od into od;
      l_found := c_od%found;
      close c_od;
      if not l_found then
         open c_od(l_orderid, l_shipid, mp.item, null);
         fetch c_od into od;
         if c_od%notfound then
            od := null;
         end if;
         close c_od;
      end if;

      l_qty := 0;
      for sp in (select item, unitofmeasure, sum(quantity) as quantity
                  from shippingplate
                  where type in ('F','P')
                    and status != 'U'
                  start with lpid = l_lpid
                  connect by prior lpid = parentlpid
                  group by item, unitofmeasure) loop

         open c_ci(oh.custid, sp.item);
         fetch c_ci into ci;
         if c_ci%found then
            l_qty := l_qty + zlbl.uom_qty_conv(oh.custid, sp.item, sp.quantity,
                  sp.unitofmeasure, ci.labeluom);
         end if;
         close c_ci;
      end loop;

      select count(distinct item) into l_cnt
         from shippingplate
         where status != 'U'
         start with lpid = l_lpid
         connect by prior lpid = parentlpid;
      if l_cnt > 1 then
         l_item := 'Mixed';
      else
         l_item := mp.item;
      end if;

      select count(1) into nBigseqof
        from shippingplate
        where orderid = l_orderid
          and shipid = l_shipid
          and status != 'U'
          and parentlpid is null;

      select nvl(max(bigseq),0) + 1 into nBigseq
         from weber_pallet_labels
         where orderid = l_orderid
           and shipid = l_shipid;

      select count(1) into nSeqof
        from shippingplate
        where orderid = l_orderid
          and shipid = l_shipid
          and status != 'U'
          and nvl(item, 'Mixed') = l_item
          and parentlpid is null;

      select nvl(max(seq),0) + 1 into nSeq
         from weber_pallet_labels
         where orderid = l_orderid
           and shipid = l_shipid
           and item = l_item;

      l_sscc := zlbl.caselabel_barcode(oh.custid, '1');
      insert into weber_pallet_labels
         (lpid,
          sscc18,
          sscc18_formatted,
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
          wave,
          seq,
          seqof,
          bigseq,
          bigseqof,
          asn_no,
          fromlpid,
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
         (l_lpid,
          l_sscc,
          '('||substr(l_sscc,1,2)||')'||substr(l_sscc,3,20),
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
          l_orderid,
          l_shipid,
          l_item,
          od.descr,
          nvl(od.consigneesku,l_item),
          oh.po,
          oh.reference,
          oh.loadno,
          oh.prono,
          l_orderid||'-'||l_shipid,
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
          oh.wave,
          nSeq,
          nSeqof,
          nBigseq,
          nBigseqof,
          l_asn_no,
          mp.fromlpid,
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
         (l_orderid,
          l_shipid,
          oh.custid,
          mp.item,
          mp.lotnumber,
          l_lpid,
          l_sscc,
          null,
          null,
          sysdate,
          'weber_pallet_labels',
          'sscc18',
          l_qty,
          'PL');
      commit;
   end if;

-- Check for label load processing
   zlod.check_plate_load(in_lpid, in_termid, 'LABELLD', errmsg);
   commit;

   out_stmt := 'select * from weber_pallet_labels where lpid = ''' || l_lpid
         || ''' order by orderid, shipid, bigseq';

end lpid_lbl;


end weber_pltlbls;
/

show errors package body weber_pltlbls;
exit;
