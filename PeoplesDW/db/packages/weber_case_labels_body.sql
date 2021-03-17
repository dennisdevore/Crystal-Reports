create or replace package body weber_caslbls as
--
-- $Id$
--


--Types


type ohdata is record(
   custid orderhdr.custid%type,
   shiptoname orderhdr.shiptoname%type,
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
   shipterms orderhdr.shipterms%type,
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
          OH.shipterms as shipterms,
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

cursor c_chlp(p_parentlpid varchar2) is
   select unitofmeasure, lotnumber, orderlot, orderitem
      from shippingplate
      where type in ('F','P')
        and parentlpid = p_parentlpid;


-- Private functions


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


function calc_bigseqof
   (in_orderid    in number,
    in_shipid     in number,
    in_shiptype   in varchar2,
    in_cons_order in boolean)
return pls_integer
is
   l_bigseqof pls_integer := 0;
   l_cnt pls_integer;
   l_wave waves.wave%type;
begin

   if in_cons_order then
      l_wave := zcord.cons_orderid(in_orderid, in_shipid);
   end if;

-- qty of labels for cartons not on a master
   if in_cons_order then
      if in_orderid != l_wave then  -- order within a consolidated order
         for cp in (select PP.lpid
                     from shippingplate PP
                     where PP.orderid = l_wave
                       and PP.shipid = 0
                       and PP.parentlpid is null
                       and PP.type = 'C'
                       and exists (select * from shippingplate KP
                                    where KP.parentlpid = PP.lpid
                                      and KP.orderid = in_orderid
                                      and KP.shipid = in_shipid)) loop
            for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                          and orderid = in_orderid
                          and shipid = in_shipid
                        start with lpid = cp.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure) loop
               l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                     sp.unitofmeasure, sp.quantity);
            end loop;
         end loop;
      else                         -- entire consolidated order
         for cp in (select PP.lpid
                     from shippingplate PP
                     where PP.orderid = l_wave
                       and PP.shipid = 0
                       and PP.parentlpid is null
                       and PP.type = 'C') loop
            for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                        start with lpid = cp.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure) loop
               l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                     sp.unitofmeasure, sp.quantity);
            end loop;
         end loop;
      end if;
   else
      select count(1) into l_bigseqof
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and type = 'C'
           and parentlpid is null;
   end if;

-- qty of labels for cartons on a master
   if nvl(in_shiptype,'?') != 'S' then
      if in_cons_order then
         if in_orderid != l_wave then  -- order within a consolidated order
            for mp in (select lpid
                        from shippingplate
                        where orderid = l_wave
                          and shipid = 0
                          and parentlpid is null
                          and type = 'M') loop
               for cp in (select PP.lpid
                           from shippingplate PP
                           where PP.parentlpid = mp.lpid
                             and PP.type = 'C'
                             and exists (select * from shippingplate KP
                                          where KP.parentlpid = PP.lpid
                                            and KP.orderid = in_orderid
                                            and KP.shipid = in_shipid)) loop
                  for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                              from shippingplate
                              where type in ('F','P')
                                and orderid = in_orderid
                                and shipid = in_shipid
                              start with lpid = cp.lpid
                              connect by prior lpid = parentlpid
                              group by custid, item, unitofmeasure) loop
                     l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                           sp.unitofmeasure, sp.quantity);
                  end loop;
               end loop;
            end loop;
         else                          -- entire consolidated order
            for mp in (select lpid
                        from shippingplate
                        where orderid = l_wave
                          and shipid = 0
                          and parentlpid is null
                          and type = 'M') loop
               for cp in (select PP.lpid
                           from shippingplate PP
                           where PP.parentlpid = mp.lpid
                             and PP.type = 'C') loop
                  for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                              from shippingplate
                              where type in ('F','P')
                              start with lpid = cp.lpid
                              connect by prior lpid = parentlpid
                              group by custid, item, unitofmeasure) loop
                     l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                           sp.unitofmeasure, sp.quantity);
                  end loop;
               end loop;
            end loop;
         end if;
      else
         for mp in (select lpid
                     from shippingplate
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and parentlpid is null
                       and type = 'M') loop
            for cp in (select lpid
                        from shippingplate
                        where parentlpid = mp.lpid
                          and type = 'C') loop
               for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                           from shippingplate
                           where type in ('F','P')
                           start with lpid = cp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure) loop
                  l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                        sp.unitofmeasure, sp.quantity);
               end loop;
            end loop;
         end loop;
      end if;
   end if;

