create or replace package body logteam_cslbl as
--
-- $Id$
--


--Types


type auxdata is record(
   lpid ucc_standard_labels.lpid%type,
   picktolp ucc_standard_labels.picktolp%type,
   item ucc_standard_labels.item%type,
   quantity ucc_standard_labels.quantity%type,
   weight ucc_standard_labels.weight%type,
   seq ucc_standard_labels.seq%type,
   seqof ucc_standard_labels.seqof%type,
   lotnumber ucc_standard_labels.lotnumber%type,
   shippingtype ucc_standard_labels.shippingtype%type,
   fromfacility ucc_standard_labels.fromfacility%type,
   fromaddr1 ucc_standard_labels.fromaddr1%type,
   fromaddr2 ucc_standard_labels.fromaddr2%type,
   fromcity ucc_standard_labels.fromcity%type,
   fromstate ucc_standard_labels.fromstate%type,
   fromzip ucc_standard_labels.fromzip%type,
   shipfromcountrycode ucc_standard_labels.shipfromcountrycode%type,
   bol ucc_standard_labels.bol%type,
   carriername ucc_standard_labels.carriername%type,
   scac ucc_standard_labels.scac%type,
   sscctype varchar2(2),
   changeproc caselabels.changeproc%type,
   consignee_name consignee.name%type,
   consignee_contact consignee.contact%type,
   consignee_addr1 consignee.addr1%type,
   consignee_addr2 consignee.addr2%type,
   consignee_city consignee.city%type,
   consignee_state consignee.state%type,
   consignee_postalcode consignee.postalcode%type,
   consignee_countrycode consignee.countrycode%type,
   shipto orderhdr.shipto%type);

type dtlpassthru is record(
   dtlpassthruchar01 orderdtl.dtlpassthruchar01%type,
   dtlpassthruchar02 orderdtl.dtlpassthruchar02%type,
   dtlpassthruchar03 orderdtl.dtlpassthruchar03%type,
   dtlpassthruchar04 orderdtl.dtlpassthruchar04%type,
   dtlpassthruchar05 orderdtl.dtlpassthruchar05%type,
   dtlpassthruchar06 orderdtl.dtlpassthruchar06%type,
   dtlpassthruchar07 orderdtl.dtlpassthruchar07%type,
   dtlpassthruchar08 orderdtl.dtlpassthruchar08%type,
   dtlpassthruchar09 orderdtl.dtlpassthruchar09%type,
   dtlpassthruchar10 orderdtl.dtlpassthruchar10%type,
   dtlpassthruchar11 orderdtl.dtlpassthruchar11%type,
   dtlpassthruchar12 orderdtl.dtlpassthruchar12%type,
   dtlpassthruchar13 orderdtl.dtlpassthruchar13%type,
   dtlpassthruchar14 orderdtl.dtlpassthruchar14%type,
   dtlpassthruchar15 orderdtl.dtlpassthruchar15%type,
   dtlpassthruchar16 orderdtl.dtlpassthruchar16%type,
   dtlpassthruchar17 orderdtl.dtlpassthruchar17%type,
   dtlpassthruchar18 orderdtl.dtlpassthruchar18%type,
   dtlpassthruchar19 orderdtl.dtlpassthruchar19%type,
   dtlpassthruchar20 orderdtl.dtlpassthruchar20%type,
   dtlpassthruchar21 orderdtl.dtlpassthruchar21%type,
   dtlpassthruchar22 orderdtl.dtlpassthruchar22%type,
   dtlpassthruchar23 orderdtl.dtlpassthruchar23%type,
   dtlpassthruchar24 orderdtl.dtlpassthruchar24%type,
   dtlpassthruchar25 orderdtl.dtlpassthruchar25%type,
   dtlpassthruchar26 orderdtl.dtlpassthruchar26%type,
   dtlpassthruchar27 orderdtl.dtlpassthruchar27%type,
   dtlpassthruchar28 orderdtl.dtlpassthruchar28%type,
   dtlpassthruchar29 orderdtl.dtlpassthruchar29%type,
   dtlpassthruchar30 orderdtl.dtlpassthruchar30%type,
   dtlpassthruchar31 orderdtl.dtlpassthruchar31%type,
   dtlpassthruchar32 orderdtl.dtlpassthruchar32%type,
   dtlpassthruchar33 orderdtl.dtlpassthruchar33%type,
   dtlpassthruchar34 orderdtl.dtlpassthruchar34%type,
   dtlpassthruchar35 orderdtl.dtlpassthruchar35%type,
   dtlpassthruchar36 orderdtl.dtlpassthruchar36%type,
   dtlpassthruchar37 orderdtl.dtlpassthruchar37%type,
   dtlpassthruchar38 orderdtl.dtlpassthruchar38%type,
   dtlpassthruchar39 orderdtl.dtlpassthruchar39%type,
   dtlpassthruchar40 orderdtl.dtlpassthruchar40%type,
   dtlpassthrunum01 orderdtl.dtlpassthrunum01%type,
   dtlpassthrunum02 orderdtl.dtlpassthrunum02%type,
   dtlpassthrunum03 orderdtl.dtlpassthrunum03%type,
   dtlpassthrunum04 orderdtl.dtlpassthrunum04%type,
   dtlpassthrunum05 orderdtl.dtlpassthrunum05%type,
   dtlpassthrunum06 orderdtl.dtlpassthrunum06%type,
   dtlpassthrunum07 orderdtl.dtlpassthrunum07%type,
   dtlpassthrunum08 orderdtl.dtlpassthrunum08%type,
   dtlpassthrunum09 orderdtl.dtlpassthrunum09%type,
   dtlpassthrunum10 orderdtl.dtlpassthrunum10%type,
   dtlpassthrunum11 orderdtl.dtlpassthrunum11%type,
   dtlpassthrunum12 orderdtl.dtlpassthrunum12%type,
   dtlpassthrunum13 orderdtl.dtlpassthrunum13%type,
   dtlpassthrunum14 orderdtl.dtlpassthrunum14%type,
   dtlpassthrunum15 orderdtl.dtlpassthrunum15%type,
   dtlpassthrunum16 orderdtl.dtlpassthrunum16%type,
   dtlpassthrunum17 orderdtl.dtlpassthrunum17%type,
   dtlpassthrunum18 orderdtl.dtlpassthrunum18%type,
   dtlpassthrunum19 orderdtl.dtlpassthrunum19%type,
   dtlpassthrunum20 orderdtl.dtlpassthrunum20%type,
   dtlpassthrudate01 orderdtl.dtlpassthrudate01%type,
   dtlpassthrudate02 orderdtl.dtlpassthrudate02%type,
   dtlpassthrudate03 orderdtl.dtlpassthrudate03%type,
   dtlpassthrudate04 orderdtl.dtlpassthrudate04%type,
   dtlpassthrudoll01 orderdtl.dtlpassthrudoll01%type,
   dtlpassthrudoll02 orderdtl.dtlpassthrudoll02%type,
   consigneesku orderdtl.consigneesku%type,
   upc custitemalias.itemalias%type);

type key_table is record (
   fieldname user_tab_columns.column_name%type,
   fieldvalue orderhdr.hdrpassthruchar01%type,
   viewname user_views.view_name%type );

type key_val is table of key_table index by pls_integer;
key_values key_val;

type ordrectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type,
   picked boolean,
   usebatch boolean);
type ordtbltype is table of ordrectype index by binary_integer;
ord_tbl ordtbltype;


-- Private


function duplicate_cnt
   (in_oh in orderhdr%rowtype)
return number
is
begin
-- 2 copies for kmart and walgreens non small package orders
   if (nvl(in_oh.hdrpassthruchar05, '(none)') in ('141627', '10485'))
   and (in_oh.shiptype != 'S') then
      return 2;
   end if;

   return 1;
end duplicate_cnt;


procedure load_key_values is
begin

