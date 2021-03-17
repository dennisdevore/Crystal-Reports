create or replace package body zenith_caslbls as
--
-- $Id: zenith_case_labels_body.sql 2794 2008-06-27 15:25:04Z ed $
--
strDebugYN char(1) := 'N';

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

function get_eanjan13(in_orderid number, in_shipid number, in_item varchar2)
return varchar2
is
   ret_val varchar2(255);
   cnt integer;
   cc integer;
   ix integer;
   l_eanjan13 varchar2(255);
   cursor c_ean(in_orderid number, in_shipid number, in_item varchar2, in_eanjan13 varchar2) is
      select sn
         from orderdtlsn
        where orderid = in_orderid
          and shipid = in_shipid
          and item = in_item
          and sn > nvl(in_eanjan13, ' ')
      order by sn;

begin
   debugmsg('get eanjan 13');
   ret_val := null;
   select count(1) into cnt
      from zenith_case_labels
                          where orderid = in_orderid
                            and shipid = in_shipid
                            and item = in_item
        and labeltype = 'EN';
   debugmsg('cnt ' || cnt);
   if cnt > 0 then
      select max(eanjan13) into l_eanjan13
        from zenith_case_labels
      where orderid = in_orderid
        and shipid = in_shipid
        and item = in_item
        and labeltype = 'EN';
      debugmsg('max ' || l_eanjan13);
   else
      debugmsg('null');
      l_eanjan13 := null;
   end if;
   open c_ean(in_orderid, in_shipid, in_item, l_eanjan13);
   fetch c_ean into ret_val;
   close c_ean;

   cc := 0;
   for cnt in 1..12 loop
      ix := substr(ret_val, cnt, 1);

      if mod(cnt, 2) = 0 then
         cc := cc + (3 * ix);
      else
         cc := cc + ix;
      end if;
   end loop;

   cc := mod(10 - mod(cc, 10), 10);
   ret_val := ret_val || to_char(cc);

   debugmsg('ret ' || ret_val);
   return ret_val;
exception
   when OTHERS then
      return null;
end get_eanjan13;


procedure verify_order
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    in_eanjan13   in varchar2,
    out_orderid   out number,
    out_shipid    out number,
    out_order_cnt out number,
    out_label_cnt out number,
    out_cons_order out boolean,
    out_useritem1fromasn out varchar2)
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
   l_wave orderhdr.wave%type;
   l_cnt integer;
   l_useritem1fromasn customer_aux.useritem1fromasn%type;
begin
   out_orderid := 0;
   out_shipid := 0;
   out_order_cnt := 0;
   out_label_cnt := 0;
   out_cons_order := FALSE;
   out_useritem1fromasn := 'N';

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
   if in_eanjan13 = 'Y'  then
      select count(1) into l_cnt
         from orderhdr
         where orderid = out_orderid
           and shipid = out_shipid
           and upper(hdrpassthruchar07) = 'LABEL01';
      if l_cnt < 1 then
         out_order_cnt := -1;
      end if;
   else
 --     select count(1) into l_cnt
 --         from orderhdr
 --        where orderid = out_orderid
 --          and shipid = out_shipid
 --          and upper(hdrpassthruchar07) != 'LABEL01';
 --     if l_cnt < 1 then
 --        out_order_cnt := -1;
 --     end if;
      out_order_cnt := 1;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from caselabels
         where orderid = inp.orderid
           and shipid = inp.shipid;
   end if;
   l_wave := zconsorder.cons_orderid(out_orderid, out_shipid);
   if l_wave != 0 then
      out_cons_order := TRUE;
      l_useritem1fromasn := 'N';
   else
      begin
         select nvl(useritem1fromasn,'N') into l_useritem1fromasn
            from customer_aux
            where custid = (select custid from orderhdr
                             where orderid = out_orderid
                               and shipid = out_shipid);
      exception when no_data_found then
         l_useritem1fromasn := 'N';
      end;
   end if;
   out_useritem1fromasn := l_useritem1fromasn;
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
   c1 number;
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
         from caselabels cl, orderhdr oh
         where oh.loadno = inp.loadno
           and oh.orderid = cl.orderid
           and oh.shipid = cl.shipid;
   end if;

end verify_load;


procedure verify_wave
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_wave      out number,
    out_wave_cnt  out number,
    out_label_cnt out number,
    out_cons_order out boolean)
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
   cursor o_lp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   olp o_lp%rowtype;

begin
   out_wave := 0;
   out_wave_cnt := 0;
   out_label_cnt := 0;
   out_cons_order := FALSE;

   if substr(l_lpid, -1, 1) != 'S' then
      debugmsg('!= S');
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
      debugmsg('= S');
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         debugmsg('c_inp%found');
         out_wave_cnt := 1;
         out_wave := inp.wave;
         open o_lp(l_lpid);
         fetch o_lp into olp;
         if o_lp%found then
            out_wave := zconsorder.cons_orderid(olp.orderid, olp.shipid);
            if out_wave != 0 then
               out_cons_order := TRUE;
            end if;
         end if;
      else -- check for consolidated order
         open o_lp(l_lpid);
         fetch o_lp into olp;
         if o_lp%found then
            out_wave := zconsorder.cons_orderid(olp.orderid, olp.shipid);
            if out_wave = 0 then
               out_wave_cnt := 0;
            else
               out_wave_cnt := 1;
               out_cons_order := TRUE;
            end if;
         else
            out_wave_cnt := 0;
            out_wave := 0;
         end if;
         close o_lp;
      end if;
      close c_inp;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from caselabels cl, orderhdr oh
         where oh.wave = inp.wave
           and oh.orderid = cl.orderid
           and oh.shipid = cl.shipid;
   end if;

end verify_wave;

procedure ord_lbl_common
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_lot    in varchar2,
    in_eanjan13 in varchar2,
    out_stmt  in out varchar2)