-- qty from non-cartons
   if in_cons_order then
      if in_orderid != l_wave then  -- order within a consolidated order
         for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                     from shippingplate
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and type in ('F','P')
                       and status != 'U'
                       and part_of_carton(type, parentlpid) = 'N'
                     group by custid, item, unitofmeasure) loop
            l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                  sp.unitofmeasure, sp.quantity);
         end loop;
      else                          -- entire consolidated order
         for sp in (select SP.custid, SP.item, SP.unitofmeasure, sum(SP.quantity) as quantity
                     from shippingplate SP, orderhdr OH
                     where OH.wave = l_wave
                       and SP.orderid = OH.orderid
                       and SP.shipid = OH.shipid
                       and SP.type in ('F','P')
                       and SP.status != 'U'
                       and part_of_carton(SP.type, SP.parentlpid) = 'N'
                     group by SP.custid, SP.item, SP.unitofmeasure) loop
            l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                  sp.unitofmeasure, sp.quantity);
         end loop;
      end if;
   else
      for mp in (select lpid, type
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and type != 'C'
                    and status != 'U'
                    and parentlpid is null) loop
         if (nvl(in_shiptype,'?') = 'S') and (mp.type = 'M') then
            l_bigseqof := l_bigseqof + 1;
         else
            for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                          and part_of_carton(type, parentlpid) = 'N'
                        start with lpid = mp.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure) loop
               l_bigseqof := l_bigseqof + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
                     sp.unitofmeasure, sp.quantity);
            end loop;
         end if;
      end loop;
   end if;
   return l_bigseqof;
end calc_bigseqof;


function calc_totalcases
   (in_orderid in number,
    in_shipid  in number)
return weber_case_labels.totalcases%type
is
   cursor c_wcl(p_orderid number, p_shipid number) is
      select totalcases
         from weber_case_labels
         where orderid = p_orderid
           and shipid = p_shipid;
   wcl c_wcl%rowtype := null;
begin
   open c_wcl(in_orderid, in_shipid);
   fetch c_wcl into wcl;
   close c_wcl;

   if wcl.totalcases is null then
      wcl.totalcases := 0;
      for sp in (select custid, item, unitofmeasure, sum(quantity) as quantity
                  from shippingplate
                  where orderid = in_orderid
                  and shipid = in_shipid
                  and type in ('F','P')
                  group by custid, item, unitofmeasure) loop
         wcl.totalcases := wcl.totalcases + weber_prplbls.lbl_remainder_qty(sp.custid, sp.item,
               sp.unitofmeasure, sp.quantity);
      end loop;
   end if;
   return wcl.totalcases;
end calc_totalcases;


function child_item
   (in_parentlpid in varchar2)
return varchar2
is
   l_item shippingplate.item%type := null;
begin
   for cp in (select distinct item from (
              select item
               from shippingplate
               where type in ('F','P')
               start with parentlpid = in_parentlpid
               connect by prior lpid = parentlpid)) loop
      if l_item is not null then
         l_item := null;
         exit;
      end if;
      l_item := cp.item;
   end loop;
   return l_item;

end child_item;


-- Private procedures


procedure verify_order
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_orderid   out number,
    out_shipid    out number,
    out_order_cnt out number,
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
begin
   out_orderid := 0;
   out_shipid := 0;
   out_order_cnt := 0;
   out_label_cnt := 0;
   out_cons_order := FALSE;

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

   select count(1) into out_label_cnt
      from weber_case_labels
      where orderid = inp.orderid
        and shipid = inp.shipid;

   l_wave := zcord.cons_orderid(out_orderid, out_shipid);
   if l_wave != 0 then
      out_cons_order := TRUE;
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

   select count(1) into out_label_cnt
      from weber_case_labels
      where loadno = inp.loadno;
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
   l_wave waves.wave%type;
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
         open o_lp(l_lpid);
         fetch o_lp into olp;
         if o_lp%found then
            l_wave := zcord.cons_orderid(olp.orderid, olp.shipid);
            if l_wave != 0 then
               out_wave := l_wave;
               out_cons_order := TRUE;
            end if;
         end if;
      else -- check for consolidated order
         open o_lp(l_lpid);
         fetch o_lp into olp;
         if o_lp%found then
            out_wave := zcord.cons_orderid(olp.orderid, olp.shipid);
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

   select count(1) into out_label_cnt
      from weber_case_labels
      where wave = inp.wave;
end verify_wave;