-- Load the vaules for the field, value, and view name for each 'shipto'
-- customer.
   key_values(1).fieldname := 'CUSTID';
   key_values(1).fieldvalue := 'HUG001';  -- bed bath and beyond
   key_values(1).viewname := 'LBL_BEDBATH_VIEW';
   key_values(2).fieldname := 'HDRPASSTHRUCHAR01';
   key_values(2).fieldvalue := '(NOTNULL)';  -- hptc01notnull
   key_values(2).viewname := 'LBL_SB_VIEW';
   key_values(3).fieldname := null;
   key_values(3).fieldvalue := 'innerpack';  -- innerpack
   key_values(3).viewname := 'LBL_SB_VIEW';
   return;
end load_key_values;


function find_key_value_idx (value varchar2) return number
is
   i pls_integer;
begin
   -- find the value in the key_values data to get the index.
   for i in 1..key_values.last loop
      if( nvl(key_values(i).fieldvalue,'x') = nvl(value,'x')) then
         return i;
      end if;
   end loop;
   return 0;
end find_key_value_idx;


procedure check_order
   (in_orderid  in number,
    in_shipid   in number,
    in_customer in varchar2,
    in_idx      in pls_integer)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.orderstatus, nvl(WV.picktype,'ORDR') as picktype
         from orderhdr OH, waves WV
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and WV.wave (+) = OH.wave;
   oh c_oh%rowtype := null;
   i binary_integer;
   l_sql varchar2(1024);
   l_cnt pls_integer := 0;
   l_taskcnt pls_integer := 0;
   l_val varchar2(255);
   l_picked boolean := false;
   l_usebatch boolean := false;
begin
   if key_values(in_idx).fieldname is null then
      null;    -- no check
   elsif key_values(in_idx).fieldvalue = '(NOTNULL)' then
      l_sql := 'select count(1) from orderhdr'
            || ' where orderid = ' || in_orderid
            || ' and shipid = ' || in_shipid
            || ' and ' || key_values(in_idx).fieldname || ' is not null';
      execute immediate l_sql into l_cnt;
      if l_cnt = 0 then
         return;
      end if;
   else
      l_sql := 'select ' || key_values(in_idx).fieldname || ' from orderhdr'
            || ' where orderid = ' || in_orderid
            || ' and shipid = ' || in_shipid;
      begin
         execute immediate l_sql into l_val;
      exception when others then
         return;
      end;

      if sql%rowcount = 0 THEN
         return;
      end if;

      -- check the value.
      if nvl(l_val,'(none)') != nvl(in_customer,'(none)') then
         return;
      end if;
   end if;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   if oh.orderstatus = '4' then
      l_picked := false;
      if oh.picktype = 'BAT' then
         select count(1) into l_taskcnt
            from batchtasks
            where orderid = in_orderid
              and shipid = in_shipid;
         select count(1) into l_cnt
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid;
         if l_taskcnt = 0 and l_cnt != 0 then
            l_usebatch := false;
         elsif l_taskcnt != 0 and l_cnt = 0 then
            l_usebatch := true;
         else
            return;
         end if;
      end if;
   elsif oh.orderstatus in ('6','7','8','9') then
      l_picked := true;
   else
      return;
   end if;

   i := ord_tbl.count+1;
   ord_tbl(i).orderid := in_orderid;
   ord_tbl(i).shipid := in_shipid;
   ord_tbl(i).picked := l_picked;
   ord_tbl(i).usebatch := l_usebatch;
end check_order;


procedure verify_order
   (in_lpid         in varchar2,
    in_auxdata      in varchar2,
    in_func         in varchar2,
    in_action       in varchar2,
    in_customer     in varchar2,
    out_msg         out varchar2,
    out_view        out varchar2,
    out_consorderid out number)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;
   l_pos number;
   l_order varchar2(255);
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   idx pls_integer := 0;
   i binary_integer;
   l_cnt pls_integer := 0;
begin
   out_msg := null;
   out_view := null;
   out_consorderid := null;

-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

-- Verify action
   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;

-- Parse out orderid/shipid from auxdata
   l_pos := instr(in_auxdata, '|');
   if l_pos != 0 then
      if upper(substr(in_auxdata, 1, l_pos-1)) = 'ORDER' then
         l_order := substr(in_auxdata, l_pos+1);
         l_pos := instr(l_order, '|');
         if l_pos != 0 then
            l_orderid := to_number(substr(l_order, 1, l_pos-1));
            l_shipid := to_number(substr(l_order, l_pos+1));
         end if;
      end if;
   end if;

   if l_orderid is null then
      if in_func = 'Q' then
         out_msg := 'Order not found';
      end if;
      return;
   end if;

-- Load the translation table.
   load_key_values;

-- get the field to look at.
   idx := find_key_value_idx(in_customer);
   if idx = 0 then
      if in_func = 'Q' then
         out_msg := 'Table error on shipto';
      end if;
      return;
   else
      out_view := key_values(idx).viewname;
   end if;

   ord_tbl.delete;

   if l_shipid != 0 then
      check_order(l_orderid, l_shipid, in_customer, idx);
   else
      for oh in (select orderid, shipid from orderhdr
                  where wave = l_orderid) loop
         check_order(oh.orderid, oh.shipid, in_customer, idx);
      end loop;
      out_consorderid := l_orderid;
   end if;

   if ord_tbl.count = 0 then
      if in_func = 'Q' then
         out_msg := 'Nothing for order';
      end if;
      return;
   end if;

   l_cnt := 0;
   for i in 1..ord_tbl.count loop
      if ord_tbl(i).picked then
         l_cnt := l_cnt + 1;
      end if;
   end loop;

   if l_cnt != 0 and l_cnt != ord_tbl.count then
      if in_func = 'Q' then
         out_msg := 'Mixed order status';
      end if;
      return;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         if out_consorderid is not null then
            select count(1) into l_cnt
               from ucc_standard_labels
               where wave = out_consorderid;
         else
            select count(1) into l_cnt
               from ucc_standard_labels
               where orderid = l_orderid
                 and shipid = l_shipid;
         end if;
         if l_cnt = 0 then
            out_msg := 'Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         if out_consorderid is not null then
            open c_wav(out_consorderid);
            fetch c_wav into oh;
            close c_wav;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || key_values(idx).viewname ||' L , zseq Z'
                  || ' where L.wave = ' || out_consorderid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(l_orderid, l_shipid);
            fetch c_oh into oh;
            close c_oh;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || key_values(idx).viewname ||' L , zseq Z'
                  || ' where L.orderid = ' || l_orderid
                  || ' and L.shipid = ' || l_shipid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_order;


procedure init_lblgroup
   (in_orderid     in number,
    in_shipid      in number,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_sscctype    in varchar2,
    in_procname    in varchar2,
    in_action      in varchar2,
    in_uom         in varchar2,
    in_lbltype     in varchar2,
    out_aux        out auxdata)
is
   cursor c_ord(p_orderid number, p_shipid number) is
      select FA.name as faname,
             FA.addr1,
             FA.addr2,
             FA.city,
             FA.state,
             FA.postalcode,
             FA.countrycode,
             CA.name as caname,
             CA.scac
         from orderhdr OH, facility FA, carrier CA
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and FA.facility = OH.fromfacility
           and CA.carrier (+) = OH.carrier;
   ord c_ord%rowtype;

  cursor c_consignee(p_orderid number, p_shipid number) is
     select nvl(oh.shiptoname, c.name) name,
            nvl(oh.shiptocontact, c.contact) contact,
            nvl(oh.shiptoaddr1, c.addr1) addr1,
            nvl(oh.shiptoaddr2, c.addr2) addr2,
            nvl(oh.shiptocity, c.city) city,
            nvl(oh.shiptostate, c.state) state,
            nvl(oh.shiptopostalcode, c.postalcode) postalcode,
            nvl(oh.shiptocountrycode, c.countrycode) countrycode,
            oh.shipto shipto
       from orderhdr oh, consignee c
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid
        and c.consignee (+) = oh.shipto;
  consignee_rec c_consignee%rowtype;
  l_uom varchar2(3);