is
-- PRN 5551. Add new fields to the Zenith Label.
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.custid as custid,
             decode(OH.shiptoname, null, CN.name, OH.shiptoname) as shiptoname,
             decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1) as shiptoaddr1,
             decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2) as shiptoaddr2,
             decode(OH.shiptoname, null, CN.city, OH.shiptocity) as shiptocity,
             decode(OH.shiptoname, null, CN.state, OH.shiptostate) as shiptostate,
             decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode) as shiptopostalcode,
             decode(OH.shiptofax, null, CN.fax, OH.shiptofax) as shiptofax,
             OH.shipdate as shipdate,
             OH.po as po,
             OH.reference as reference,
             OH.loadno as loadno,
             OH.stopno as stopno,
             OH.shipto as shipto,
             OH.wave as wave,
             OH.comment1 as comment1,
             OH.stageloc as ordstageloc,
             FA.name as fa_name,
             FA.addr1 as fa_addr1,
             FA.addr2 as fa_addr2,
             FA.city as fa_city,
             FA.state as fa_state,
             FA.postalcode as fa_postalcode,
             LD.prono as prono,
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
             LD.stageloc as stageloc,
             OH.hdrpassthruchar01 as hdrpassthruchar01,
             OH.hdrpassthruchar02 as hdrpassthruchar02,
             OH.hdrpassthruchar03 as hdrpassthruchar03,
             OH.hdrpassthruchar04 as hdrpassthruchar04,
             OH.hdrpassthruchar05 as hdrpassthruchar05,
             OH.hdrpassthruchar06 as hdrpassthruchar06,
             OH.hdrpassthruchar07 as hdrpassthruchar07,
             OH.hdrpassthruchar08 as hdrpassthruchar08,
             OH.hdrpassthruchar09 as hdrpassthruchar09,
             OH.hdrpassthruchar10 as hdrpassthruchar10,
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
             OH.billtoname as billtoname,
             OH.billtocontact as billtocontact,
             OH.billtoaddr1 as billtoaddr1,
             OH.billtoaddr2 as billtoaddr2,
             OH.billtocity as billtocity,
             OH.billtostate as billtostate,
             OH.billtopostalcode as billtopostalcode,
             OH.billtocountrycode as billtocountrycode,
             OH.billtophone as billtophone,
             OH.billtofax as billtofax,
             OH.billtoemail as billtoemail,
             CU.contact as contact
         from orderhdr OH, facility FA, loads LD, carrier CA,
              consignee CN, customer CU
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
             rtrim(CI.descr) as descr,
             rtrim(CI.abbrev) as abbrev,
             nvl(CI.labeluom, 'CS') as labeluom,
             substr(CIA.itemalias,1,12) as upc,
             CC.abbrev as countryofabbrev,
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
          CI.itmpassthruchar01 as itmpassthruchar01
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
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select labeluom
         from custitem
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype;

   cursor c_cia(p_custid varchar2, p_item varchar2) is
      select itemalias
         from custitemalias
         where custid = p_custid
           and item = p_item;
   cia c_cia%rowtype;

   cursor c_cust(p_custid varchar2) is
      select sscc_extension_digit
         from customer_aux
         where custid = p_custid;
   cu c_cust%rowtype;

   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_sscc varchar2(20);
   l_qty shippingplate.quantity%type;
   l_seq pls_integer;
   l_seqof pls_integer;
   l_bigseq pls_integer;
   l_bigseqof pls_integer;
   l_match varchar2(1);
   l_rowid varchar2(20);
   l_cons_order boolean;
   l_itemalias varchar2(20);
   l_eanjan13 varchar2(255);
   c1 number;
   rowCnt integer;
   l_useritem1fromasn customer_aux.useritem1fromasn%type;

begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, in_eanjan13, l_orderid, l_shipid, l_order_cnt, l_label_cnt, l_cons_order, l_useritem1fromasn);
   debugmsg(in_lpid || ' ' || l_orderid || ' ' || l_shipid);
   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         elsif l_order_cnt = -1 then
            out_stmt := 'Nothing for order';
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
      if in_action != 'C' then
         if in_eanjan13 = 'Y' then
            delete from zenith_case_labels
               where lpid = in_lpid
                 and labeltype != 'CS';
         else
            delete from caselabels
            where lpid = in_lpid
              and labeltype = 'CS';
         delete from zenith_case_labels
            where lpid = in_lpid
                 and labeltype = 'CS';
         end if;
         commit;
      end if;

      open c_oh(l_orderid, l_shipid);
      fetch c_oh into oh;
      if c_oh%notfound then
         oh := null;
      end if;
      close c_oh;
      open c_cust(oh.custid);
      fetch c_cust into cu;
      if c_cust%notfound then
         cu := null;
      end if;
      close c_cust;


      l_bigseq := 0;
      l_bigseqof := 0;


      if l_cons_order then
         for sp in (select SP.lpid, SP.custid, SP.item, SP.unitofmeasure,
                    SP.orderlot, sum(SP.quantity) as quantity,
                    nvl(CI.labeluom,'CS') as labeluom
                     from shippingplate SP, custitem CI
                     where orderid = l_orderid
                       and shipid = l_shipid
                       and SP.type in ('F','P')
                       and CI.custid = SP.custid
                       and CI.item = SP.item
                     group by SP.lpid, SP.custid, SP.item, SP.unitofmeasure, SP.orderlot,
                              labeluom) loop
            l_bigseqof := l_bigseqof
                  + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                       sp.unitofmeasure,sp.labeluom);
         end loop;
      else
         for mp in (select lpid
                     from shippingplate
                     where orderid = l_orderid
                       and shipid = l_shipid
                       and status != 'U'
                       and parentlpid is null) loop

            for sp in (select SP.custid, SP.item, SP.unitofmeasure,
                       SP.orderlot, sum(SP.quantity) as quantity,
                       nvl(CI.labeluom,'CS') as labeluom
                        from shippingplate SP, custitem CI
                        where SP.type in ('F','P')
                          and SP.status != 'U'
                          and SP.lpid in (select lpid from shippingplate
                                          start with lpid = mp.lpid
                                          connect by prior lpid = parentlpid)
                          and CI.custid = SP.custid
                          and CI.item = SP.item
                        group by SP.custid, SP.item, SP.unitofmeasure,
                                 SP.orderlot, labeluom) loop

               l_bigseqof := l_bigseqof
                     + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                          sp.unitofmeasure,sp.labeluom);
            end loop;
         end loop;
      end if;
      if l_cons_order then
         for sp in (select distinct s.lpid, s.custid, s.orderid, s.shipid,
                    s.item, s.unitofmeasure, s.lotnumber,
                     s.quantity,  s.fromlpid, s.parentlpid, s.orderlot
               from shippingplate s
               where s.orderid = l_orderid
                 and s.shipid = l_shipid
                 and s.type in ('F','P')
               order by s.item, s.lotnumber, s.lpid) loop

            open c_od(l_orderid, l_shipid, sp.item, sp.orderlot);
            fetch c_od into od;
            if c_od%notfound then
               od := null;
            end if;
            close c_od;

            l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, od.labeluom,
                        sp.unitofmeasure);
            if l_qty = 0 then
               l_qty := sp.quantity;
            end if;
            l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                        sp.unitofmeasure,
                  od.labeluom);
            if l_seqof = 0 then
               l_seqof := 1;
            end if;
            for l_seq in 1..l_seqof loop
               if in_action != 'C' then
                  l_bigseq := l_bigseq + 1;
                  if nvl(cu.sscc_extension_digit, '0') = '0' then
                    l_sscc := zlbl.caselabel_barcode(oh.custid, '0');
                  else
                    l_sscc := zlbl.caselabel_barcode(oh.custid, cu.sscc_extension_digit);
                  end if;
                  l_itemalias := null;
                  open c_cia(OH.custid, sp.item);
                  fetch c_cia into l_itemalias;
                  close c_cia;
                  if in_eanjan13 = 'Y' then
                     l_eanjan13 := get_eanjan13(l_orderid,l_shipid,sp.item);
                  else
                     l_eanjan13 := null;
                  end if;
                  begin
                  insert into zenith_case_labels
                     (lpid,
                      sscc18,
                      shiptoname,
                      shiptoaddr1,
                      shiptoaddr2,
                      shiptocity,
                      shiptostate,
                      shiptopstlcd,
                      shiptofax,
                      barpstlcd,
                      label_dat,
                      orderid,
                      shipid,
                      item,
                      descr,
                      wmit,
                      po,
                      reference,
                      loadno,
                      custname,
                      whsename,
                      whseaddr1,
                      whseaddr2,
                      whsecity,
                      whsestate,
                      whsepstlcd,
                      seq,
                      seqof,
                      comment1,
                      wave,
                      stageloc,
                      changed,
                      hdrchar01,
                      hdrchar02,
                      hdrchar03,
                      hdrchar04,
                      hdrchar05,
                      hdrchar06,
                      hdrchar07,
                      hdrchar08,
                      hdrchar09,
                      hdrchar10,
                      hdrnum01,
                      hdrnum02,
                      hdrnum03,
                      hdrnum04,
                      hdrnum05,
                      hdrnum06,
                      hdrnum07,
                      hdrnum08,
                      hdrnum09,
                      hdrnum10,
                      dtlchar01,
                      dtlchar02,
                      dtlchar03,
                      dtlchar04,
                      dtlchar05,
                      dtlchar06,
                      dtlchar07,
                      dtlchar08,
                      dtlchar09,
                      dtlchar10,
                      dtlnum01,
                      dtlnum02,
                      dtlnum03,
                      dtlnum04,
                      dtlnum05,
                      dtlnum06,
                      dtlnum07,
                      dtlnum08,
                      dtlnum09,
                      dtlnum10,
                      itmchar01,
                      carriername,
                      carrierscac,
                      poitem,
                      poitembar,
                      postalbc,
                      storebc,
                      jcpsscc18,
                      jcpsscct1,
                      jcpsscct2,
                      stopno,
                      itemalias,
                      macys128,
                      labeltype,
                      eanjan13,
                      ordstageloc,
                      billtoname,
                      billtocontact,
                      billtoaddr1,
                      billtoaddr2,
                      billtocity,
                      billtostate,
                      billtopostalcode,
                      billtocountrycode,
                      billtophone,
                      billtofax,
                      billtoemail,
                      quantity,
                      useritem1,
                      contact)
                  values
                     (sp.lpid,
                      l_sscc,
                      oh.shiptoname,
                      oh.shiptoaddr1,
                      oh.shiptoaddr2,
                      oh.shiptocity,
                      oh.shiptostate,
                      oh.shiptopostalcode,
                      oh.shiptofax,
                      oh.shiptopostalcode,
                      to_char(sysdate, 'MM/DD/YY'),
                      l_orderid,
                      l_shipid,
                      sp.item,
                      od.descr,
                      nvl(od.consigneesku,sp.item),
                      oh.po,
                      oh.reference,
                      oh.loadno,
                      oh.cu_name,
                      oh.fa_name,
                      oh.fa_addr1,
                      oh.fa_addr2,
                      oh.fa_city,
                      oh.fa_state,
                      oh.fa_postalcode,
                      l_seq,
                      l_seqof,
                      substr(oh.comment1,1,40),
                      oh.wave,
                      oh.stageloc,
                      null,
                      OH.hdrpassthruchar01,
                      OH.hdrpassthruchar02,
                      OH.hdrpassthruchar03,
                      OH.hdrpassthruchar04,
                      OH.hdrpassthruchar05,
                      OH.hdrpassthruchar06,
                      OH.hdrpassthruchar07,
                      OH.hdrpassthruchar08,
                      OH.hdrpassthruchar09,
                      OH.hdrpassthruchar10,
                      OH.hdrpassthrunum01,
                      OH.hdrpassthrunum02,
                      OH.hdrpassthrunum03,
                      OH.hdrpassthrunum04,
                      OH.hdrpassthrunum05,
                      OH.hdrpassthrunum06,
                      OH.hdrpassthrunum07,
                      OH.hdrpassthrunum08,
                      OH.hdrpassthrunum09,
                      OH.hdrpassthrunum10,
                      OD.dtlpassthruchar01,
                      OD.dtlpassthruchar02,
                      OD.dtlpassthruchar03,
                      OD.dtlpassthruchar04,
                      OD.dtlpassthruchar05,
                      OD.dtlpassthruchar06,
                      OD.dtlpassthruchar07,
                      OD.dtlpassthruchar08,
                      OD.dtlpassthruchar09,
                      OD.dtlpassthruchar10,
                      OD.dtlpassthrunum01,
                      OD.dtlpassthrunum02,
                      OD.dtlpassthrunum03,
                      OD.dtlpassthrunum04,
                      OD.dtlpassthrunum05,
                      OD.dtlpassthrunum06,
                      OD.dtlpassthrunum07,
                      OD.dtlpassthrunum08,
                      OD.dtlpassthrunum09,
                      OD.dtlpassthrunum10,
                 OD.itmpassthruchar01,
                      OH.ca_name,
                      OH.carrier,
                      '(400) 0' || rtrim(OH.po) || ' (240) ' || od.dtlpassthruchar02,
                      '4000' || rtrim(OH.po) || '240' || od.dtlpassthruchar02,
                      '420' || rtrim(oh.shiptopostalcode),
                      '910' || rtrim(OH.hdrpassthruchar01),
                      substr(l_sscc,3,18),
                     '>;>800' || l_sscc,
                     '>;>8' || l_sscc,
                      OH.stopno,
                      l_itemalias,
                      oh.po || '645',
                      decode(in_eanjan13,'Y','EN','CS'),
                      l_eanjan13,
                      oh.ordstageloc,
                      OH.billtoname,
                      OH.billtocontact,
                      OH.billtoaddr1,
                      OH.billtoaddr2,
                      OH.billtocity,
                      OH.billtostate,
                      OH.billtopostalcode,
                      OH.billtocountrycode,
                      OH.billtophone,
                      OH.billtofax,
                      OH.billtoemail,
                      l_qty,
                      null,
                      OH.contact);
                  exception
                     when dup_val_on_index  then
                        null;
                  end;
                  if in_eanjan13 != 'Y' then
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
                      sp.item,
                      decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                      sp.lpid,
                      l_sscc,
                      l_seq,
                      l_seqof,
                      sysdate,
                      'caselabels',
                      'sscc18',
                      decode(l_seq, l_seqof, sp.quantity, l_qty),
--                      l_qty,
                         decode(in_eanjan13,'Y','EN','CS'));
                  end if;
                  sp.quantity := sp.quantity - l_qty;

               else
                  if in_eanjan13 != 'Y' then
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
                      sp.item,
                      decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                      sp.lpid,
                      l_seq,
                      l_seqof,
                      decode(l_seq, l_seqof, sp.quantity, l_qty),
--                      l_qty,
                         decode(in_eanjan13,'Y','EN','CS'),
                      '0',
                      l_rowid,
                      'N');
                  end if;
                  sp.quantity := sp.quantity - l_qty;

               end if;
            end loop; -- for l_seq in 1..l_seqof loop
         end loop; -- for sp in ...
      else