procedure add_label
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lot        in varchar2,
    in_uom        in varchar2,
    in_action     in varchar2,
    in_bigseqof   in number,
    in_lpid       in varchar2,
    in_asn_no     in varchar2,
    in_fromlpid   in varchar2,
    in_oh         in ohdata,
    in_carton     in boolean,
    in_orderitem  in varchar2,
    in_orderlot   in varchar2,
    io_quantity   in out number,
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
   cursor c_sp(p_lpid varchar2) is
      select orderitem, orderlot
         from shippingplate
         where type in ('F','P')
         start with lpid = p_lpid
         connect by prior lpid = parentlpid;
   sp c_sp%rowtype := null;
   l_lbluomqty number;
   l_remqty number;
   l_seq pls_integer;
   l_seqof pls_integer;
   l_qty shippingplate.quantity%type;
   l_sscc varchar2(20);
   l_rowid varchar2(20);
   l_item custitem.item%type := in_item;
   l_totalcases number;
begin
   if l_item is null then

      for sp in (select distinct custid, item from (
                 select custid, item
                  from shippingplate
                  where type in ('F','P')
                  start with parentlpid = in_lpid
                  connect by prior lpid = parentlpid)) loop
         if l_item is null then
            l_item := sp.item;
         else
            l_item := null;
            exit;
         end if;
      end loop;
   end if;

   if in_orderitem is null then
      open c_sp(in_lpid);
      fetch c_sp into sp;
      close c_sp;
   else
      sp.orderitem := in_orderitem;
      sp.orderlot := in_orderlot;
   end if;
   open c_od(in_orderid, in_shipid, sp.orderitem, sp.orderlot);
   fetch c_od into od;
   if c_od%notfound then
      od := null;
   end if;
   close c_od;

   weber_prplbls.lbluom_qtys(in_oh.custid, l_item, in_uom, io_quantity,
         l_lbluomqty, l_remqty);
   if in_carton then
      l_seqof := 1;
   else
      l_seqof := greatest(l_lbluomqty+l_remqty, 1);
   end if;
   l_totalcases := calc_totalcases(in_orderid, in_shipid);

   for l_seq in 1..l_seqof loop

      if (l_lbluomqty != 0) and (not in_carton) then
         l_qty := zlbl.uom_qty_conv(in_oh.custid, l_item, 1, od.labeluom, in_uom);
         if l_qty = 0 then
            l_qty := io_quantity;
         end if;
         l_lbluomqty := l_lbluomqty - 1;
      elsif (l_lbluomqty = 0) and (not in_carton) then
         l_qty := 1;
      else
         l_qty := io_quantity;
      end if;

      io_bigseq := io_bigseq + 1;
      if in_action != 'C' then
         l_sscc := zlbl.caselabel_barcode(in_oh.custid, '0');

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
             totalcases)
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
             nvl(l_item, 'Mixed'),
             decode(l_item, null, 'Mixed', od.descr),
             od.abbrev,
             nvl(od.consigneesku,l_item),
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
             in_asn_no,
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
             l_totalcases);

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
             l_item,
             in_lot,
             in_lpid,
             l_sscc,
             l_seq,
             l_seqof,
             sysdate,
             'weber_case_labels',
             'sscc18',
             decode(l_seq, l_seqof, io_quantity, l_qty),
             'CS');

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
             totalcases)
         values
            (in_lpid,
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
             nvl(l_item, 'Mixed'),
             decode(l_item, null, 'Mixed', od.descr),
             od.abbrev,
             nvl(od.consigneesku,l_item),
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
             in_asn_no,
             decode(od.hazardous,
               'Y', 'HAZARDOUS MATERIAL',
                     null),
             in_oh.wave,
             in_fromlpid,
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
             l_totalcases)
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
             in_oh.custid,
             l_item,
             in_lot,
             in_lpid,
             l_seq,
             l_seqof,
             decode(l_seq, l_seqof, io_quantity, l_qty),
             'CS',
             '0',
             l_rowid,
             'N');
      end if;

      io_quantity := io_quantity - l_qty;
   end loop;

end add_label;


procedure lpid_lbl_order
   (in_lpid       in varchar2,
    in_action     in varchar2,
    in_orderid    in orderhdr.orderid%type,
    in_shipid     in orderhdr.shipid%type,
    in_cons_order in boolean)