begin
   out_aux := null;
   out_aux.quantity := 0;
   out_aux.weight := 0;
   out_aux.seq := 0;
   out_aux.seqof := 0;
   if in_uom is null then
      l_uom := 'CTN';
   else
      l_uom := in_uom;
   end if;

   if in_picked then
      if in_consorderid is not null then
         -- picked consolidated order
         for sp in (select custid, item, unitofmeasure, lotnumber,
                           sum(quantity) as quantity
                     from shippingplate
                     where type in ('F','P')
                       and orderid = in_orderid
                       and shipid = in_shipid
                     group by custid, item, unitofmeasure, lotnumber) loop
            out_aux.seqof := out_aux.seqof
                  + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_uom);
         end loop;
      else
         -- picked non-consolidated order
         for pp in (select lpid, type from shippingplate
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and parentlpid is null) loop
            if pp.type = 'C' and in_lbltype != 'I' then
               out_aux.seqof := out_aux.seqof + 1;
            else
               for cp in (select custid, item, unitofmeasure, lotnumber,
                                 sum(quantity) as quantity
                           from shippingplate
                           where type in ('F','P')
                           start with lpid = pp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber) loop
                  out_aux.seqof := out_aux.seqof
                        + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_uom);
               end loop;
            end if;
         end loop;
      end if;

   elsif in_consorderid is not null or in_usebatch then
      -- unpicked consolidated order or unpicked non-consolidated batch pick order
      for bt in (select custid, item, uom, orderlot, sum(qty) as qty
                  from batchtasks
                  where orderid = in_orderid
                    and shipid = in_shipid
                  group by custid, item, uom, orderlot) loop
         out_aux.seqof := out_aux.seqof
               + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_uom);
      end loop;
   else
      -- unpicked non-consolidated non-batch pick order
      for sp in (select custid, item, unitofmeasure, lotnumber,
                        sum(quantity) as quantity
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                  group by custid, item, unitofmeasure, lotnumber) loop
         out_aux.seqof := out_aux.seqof
               + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_uom);
      end loop;
   end if;

   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;
   out_aux.fromfacility := ord.faname;
   out_aux.fromaddr1 := ord.addr1;
   out_aux.fromaddr2 := ord.addr2;
   out_aux.fromcity := ord.city;
   out_aux.fromstate := ord.state;
   out_aux.fromzip := ord.postalcode;
   out_aux.shipfromcountrycode := ord.countrycode;
   out_aux.bol := zedi.get_custom_bol(in_orderid, in_shipid);
   out_aux.carriername := ord.caname;
   out_aux.scac := ord.scac;

   open c_consignee(in_orderid, in_shipid);
   fetch c_consignee into consignee_rec;
   close c_consignee;
   out_aux.consignee_name := consignee_rec.name;
   out_aux.consignee_addr1 := consignee_rec.addr1;
   out_aux.consignee_addr2 := consignee_rec.addr2;
   out_aux.consignee_city := consignee_rec.city;
   out_aux.consignee_state := consignee_rec.state;
   out_aux.consignee_postalcode := consignee_rec.postalcode;
   out_aux.consignee_countrycode := consignee_rec.countrycode;
   out_aux.shipto := consignee_rec.shipto;

   out_aux.sscctype := in_sscctype;
   out_aux.changeproc := 'logteam_cslbl.'||upper(in_procname);

   if in_action = 'A' then
      delete from ucc_standard_labels
         where orderid = in_orderid
           and shipid = in_shipid;
      delete from caselabels
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;

   delete caselabels_temp;
   delete ucc_standard_labels_temp;

end init_lblgroup;


function sscc14_barcode
   (in_custid in varchar2,
    in_type   in varchar2)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc
         from customer
         where custid = in_custid;
   manucc customer.manufacturerucc%type := null;
   barcode varchar2(14);
   seqname varchar2(30);
   seqval varchar2(5);
   ix integer;
   cc integer;
   cnt integer;
begin
   open c_cust;
   fetch c_cust into manucc;
   close c_cust;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   seqname := 'SSCC14_' || manucc || '_SEQ';
   select count(1)
      into cnt
      from user_sequences
      where sequence_name = seqname;

   if cnt = 0 then
      execute immediate 'create sequence ' || seqname
            || ' increment by 1 start with 1 maxvalue 99999 minvalue 1 nocache cycle';
   end if;

   execute immediate 'select lpad(' || seqname || '.nextval, 5, ''0'') from dual'
      into seqval;

   barcode := lpad(substr(in_type, 1, 1), 1, '1') || manucc || seqval;

   cc := 0;
   for cnt in 1..13 loop
      ix := substr(barcode, cnt, 1);

      if mod(cnt, 2) = 0 then
         cc := cc + ix;
      else
         cc := cc + (3 * ix);
      end if;
   end loop;

   cc := mod(10 - mod(cc, 10), 10);
   barcode := barcode || to_char(cc);
   commit;
   return barcode;

exception
  when others then
      rollback;
      return '00000000000000';
end sscc14_barcode;


procedure add_label
   (in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru,
    in_action  in varchar2,
    in_lbltype in varchar2,
    in_part    in varchar2,
    io_aux     in out auxdata)
is
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select item, descr, weight
         from custitem
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;
   l_sscc varchar2(20);
   l_ssccfmt varchar2(40);
   l_barcodetype varchar2(1);
   l_rowid varchar2(20);
   l_labeltype caselabels.labeltype%type;
   l_lbltypedesc ucc_standard_labels.lbltypedesc%type;
   l_postalcode varchar2(20);
   l_postalcodehuman varchar2(20);
   l_postalcodebar varchar2(20);
   l_custname varchar2(40);
   l_zip_prefix varchar2(3);
   cursor c_cust (in_custid varchar2) is
      select name
         from customer
         where custid = in_custid;