--         for mp in (select lpid, fromlpid, quantity, type
--                     from shippingplate
--                     where orderid = l_orderid
--                       and shipid = l_shipid
--                       and status != 'U'
--                       and parentlpid is null) loop

            if l_useritem1fromasn = 'Y' then
               for sp in (select custid, item, unitofmeasure, orderlot, lotnumber, type,
                                 sum(quantity) as quantity, useritem1
                           from shippingplate
                           where type in ('F','P')
                             and status != 'U'
                           start with lpid = in_lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, orderlot, lotnumber, type, useritem1
                           order by item) loop

                  open c_od(l_orderid, l_shipid, sp.item, sp.orderlot);
                  fetch c_od into od;
                  if c_od%notfound then
                     od := null;
                  end if;
                  close c_od;

                  if( sp.type = 'F' ) THEN
                     l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                                 sp.unitofmeasure, od.labeluom);
                     l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                                 od.labeluom, sp.unitofmeasure);
                  elsif sp.type = 'C' then
                     l_seqof := 1;
                     l_qty := 1;
                     if sp.item is null then
                        sp.item := 'Mixed';
                        od.descr := 'Mixed';
                     end if;
                  else
                     l_qty := 1;
   --                  l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
   --                             od.labeluom, sp.unitofmeasure);
                     l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                                 sp.unitofmeasure, od.labeluom);
                  end if;
                  if l_qty = 0 then
                     l_qty := sp.quantity;
                  end if;
                  if l_seqof = 0 then
                     l_seqof := 1;
                  end if;
                  for l_seq in 1..l_seqof loop
                     if in_action != 'C' then
                        l_bigseq := l_bigseq + 1;

                        if nvl(cu.sscc_extension_digit, '0') = '0' then
                           l_sscc := zlbl.caselabel_barcode(oh.custid, '0');
                        else
                           l_sscc := zlbl.caselabel_barcode(oh.custid, cu.sscc_extension_digit);
                        end if;
                        if in_eanjan13 = 'Y' then
                           l_eanjan13 := get_eanjan13(l_orderid,l_shipid,sp.item);
                        else
                           l_eanjan13 := null;
                        end if;

                        begin
                           l_itemalias := null;
                           open c_cia(OH.custid, sp.item);
                           fetch c_cia into l_itemalias;
                           close c_cia;
                           insert into zenith_case_labels
                          (lpid,
                          sscc18,
                          shiptoname,
                          shiptoaddr1,
                          shiptoaddr2,
                          shiptocity,
                          shiptostate,
                          shiptopstlcd,
                          shiptofax,
                          barpstlcd,
                          label_dat,
                          orderid,
                          shipid,
                          item,
                          descr,
                          wmit,
                          po,
                          reference,
                          loadno,
                          custname,
                          whsename,
                          whseaddr1,
                          whseaddr2,
                          whsecity,
                          whsestate,
                          whsepstlcd,
                          seq,
                          seqof,
                          comment1,
                          wave,
                          stageloc,
                          changed,
                          hdrchar01,
                          hdrchar02,
                          hdrchar03,
                          hdrchar04,
                          hdrchar05,
                          hdrchar06,
                          hdrchar07,
                          hdrchar08,
                          hdrchar09,
                          hdrchar10,
                          hdrnum01,
                          hdrnum02,
                          hdrnum03,
                          hdrnum04,
                          hdrnum05,
                          hdrnum06,
                          hdrnum07,
                          hdrnum08,
                          hdrnum09,
                          hdrnum10,
                          dtlchar01,
                          dtlchar02,
                          dtlchar03,
                          dtlchar04,
                          dtlchar05,
                          dtlchar06,
                          dtlchar07,
                          dtlchar08,
                          dtlchar09,
                          dtlchar10,
                          dtlnum01,
                          dtlnum02,
                          dtlnum03,
                          dtlnum04,
                          dtlnum05,
                          dtlnum06,
                          dtlnum07,
                          dtlnum08,
                          dtlnum09,
                          dtlnum10,
                          itmchar01,
                          carriername,
                          carrierscac,
                          poitem,
                          poitembar,
                          postalbc,
                          storebc,
                          jcpsscc18,
                          jcpsscct1,
                          jcpsscct2,
                          stopno,
                          itemalias,
                          macys128,
                          labeltype,
                          eanjan13,
                          ordstageloc,
                          billtoname,
                          billtocontact,
                          billtoaddr1,
                          billtoaddr2,
                          billtocity,
                          billtostate,
                          billtopostalcode,
                          billtocountrycode,
                          billtophone,
                          billtofax,
                          billtoemail,
                          quantity,
                          useritem1,
                          contact)
                           values
                         (in_lpid,
                          l_sscc,
                          oh.shiptoname,
                          oh.shiptoaddr1,
                          oh.shiptoaddr2,
                          oh.shiptocity,
                          oh.shiptostate,
                          oh.shiptopostalcode,
                          oh.shiptofax,
                          oh.shiptopostalcode,
                          to_char(sysdate,'MM/DD/YY'),
                          l_orderid,
                          l_shipid,
                          sp.item,
                          od.descr,
                          nvl(od.consigneesku,sp.item),
                          oh.po,
                          oh.reference,
                          oh.loadno,
                          oh.cu_name,
                          oh.fa_name,
                          oh.fa_addr1,
                          oh.fa_addr2,
                          oh.fa_city,
                          oh.fa_state,
                          oh.fa_postalcode,
                          l_seq,
                          l_seqof,
                          substr(oh.comment1,1,40),
                          oh.wave,
                          oh.stageloc,
                          null,
                          OH.hdrpassthruchar01,
                          OH.hdrpassthruchar02,
                          OH.hdrpassthruchar03,
                          OH.hdrpassthruchar04,
                          OH.hdrpassthruchar05,
                          OH.hdrpassthruchar06,
                          OH.hdrpassthruchar07,
                          OH.hdrpassthruchar08,
                          OH.hdrpassthruchar09,
                          OH.hdrpassthruchar10,
                          OH.hdrpassthrunum01,
                          OH.hdrpassthrunum02,
                          OH.hdrpassthrunum03,
                          OH.hdrpassthrunum04,
                          OH.hdrpassthrunum05,
                          OH.hdrpassthrunum06,
                          OH.hdrpassthrunum07,
                          OH.hdrpassthrunum08,
                          OH.hdrpassthrunum09,
                          OH.hdrpassthrunum10,
                          OD.dtlpassthruchar01,
                          OD.dtlpassthruchar02,
                          OD.dtlpassthruchar03,
                          OD.dtlpassthruchar04,
                          OD.dtlpassthruchar05,
                          OD.dtlpassthruchar06,
                          OD.dtlpassthruchar07,
                          OD.dtlpassthruchar08,
                          OD.dtlpassthruchar09,
                          OD.dtlpassthruchar10,
                          OD.dtlpassthrunum01,
                          OD.dtlpassthrunum02,
                          OD.dtlpassthrunum03,
                          OD.dtlpassthrunum04,
                          OD.dtlpassthrunum05,
                          OD.dtlpassthrunum06,
                          OD.dtlpassthrunum07,
                          OD.dtlpassthrunum08,
                          OD.dtlpassthrunum09,
                          OD.dtlpassthrunum10,
                          OD.itmpassthruchar01,
                          OH.ca_name,
                          OH.carrier,
                          '(400) 0' || rtrim(OH.po) || ' (240) ' || od.dtlpassthruchar02,
                          '4000' || rtrim(OH.po) || '240' || od.dtlpassthruchar02,
                          '420' || rtrim(oh.shiptopostalcode),
                          '910' || rtrim(OH.hdrpassthruchar01),
                          substr(l_sscc,3,18),
                          '>;>800' || l_sscc,
                          '>;>8' || l_sscc,
                          OH.stopno,
                          l_itemalias,
                          oh.po || '645',
                          decode(in_eanjan13,'Y','EN','CS'),
                          l_eanjan13,
                          oh.ordstageloc,
                          OH.billtoname,
                          OH.billtocontact,
                          OH.billtoaddr1,
                          OH.billtoaddr2,
                          OH.billtocity,
                          OH.billtostate,
                          OH.billtopostalcode,
                          OH.billtocountrycode,
                          OH.billtophone,
                          OH.billtofax,
                          OH.billtoemail,
                          l_qty,
                          sp.useritem1,
                          OH.contact);
                           exception
                         when dup_val_on_index  then
                            null;
                           end;
                        if in_eanjan13 != 'Y' then
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
                            sp.item,
                            decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                            in_lpid,
                            l_sscc,
                            l_seq,
                            l_seqof,
                            sysdate,
                            'caselabels',
                            'sscc18',
                            decode(l_seq, l_seqof, sp.quantity, l_qty),
   --                         l_qty,
                               decode(in_eanjan13,'Y','EN','CS'));
                        end if;
                        sp.quantity := sp.quantity - l_qty;

                     else
                        if in_eanjan13 != 'Y' then
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
                            sp.item,
                            decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                            in_lpid,
                            l_seq,
                            l_seqof,
   --                         null,
   --                         null,
                            decode(l_seq, l_seqof, sp.quantity, l_qty),
   --                         l_qty,
                               decode(in_eanjan13,'Y','EN','CS'),
                            '0',
                            l_rowid,
                            'N');
                        end if;
                        sp.quantity := sp.quantity - l_qty;

                     end if;
                  end loop; -- for l_seq in 1..l_seqof loop
               end loop; -- for sp
            else
            for sp in (select custid, item, unitofmeasure, orderlot, lotnumber, type,
                              sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                          and status != 'U'
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, orderlot, lotnumber, type
                        order by item) loop

               open c_od(l_orderid, l_shipid, sp.item, sp.orderlot);
               fetch c_od into od;
               if c_od%notfound then
                  od := null;
               end if;
               close c_od;

               if( sp.type = 'F' ) THEN
                  l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                              sp.unitofmeasure, od.labeluom);
                  l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                              od.labeluom, sp.unitofmeasure);
               elsif sp.type = 'C' then
                  l_seqof := 1;
                  l_qty := 1;
                  if sp.item is null then
                     sp.item := 'Mixed';
                     od.descr := 'Mixed';
                  end if;
               else
                  l_qty := 1;