is
   cursor c_sp(p_lpid varchar2) is
      select item, unitofmeasure, quantity, fromlpid, orderlot, lotnumber,
             type, pickuom, custid, orderitem
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype := null;
   oh ohdata;
   chlp c_chlp%rowtype;
   l_minorderid orderhdr.orderid%type;
   l_asn_no weber_case_labels.asn_no%type;
   l_bigseq pls_integer;
   l_bigseqof pls_integer;
   l_carton boolean;
   l_wave waves.wave%type;
begin

   if in_cons_order then
      l_wave := zcord.cons_orderid(in_orderid, in_shipid);
   end if;

   open c_oh(in_orderid, in_shipid);
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

   select count(1) into l_bigseq
      from weber_case_labels
      where orderid = in_orderid
        and shipid = in_shipid;
   l_bigseqof := calc_bigseqof(in_orderid, in_shipid, oh.shiptype, in_cons_order);

   open c_sp(in_lpid);
   fetch c_sp into sp;
   close c_sp;

   if sp.type = 'M' then
      if oh.shiptype != 'S' then
--       do cartons on a master
         for ctn in (select lpid
                        from shippingplate
                        where parentlpid = in_lpid
                          and orderid = in_orderid
                          and shipid = in_shipid
                          and type = 'C') loop
            for cp in (select custid, item, unitofmeasure, lotnumber, sum(quantity) as quantity,
                              orderitem, orderlot
                        from shippingplate
                        where type in ('F','P')
                        start with lpid = ctn.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber,
                                 orderitem, orderlot) loop
               add_label(in_orderid, in_shipid, cp.item, cp.lotnumber, cp.unitofmeasure,
                     in_action, l_bigseqof, ctn.lpid, l_asn_no, sp.fromlpid, oh, not in_cons_order,
                     cp.orderitem, cp.orderlot, cp.quantity, l_bigseq);
            end loop;
         end loop;

         if in_cons_order then
            for ctn in (select PP.lpid
                           from shippingplate PP
                           where PP.parentlpid = in_lpid
                             and PP.orderid = l_wave
                             and PP.shipid = 0
                             and PP.type = 'C'
                             and exists (select * from shippingplate KP
                                          where KP.parentlpid = PP.lpid
                                            and KP.orderid = in_orderid
                                            and KP.shipid = in_shipid)) loop
               for cp in (select custid, item, unitofmeasure, lotnumber, sum(quantity) as quantity,
                                 orderitem, orderlot
                           from shippingplate
                           where type in ('F','P')
                             and orderid = in_orderid
                             and shipid = in_shipid
                           start with lpid = ctn.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber,
                                    orderitem, orderlot) loop
                  add_label(in_orderid, in_shipid, cp.item, cp.lotnumber, cp.unitofmeasure,
                        in_action, l_bigseqof, in_lpid, l_asn_no, sp.fromlpid, oh, false,
                        cp.orderitem, cp.orderlot, cp.quantity, l_bigseq);
               end loop;
            end loop;
         end if;
      end if;

      if oh.shiptype = 'S' then