begin
   if in_lbltype = 'S' then
      l_labeltype := 'CS';
      if in_oh.shiptype = 'S' then
         l_barcodetype := '0';
         l_lbltypedesc := 'carton';
      else
         l_barcodetype := '0';
         l_lbltypedesc := 'carton';
      end if;
   elsif in_lbltype = 'I' then
      l_labeltype := 'IP';
      l_barcodetype := '0';
      l_lbltypedesc := 'innerpack';
   else
      l_labeltype := 'CS';
      l_barcodetype := '0';
      l_lbltypedesc := 'carton';
   end if;

   if io_aux.item is null then
      itm.item := 'Mixed';
      itm.descr := 'Mixed';
      itm.weight := null;
   else
      open c_itm(in_oh.custid, io_aux.item);
      fetch c_itm into itm;
      close c_itm;
   end if;
   if nvl(in_oh.shiptocountrycode,'USA') in ('US','USA','840') then
      l_zip_prefix := '420';
   else
      l_zip_prefix := '421';
   end if;
   l_postalcode := nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode);
   if length(l_postalcode) = 7 then
      l_postalcodebar := l_zip_prefix||substr(l_postalcode,1,7);
      l_postalcodehuman := '('||l_zip_prefix||')'||substr(l_postalcode,1,7);
   else
      l_postalcodebar := l_zip_prefix ||substr(l_postalcode,1,5);
      l_postalcodehuman := '(' || l_zip_prefix || ')'||substr(l_postalcode,1,5);
   end if;
   l_custname := null;
   open c_cust(in_oh.custid);
   fetch c_cust into l_custname;
   close c_cust;

   io_aux.seq := io_aux.seq + 1;

   if in_action = 'A' then
      if io_aux.sscctype = '18' then
         l_sscc := zlbl.caselabel_barcode(in_oh.custid, l_barcodetype);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      else
         l_sscc := sscc14_barcode(in_oh.custid, l_barcodetype);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;
      insert into ucc_standard_labels
         (sscc,
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
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          custname,
          iteminner,
          itemweight,
          vendhuman,
          vendbar)
      values
         (l_sscc,
          l_ssccfmt,
          io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          in_oh.wave,
          itm.item,
          itm.descr,
          io_aux.quantity,
          io_aux.weight,
          io_aux.seq,
          io_aux.seqof,
          in_lbltype,
          sysdate,
          nvl(in_oh.shiptoname, io_aux.consignee_name),
          nvl(in_oh.shiptocontact, io_aux.consignee_contact),
          nvl(in_oh.shiptoaddr1, io_aux.consignee_addr1),
          nvl(in_oh.shiptoaddr2, io_aux.consignee_addr2),
          nvl(in_oh.shiptocity, io_aux.consignee_city),
          nvl(in_oh.shiptostate, io_aux.consignee_state),
          nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          nvl(in_oh.shiptocountrycode, io_aux.consignee_countrycode),
          io_aux.fromfacility,
          io_aux.fromaddr1,
          io_aux.fromaddr2,
          io_aux.fromcity,
          io_aux.fromstate,
          io_aux.fromzip,
          io_aux.shipfromcountrycode,
          in_oh.prono,
          io_aux.bol,
          in_oh.po,
          in_oh.reference,
          io_aux.carriername,
          io_aux.scac,
          io_aux.lotnumber,
          io_aux.shippingtype,
          in_oh.custid,
          in_oh.fromfacility,
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
          nvl(in_oh.hdrpassthruchar33, in_oh.hdrpassthruchar50),
          in_oh.hdrpassthruchar34,
          in_oh.hdrpassthruchar35,
          in_oh.hdrpassthruchar36,
          in_oh.hdrpassthruchar37,
          in_oh.hdrpassthruchar38,
          in_oh.hdrpassthruchar39,
          in_oh.hdrpassthruchar40,
          in_oh.hdrpassthruchar41,
          in_oh.hdrpassthruchar42,
          in_oh.hdrpassthruchar43,
          in_oh.hdrpassthruchar44,
          in_oh.hdrpassthruchar45,
          in_oh.hdrpassthruchar46,
          in_oh.hdrpassthruchar47,
          in_oh.hdrpassthruchar48,
          in_oh.hdrpassthruchar49,
          nvl(in_oh.hdrpassthruchar50, in_oh.hdrpassthruchar33),
          in_oh.hdrpassthruchar51,
          in_oh.hdrpassthruchar52,
          in_oh.hdrpassthruchar53,
          in_oh.hdrpassthruchar54,
          in_oh.hdrpassthruchar55,
          in_oh.hdrpassthruchar56,
          in_oh.hdrpassthruchar57,
          in_oh.hdrpassthruchar58,
          in_oh.hdrpassthruchar59,
          in_oh.hdrpassthruchar60,
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
          in_oh.hdrpassthrudate01,
          in_oh.hdrpassthrudate02,
          in_oh.hdrpassthrudate03,
          in_oh.hdrpassthrudate04,
          in_oh.hdrpassthrudoll01,
          in_oh.hdrpassthrudoll02,
          in_od.dtlpassthruchar01,
          in_od.dtlpassthruchar02,
          in_od.dtlpassthruchar03,
          in_od.dtlpassthruchar04,
          in_od.dtlpassthruchar05,
          in_od.dtlpassthruchar06,
          in_od.dtlpassthruchar07,
          in_od.dtlpassthruchar08,
          in_od.dtlpassthruchar09,
          in_od.dtlpassthruchar10,
          in_od.dtlpassthruchar11,
          in_od.dtlpassthruchar12,
          in_od.dtlpassthruchar13,
          in_od.dtlpassthruchar14,
          in_od.dtlpassthruchar15,
          in_od.dtlpassthruchar16,
          in_od.dtlpassthruchar17,
          in_od.dtlpassthruchar18,
          in_od.dtlpassthruchar19,
          in_od.dtlpassthruchar20,
          in_od.dtlpassthruchar21,
          in_od.dtlpassthruchar22,
          in_od.dtlpassthruchar23,
          in_od.dtlpassthruchar24,
          in_od.dtlpassthruchar25,
          in_od.dtlpassthruchar26,
          in_od.dtlpassthruchar27,
          in_od.dtlpassthruchar28,
          in_od.dtlpassthruchar29,
          in_od.dtlpassthruchar30,
          in_od.dtlpassthruchar31,
          in_od.dtlpassthruchar32,
          in_od.dtlpassthruchar33,
          in_od.dtlpassthruchar34,
          in_od.dtlpassthruchar35,
          in_od.dtlpassthruchar36,
          in_od.dtlpassthruchar37,
          in_od.dtlpassthruchar38,
          in_od.dtlpassthruchar39,
          in_od.dtlpassthruchar40,
          in_od.dtlpassthrunum01,
          in_od.dtlpassthrunum02,
          in_od.dtlpassthrunum03,
          in_od.dtlpassthrunum04,
          in_od.dtlpassthrunum05,
          in_od.dtlpassthrunum06,
          in_od.dtlpassthrunum07,
          in_od.dtlpassthrunum08,
          in_od.dtlpassthrunum09,
          in_od.dtlpassthrunum10,
          in_od.dtlpassthrunum11,
          in_od.dtlpassthrunum12,
          in_od.dtlpassthrunum13,
          in_od.dtlpassthrunum14,
          in_od.dtlpassthrunum15,
          in_od.dtlpassthrunum16,
          in_od.dtlpassthrunum17,
          in_od.dtlpassthrunum18,
          in_od.dtlpassthrunum19,
          in_od.dtlpassthrunum20,
          in_od.dtlpassthrudate01,
          in_od.dtlpassthrudate02,
          in_od.dtlpassthrudate03,
          in_od.dtlpassthrudate04,
          in_od.dtlpassthrudoll01,
          in_od.dtlpassthrudoll02,
          in_od.consigneesku,
          in_od.upc,
          l_postalcodebar,
          l_postalcodehuman,
          '',
          '',
          '',
          '',
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          l_custname,
          zuccnl.item_in_uom_to_innerpack(in_oh.custid,itm.item),
          itm.weight,
          '(90)'|| in_oh.hdrpassthruchar05,
          '90'|| in_oh.hdrpassthruchar05);

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
          changeproc)
      values
         (in_oh.orderid,
          in_oh.shipid,
          in_oh.custid,
          io_aux.item,
          io_aux.lotnumber,
          io_aux.lpid,
          l_sscc,
          io_aux.seq,
          io_aux.seqof,
          sysdate,
          'ucc_standard_labels',
          'sscc',
          io_aux.quantity,
          l_labeltype,
          io_aux.changeproc);
   else
      insert into ucc_standard_labels_temp
         (lpid,
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
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          custname,
          iteminner,
          itemweight,
          vendhuman,
          vendbar)
      values
         (io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          in_oh.wave,
          itm.item,
          itm.descr,
          io_aux.quantity,
          io_aux.weight,
          io_aux.seq,
          io_aux.seqof,
          in_lbltype,
          nvl(in_oh.shiptoname, io_aux.consignee_name),
          nvl(in_oh.shiptocontact, io_aux.consignee_contact),
          nvl(in_oh.shiptoaddr1, io_aux.consignee_addr1),
          nvl(in_oh.shiptoaddr2, io_aux.consignee_addr2),
          nvl(in_oh.shiptocity, io_aux.consignee_city),
          nvl(in_oh.shiptostate, io_aux.consignee_state),
          nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          nvl(in_oh.shiptocountrycode, io_aux.consignee_countrycode),
          io_aux.fromfacility,
          io_aux.fromaddr1,
          io_aux.fromaddr2,
          io_aux.fromcity,
          io_aux.fromstate,
          io_aux.fromzip,
          io_aux.shipfromcountrycode,
          in_oh.prono,
          io_aux.bol,
          in_oh.po,
          in_oh.reference,
          io_aux.carriername,
          io_aux.scac,
          io_aux.lotnumber,
          io_aux.shippingtype,
          in_oh.custid,
          in_oh.fromfacility,
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
          nvl(in_oh.hdrpassthruchar33, in_oh.hdrpassthruchar50),
          in_oh.hdrpassthruchar34,
          in_oh.hdrpassthruchar35,
          in_oh.hdrpassthruchar36,
          in_oh.hdrpassthruchar37,
          in_oh.hdrpassthruchar38,
          in_oh.hdrpassthruchar39,
          in_oh.hdrpassthruchar40,
          in_oh.hdrpassthruchar41,
          in_oh.hdrpassthruchar42,
          in_oh.hdrpassthruchar43,
          in_oh.hdrpassthruchar44,
          in_oh.hdrpassthruchar45,
          in_oh.hdrpassthruchar46,
          in_oh.hdrpassthruchar47,
          in_oh.hdrpassthruchar48,
          in_oh.hdrpassthruchar49,
          nvl(in_oh.hdrpassthruchar50, in_oh.hdrpassthruchar33),
          in_oh.hdrpassthruchar51,
          in_oh.hdrpassthruchar52,
          in_oh.hdrpassthruchar53,
          in_oh.hdrpassthruchar54,
          in_oh.hdrpassthruchar55,
          in_oh.hdrpassthruchar56,
          in_oh.hdrpassthruchar57,
          in_oh.hdrpassthruchar58,
          in_oh.hdrpassthruchar59,
          in_oh.hdrpassthruchar60,
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
          in_oh.hdrpassthrudate01,
          in_oh.hdrpassthrudate02,
          in_oh.hdrpassthrudate03,
          in_oh.hdrpassthrudate04,
          in_oh.hdrpassthrudoll01,
          in_oh.hdrpassthrudoll02,
          in_od.dtlpassthruchar01,
          in_od.dtlpassthruchar02,
          in_od.dtlpassthruchar03,
          in_od.dtlpassthruchar04,
          in_od.dtlpassthruchar05,
          in_od.dtlpassthruchar06,
          in_od.dtlpassthruchar07,
          in_od.dtlpassthruchar08,
          in_od.dtlpassthruchar09,
          in_od.dtlpassthruchar10,
          in_od.dtlpassthruchar11,
          in_od.dtlpassthruchar12,
          in_od.dtlpassthruchar13,
          in_od.dtlpassthruchar14,
          in_od.dtlpassthruchar15,
          in_od.dtlpassthruchar16,
          in_od.dtlpassthruchar17,
          in_od.dtlpassthruchar18,
          in_od.dtlpassthruchar19,
          in_od.dtlpassthruchar20,
          in_od.dtlpassthruchar21,
          in_od.dtlpassthruchar22,
          in_od.dtlpassthruchar23,
          in_od.dtlpassthruchar24,
          in_od.dtlpassthruchar25,
          in_od.dtlpassthruchar26,
          in_od.dtlpassthruchar27,
          in_od.dtlpassthruchar28,
          in_od.dtlpassthruchar29,
          in_od.dtlpassthruchar30,
          in_od.dtlpassthruchar31,
          in_od.dtlpassthruchar32,
          in_od.dtlpassthruchar33,
          in_od.dtlpassthruchar34,
          in_od.dtlpassthruchar35,
          in_od.dtlpassthruchar36,
          in_od.dtlpassthruchar37,
          in_od.dtlpassthruchar38,
          in_od.dtlpassthruchar39,
          in_od.dtlpassthruchar40,
          in_od.dtlpassthrunum01,
          in_od.dtlpassthrunum02,
          in_od.dtlpassthrunum03,
          in_od.dtlpassthrunum04,
          in_od.dtlpassthrunum05,
          in_od.dtlpassthrunum06,
          in_od.dtlpassthrunum07,
          in_od.dtlpassthrunum08,
          in_od.dtlpassthrunum09,
          in_od.dtlpassthrunum10,
          in_od.dtlpassthrunum11,
          in_od.dtlpassthrunum12,
          in_od.dtlpassthrunum13,
          in_od.dtlpassthrunum14,
          in_od.dtlpassthrunum15,
          in_od.dtlpassthrunum16,
          in_od.dtlpassthrunum17,
          in_od.dtlpassthrunum18,
          in_od.dtlpassthrunum19,
          in_od.dtlpassthrunum20,
          in_od.dtlpassthrudate01,
          in_od.dtlpassthrudate02,
          in_od.dtlpassthrudate03,
          in_od.dtlpassthrudate04,
          in_od.dtlpassthrudoll01,
          in_od.dtlpassthrudoll02,
          in_od.consigneesku,
          in_od.upc,
          l_postalcodebar,
          l_postalcodehuman,
          '',
          '',
          '',
          '',
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          l_custname,
          zuccnl.item_in_uom_to_innerpack(in_oh.custid,itm.item),
          itm.weight,
          '(90)'|| in_oh.hdrpassthruchar05,
          '90'|| in_oh.hdrpassthruchar05)
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
         (in_oh.orderid,
          in_oh.shipid,
          in_oh.custid,
          io_aux.item,
          io_aux.lotnumber,
          io_aux.lpid,
          io_aux.seq,
          io_aux.seqof,
          io_aux.quantity,
          l_labeltype,
          l_barcodetype,
          l_rowid,
          'N');
   end if;