--                  l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
--                             od.labeluom, sp.unitofmeasure);
                  l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity,
                              sp.unitofmeasure, od.labeluom);
               end if;
               if l_qty = 0 then
                  l_qty := sp.quantity;
               end if;
               if l_seqof = 0 then
                  l_seqof := 1;
               end if;
               for l_seq in 1..l_seqof loop
                  if in_action != 'C' then
                     l_bigseq := l_bigseq + 1;
                     if nvl(cu.sscc_extension_digit, '0') = '0' then
                        l_sscc := zlbl.caselabel_barcode(oh.custid, '0');
                     else
                        l_sscc := zlbl.caselabel_barcode(oh.custid, cu.sscc_extension_digit);
                     end if;
                     if in_eanjan13 = 'Y' then
                        l_eanjan13 := get_eanjan13(l_orderid,l_shipid,sp.item);
                     else
                        l_eanjan13 := null;
                     end if;

                     begin
                        l_itemalias := null;
                        open c_cia(OH.custid, sp.item);
                        fetch c_cia into l_itemalias;
                        close c_cia;
                        insert into zenith_case_labels
                       (lpid,
                       sscc18,
                       shiptoname,
                       shiptoaddr1,
                       shiptoaddr2,
                       shiptocity,
                       shiptostate,
                       shiptopstlcd,
                       shiptofax,
                       barpstlcd,
                       label_dat,
                       orderid,
                       shipid,
                       item,
                       descr,
                       wmit,
                       po,
                       reference,
                       loadno,
                       custname,
                       whsename,
                       whseaddr1,
                       whseaddr2,
                       whsecity,
                       whsestate,
                       whsepstlcd,
                       seq,
                       seqof,
                       comment1,
                       wave,
                       stageloc,
                       changed,
                       hdrchar01,
                       hdrchar02,
                       hdrchar03,
                       hdrchar04,
                       hdrchar05,
                       hdrchar06,
                       hdrchar07,
                       hdrchar08,
                       hdrchar09,
                       hdrchar10,
                       hdrnum01,
                       hdrnum02,
                       hdrnum03,
                       hdrnum04,
                       hdrnum05,
                       hdrnum06,
                       hdrnum07,
                       hdrnum08,
                       hdrnum09,
                       hdrnum10,
                       dtlchar01,
                       dtlchar02,
                       dtlchar03,
                       dtlchar04,
                       dtlchar05,
                       dtlchar06,
                       dtlchar07,
                       dtlchar08,
                       dtlchar09,
                       dtlchar10,
                       dtlnum01,
                       dtlnum02,
                       dtlnum03,
                       dtlnum04,
                       dtlnum05,
                       dtlnum06,
                       dtlnum07,
                       dtlnum08,
                       dtlnum09,
                       dtlnum10,
                       itmchar01,
                       carriername,
                       carrierscac,
                       poitem,
                       poitembar,
                       postalbc,
                       storebc,
                       jcpsscc18,
                       jcpsscct1,
                       jcpsscct2,
                       stopno,
                       itemalias,
                       macys128,
                       labeltype,
                       eanjan13,
                       ordstageloc,
                       billtoname,
                       billtocontact,
                       billtoaddr1,
                       billtoaddr2,
                       billtocity,
                       billtostate,
                       billtopostalcode,
                       billtocountrycode,
                       billtophone,
                       billtofax,
                       billtoemail,
                       quantity,
                          useritem1,
                          contact)
                        values
                      (in_lpid,
                       l_sscc,
                       oh.shiptoname,
                       oh.shiptoaddr1,
                       oh.shiptoaddr2,
                       oh.shiptocity,
                       oh.shiptostate,
                       oh.shiptopostalcode,
                       oh.shiptofax,
                       oh.shiptopostalcode,
                       to_char(sysdate,'MM/DD/YY'),
                       l_orderid,
                       l_shipid,
                       sp.item,
                       od.descr,
                       nvl(od.consigneesku,sp.item),
                       oh.po,
                       oh.reference,
                       oh.loadno,
                       oh.cu_name,
                       oh.fa_name,
                       oh.fa_addr1,
                       oh.fa_addr2,
                       oh.fa_city,
                       oh.fa_state,
                       oh.fa_postalcode,
                       l_seq,
                       l_seqof,
                       substr(oh.comment1,1,40),
                       oh.wave,
                       oh.stageloc,
                       null,
                       OH.hdrpassthruchar01,
                       OH.hdrpassthruchar02,
                       OH.hdrpassthruchar03,
                       OH.hdrpassthruchar04,
                       OH.hdrpassthruchar05,
                       OH.hdrpassthruchar06,
                       OH.hdrpassthruchar07,
                       OH.hdrpassthruchar08,
                       OH.hdrpassthruchar09,
                       OH.hdrpassthruchar10,
                       OH.hdrpassthrunum01,
                       OH.hdrpassthrunum02,
                       OH.hdrpassthrunum03,
                       OH.hdrpassthrunum04,
                       OH.hdrpassthrunum05,
                       OH.hdrpassthrunum06,
                       OH.hdrpassthrunum07,
                       OH.hdrpassthrunum08,
                       OH.hdrpassthrunum09,
                       OH.hdrpassthrunum10,
                       OD.dtlpassthruchar01,
                       OD.dtlpassthruchar02,
                       OD.dtlpassthruchar03,
                       OD.dtlpassthruchar04,
                       OD.dtlpassthruchar05,
                       OD.dtlpassthruchar06,
                       OD.dtlpassthruchar07,
                       OD.dtlpassthruchar08,
                       OD.dtlpassthruchar09,
                       OD.dtlpassthruchar10,
                       OD.dtlpassthrunum01,
                       OD.dtlpassthrunum02,
                       OD.dtlpassthrunum03,
                       OD.dtlpassthrunum04,
                       OD.dtlpassthrunum05,
                       OD.dtlpassthrunum06,
                       OD.dtlpassthrunum07,
                       OD.dtlpassthrunum08,
                       OD.dtlpassthrunum09,
                       OD.dtlpassthrunum10,
                       OD.itmpassthruchar01,
                       OH.ca_name,
                       OH.carrier,
                       '(400) 0' || rtrim(OH.po) || ' (240) ' || od.dtlpassthruchar02,
                       '4000' || rtrim(OH.po) || '240' || od.dtlpassthruchar02,
                       '420' || rtrim(oh.shiptopostalcode),
                       '910' || rtrim(OH.hdrpassthruchar01),
                       substr(l_sscc,3,18),
                       '>;>800' || l_sscc,
                       '>;>8' || l_sscc,
                       OH.stopno,
                       l_itemalias,
                       oh.po || '645',
                       decode(in_eanjan13,'Y','EN','CS'),
                       l_eanjan13,
                       oh.ordstageloc,
                       OH.billtoname,
                       OH.billtocontact,
                       OH.billtoaddr1,
                       OH.billtoaddr2,
                       OH.billtocity,
                       OH.billtostate,
                       OH.billtopostalcode,
                       OH.billtocountrycode,
                       OH.billtophone,
                       OH.billtofax,
                       OH.billtoemail,
                       l_qty,
                          null,
                          OH.contact);
                        exception
                      when dup_val_on_index  then
                         null;
                        end;
                     if in_eanjan13 != 'Y' then
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
                         sp.item,
                         decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                         in_lpid,
                         l_sscc,
                         l_seq,
                         l_seqof,
                         sysdate,
                         'caselabels',
                         'sscc18',
                         decode(l_seq, l_seqof, sp.quantity, l_qty),