--       small package master, only 1 label but need 1st child to get needed rows
         sp.item := nvl(sp.item, child_item(in_lpid));
         chlp := null;
         if sp.item is not null then
            open c_chlp(in_lpid);
            fetch c_chlp into chlp;
            close c_chlp;
         end if;
         add_label(in_orderid, in_shipid, sp.item, chlp.lotnumber, chlp.unitofmeasure,
               in_action, l_bigseqof, in_lpid, l_asn_no, sp.fromlpid, oh, true,
               chlp.orderitem, chlp.orderlot, sp.quantity, l_bigseq);
      else
         for cp in (select custid, item, unitofmeasure, lotnumber, sum(quantity) as quantity,
                           orderitem, orderlot
                     from shippingplate
                     where type in ('F','P')
                       and part_of_carton(type, parentlpid) = 'N'
                       and orderid = in_orderid
                       and shipid = in_shipid
                     start with lpid = in_lpid
                     connect by prior lpid = parentlpid
                     group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                     order by item) loop
            add_label(in_orderid, in_shipid, cp.item, cp.lotnumber, cp.unitofmeasure,
                  in_action, l_bigseqof, in_lpid, l_asn_no, sp.fromlpid, oh, false,
                  cp.orderitem, cp.orderlot, cp.quantity, l_bigseq);
         end loop;
      end if;
   else
      l_carton := false;
      if sp.type = 'C' then
         l_carton := true;
         sp.item := nvl(sp.item, child_item(in_lpid));
         chlp := null;
         if sp.item is not null then
            open c_chlp(in_lpid);
            fetch c_chlp into chlp;
            close c_chlp;
         end if;
         sp.lotnumber := chlp.lotnumber;
         sp.unitofmeasure := chlp.unitofmeasure;
         sp.orderitem := chlp.orderitem;
         sp.orderlot := chlp.orderlot;
         if in_cons_order then
            select nvl(sum(quantity),0) into sp.quantity
               from shippingplate
               where parentlpid = in_lpid
                 and orderid = in_orderid
                 and shipid = in_shipid;
            l_carton := false;
         end if;
      elsif zci.picktotype(sp.custid, sp.item, sp.pickuom) = 'PACK'
        and oh.shiptype != 'T'
        and oh.shipterms != 'PCK' then
         l_carton := true;
      end if;

      add_label(in_orderid, in_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
            in_action, l_bigseqof, in_lpid, l_asn_no, sp.fromlpid, oh, l_carton,
            sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
   end if;

end lpid_lbl_order;


-- Public functions


function part_of_carton
   (in_type   in varchar2,
    in_parent in varchar2)
return varchar2
is
   cursor c_slp(p_lpid varchar2) is
      select type
         from shippingplate
         where lpid = p_lpid;
   slp c_slp%rowtype;
   l_results varchar2(1) := 'N';
begin
   if in_type = 'C' then
      l_results := 'Y';
   elsif (in_type in ('F','P')) and (in_parent is not null) then
      open c_slp(in_parent);
      fetch c_slp into slp;
      close c_slp;
      if nvl(slp.type, 'M') = 'C' then
         l_results := 'Y';
      end if;
   end if;

   return l_results;

end part_of_carton;


-- Public Procedures


procedure ord_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   oh ohdata;
   cursor c_alt(p_rowid varchar2) is
      select *
         from weber_case_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   chlp c_chlp%rowtype;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_sscc varchar2(20);
   l_bigseq pls_integer;
   l_bigseqof pls_integer;
   l_minorderid orderhdr.orderid%type;
   l_asn_no weber_case_labels.asn_no%type;
   l_match varchar2(1);
   l_rowid varchar2(20);
   l_cons_order boolean;
   l_wave waves.wave%type;
   cntCombined pls_integer;
begin
   out_stmt := null;

   if in_action not in ('A','C','P') then
      out_stmt := 'Unsupported Action';
      return;
   end if;

   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt,
         l_cons_order);
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
      if in_action = 'A' then
         out_stmt := 'OKAY';
      elsif in_action = 'P' then
         if l_label_cnt = 0 then
            out_stmt := 'Nothing for order';
         else
            out_stmt := 'OKAY';
         end if;
      end if;
      if out_stmt is not null then
         return;
      end if;
   end if;

   if (in_action != 'P')
   and (in_action != 'A' or l_label_cnt = 0) then
      if in_action != 'C' then
         delete from caselabels
            where orderid = l_orderid
              and shipid = l_shipid;
         delete from weber_case_labels
            where orderid = l_orderid
              and shipid = l_shipid;
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

      l_bigseq := 0;
      l_bigseqof := calc_bigseqof(l_orderid, l_shipid, oh.shiptype, l_cons_order);

      if l_cons_order then
         l_wave := zcord.cons_orderid(l_orderid, l_shipid);
      end if;

--  do cartons not on a master
      if l_cons_order and l_orderid != l_wave then   -- order within a consolidated order
         for cp in (select PP.lpid, PP.item, PP.unitofmeasure, PP.quantity, PP.fromlpid,
                           PP.orderlot, PP.lotnumber, PP.orderitem
                     from shippingplate PP
                     where PP.orderid = l_wave
                       and PP.shipid = 0
                       and PP.type = 'C'
                       and PP.parentlpid is null
                       and exists (select * from shippingplate KP
                                    where KP.parentlpid = PP.lpid
                                      and KP.orderid = l_orderid
                                      and KP.shipid = l_shipid)) loop
            for sp in (select distinct lpid, custid, orderid, shipid, item, unitofmeasure,
                              lotnumber, quantity, fromlpid, parentlpid, orderlot, orderitem
                        from shippingplate
                        where orderid = l_orderid
                          and shipid = l_shipid
                          and type in ('F','P')
                          and status != 'U'
                          and parentlpid = cp.lpid
                        order by item, lotnumber, lpid) loop
               add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                     in_action, l_bigseqof, sp.lpid, l_asn_no, sp.fromlpid, oh, false,
                     sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
            end loop;
         end loop;
      else                 -- not consolidated or entire consolidated
         for cp in (select lpid, item, unitofmeasure, quantity, fromlpid, orderlot, lotnumber,
                           orderitem
                     from shippingplate
                     where orderid = l_orderid
                       and shipid = l_shipid
                       and type = 'C'
                       and parentlpid is null) loop
            add_label(l_orderid, l_shipid, cp.item, cp.lotnumber, cp.unitofmeasure,
                  in_action, l_bigseqof, cp.lpid, l_asn_no, cp.fromlpid, oh, not l_cons_order,
                  cp.orderitem, cp.orderlot, cp.quantity, l_bigseq);
         end loop;
      end if;