end add_label;


procedure match_labels
   (in_orderid in number,
    in_shipid  in number,
    out_stmt   out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select fromlpid
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype;
   l_match varchar2(1);
   l_cnt pls_integer;
   l_barcode caselabels.barcode%type;
begin
   out_stmt := null;

-- match caselabels with temp ignoring barcode
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = in_orderid
                    and shipid = in_shipid) loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
         and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
         and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
         and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then

            l_match := 'Y';
            update caselabels_temp
               set matched = l_match
               where rowid = tmp.rowid;

            if nvl(tmp.lpid,'?') != nvl(lbl.lpid,'?') then
               update caselabels
                  set lpid = tmp.lpid
                  where rowid = lbl.rowid
                  returning barcode into l_barcode;

               sp := null;
               open c_sp(tmp.lpid);
               fetch c_sp into sp;
               close c_sp;

               update ucc_standard_labels
                  set lpid = tmp.lpid,
                      picktolp = sp.fromlpid
                  where sscc = l_barcode;
            end if;

            exit;
         end if;
      end loop;

      if l_match = 'N' then
         out_stmt := 'OKAY';
         exit;
      end if;
   end loop;

-- each caselabel is also in temp, check for extras in temp
   if out_stmt is null then
      select count(1) into l_cnt
         from caselabels_temp
         where matched = 'N';
      if l_cnt > 0 then
         out_stmt := 'OKAY';
      end if;
   end if;

   if out_stmt is null then
      out_stmt := 'Nothing for order';
   end if;

end match_labels;


procedure merge_labels
   (in_oh    in orderhdr%rowtype,
    in_aux   in auxdata)
is
   cursor c_alt(p_rowid varchar2) is
      select *
         from ucc_standard_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   l_match varchar2(1);
   l_sscc varchar2(20);
   l_ssccfmt varchar2(40);
begin
-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = in_oh.orderid
                    and shipid = in_oh.shipid) loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
         and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
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
   delete ucc_standard_labels
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid
        and sscc in (select barcode from caselabels
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                       and matched = 'N');
   delete caselabels
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid
        and matched = 'N';