--                         l_qty,
                            decode(in_eanjan13,'Y','EN','CS'));
                     end if;
                     sp.quantity := sp.quantity - l_qty;

                  else
                     if in_eanjan13 != 'Y' then
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
                         sp.item,
                         decode(in_lot, 'Y', sp.lotnumber, sp.orderlot),
                         in_lpid,
                         l_seq,
                         l_seqof,
--                         null,
--                         null,
                         decode(l_seq, l_seqof, sp.quantity, l_qty),
--                         l_qty,
                            decode(in_eanjan13,'Y','EN','CS'),
                         '0',
                         l_rowid,
                         'N');
                     end if;
                     sp.quantity := sp.quantity - l_qty;

                  end if;
               end loop; -- for l_seq in 1..l_seqof loop
            end loop; -- for sp
            end if;
        --  end loop; -- for mp
      end if; -- if l_cons_order
      if in_action != 'C' then
         commit;
      end if;
   end if;
   if in_action != 'C' then
      if in_eanjan13 = 'Y' then
      out_stmt := 'select * from zenith_remap_view where lpid= '''
        || in_lpid || ''' and labeltype != ''CS'' ';
      else
         out_stmt := 'select * from zenith_remap_view where lpid= '''
           || in_lpid || ''' and labeltype = ''CS'' ';
      end if;
      return;
   end if;


   debugmsg('in_action = C, in_func = '||in_func);
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
      return;
   end if;
   c1 := 0;
-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = l_orderid
                    and shipid = l_shipid) loop
      c1 := c1 + 1;
      if c1 = 1 then
         debugmsg('lbl ' || lbl.orderid || ' s ' || lbl.shipid || ' c ' || lbl.custid ||
                  ' l ' || lbl.lotnumber || ' p ' || lbl.lpid  || ' s ' || l_sscc ||
                  ' q ' || lbl.seq || ' o ' || lbl.seqof || ' q ' || lbl.quantity);
      end if;

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop
         if c1 = 1  then
            debugmsg('cl o ' || tmp.orderid || ' s ' || tmp.shipid || ' c ' || tmp.custid ||
                     ' l ' || tmp.lotnumber || ' p ' || tmp.lpid  || ' s ' || l_sscc ||
                    ' q ' || tmp.seq || ' o ' || tmp.seqof || ' q ' || tmp.quantity);
         end if;

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
   delete caselabels
      where orderid = l_orderid
        and shipid = l_shipid
        and matched = 'N';

-- add new data
   select count(1) into rowcnt from caselabels_temp;
   debugmsg('count ' || rowcnt);
   for tmp in (select * from caselabels_temp
                  where matched = 'N') loop

      l_sscc := zlbl.caselabel_barcode(tmp.custid, tmp.barcodetype);
      debugmsg(tmp.custid || ' ' || tmp.barcodetype || ' ' || l_sscc);
      debugmsg('cl o ' || tmp.orderid || ' s ' || tmp.shipid || ' c ' || tmp.custid ||
               ' l ' || tmp.lotnumber || ' p ' || tmp.lpid  || ' s ' || l_sscc ||
               ' q ' || tmp.seq || ' o ' || tmp.seqof || ' q ' || tmp.quantity);

      begin
         l_itemalias := null;
         open c_cia(OH.custid, tmp.item);
         fetch c_cia into l_itemalias;
         close c_cia;
         if in_eanjan13 = 'Y' then
            l_eanjan13 := get_eanjan13(l_orderid,l_shipid,tmp.item);
         else
            l_eanjan13 := null;
         end if;

      insert into zenith_case_labels
    (lpid,
     sscc18,
     shiptoname,
     shiptoaddr1,
     shiptoaddr2,
     shiptocity,
     shiptostate,
     shiptopstlcd,
     shiptofax,
     barpstlcd,
     label_dat,
     orderid,
     shipid,
     item,
     descr,
     wmit,
     po,
     reference,
     loadno,
     custname,
     whsename,
     whseaddr1,
     whseaddr2,
     whsecity,
     whsestate,
     whsepstlcd,
     seq,
     seqof,
     comment1,
     wave,
     stageloc,
     changed,
     hdrchar01,
     hdrchar02,
     hdrchar03,
     hdrchar04,
     hdrchar05,
     hdrchar06,
     hdrchar07,
     hdrchar08,
     hdrchar09,
     hdrchar10,
     hdrnum01,
     hdrnum02,
     hdrnum03,
     hdrnum04,
     hdrnum05,
     hdrnum06,
     hdrnum07,
     hdrnum08,
     hdrnum09,
     hdrnum10,
     dtlchar01,
     dtlchar02,
     dtlchar03,
     dtlchar04,
     dtlchar05,
     dtlchar06,
     dtlchar07,
     dtlchar08,
     dtlchar09,
     dtlchar10,
     dtlnum01,
     dtlnum02,
     dtlnum03,
     dtlnum04,
     dtlnum05,
     dtlnum06,
     dtlnum07,
     dtlnum08,
     dtlnum09,
     dtlnum10,
     itmchar01,
     carriername,
     carrierscac,
     poitem,
     poitembar,
     postalbc,
     storebc,
     jcpsscc18,
     jcpsscct1,
     jcpsscct2,
     stopno,
     itemalias,
     macys128,
     labeltype,
     eanjan13,
     ordstageloc,
     billtoname,
     billtocontact,
     billtoaddr1,
     billtoaddr2,
     billtocity,
     billtostate,
     billtopostalcode,
     billtocountrycode,
     billtophone,
     billtofax,
     billtoemail,
     quantity,
     contact)
      values
    (tmp.lpid,
     l_sscc,
     oh.shiptoname,
     oh.shiptoaddr1,
     oh.shiptoaddr2,
     oh.shiptocity,
     oh.shiptostate,
     oh.shiptopostalcode,
     oh.shiptofax,
     oh.shiptopostalcode,
     to_char(sysdate, 'MM/DD/YY'),
     l_orderid,
     l_shipid,
     tmp.item,
     od.descr,
     nvl(od.consigneesku,tmp.item),
     oh.po,
     oh.reference,
     oh.loadno,
     oh.cu_name,
     oh.fa_name,
     oh.fa_addr1,
     oh.fa_addr2,
     oh.fa_city,
     oh.fa_state,
     oh.fa_postalcode,
     l_seq,
     l_seqof,
          substr(oh.comment1,1,40),
     oh.wave,
     oh.stageloc,
     null,
     OH.hdrpassthruchar01,
     OH.hdrpassthruchar02,
     OH.hdrpassthruchar03,
     OH.hdrpassthruchar04,
     OH.hdrpassthruchar05,
     OH.hdrpassthruchar06,
     OH.hdrpassthruchar07,
     OH.hdrpassthruchar08,
     OH.hdrpassthruchar09,
     OH.hdrpassthruchar10,
     OH.hdrpassthrunum01,
     OH.hdrpassthrunum02,
     OH.hdrpassthrunum03,
     OH.hdrpassthrunum04,
     OH.hdrpassthrunum05,
     OH.hdrpassthrunum06,
     OH.hdrpassthrunum07,
     OH.hdrpassthrunum08,
     OH.hdrpassthrunum09,
     OH.hdrpassthrunum10,
     OD.dtlpassthruchar01,
     OD.dtlpassthruchar02,
     OD.dtlpassthruchar03,
     OD.dtlpassthruchar04,
     OD.dtlpassthruchar05,
     OD.dtlpassthruchar06,
     OD.dtlpassthruchar07,
     OD.dtlpassthruchar08,
     OD.dtlpassthruchar09,
     OD.dtlpassthruchar10,
     OD.dtlpassthrunum01,
     OD.dtlpassthrunum02,
     OD.dtlpassthrunum03,
     OD.dtlpassthrunum04,
     OD.dtlpassthrunum05,
     OD.dtlpassthrunum06,
     OD.dtlpassthrunum07,
     OD.dtlpassthrunum08,
     OD.dtlpassthrunum09,
     OD.dtlpassthrunum10,
     OD.itmpassthruchar01,
     OH.ca_name,
     OH.carrier,
     '(400) 0' || rtrim(OH.po) || ' (240) ' || od.dtlpassthruchar02,
     '4000' || rtrim(OH.po) || '240' || od.dtlpassthruchar02,
     '420' || rtrim(oh.shiptopostalcode),
     '910' || rtrim(OH.hdrpassthruchar01),
      substr(l_sscc,3,18),
      '>;>800' || l_sscc,
      '>;>8' || l_sscc,
      OH.stopno,
      l_itemalias,
      oh.po || '645',
      decode(in_eanjan13,'Y','EN','CS'),
      l_eanjan13,
      oh.ordstageloc,
      OH.billtoname,
      OH.billtocontact,
      OH.billtoaddr1,
      OH.billtoaddr2,
      OH.billtocity,
      OH.billtostate,
      OH.billtopostalcode,
      OH.billtocountrycode,
      OH.billtophone,
      OH.billtofax,
      OH.billtoemail,
      tmp.quantity,
      OH.contact);
      exception
    when dup_val_on_index  then
       null;
      end;
      if in_eanjan13 != 'Y' then
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
          'caselabels',
          'sscc18',
          tmp.quantity,
             decode(in_eanjan13,'Y','EN','CS'));
      end if;

   end loop;
   debugmsg('commit');
   commit;
   if in_eanjan13 = 'Y' then
      out_stmt := 'select * from zenith_remap_view where lpid = ''' || in_lpid
         || '''' || ' and nvl(changed,''N'') = ''Y'' and labeltype != ''CS''';
   else
      out_stmt := 'select * from zenith_remap_view where lpid = ''' || in_lpid
            || '''' || ' and nvl(changed,''N'') = ''Y'' and labeltype = ''CS''';
   end if;