-- do cartons on a master
      if nvl(oh.shiptype,'?') != 'S' then
         if l_cons_order and l_orderid != l_wave then   -- order within a consolidated order
               for mp in (select lpid, fromlpid, orderid, shipid, quantity, parentlpid
                           from shippingplate
                           where orderid = l_wave
                             and shipid = 0
                             and parentlpid is null
                             and type = 'M') loop
                  for cp in (select PP.lpid
                              from shippingplate PP
                              where PP.parentlpid = mp.lpid
                                and PP.type = 'C'
                                and exists (select * from shippingplate KP
                                             where KP.parentlpid = PP.lpid
                                               and KP.orderid = l_orderid
                                               and KP.shipid = l_shipid)) loop
                     for sp in (select distinct lpid, custid, orderid, shipid, item, unitofmeasure,
                                       lotnumber, quantity, fromlpid, parentlpid, orderlot, orderitem
                                 from shippingplate
                                 where orderid = l_orderid
                                   and shipid = l_shipid
                                   and type in ('F','P')
                                   and status != 'U'
                                   and parentlpid = cp.lpid
                                 order by item, lotnumber, lpid) loop
                        add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                              in_action, l_bigseqof, sp.lpid, l_asn_no, sp.fromlpid, oh, false,
                              sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
                     end loop;
                  end loop;
               end loop;
         else           -- not consolidated or entire consolidated order
            for mp in (select lpid, fromlpid, orderid, shipid, quantity, parentlpid
                        from shippingplate
                        where orderid = l_orderid
                          and shipid = l_shipid
                          and parentlpid is null
                          and type = 'M') loop
               for cp in (select lpid
                           from shippingplate
                           where parentlpid = mp.lpid
                             and type = 'C') loop
                  for sp in (select custid, item, unitofmeasure, lotnumber, orderlot,
                                    sum(quantity) as quantity, orderitem
                              from shippingplate
                              where type in ('F','P')
                              start with lpid = cp.lpid
                              connect by prior lpid = parentlpid
                              group by custid, item, unitofmeasure, lotnumber, orderlot,
                                       orderitem) loop
                     add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                           in_action, l_bigseqof, cp.lpid, l_asn_no, mp.fromlpid, oh, not l_cons_order,
                           sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
                  end loop;
               end loop;
            end loop;
         end if;
      end if;

-- do non-cartons
      if l_cons_order then
         if l_orderid != l_wave then   -- order within a consolidated order
            for sp in (select distinct lpid, custid, orderid, shipid, item, unitofmeasure,
                              lotnumber, quantity, fromlpid, parentlpid, orderlot, orderitem
                  from shippingplate
                  where orderid = l_orderid
                    and shipid = l_shipid
                    and type in ('F','P')
                    and status != 'U'
                    and part_of_carton(type, parentlpid) = 'N'
                  order by item, lotnumber, lpid) loop
               add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                     in_action, l_bigseqof, sp.lpid, l_asn_no, sp.fromlpid, oh, false,
                     sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
            end loop;
         else                 -- entire consolidated order
            for sp in (select distinct SP.lpid, SP.custid, SP.orderid, SP.shipid, SP.item,
                              SP.unitofmeasure, SP.lotnumber, SP.quantity, SP.fromlpid,
                              SP.parentlpid, SP.orderlot, SP.orderitem
                  from shippingplate SP, orderhdr OH
                  where OH.wave = l_wave
                    and SP.orderid = OH.orderid
                    and SP.shipid = OH.shipid
                    and SP.type in ('F','P')
                    and SP.status != 'U'
                    and part_of_carton(SP.type, SP.parentlpid) = 'N'
                  order by SP.item, SP.lotnumber, SP.lpid) loop
               add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                     in_action, l_bigseqof, sp.lpid, l_asn_no, sp.fromlpid, oh, false,
                     sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
            end loop;
         end if;
      else
         for mp in (select lpid, fromlpid, quantity, type, item
                     from shippingplate
                     where orderid = l_orderid
                       and shipid = l_shipid
                       and status != 'U'
                       and type != 'C'
                       and parentlpid is null) loop

            if oh.shiptype = 'S' then