-- add new data
   update ucc_standard_labels
      set changed = 'N'
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid;

   for tmp in (select * from caselabels_temp
                  where matched = 'N') loop


      if in_aux.sscctype = '18' then
         l_sscc := zlbl.caselabel_barcode(tmp.custid, tmp.barcodetype);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      else
         l_sscc := sscc14_barcode(tmp.custid, tmp.barcodetype);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;

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
          changeproc)
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
          'ucc_standard_labels',
          'sscc',
          tmp.quantity,
          tmp.labeltype,
          in_aux.changeproc);

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;

      insert into ucc_standard_labels
         (sscc,
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
          consigneesku,
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
          shipto,
          custname,
          iteminner,
          itemweight,
          vendhuman,
          vendbar)
      values
         (l_sscc,
          l_ssccfmt,
          alt.lpid,
          alt.picktolp,
          alt.orderid,
          alt.shipid,
          alt.loadno,
          alt.wave,
          alt.item,
          alt.itemdescr,
          alt.quantity,
          alt.weight,
          alt.seq,
          alt.seqof,
          alt.lbltype,
          sysdate,
          alt.shiptoname,
          alt.shiptocontact,
          alt.shiptoaddr1,
          alt.shiptoaddr2,
          alt.shiptocity,
          alt.shiptostate,
          alt.shiptozip,
          alt.shiptocountrycode,
          alt.fromfacility,
          alt.fromaddr1,
          alt.fromaddr2,
          alt.fromcity,
          alt.fromstate,
          alt.fromzip,
          alt.shipfromcountrycode,
          alt.pro,
          alt.bol,
          alt.po,
          alt.reference,
          alt.carriername,
          alt.scac,
          alt.lotnumber,
          alt.shippingtype,
          alt.custid,
          alt.facility,
          alt.hdrpasschar01,
          alt.hdrpasschar02,
          alt.hdrpasschar03,
          alt.hdrpasschar04,
          alt.hdrpasschar05,
          alt.hdrpasschar06,
          alt.hdrpasschar07,
          alt.hdrpasschar08,
          alt.hdrpasschar09,
          alt.hdrpasschar10,
          alt.hdrpasschar11,
          alt.hdrpasschar12,
          alt.hdrpasschar13,
          alt.hdrpasschar14,
          alt.hdrpasschar15,
          alt.hdrpasschar16,
          alt.hdrpasschar17,
          alt.hdrpasschar18,
          alt.hdrpasschar19,
          alt.hdrpasschar20,
          alt.hdrpasschar21,
          alt.hdrpasschar22,
          alt.hdrpasschar23,
          alt.hdrpasschar24,
          alt.hdrpasschar25,
          alt.hdrpasschar26,
          alt.hdrpasschar27,
          alt.hdrpasschar28,
          alt.hdrpasschar29,
          alt.hdrpasschar30,
          alt.hdrpasschar31,
          alt.hdrpasschar32,
          alt.hdrpasschar33,
          alt.hdrpasschar34,
          alt.hdrpasschar35,
          alt.hdrpasschar36,
          alt.hdrpasschar37,
          alt.hdrpasschar38,
          alt.hdrpasschar39,
          alt.hdrpasschar40,
          alt.hdrpasschar41,
          alt.hdrpasschar42,
          alt.hdrpasschar43,
          alt.hdrpasschar44,
          alt.hdrpasschar45,
          alt.hdrpasschar46,
          alt.hdrpasschar47,
          alt.hdrpasschar48,
          alt.hdrpasschar49,
          alt.hdrpasschar50,
          alt.hdrpasschar51,
          alt.hdrpasschar52,
          alt.hdrpasschar53,
          alt.hdrpasschar54,
          alt.hdrpasschar55,
          alt.hdrpasschar56,
          alt.hdrpasschar57,
          alt.hdrpasschar58,
          alt.hdrpasschar59,
          alt.hdrpasschar60,
          alt.hdrpassnum01,
          alt.hdrpassnum02,
          alt.hdrpassnum03,
          alt.hdrpassnum04,
          alt.hdrpassnum05,
          alt.hdrpassnum06,
          alt.hdrpassnum07,
          alt.hdrpassnum08,
          alt.hdrpassnum09,
          alt.hdrpassnum10,
          alt.hdrpassdate01,
          alt.hdrpassdate02,
          alt.hdrpassdate03,
          alt.hdrpassdate04,
          alt.hdrpassdoll01,
          alt.hdrpassdoll02,
          alt.dtlpasschar01,
          alt.dtlpasschar02,
          alt.dtlpasschar03,
          alt.dtlpasschar04,
          alt.dtlpasschar05,
          alt.dtlpasschar06,
          alt.dtlpasschar07,
          alt.dtlpasschar08,
          alt.dtlpasschar09,
          alt.dtlpasschar10,
          alt.dtlpasschar11,
          alt.dtlpasschar12,
          alt.dtlpasschar13,
          alt.dtlpasschar14,
          alt.dtlpasschar15,
          alt.dtlpasschar16,
          alt.dtlpasschar17,
          alt.dtlpasschar18,
          alt.dtlpasschar19,
          alt.dtlpasschar20,
          alt.dtlpasschar21,
          alt.dtlpasschar22,
          alt.dtlpasschar23,
          alt.dtlpasschar24,
          alt.dtlpasschar25,
          alt.dtlpasschar26,
          alt.dtlpasschar27,
          alt.dtlpasschar28,
          alt.dtlpasschar29,
          alt.dtlpasschar30,
          alt.dtlpasschar31,
          alt.dtlpasschar32,
          alt.dtlpasschar33,
          alt.dtlpasschar34,
          alt.dtlpasschar35,
          alt.dtlpasschar36,
          alt.dtlpasschar37,
          alt.dtlpasschar38,
          alt.dtlpasschar39,
          alt.dtlpasschar40,
          alt.dtlpassnum01,
          alt.dtlpassnum02,
          alt.dtlpassnum03,
          alt.dtlpassnum04,
          alt.dtlpassnum05,
          alt.dtlpassnum06,
          alt.dtlpassnum07,
          alt.dtlpassnum08,
          alt.dtlpassnum09,
          alt.dtlpassnum10,
          alt.dtlpassnum11,
          alt.dtlpassnum12,
          alt.dtlpassnum13,
          alt.dtlpassnum14,
          alt.dtlpassnum15,
          alt.dtlpassnum16,
          alt.dtlpassnum17,
          alt.dtlpassnum18,
          alt.dtlpassnum19,
          alt.dtlpassnum20,
          alt.dtlpassdate01,
          alt.dtlpassdate02,
          alt.dtlpassdate03,
          alt.dtlpassdate04,
          alt.dtlpassdoll01,
          alt.dtlpassdoll02,
          alt.consigneesku,
          alt.upc,
          alt.zipcodebar,
          alt.zipcodehuman,
          alt.storebarcode,
          alt.storehuman,
          alt.vendorbar,
          alt.vendorhuman,
          alt.shiptocsz,
          alt.shipfromcsz,
          'Y',
          alt.lbltypedesc,
          alt.part,
          alt.shipto,
          alt.custname,
          alt.iteminner,
          alt.itemweight,
          alt.vendhuman,
          alt.vendbar);

   end loop;

end merge_labels;


procedure shipunit_label
   (in_oh       in orderhdr%rowtype,
    in_action   in varchar2,
    in_lblcount in number,
    io_aux      in out auxdata)
is
   cursor c_od(p_lpid varchar2) is
      select distinct OD.dtlpassthruchar01,
             OD.dtlpassthruchar02,
             OD.dtlpassthruchar03,
             OD.dtlpassthruchar04,
             OD.dtlpassthruchar05,
             OD.dtlpassthruchar06,
             OD.dtlpassthruchar07,
             OD.dtlpassthruchar08,
             OD.dtlpassthruchar09,
             OD.dtlpassthruchar10,
             OD.dtlpassthruchar11,
             OD.dtlpassthruchar12,
             OD.dtlpassthruchar13,
             OD.dtlpassthruchar14,
             OD.dtlpassthruchar15,
             OD.dtlpassthruchar16,
             OD.dtlpassthruchar17,
             OD.dtlpassthruchar18,
             OD.dtlpassthruchar19,
             OD.dtlpassthruchar20,
             OD.dtlpassthruchar21,
             OD.dtlpassthruchar22,
             OD.dtlpassthruchar23,
             OD.dtlpassthruchar24,
             OD.dtlpassthruchar25,
             OD.dtlpassthruchar26,
             OD.dtlpassthruchar27,
             OD.dtlpassthruchar28,
             OD.dtlpassthruchar29,
             OD.dtlpassthruchar30,
             OD.dtlpassthruchar31,
             OD.dtlpassthruchar32,
             OD.dtlpassthruchar33,
             OD.dtlpassthruchar34,
             OD.dtlpassthruchar35,
             OD.dtlpassthruchar36,
             OD.dtlpassthruchar37,
             OD.dtlpassthruchar38,
             OD.dtlpassthruchar39,
             OD.dtlpassthruchar40,
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
             OD.dtlpassthrunum11,
             OD.dtlpassthrunum12,
             OD.dtlpassthrunum13,
             OD.dtlpassthrunum14,
             OD.dtlpassthrunum15,
             OD.dtlpassthrunum16,
             OD.dtlpassthrunum17,
             OD.dtlpassthrunum18,
             OD.dtlpassthrunum19,
             OD.dtlpassthrunum20,
             OD.dtlpassthrudate01,
             OD.dtlpassthrudate02,
             OD.dtlpassthrudate03,
             OD.dtlpassthrudate04,
             OD.dtlpassthrudoll01,
             OD.dtlpassthrudoll02,
             OD.consigneesku,
             CIA.itemalias upc
         from custitemalias CIA, orderdtl OD, shippingplate SP
         where OD.orderid = SP.orderid
           and OD.shipid = SP.shipid
           and OD.item = SP.orderitem
           and nvl(OD.lotnumber, '(none)') = nvl(SP.orderlot, '(none)')
           and CIA.item(+) = od.item
           and CIA.custid(+) = in_oh.custid
           and CIA.aliasdesc(+) like 'UPC%'
           and SP.lpid in (select lpid from shippingplate
                              where type in ('F','P')
                              start with lpid = p_lpid
                              connect by prior lpid = parentlpid);

   cursor c_sp(p_lpid varchar2) is
      select distinct item, lotnumber
         from shippingplate
         where type in ('F','P')
         start with lpid = p_lpid
         connect by prior lpid = parentlpid
         order by item;

   l_od dtlpassthru := null;
   l_cnt pls_integer := 0;
   l_lblcount pls_integer := in_lblcount;
   l_quantity ucc_standard_labels.quantity%type := io_aux.quantity;
   l_weight ucc_standard_labels.weight%type := io_aux.weight;
   l_plqty shippingplate.quantity%type := io_aux.quantity / in_lblcount;
   l_plwt shippingplate.weight%type := io_aux.weight / in_lblcount;