end ord_lbl_common;

procedure ord_lbl_reprint
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_lot    in varchar2,
    in_eanjan13 in varchar2,
    out_stmt  in out varchar2)
is
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cons_order boolean;
   l_useritem1fromasn customer_aux.useritem1fromasn%type;

begin
   out_stmt := null;

   verify_order(in_lpid, in_func, 'P', in_eanjan13, l_orderid, l_shipid, l_order_cnt, l_label_cnt, l_cons_order, l_useritem1fromasn);
   debugmsg(in_lpid || ' ' || l_orderid || ' ' || l_shipid);
   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         elsif l_order_cnt = -1 then
            out_stmt := 'Nothing for order';
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

   if in_eanjan13 = 'Y' then
      out_stmt := 'select * from zenith_remap_view where lpid = ''' || in_lpid
         || '''' || '  and labeltype != ''CS''';
   else
      out_stmt := 'select * from zenith_remap_view where lpid = ''' || in_lpid
            || '''' || ' and labeltype = ''CS''';
   end if;
end ord_lbl_reprint;

-- Public

procedure ord_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   ord_lbl_common(in_lpid, in_func, in_action, 'N', 'N', out_stmt);
end ord_lbl;

procedure ord_lbl_e13
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   ord_lbl_common(in_lpid, in_func, in_action, 'N', 'Y', out_stmt);
end ord_lbl_e13;

procedure ord_lbl_e13_reprint
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   ord_lbl_reprint(in_lpid, in_func, in_action, 'N', 'Y', out_stmt);
end ord_lbl_e13_reprint;