--             small package master, only 1 label but need 1st child to get needed rows
               chlp := null;
               open c_chlp(mp.lpid);
               fetch c_chlp into chlp;
               close c_chlp;
               add_label(l_orderid, l_shipid, mp.item, chlp.lotnumber, chlp.unitofmeasure,
                     in_action, l_bigseqof, mp.lpid, l_asn_no, mp.fromlpid, oh, true,
                     chlp.orderitem, chlp.orderlot, mp.quantity, l_bigseq);
            else
               for sp in (select custid, item, unitofmeasure, lotnumber, orderlot,
                                 sum(quantity) as quantity, orderitem
                           from shippingplate
                           where type in ('F','P')
                             and part_of_carton(type, parentlpid) = 'N'
                           start with lpid = mp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber, orderlot, orderitem
                           order by item) loop
                  add_label(l_orderid, l_shipid, sp.item, sp.lotnumber, sp.unitofmeasure,
                        in_action, l_bigseqof, mp.lpid, l_asn_no, mp.fromlpid, oh, false,
                        sp.orderitem, sp.orderlot, sp.quantity, l_bigseq);
               end loop;
            end if;
         end loop;
      end if;
      if in_action != 'C' then
         commit;
      end if;
   end if;
   if in_action != 'C' then
      out_stmt := 'select * from weber_case_labels where orderid = ' || l_orderid
            || ' and shipid = ' || l_shipid || ' order by bigseq';
      return;
   end if;

   if in_func = 'Q' then
      select count(1) into cntCombined
         from caselabels
         where orderid = l_orderid
           and shipid = l_shipid
           and labeltype in ('CS', 'CQ')
           and nvl(combined,'N') = 'Y';
--    match caselabels with temp ignoring barcode
      for lbl in (select * from caselabels
                     where orderid = l_orderid
                       and shipid = l_shipid) loop

         l_match := 'N';
         for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                        where matched = 'N') loop

            if cntCombined = 0 then
               if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
               and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
               and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
               and nvl(tmp.item,'?') = nvl(lbl.item,'?')
               and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
               and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
               and nvl(tmp.seq,0) = nvl(lbl.seq,0)
               and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
               and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
               and ( nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') or
                     (nvl(tmp.labeltype,'?') = 'CS' and
                      nvl(lbl.labeltype,'?') = 'CQ'
                     )
                   ) then
                  l_match := 'Y';
                  update caselabels_temp
                     set matched = l_match
                     where rowid = tmp.rowid;
                  exit;
               end if;
            else
               if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
               and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
               and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
               and nvl(tmp.item,'?') = nvl(lbl.item,'?')
               and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
               and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
               and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
               and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
               and ( nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') or
                     (nvl(tmp.labeltype,'?') = 'CS' and
                      nvl(lbl.labeltype,'?') = 'CQ'
                     )
                   ) then
                  l_match := 'Y';
                  update caselabels_temp
                     set matched = l_match
                     where rowid = tmp.rowid;
                  exit;
               end if;
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

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
         and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
         and nvl(tmp.seq,0) = nvl(lbl.seq,0)
         and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
         and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
         and ( nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') or
               (nvl(tmp.labeltype,'?') = 'CS' and
                nvl(lbl.labeltype,'?') = 'CQ'
               )
             ) then

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
          'CS');

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
          totalcases)
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
          alt.conspassthruchar10,
          alt.totalcases);
   end loop;
   commit;
   out_stmt := 'select * from weber_case_labels where orderid = ' || l_orderid
         || ' and shipid = ' || l_shipid ||
         ' and nvl(changed,''N'') = ''Y'' order by bigseq';
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
   l_action varchar2(2);
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

      if (in_action in ('A', 'P')) and (l_label_cnt != 0) then
         out_stmt := 'OKAY';
         return;
      end if;

      out_stmt := 'NoWay';
      for oh in (select orderid, shipid from orderhdr
                  where loadno = l_loadno) loop
         if in_action = 'N' then
            select count(1) into l_cnt
               from weber_case_labels
               where orderid = oh.orderid
                 and shipid = oh.shipid;
            if l_cnt = 0 then
               out_stmt := 'OKAY';
               exit;
            end if;
         else
            l_wave := zcord.cons_orderid(oh.orderid, oh.shipid);
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
               ord_lbl(sp.lpid, in_func, in_action, l_msg);
               if l_msg = 'OKAY' then
                  out_stmt := l_msg;
                  exit;
               end if;
            end if;
         end if;
      end loop;
      return;
   end if;

   if (in_action != 'P')
   and (in_action != 'A' or l_label_cnt = 0) then
      for oh in (select orderid, shipid from orderhdr
                  where loadno = l_loadno
                  order by orderid, shipid) loop
         l_wave := zcord.cons_orderid(oh.orderid, oh.shipid);
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
               l_action := 'A';
               select count(1) into l_cnt
                  from weber_case_labels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
            else
               l_action := in_action;
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl(sp.lpid, in_func, l_action, l_msg);
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from weber_case_labels where loadno = ' || l_loadno
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
   l_action varchar2(2);