begin

   for od in c_od(io_aux.lpid) loop -- determine whether multiple orderdtl rows
      l_od := od;
      l_cnt := l_cnt + 1;
      exit when l_cnt > 1;
   end loop;

   if l_cnt > 1 then
      l_od := null;
   else
      for sp in c_sp(io_aux.lpid) loop -- determine if multiple lotnumbers
         if c_sp%rowcount = 1 then
            io_aux.item := sp.item;
            io_aux.lotnumber := sp.lotnumber;
         else
            io_aux.lotnumber := null;
            exit;
         end if;
      end loop;
   end if;

   while (l_lblcount > 0) loop
      io_aux.quantity := least(l_quantity, l_plqty);
      io_aux.weight := least(l_weight, l_plwt);

      add_label(in_oh, l_od, in_action, 'S', null, io_aux);

      l_quantity := l_quantity - io_aux.quantity;
      l_weight := l_weight - io_aux.weight;
      l_lblcount := l_lblcount - 1;
   end loop;

end shipunit_label;


procedure case_label
   (in_oh          in orderhdr%rowtype,
    in_action      in varchar2,
    in_uom         in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_lbltype     in varchar2,
    io_aux         in out auxdata)
is
   cursor c_od(p_orderid number, p_shipid number, p_orderitem varchar2,
               p_orderlot varchar2, p_custid varchar2) is
      select dtlpassthruchar01,
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
             dtlpassthruchar21,
             dtlpassthruchar22,
             dtlpassthruchar23,
             dtlpassthruchar24,
             dtlpassthruchar25,
             dtlpassthruchar26,
             dtlpassthruchar27,
             dtlpassthruchar28,
             dtlpassthruchar29,
             dtlpassthruchar30,
             dtlpassthruchar31,
             dtlpassthruchar32,
             dtlpassthruchar33,
             dtlpassthruchar34,
             dtlpassthruchar35,
             dtlpassthruchar36,
             dtlpassthruchar37,
             dtlpassthruchar38,
             dtlpassthruchar39,
             dtlpassthruchar40,
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
             dtlpassthrunum11,
             dtlpassthrunum12,
             dtlpassthrunum13,
             dtlpassthrunum14,
             dtlpassthrunum15,
             dtlpassthrunum16,
             dtlpassthrunum17,
             dtlpassthrunum18,
             dtlpassthrunum19,
             dtlpassthrunum20,
             dtlpassthrudate01,
             dtlpassthrudate02,
             dtlpassthrudate03,
             dtlpassthrudate04,
             dtlpassthrudoll01,
             dtlpassthrudoll02,
             consigneesku,
             itemalias
         from orderdtl od, custitemalias cia
         where od.orderid = p_orderid
           and od.shipid = p_shipid
           and od.item = p_orderitem
           and nvl(lotnumber, '(none)') = nvl(p_orderlot, '(none)')
           and cia.item(+) = od.item
           and cia.custid(+) = p_custid
           and cia.aliasdesc(+) like 'UPC%';

   od dtlpassthru;
   l_csqty shippingplate.quantity%type;
   l_cswt shippingplate.weight%type;
   l_cnt pls_integer;
   l_part varchar2(4);
   l_uom varchar2(3);
begin
   if in_uom is null then
      l_uom := 'CTN';
   else
      l_uom := in_uom;
   end if;

   if in_picked then
      if in_consorderid is not null then
         -- picked consolidated order
         for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                           sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                        from shippingplate
                        where type in ('F','P')
                          and orderid = in_oh.orderid
                          and shipid = in_oh.shipid
                        start with lpid = io_aux.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                        order by item, lotnumber, orderitem, orderlot) loop

            l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_uom, sp.unitofmeasure);
            l_cswt := l_csqty * sp.weight / sp.quantity;
            l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_uom);

            io_aux.item := sp.item;
            io_aux.lotnumber := sp.lotnumber;
            while (l_cnt > 0) loop
               open c_od(in_oh.orderid, in_oh.shipid, sp.orderitem, sp.orderlot,
                    in_oh.custid);
               fetch c_od into od;
               close c_od;

               io_aux.quantity := least(sp.quantity, l_csqty);
               io_aux.weight := least(sp.weight, l_cswt);
               if io_aux.quantity = l_csqty then
                  l_part := null;
               else
                  l_part := 'PART';
               end if;
               add_label(in_oh, od, in_action, in_lbltype, l_part, io_aux);

               sp.quantity := sp.quantity - io_aux.quantity;
               sp.weight := sp.weight - io_aux.weight;
               l_cnt := l_cnt - 1;
            end loop;
         end loop;
      else
         -- picked non-consolidated order
         for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                           sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                        from shippingplate
                        where type in ('F','P')
                        start with lpid = io_aux.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                        order by item, lotnumber, orderitem, orderlot) loop

            l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_uom, sp.unitofmeasure);
            l_cswt := l_csqty * sp.weight / sp.quantity;
            l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_uom);

            io_aux.item := sp.item;
            io_aux.lotnumber := sp.lotnumber;
            while (l_cnt > 0) loop
               open c_od(in_oh.orderid, in_oh.shipid, sp.orderitem, sp.orderlot,
                    in_oh.custid);
               fetch c_od into od;
               close c_od;

               io_aux.quantity := least(sp.quantity, l_csqty);
               io_aux.weight := least(sp.weight, l_cswt);
               if io_aux.quantity = l_csqty then
                  l_part := null;
               else
                  l_part := 'PART';
               end if;
               add_label(in_oh, od, in_action, in_lbltype, l_part, io_aux);

               sp.quantity := sp.quantity - io_aux.quantity;
               sp.weight := sp.weight - io_aux.weight;
               l_cnt := l_cnt - 1;
            end loop;
         end loop;
      end if;
   elsif in_consorderid is not null or in_usebatch then
      -- unpicked consolidated order or unpicked non-consolidated batch pick order
      for bt in (select custid, item, uom, orderitem, orderlot,
                        sum(qty) as qty, sum(nvl(weight,0)) as weight
                     from batchtasks
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, uom, orderitem, orderlot
                     order by item, orderitem, orderlot) loop

         l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, l_uom, bt.uom);
         l_cswt := l_csqty * bt.weight / bt.qty;
         l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_uom);

         io_aux.item := bt.item;
         io_aux.lotnumber := bt.orderlot;
         while (l_cnt > 0) loop
            open c_od(in_oh.orderid, in_oh.shipid, bt.orderitem, bt.orderlot,
                  in_oh.custid);
            fetch c_od into od;
            close c_od;

            io_aux.quantity := least(bt.qty, l_csqty);
            io_aux.weight := least(bt.weight, l_cswt);
            if io_aux.quantity = l_csqty then
               l_part := null;
            else
               l_part := 'PART';
            end if;
            add_label(in_oh, od, in_action, in_lbltype, l_part, io_aux);

            bt.qty := bt.qty - io_aux.quantity;
            bt.weight := bt.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   else
      -- unpicked non-consolidated non-batch pick order
      for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                        sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                     from shippingplate
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                     order by item, lotnumber, orderitem, orderlot) loop

         l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_uom, sp.unitofmeasure);
         l_cswt := l_csqty * sp.weight / sp.quantity;
         l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_uom);

         io_aux.item := sp.item;
         io_aux.lotnumber := sp.lotnumber;
         while (l_cnt > 0) loop
            open c_od(in_oh.orderid, in_oh.shipid, sp.orderitem, sp.orderlot,
                 in_oh.custid);
            fetch c_od into od;
            close c_od;

            io_aux.quantity := least(sp.quantity, l_csqty);
            io_aux.weight := least(sp.weight, l_cswt);
            if io_aux.quantity = l_csqty then
               l_part := null;
            else
               l_part := 'PART';
            end if;
            add_label(in_oh, od, in_action, in_lbltype, l_part, io_aux);

            sp.quantity := sp.quantity - io_aux.quantity;
            sp.weight := sp.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   end if;