procedure ord_lbl_lot
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   ord_lbl_common(in_lpid, in_func, in_action, 'Y', 'N', out_stmt);
end ord_lbl_lot;


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
   cursor c_sp_consolidated(p_orderid number, p_shipid number) is
      select lpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid;
   sp c_sp%rowtype;
   spfound boolean;
   l_loadno orderhdr.loadno%type;
   l_load_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
   l_wave orderhdr.wave%type;
   rowCnt integer;
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
      for oh in (select orderid, shipid from orderhdr
                  where loadno = l_loadno) loop
         l_wave := zconsorder.cons_orderid(oh.orderid, oh.shipid);
         if l_wave = 0 then
            open c_sp(oh.orderid, oh.shipid);
            fetch c_sp into sp;
            spfound := c_sp%found;
            close c_sp;
         else
            open c_sp_consolidated(oh.orderid, oh.shipid);
            fetch c_sp_consolidated into sp;
            spfound := c_sp_consolidated%found;
            close c_sp_consolidated;
         end if;
         if spfound then
            ord_lbl_all(sp.lpid, in_func, in_action, l_msg);
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
                  where loadno = l_loadno
                  order by orderid, shipid) loop
         l_wave := zconsorder.cons_orderid(oh.orderid, oh.shipid);
         if l_wave = 0 then
            open c_sp(oh.orderid, oh.shipid);
            fetch c_sp into sp;
            spfound := c_sp%found;
            close c_sp;
         else
            open c_sp_consolidated(oh.orderid, oh.shipid);
            fetch c_sp_consolidated into sp;
            spfound := c_sp_consolidated%found;
            close c_sp_consolidated;
         end if;
         if spfound then
            if in_action = 'N' then
               select count(1) into l_cnt
                  from caselabels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
            else
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl_all(sp.lpid, in_func, in_action, l_msg);
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from zenith_remap_view where loadno = ' || l_loadno || ' and labeltype = ''CS'' '
         || ' order by orderid, shipid';

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
   cursor c_sp_consolidated(p_orderid number, p_shipid number) is
      select lpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid;

   sp c_sp%rowtype;
   spfound boolean;
   l_wave orderhdr.wave%type;
   l_wave_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_cons_order boolean;
   l_msg varchar2(1024);
begin
   out_stmt := null;

   verify_wave(in_lpid, in_func, in_action, l_wave, l_wave_cnt, l_label_cnt, l_cons_order);
   debugmsg('wave ' || l_wave);
   if l_cons_order then
      debugmsg('cons order');
   else
      debugmsg('not not not cons order');
   end if;
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
            ord_lbl_all(sp.lpid, in_func, in_action, l_msg);
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
         debugmsg('wave loop ' || oh.orderid || ' ' || oh.shipid);
         if l_cons_order then
            open c_sp_consolidated(oh.orderid, oh.shipid);
            fetch c_sp_consolidated into sp;
            spfound := c_sp_consolidated%found;
            close c_sp_consolidated;
         else
            open c_sp(oh.orderid, oh.shipid);
            fetch c_sp into sp;
            spfound := c_sp%found;
            close c_sp;
         end if;
         if spfound then
            if in_action = 'N' then
               select count(1) into l_cnt
                  from caselabels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
            else
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl_all(sp.lpid, in_func, in_action, l_msg);
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from zenith_remap_view where wave = ' || l_wave || ' and labeltype = ''CS'' '
         || ' order by orderid, shipid';

end wav_lbl;

procedure ord_lbl_all
   (in_lpid     in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    out varchar2)
is
   out_msg varchar2(200);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cons_order boolean;
   l_useritem1fromasn customer_aux.useritem1fromasn%type;
begin
   verify_order(in_lpid, in_func, in_action, 'N', l_orderid, l_shipid, l_order_cnt, l_label_cnt, l_cons_order, l_useritem1fromasn);
   debugmsg(in_lpid || ' ' || l_orderid || ' ' || l_shipid);
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

   if in_action = 'A' then
      delete from zenith_case_labels
         where orderid = l_orderid
           and shipid = l_shipid
           and labeltype ='CS';
      delete from caselabels
         where orderid = l_orderid
           and shipid = l_shipid
           and labeltype = 'CS';
   end if;

   delete caselabels_temp;
--   delete zenith_case_labels_temp;

   for mp in (select lpid
               from shippingplate
               where orderid = l_orderid
                 and shipid = l_shipid
                 and parentlpid is null) loop


--      if l_aux.shippingtype = 'C' then
--         carton_label(in_action, in_oh, in_oa, l_aux);
--      else
      for sp in (select lpid
                   from shippingplate
                  where type in ('F','P')
                    and status != 'U'
                  start with parentlpid = mp.lpid or
                             (lpid = mp.lpid and type = 'F')
                  connect by prior lpid = parentlpid) loop
         ord_lbl(sp.lpid, in_func, in_action, out_msg);
      end loop;
--      end if;
   end loop;

   if in_func = 'Q' then
      out_stmt := 'OKAY';
   elsif in_action = 'A' then
      out_stmt := 'select * from zenith_remap_view'
            || ' where orderid = ' || l_orderid
            || ' and shipid = ' || l_shipid
            || ' and labeltype = ''CS'' '
            || ' order by lpid';
   else
      out_stmt := 'OKAY';
   end if;
   commit;

end ord_lbl_all;

procedure ord_lbl_all_e13
   (in_lpid     in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    out varchar2)
is
   out_msg varchar2(200);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cons_order boolean;
   l_useritem1fromasn customer_aux.useritem1fromasn%type;
begin
   verify_order(in_lpid, in_func, in_action, 'Y', l_orderid, l_shipid, l_order_cnt, l_label_cnt, l_cons_order, l_useritem1fromasn);
   debugmsg(in_lpid || ' ' || l_orderid || ' ' || l_shipid);
   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         elsif l_order_cnt = -1 then
            out_stmt := 'Nothing for order';
         else
            out_stmt := 'Order not unique';
         end if;
      end if;
      return;
   end if;

   if in_action = 'A' then
      delete from zenith_case_labels
         where orderid = l_orderid
           and shipid = l_shipid
           and labeltype != 'CS';
   end if;

   delete caselabels_temp;
   commit;
--   delete zenith_case_labels_temp;
   debugmsg('here');
   for mp in (select lpid
               from shippingplate
               where orderid = l_orderid
                 and shipid = l_shipid
                 and parentlpid is null) loop

      debugmsg('mp ' || mp.lpid);
--      if l_aux.shippingtype = 'C' then
--         carton_label(in_action, in_oh, in_oa, l_aux);
--      else
      for sp in (select lpid
                   from shippingplate
                  where type in ('F','P')
                    and status != 'U'
                  start with parentlpid = mp.lpid or
                             (lpid = mp.lpid and type = 'F')
                  connect by prior lpid = parentlpid) loop
         debugmsg('sp ' || sp.lpid);

         ord_lbl_e13(sp.lpid, in_func, in_action, out_msg);
      end loop;
--      end if;
   end loop;

   if in_func = 'Q' then
      out_stmt := 'OKAY';
   elsif in_action = 'A' then
      out_stmt := 'select * from zenith_remap_view'
            || ' where orderid = ' || l_orderid
            || ' and shipid = ' || l_shipid
            || ' and labeltype != ''CS'' '
            || ' order by lpid';
   else
      out_stmt := 'OKAY';
   end if;
   commit;

end ord_lbl_all_e13;


end zenith_caslbls;
/

show errors package body zenith_caslbls;
exit;