begin
   out_stmt := null;

   verify_wave(in_lpid, in_func, in_action, l_wave, l_wave_cnt, l_label_cnt, l_cons_order);

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

      if (in_action in ('A', 'P')) and (l_label_cnt != 0) then
         out_stmt := 'OKAY';
         return;
      end if;

      out_stmt := 'NoWay';
      for oh in (select orderid, shipid from orderhdr
                  where wave = l_wave) loop
         if in_action = 'N' then
            select count(1) into l_cnt
               from weber_case_labels
               where orderid = oh.orderid
                 and shipid = oh.shipid;
            if l_cnt = 0 then
               out_stmt := 'OKAY';
               exit;
            end if;
         else
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
               ord_lbl(sp.lpid, in_func, in_action, l_msg);
               if l_msg = 'OKAY' then
                  out_stmt := l_msg;
                  exit;
               end if;
            end if;
         end if;
      end loop;
      return;
   end if;

   if (in_action != 'P')
   and (in_action != 'A' or l_label_cnt = 0) then
      for oh in (select orderid, shipid from orderhdr
                  where wave = l_wave
                  order by orderid, shipid) loop
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
               l_action := 'A';
               select count(1) into l_cnt
                  from weber_case_labels
                  where orderid = oh.orderid
                    and shipid = oh.shipid;
            else
               l_action := in_action;
               l_cnt := 0;
            end if;

            if l_cnt = 0 then
               ord_lbl(sp.lpid, in_func, l_action, l_msg);
            end if;
         end if;
      end loop;
   end if;

   out_stmt := 'select * from weber_case_labels where wave = ' || l_wave
         || ' order by orderid, shipid, bigseq';

end wav_lbl;


procedure lpid_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_termid in varchar2,          -- Terminal ID
    out_stmt  out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select status
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype := null;
   l_lpid shippingplate.lpid%type;
   l_cnt pls_integer;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cons_order boolean;
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
      from weber_case_labels
      where lpid in (select lpid
                  from shippingplate
                  start with lpid = l_lpid
                  connect by prior lpid = parentlpid);

   if l_cnt > 0 then
      if in_func = 'Q' then
         out_stmt := 'OKAY';
      else
         out_stmt := 'select * from weber_case_labels where lpid in'
               || ' (select lpid from shippingplate start with lpid = ''' || l_lpid
               || ''' connect by prior lpid = parentlpid) order by orderid, shipid, bigseq';
         open c_sp(l_lpid);
         fetch c_sp into sp;
         close c_sp;
         if nvl(sp.status,'L') != 'L' then
            zlod.check_plate_load(in_lpid, in_termid, 'LABELLD', errmsg);
            commit;
         end if;
      end if;
      return;
   end if;

   verify_order(l_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt,
         l_label_cnt, l_cons_order);
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

   out_stmt := 'select * from weber_case_labels where lpid = ''' || l_lpid
         || ''' order by orderid, shipid, bigseq';
   if (in_action = 'P') then
      return;
   end if;

   if l_cons_order then
      for oh in (select orderid, shipid from orderhdr
                  where wave = zcord.cons_orderid(l_orderid, l_shipid)) loop
         lpid_lbl_order(l_lpid, in_action, oh.orderid, oh.shipid, l_cons_order);
      end loop;
   else
      lpid_lbl_order(l_lpid, in_action, l_orderid, l_shipid, l_cons_order);
   end if;

-- Check for label load processing
   zlod.check_plate_load(in_lpid, in_termid, 'LABELLD', errmsg);

   commit;

end lpid_lbl;


end weber_caslbls;
/

show errors package body weber_caslbls;
exit;