end case_label;


procedure ctn_group
   (in_oh          in orderhdr%rowtype,
    in_sscctype    in varchar2,
    in_procname    in varchar2,
    in_func        in varchar2,
    in_action      in varchar2,
    in_uom         in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_view        in varchar2,
    in_lbltype     in varchar2,
    out_stmt       in out varchar2)
is
   l_aux auxdata;
begin

   init_lblgroup(in_oh.orderid, in_oh.shipid, in_picked, in_consorderid, in_usebatch,
         in_sscctype, in_procname, in_action, in_uom, in_lbltype, l_aux);

   if in_picked then
      if in_consorderid is not null then
         -- picked consolidated order
         for pp in (select PP.lpid, PP.fromlpid, PP.type
                     from shippingplate PP
                     where orderid = in_consorderid
                       and shipid = 0
                       and exists (select * from shippingplate KP
                                      where KP.parentlpid = PP.lpid
                                        and KP.orderid = in_oh.orderid
                                        and KP.shipid = in_oh.shipid)) loop
            l_aux.lpid := pp.lpid;
            l_aux.picktolp := pp.fromlpid;
            l_aux.shippingtype := pp.type;
            case_label(in_oh, in_action, in_uom, in_picked, in_consorderid, in_usebatch,
                  in_lbltype, l_aux);
         end loop;
      else
         -- picked non-consolidated order
         for pp in (select lpid, type, fromlpid, quantity, weight
                     from shippingplate
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                       and parentlpid is null
                     order by lpid) loop
            l_aux.lpid := pp.lpid;
            l_aux.picktolp := pp.fromlpid;
            l_aux.shippingtype := pp.type;
            if pp.type = 'C' and in_lbltype != 'I' then
               l_aux.quantity := pp.quantity;
               l_aux.weight := pp.weight;
               shipunit_label(in_oh, in_action, 1, l_aux);
            else
               case_label(in_oh, in_action, in_uom, in_picked, in_consorderid, in_usebatch,
                     in_lbltype, l_aux);
            end if;
         end loop;
      end if;
   else
      -- unpicked order
      l_aux.lpid := null;
      l_aux.picktolp := null;
      l_aux.shippingtype := 'P';
      case_label(in_oh, in_action, in_uom, in_picked, in_consorderid, in_usebatch,
            in_lbltype, l_aux);
   end if;

   if in_action = 'C' then
      if in_func = 'Q' then
         match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
      else
         merge_labels(in_oh, l_aux);
      end if;
   end if;

end ctn_group;


-- Public


procedure order18
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;
   i binary_integer;
   l_view user_views.view_name%type;
   l_consorderid number;
begin
   out_stmt := null;

   verify_order(in_lpid, in_auxdata, in_func, in_action, '(NOTNULL)', out_stmt, l_view,
         l_consorderid);

   if out_stmt = 'Continue' then
      -- order could be part of a consolidated order
      if (ord_tbl.count = 1) then
         l_consorderid := zcord.cons_orderid(ord_tbl(1).orderid, ord_tbl(1).shipid);
         if l_consorderid = 0 then
            l_consorderid := null;
         end if;
      end if;

      for i in 1..ord_tbl.count loop
         open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
         fetch c_oh into oh;
         close c_oh;
         ctn_group(oh, '18', 'order18', in_func, in_action, 'CS', ord_tbl(i).picked,
               l_consorderid, ord_tbl(i).usebatch, l_view, 'C', out_stmt);

         if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
            exit;
         end if;

         out_stmt := 'Continue';
      end loop;

      if in_action = 'A' then
         if l_consorderid is not null then
            open c_wav(l_consorderid);
            fetch c_wav into oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view || ' L, zseq Z'
               || ' where L.wave = ' || l_consorderid
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
            fetch c_oh into oh;
            close c_oh;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view || ' L, zseq Z'
               || ' where L.orderid = ' || ord_tbl(1).orderid
               || ' and L.shipid = ' || ord_tbl(1).shipid
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
      elsif in_func = 'X' then
         if l_consorderid is not null then
            open c_wav(l_consorderid);
            fetch c_wav into oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from ucc_standard_labels L, zseq Z'
               || ' where L.wave = ' || l_consorderid
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
            fetch c_oh into oh;
            close c_oh;
            out_stmt := 'select L.*, Z.seq as zseq_seq from ucc_standard_labels L, zseq Z'
               || ' where L.orderid = ' || ord_tbl(1).orderid
               || ' and L.shipid = ' || ord_tbl(1).shipid
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';

         end if;
      elsif out_stmt = 'Continue' then
         out_stmt := 'Nothing for order';
      else
         rollback;      -- mismatch, undo any lpid updates
      end if;
      commit;
   end if;

end order18;


procedure orderipk18
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;
   i binary_integer;
   l_view user_views.view_name%type;
   l_consorderid number;
begin
   out_stmt := null;

   verify_order(in_lpid, in_auxdata, in_func, in_action, 'innerpack', out_stmt, l_view,
         l_consorderid);

   if out_stmt = 'Continue' then
      -- order could be part of a consolidated order
      if (ord_tbl.count = 1) then
         l_consorderid := zcord.cons_orderid(ord_tbl(1).orderid, ord_tbl(1).shipid);
         if l_consorderid = 0 then
            l_consorderid := null;
         end if;
      end if;

      for i in 1..ord_tbl.count loop
         open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
         fetch c_oh into oh;
         close c_oh;
         ctn_group(oh, '18', 'orderipk18', in_func, in_action, 'IN', ord_tbl(i).picked,
               l_consorderid, ord_tbl(i).usebatch, l_view, 'I', out_stmt);

         if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
            exit;
         end if;

         out_stmt := 'Continue';
      end loop;

      if in_action = 'A' then
         if l_consorderid is not null then
            open c_wav(l_consorderid);
            fetch c_wav into oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view || ' L, zseq Z'
               || ' where L.wave = ' || l_consorderid
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
            fetch c_oh into oh;
            close c_oh;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view || ' L, zseq Z'
               || ' where L.orderid = ' || ord_tbl(1).orderid
               || ' and L.shipid = ' || ord_tbl(1).shipid
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
      elsif in_func = 'X' then
         if l_consorderid is not null then
            open c_wav(l_consorderid);
            fetch c_wav into oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from ucc_standard_labels L, zseq Z'
               || ' where L.wave = ' || l_consorderid
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
            fetch c_oh into oh;
            close c_oh;
            out_stmt := 'select L.*, Z.seq as zseq_seq from ucc_standard_labels L, zseq Z'
               || ' where L.orderid = ' || ord_tbl(1).orderid
               || ' and L.shipid = ' || ord_tbl(1).shipid
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';

         end if;
      elsif out_stmt = 'Continue' then
         out_stmt := 'Nothing for order';
      else
         rollback;      -- mismatch, undo any lpid updates
      end if;
      commit;
   end if;

end orderipk18;


end logteam_cslbl;
/
show error package body logteam_cslbl;
exit;
