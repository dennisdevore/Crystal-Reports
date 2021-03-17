CREATE OR REPLACE package body zstdlabels as
--
-- $Id: zstdlabels.sql 815 2007-04-20 15:43:49Z ed $
--


-- Types


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
   shipto orderhdr.shipto%type,
   color ucc_standard_labels.color%type,
   pptype shippingplate.type%type,
   sscc_type varchar2(2),
   totalcases number(7),
   bigseq number(7),
   bigseqof number(7),
   rcpt_qty_is_full_qty customer_aux.rcpt_qty_is_full_qty%type
   );

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
   dtlpassthrunum11 orderdtl.dtlpassthrunum01%type,
   dtlpassthrunum12 orderdtl.dtlpassthrunum02%type,
   dtlpassthrunum13 orderdtl.dtlpassthrunum03%type,
   dtlpassthrunum14 orderdtl.dtlpassthrunum04%type,
   dtlpassthrunum15 orderdtl.dtlpassthrunum05%type,
   dtlpassthrunum16 orderdtl.dtlpassthrunum06%type,
   dtlpassthrunum17 orderdtl.dtlpassthrunum07%type,
   dtlpassthrunum18 orderdtl.dtlpassthrunum08%type,
   dtlpassthrunum19 orderdtl.dtlpassthrunum09%type,
   dtlpassthrunum20 orderdtl.dtlpassthrunum10%type,
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
   fieldvalue orderhdr.hdrpassthruchar01%type );

type key_val is table of key_table index by pls_integer;
key_values key_val;

l_cartonsuom varchar2(3) := 'CTN';
globalConsorderid number(9);
globalLabelType varchar2(2) := 'CS';
type contents_rectype is record (
   dptchar01 ucc_standard_labels.dptchar01_01%type,
   dptchar02 ucc_standard_labels.dptchar02_01%type,
   dptchar03 ucc_standard_labels.dptchar03_01%type,
   itemqty ucc_standard_labels.itemqty_01%type);
type contents_tbltype is table of contents_rectype index by binary_integer;
cntnts contents_tbltype;
cntntsx integer;

type ordrectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type,
   picked boolean,
   usebatch boolean,
   conswave orderhdr.wave%type);
type ordtbltype is table of ordrectype index by binary_integer;
ord_tbl ordtbltype;
debug_level char(1) := 0;

cursor c_item(in_custid varchar2, in_item varchar2) is
 select labeluom
  from custitem
 where custid = in_custid
   and item = in_item;
it c_item%rowtype;

cursor c_multi_aux (in_custid varchar2 ) is
                 select labelmultiuombase,labelmultiuombundle,labelmultiuompallet
                 from customer_aux
                 where custid = in_custid;
c_aux c_multi_aux%rowtype;


-- Private

procedure app_msg (in_msg varchar2) is
out_msg varchar2(255);
begin
   if debug_level in('1','2') then
      zms.log_autonomous_msg('LABELS', 'LBL', 'LBL', to_char(systimestamp, 'yyyymmddhh24missff') || ' ' ||in_msg, 'L', 'LABELS', out_msg);
   end if;
   if debug_level in ('2','3') then
      zut.prt(in_msg);
   end if;
end app_msg;

function duplicate_cnt
   (in_oh in orderhdr%rowtype)
return number
is
begin
-- 2 copies for kmart and walgreens non small package orders
--   if (nvl(in_oh.hdrpassthruchar05, '(none)') in ('141627', '10485'))
--   and (in_oh.shiptype != 'S') then
--      return 2;
--   end if;
   return 1;
end duplicate_cnt;

procedure check_order
   (in_orderid  in number,
    in_shipid   in number,
    in_idx      in pls_integer)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.orderstatus, nvl(WV.picktype,'ORDR') as picktype,
             WV.consolidated, OH.wave
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
   app_msg('check_order ' || in_orderid || ' ' || in_shipid);
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
   if oh.consolidated = 'Y' then
      ord_tbl(i).conswave := oh.wave;
   end if;
end check_order;

procedure verify_order
   (in_lpid          in varchar2,
    in_func          in varchar2,
    in_action        in varchar2,
    in_auxdata       in varchar2,
    in_sscc_type     in varchar2,
    out_oh           out orderhdr%rowtype,
    out_msg          out varchar2
)
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
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave
            or original_wave_before_combine = p_wave;

   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
   l_pos number;
   l_order varchar2(255);
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   i binary_integer;
   l_consolidated char(1);
   l_wave orderhdr.wave%type := null;
   l_auxdata varchar2(255);

begin
   out_msg := null;
   globalConsorderid := 0;
-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');
   app_msg('in_auxdata >' || l_auxdata ||'<');
   if l_auxdata = '(none)' then
      app_msg('(none) processing');
   -- try to determine order from lpid (could be plate or shippingplate)
      if substr(l_lpid, -1, 1) != 'S' then
         open c_lp(l_lpid);
         fetch c_lp into lp;
         if c_lp%found then            -- direct hit on XP
            l_lpid := lp.parentlpid;
         else
            open c_inf(l_lpid);
            fetch c_inf into inp;
            if c_inf%found then        -- try picked from lp
               l_cnt := 1;
               fetch c_inf into inp;
               if c_inf%found then     -- orderid/shipid not unique
                  l_cnt := 2;
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
            l_cnt := 1;
         end if;
         close c_inp;
      end if;
      app_msg('orderid '|| inp.orderid ||'-'||inp.shipid);
      if inp.shipid = 0 then
         l_auxdata := 'ORDER|'||inp.orderid || '|0';
      else
         if l_cnt != 1 then
            if in_func = 'Q' then
               if l_cnt = 0 then
                  out_msg := 'Order not found';
               else
                  out_msg := 'Order not unique';
               end if;
            end if;
            return;
         end if;

         open c_oh(inp.orderid, inp.shipid);
         fetch c_oh into out_oh;
         close c_oh;
         check_order(inp.orderid, inp.shipid, idx);
         app_msg('order status ' || out_oh.orderstatus);
         if out_oh.orderstatus in ('5','6','7','8','9') then
         select count(1) into l_cnt
            from shippingplate
            where orderid = inp.orderid
              and shipid = inp.shipid
              and status in ('U','P');
         if l_cnt != 0 then
            if in_func = 'Q' then
               out_msg := 'Order has picks';
            end if;
            return;
         end if;
         end if;
      end if;
   end if;

   app_msg('in_auxdata ' || l_auxdata);

   if l_auxdata != '(none)' then
      app_msg('not (none) processing');
        --aux data has data check to see if consolidated order or regular order
        -- Parse out orderid/shipid from auxdata
------------------------------------------------------------------------------------------------
      l_pos := instr(l_auxdata, '|');
      if l_pos != 0 then
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'ORDER' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
            end if;
         end if;
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'WAVE' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
            end if;
            begin
               select nvl(consolidated,'X') into l_consolidated
                  from waves
                  where wave = l_order;
            exception when no_data_found then
               l_consolidated := 'X';
            end;
            if l_consolidated <> 'Y' then
               if in_func = 'Q' then
                  out_msg := 'Wv not consolidated';
              end if;
              return;
            end if;
         end if;
      end if;
      if l_orderid is null then
         if in_func = 'Q' then
            out_msg := 'Order not found';
         end if;
         return;
      end if;

      ord_tbl.delete;

      if l_shipid != 0 then
         begin
            select nvl(consolidated,'X'), wave into l_consolidated, l_wave
               from waves
               where wave = (select wave from orderhdr
                               where orderid = l_orderid and shipid =  l_shipid);
         exception when no_data_found then
            l_consolidated := 'X';
         end;
         if l_consolidated = 'Y' then
            l_orderid := l_wave;
         for oh in (select orderid, shipid from orderhdr
                     where wave = l_orderid
                    union
                      select orderid, shipid from orderhdr
                        where original_wave_before_combine = l_orderid) loop
               check_order(oh.orderid, oh.shipid, idx);
            end loop;
            globalConsorderid := l_orderid;
         else
            app_msg('check order non cons ' || l_orderid || ' ' || l_shipid);
            check_order(l_orderid, l_shipid, idx);
         end if;
      else
         for oh in (select orderid, shipid from orderhdr
                     where wave = l_orderid) loop
            check_order(oh.orderid, oh.shipid, idx);
         end loop;
         globalConsorderid := l_orderid;
      end if;
      if ord_tbl.count = 0 then
         if in_func = 'Q' then
            out_msg := 'Nothing for order';
         end if;
         return;
      end if;
      l_cnt := 0;
      /*
      for i in 1..ord_tbl.count loop
         if ord_tbl(i).picked then
            l_cnt := l_cnt + 1;
         end if;
      end loop;

      if l_cnt != ord_tbl.count then
         if in_func = 'Q' then
            out_msg := 'Order has picks';
         end if;
         return;
      end if;
      */
      if nvl(globalConsorderid,0) = 0 then
         open c_oh(l_orderid, l_shipid);
         fetch c_oh into out_oh;
         close c_oh;
      end if;
   end if;
   l_cnt := 0;
   for i in 1..ord_tbl.count loop
      if ord_tbl(i).picked then
         l_cnt := l_cnt + 1;
      end if;
   end loop;

   if l_cnt != 0 and
      l_cnt != ord_tbl.count then
      if in_func = 'Q' then
         out_msg := 'Mixed order status';
      end if;
      return;
   end if;


-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         if globalConsorderid is not null and
            globalConsorderid <> 0 then
            select count(1) into l_cnt
               from ucc_standard_labels
               where wave = globalConsorderid;
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
         if nvl(globalConsorderid, 0) <> 0 then
            open c_wav(globalConsorderid);
            fetch c_wav into oh;
            close c_wav;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_stdlabels_view L , zseq Z'
                  || ' where L.wave = ' || globalConsorderid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(l_orderid, l_shipid);
            fetch c_oh into oh;
            close c_oh;
            if in_sscc_type <> 'CT' then
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_stdlabels_view L , zseq Z'
                  || ' where L.orderid = ' || l_orderid
                  || ' and L.shipid = ' || l_shipid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';

            else
               out_msg := 'select L.*, Z.seq as zseq_seq from '
                     || ' lbl_stdcntnts_view L , zseq Z'
                     || ' where L.orderid = ' || l_orderid
                  || ' and L.shipid = ' || l_shipid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
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


procedure verify_order_picked
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_type      in varchar2,
    out_oh       out orderhdr%rowtype,
    out_msg      out varchar2)
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
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
begin
   out_msg := null;

   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;

-- try to determine order from lpid (could be plate or shippingplate)
   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then            -- direct hit on XP
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then        -- try picked from lp
            l_cnt := 1;
            fetch c_inf into inp;
            if c_inf%found then     -- orderid/shipid not unique
               l_cnt := 2;
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
         l_cnt := 1;
      end if;
      close c_inp;
   end if;

   if l_cnt != 1 then
      if in_func = 'Q' then
         if l_cnt = 0 then
            out_msg := 'Order not found';
         else
            out_msg := 'Order not unique';
         end if;
      end if;
      return;
   end if;

-- insure order is for correct customer
   open c_oh(inp.orderid, inp.shipid);
   fetch c_oh into out_oh;
   close c_oh;
-- insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where orderid = inp.orderid
        and shipid = inp.shipid
        and status in ('U','P');

   if l_cnt != 0 then
      if in_func = 'Q' then
         out_msg := 'Order has picks';
      end if;
      return;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where orderid = inp.orderid
              and shipid = inp.shipid;
         if l_cnt = 0 then
            out_msg := 'Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         if in_type = 'C' then
            out_msg := 'select L.*'
                  || ' from lbl_stdcntnts_view L, zseq Z'
                  || ' where L.orderid = ' || inp.orderid
                  || ' and L.shipid = ' || inp.shipid
                  || ' and Z.seq <= ' || duplicate_cnt(out_oh)
                  || ' order by L.item, L.seq';
         else
            out_msg := 'select L.*'
            || ' from lbl_stdlabels_view L, zseq Z'
            || ' where L.orderid = ' || inp.orderid
            || ' and L.shipid = ' || inp.shipid
            || ' and Z.seq <= ' || duplicate_cnt(out_oh)
            || ' order by L.item, L.seq';
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

end verify_order_picked;


procedure verify_wave
   (in_lpid          in varchar2,
    in_func          in varchar2,
    in_action        in varchar2,
    in_auxdata       in varchar2,
    out_oh           out orderhdr%rowtype,
    out_msg          out varchar2
)
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
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;

   cursor c_load(p_load number) is
      select wave from orderhdr
         where loadno = p_load;

   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   l_pos number;
   l_order varchar2(255);
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   l_loadno orderhdr.loadno%type := null;
   i binary_integer;
   l_consolidated char(1);
   l_wave orderhdr.wave%type := null;
   l_auxdata varchar2(255);

begin
   out_msg := null;
   globalConsorderid := 0;
-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');
   app_msg('in_auxdata >' || l_auxdata ||'<');
   if l_auxdata = '(none)' then
      app_msg('(none) processing');
   -- try to determine order from lpid (could be plate or shippingplate)
      if substr(l_lpid, -1, 1) != 'S' then
         open c_lp(l_lpid);
         fetch c_lp into lp;
         if c_lp%found then            -- direct hit on XP
            l_lpid := lp.parentlpid;
         else
            open c_inf(l_lpid);
            fetch c_inf into inp;
            if c_inf%found then        -- try picked from lp
               l_cnt := 1;
               fetch c_inf into inp;
               if c_inf%found then     -- orderid/shipid not unique
                  l_cnt := 2;
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
            l_cnt := 1;
         end if;
         close c_inp;
      end if;
      app_msg('orderid '|| inp.orderid ||'-'||inp.shipid);
      if inp.shipid = 0 then
         l_auxdata := 'WAVE|'||inp.orderid;
      else
         if l_cnt != 1 then
            if in_func = 'Q' then
               if l_cnt = 0 then
                  out_msg := 'Order not found';
               else
                  out_msg := 'Order not unique';
               end if;
            end if;
            return;
         end if;

         open c_oh(inp.orderid, inp.shipid);
         fetch c_oh into out_oh;
         close c_oh;
         l_auxdata := 'WAVE|' || out_oh.wave;
      end if;
   end if;

   app_msg('in_auxdata wave  ' || l_auxdata);

   if l_auxdata != '(none)' then
      app_msg('not (none) wave processing ' || l_auxdata);
        --aux data has data check to see if consolidated order or regular order
        -- Parse out orderid/shipid from auxdata
------------------------------------------------------------------------------------------------
      l_wave := null;
      l_pos := instr(l_auxdata, '|');
      if l_pos != 0 then
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'ORDER' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
               if l_shipid = 0 then
                  l_wave := l_orderid;
               else
                  begin
                    select wave into l_wave
                       from orderhdr
                      where orderid = l_orderid
                        and shipid = l_shipid;
                  exception when no_data_found then
                     l_wave := null;
                  end;
               end if;
            end if;
            begin
               select nvl(consolidated,'X') into l_consolidated
                 from waves
                where wave = l_wave;
            exception when no_data_found then
               l_consolidated := 'X';
            end;
         else
            if upper(substr(l_auxdata, 1, l_pos-1)) = 'WAVE' then
               l_wave := substr(l_auxdata, l_pos+1);
               begin
                  select nvl(consolidated,'X') into l_consolidated
                     from waves
                     where wave = l_wave;
               exception when no_data_found then
                  l_consolidated := 'X';
               end;
            else
               if upper(substr(l_auxdata, 1, l_pos-1)) = 'LOAD' then
                  out_msg := 'Load ent. Wave exp.';
                  return;
               end if;
            end if;
         end if;
      end if;
      if nvl(l_wave,0) = 0  then
         if in_func = 'Q' then
            out_msg := 'Wave not found';
         end if;
         return;
      end if;

      ord_tbl.delete;
      if l_consolidated = 'Y' then
         globalConsorderid := l_wave;
      else
         globalConsorderid := 0;

      end if;

      for oh in (select orderid, shipid
                 from orderhdr
                 where wave = l_wave
                  and ((orderid = l_orderid and shipid = l_shipid) or in_func <> 'Q' or  in_action <> 'C' or
                          upper(substr(l_auxdata, 1, instr(l_auxdata, '|')-1)) <> 'ORDER'))
      loop
         check_order(oh.orderid, oh.shipid, idx);
      end loop;
      if ord_tbl.count = 0 then
         if in_func = 'Q' then
            out_msg := 'Nothing for wave';
         end if;
         return;
      end if;
      l_cnt := 0;
      if nvl(globalConsorderid,0) = 0 then
         open c_oh(l_orderid, l_shipid);
         fetch c_oh into out_oh;
         close c_oh;
      end if;
   end if;
   l_cnt := 0;
   for i in 1..ord_tbl.count loop
      if ord_tbl(i).picked then
         l_cnt := l_cnt + 1;
      end if;
   end loop;

   if l_cnt != 0 and
      l_cnt != ord_tbl.count then
      if in_func = 'Q' then
         out_msg := 'Mixed order status';
      end if;
      return;
   end if;


-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where wave = l_wave;

           if l_cnt = 0 then
              out_msg := 'Nothing for wave';
           else
              out_msg := 'OKAY';
           end if;
      else
         open c_wav(globalConsorderid);
         fetch c_wav into oh;
         close c_wav;
         out_msg := 'select L.*, Z.seq as zseq_seq from '
               || ' lbl_stdlabels_view L , zseq Z'
               || ' where L.wave = ' || l_wave
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_wave;

procedure verify_load
   (in_lpid          in varchar2,
    in_func          in varchar2,
    in_action        in varchar2,
    in_auxdata       in varchar2,
    out_oh           out orderhdr%rowtype,
    out_msg          out varchar2
)
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
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   oh c_oh%rowtype := null;

   cursor c_load(p_orderid number) is
      select loadno from shippingplate
         where orderid = p_orderid
           and shipid = 0;

   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   l_pos number;
   l_order varchar2(255);
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   l_loadno orderhdr.loadno%type := null;
   i binary_integer;
   l_consolidated char(1);
   l_auxdata varchar2(255);

begin
   out_msg := null;
   l_loadno := null;
   globalConsorderid := 0;
-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');
   app_msg('in_auxdata load >' || l_auxdata ||'<');
   if l_auxdata = '(none)' then
      app_msg('(none) processing');
   -- try to determine order from lpid (could be plate or shippingplate)
      if substr(l_lpid, -1, 1) != 'S' then
         open c_lp(l_lpid);
         fetch c_lp into lp;
         if c_lp%found then            -- direct hit on XP
            l_lpid := lp.parentlpid;
         else
            open c_inf(l_lpid);
            fetch c_inf into inp;
            if c_inf%found then        -- try picked from lp
               l_cnt := 1;
               fetch c_inf into inp;
               if c_inf%found then     -- orderid/shipid not unique
                  l_cnt := 2;
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
            l_cnt := 1;
         end if;
         close c_inp;
      end if;
      app_msg('orderid '|| inp.orderid ||'-'||inp.shipid);
      if inp.shipid = 0 then
         open c_load(inp.orderid);
         fetch c_load into l_loadno;
         close c_load;
         if l_loadno is null then
            out_msg := 'Load not found';
            return;
         end if;
         l_auxdata := 'LOAD|'||l_loadno;
      else
         if l_cnt != 1 then
            if in_func = 'Q' then
               if l_cnt = 0 then
                  out_msg := 'Load not found';
               else
                  out_msg := 'Load not unique';
               end if;
            end if;
            return;
         end if;

         open c_oh(inp.orderid, inp.shipid);
         fetch c_oh into out_oh;
         close c_oh;
         if out_oh.loadno is null then
            out_msg := 'Load not found';
            return;
         end if;
         l_auxdata := 'LOAD|' || out_oh.loadno;
      end if;
   end if;

   app_msg('in_auxdata ' || l_auxdata);

   if l_auxdata != '(none)' then
      app_msg('not (none) load processing');
        --aux data has data check to see if consolidated order or regular order
        -- Parse out orderid/shipid from auxdata
------------------------------------------------------------------------------------------------
      l_loadno := null;
      l_pos := instr(l_auxdata, '|');
      if l_pos != 0 then
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'ORDER' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
               if l_shipid = 0 then
                  open c_load(inp.orderid);
                  fetch c_load into l_loadno;
                  close c_load;
                  if l_loadno is null then
                     out_msg := 'Load not found';
                     return;
                  end if;
               else
                  begin
                    select loadno into l_loadno
                       from orderhdr
                      where orderid = l_orderid
                        and shipid = l_shipid;
                  exception when no_data_found then
                     l_loadno := null;
                  end;
               end if;
            end if;
         else
            if upper(substr(l_auxdata, 1, l_pos-1)) = 'WAVE' then
               out_msg := 'Wave ent. LLoad exp.';
               return;
            end if;
            l_loadno := substr(l_auxdata, l_pos+1);
         end if;
      end if;
      if nvl(l_loadno,0) = 0  then
         if in_func = 'Q' then
            out_msg := 'Load not found';
         end if;
         return;
      end if;

      ord_tbl.delete;
      globalConsorderid := 0;


      for oh in (select orderid, shipid
                 from orderhdr
                 where loadno = l_loadno
                  and ((orderid = l_orderid and shipid = l_shipid) or in_func <> 'Q' or  in_action <> 'C' or
                          upper(substr(l_auxdata, 1, instr(l_auxdata, '|')-1)) <> 'ORDER'))
      loop
         check_order(oh.orderid, oh.shipid, idx);
      end loop;
      if ord_tbl.count = 0 then
         if in_func = 'Q' then
            out_msg := 'Nothing for load';
         end if;
         return;
      end if;
      l_cnt := 0;
      if nvl(globalConsorderid,0) = 0 then
         open c_oh(l_orderid, l_shipid);
         fetch c_oh into out_oh;
         close c_oh;
      end if;
   end if;
   l_cnt := 0;
   for i in 1..ord_tbl.count loop
      if ord_tbl(i).picked then
         l_cnt := l_cnt + 1;
      end if;
   end loop;

   if l_cnt != 0 and
      l_cnt != ord_tbl.count then
      if in_func = 'Q' then
         out_msg := 'Mixed order status';
      end if;
      return;
   end if;


-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where loadno = l_loadno;

           if l_cnt = 0 then
              out_msg := 'Nothing for load';
           else
              out_msg := 'OKAY';
           end if;
      else
         out_msg := 'select L.*, Z.seq as zseq_seq from '
               || ' lbl_stdlabels_view L , zseq Z'
               || ' where L.loadno = ' || l_loadno
               || ' and Z.seq <= ' || duplicate_cnt(oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_load;

procedure init_lblgroup
   (in_orderid     in number,
    in_shipid      in number,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_sscctype    in varchar2,
    in_procname    in varchar2,
    in_action      in varchar2,
    in_group       in varchar2,
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
             CA.scac,
             OH.custid
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
  l_consolidated char(1);
  pos pls_integer;
  cnt pls_integer;

begin
   app_msg('init_lblgroup');

   out_aux := null;
   out_aux.quantity := 0;
   out_aux.weight := 0;
   out_aux.seq := 0;
   out_aux.seqof := 0;

   begin
      select upper(nvl(defaultvalue,'CTN')) into l_cartonsuom
         from systemdefaults
         where defaultid = 'CARTONSUOM';
   exception when no_data_found then
         l_cartonsuom := 'CTN';
   end;

   begin
      select nvl(rcpt_qty_is_full_qty,'N') into out_aux.rcpt_qty_is_full_qty
        from customer_aux
        where custid = (select custid
                       from orderhdr
                       where orderid = in_orderid
                         and shipid = in_shipid);
   exception when no_data_found then
       out_aux.rcpt_qty_is_full_qty := 'N';
   end;

   begin
   select nvl(consolidated,'N') into l_consolidated
      from waves
      where wave = (select nvl(original_wave_before_combine, wave)
                       from orderhdr
                       where orderid = in_orderid
                         and shipid = in_shipid);
      exception when no_data_found then
      l_consolidated := 'N';
   end;

   if in_picked then
      app_msg('init ' || l_consolidated || ' <> picked');
   else
      app_msg('init ' || l_consolidated || ' <> not picked');
   end if;
   pos := instr(upper(in_procname), '_PLATE');

   if pos > 0 then
      out_aux.seqof := null;
      out_aux.seq := null;
   else
   if in_picked then
      if l_consolidated = 'Y' then
         for pp in (select lpid, type, fromlpid, quantity, weight, item
                     from shippingplate
                     where lpid in (select distinct parentlpid
                                     from shippingplate
                                     where orderid = in_orderid
                                       and shipid = in_shipid)) loop
            if (pp.type = 'C') or (in_group = 'ccp') then
               out_aux.seqof := out_aux.seqof + 1;
            else
               for cp in (select custid, item, unitofmeasure, lotnumber,
                                 sum(quantity) as quantity
                           from shippingplate
                           where type in ('F','P')
                             and orderid = in_orderid
                             and shipid = in_shipid
                           start with lpid = pp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber) loop
                   if in_procname = 'stdinnerpack' or
                      in_procname = 'stdinnerpack_plate' then
                     it := null;
                     open c_item(cp.custid, cp.item);
                     fetch c_item into it;
                     close c_item;
                     if it.labeluom is not null then
                        out_aux.seqof := out_aux.seqof
                            + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, it.labeluom);
                     else
                         out_aux.seqof := out_aux.seqof
                          + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
                     end if;
                   elsif in_procname = 'stdinnerpack_nopart' or
                         in_procname = 'stdinnerpack_nopart_plate 'then
                     it := null;
                     open c_item(cp.custid, cp.item);
                     fetch c_item into it;
                     close c_item;
                     if it.labeluom is not null then
                        out_aux.seqof := out_aux.seqof
                            + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, it.labeluom,'Y');
                     else
                         out_aux.seqof := out_aux.seqof
                          + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom,'Y');
                     end if;
                   else
                  out_aux.seqof := out_aux.seqof
                        + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
               end if;
               end loop;
            end if;
         end loop;
      else
         if out_aux.rcpt_qty_is_full_qty = 'Y' then
            select count(1) into out_aux.seqof
               from shippingplate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and (type = 'C' or (type = 'F' and parentlpid is null) or
                      (type in ('F', 'P')
                       and parentlpid is not null
                       and parentlpid not in (select lpid
                                                from shippingplate
                                                where orderid = in_orderid
                                                  and shipid = in_shipid
                                                  and type = 'C')));
         else

            for pp in (select lpid, type, quantity from shippingplate
                        where orderid = in_orderid
                          and shipid = in_shipid
                          and parentlpid is null) loop
               app_msg('!@# ' || pp.lpid || ' ' || pp.type || ' ' || pp.quantity);
               if (pp.type = 'C') or  (pp.type = 'F' and out_aux.rcpt_qty_is_full_qty = 'Y') or (in_group = 'ccp') then
                  out_aux.seqof := out_aux.seqof + 1;
               else
                  if in_procname = 'stdmultiuom' then
                     OPEN  c_multi_aux (ord.custid);
                     FETCH c_multi_aux INTO c_aux;
                     CLOSE c_multi_aux;

                      for pp in (select lpid, type, quantity from shippingplate
                                     where orderid = in_orderid
                                       and shipid = in_shipid
                                       and parentlpid is null) loop
                         for cp in (select custid, item, unitofmeasure, lotnumber,
                                           sum(pickqty) pickqty, pickuom
                                     from shippingplate
                                     where type in ('F','P')
                                     start with lpid = pp.lpid
                                     connect by prior lpid = parentlpid
                                     group by custid, item, unitofmeasure, lotnumber, pickuom) loop

                              if      nvl(c_aux.LABELMULTIUOMBASE,'ZZZ') = cp.pickuom or
                                      nvl(c_aux.LABELMULTIUOMBUNDLE,'ZZZ')  =  cp.pickuom  then
                                      out_aux.seqof := out_aux.seqof + cp.pickqty;
                                      --app_msg('out_aux.seqof BASE(''' || out_aux.seqof || ''', ''' || cp.pickqty);
                              elsif   nvl(c_aux.LABELMULTIUOMPALLET,'ZZZ') =  cp.pickuom  then
                                      out_aux.seqof := out_aux.seqof
                                          + zlbl.uom_qty_conv(cp.custid, cp.item, 1, c_aux.LABELMULTIUOMPALLET, c_aux.LABELMULTIUOMBUNDLE);
                                      --app_msg('out_aux.seqof BASE(''' || out_aux.seqof || ''', ''' || c_aux.LABELMULTIUOMPALLET ||''', '''|| c_aux.LABELMULTIUOMBUNDLE );
                              end if;
                         end loop;
                      end loop;
                  else
                     select count(1) into cnt
                        from shippingplate
                        where parentlpid = pp.lpid
                          and type = 'C';
                     out_aux.seqof := out_aux.seqof + cnt;
                     for cp in (select custid, item, unitofmeasure, lotnumber,
                                       sum(quantity) as quantity
                                 from shippingplate
                                 where type in ('F','P')
                                   and orderid = in_orderid
                                   and shipid = in_shipid
                                   and lpid not in (select lpid from shippingplate where parentlpid = pp.lpid and type = 'C')
                                   and parentlpid not in (select lpid from shippingplate where parentlpid = pp.lpid and type = 'C')
                                 start with lpid = pp.lpid
                                 connect by prior lpid = parentlpid
                                 group by custid, item, unitofmeasure, lotnumber) loop
                         if in_procname = 'stdinnerpack' or
                            in_procname = 'stdinnerpack_plate' then
                           it := null;
                           open c_item(cp.custid, cp.item);
                           fetch c_item into it;
                           close c_item;
                           if it.labeluom is not null then
                              out_aux.seqof := out_aux.seqof
                                  + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, it.labeluom);
                           else
                               out_aux.seqof := out_aux.seqof
                                + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
                           end if;
                         elsif in_procname = 'stdinnerpack_nopart' or
                               in_procname = 'stdinnerpack_nopart_plate' then
                           it := null;
                           open c_item(cp.custid, cp.item);
                           fetch c_item into it;
                           close c_item;
                           if it.labeluom is not null then
                              out_aux.seqof := out_aux.seqof
                                  + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, it.labeluom,'Y');
                           else
                               out_aux.seqof := out_aux.seqof
                                + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom,'Y');
                           end if;
                         else
                            out_aux.seqof := out_aux.seqof
                                  + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
   --                         zut.prt('out_aux.seqof ' || out_aux.seqof);
                         end if;
                     end loop;
                  end if;
               end if;
            end loop;
         end if;
      end if;
   elsif l_consolidated = 'Y' or in_usebatch then
      -- unpicked consolidated order or unpicked non-consolidated batch pick order
      for bt in (select custid, item, uom, orderlot, sum(qty) as qty
                  from batchtasks
                  where orderid = in_orderid
                    and shipid = in_shipid
                  group by custid, item, uom, orderlot) loop
         if in_procname = 'stdinnerpack' or
            in_procname = 'stdinnerpack_plate' then
           it := null;
           open c_item(bt.custid, bt.item);
           fetch c_item into it;
           close c_item;
           if it.labeluom is not null then
              out_aux.seqof := out_aux.seqof
                  + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, it.labeluom);
           else
               out_aux.seqof := out_aux.seqof
                + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom);
           end if;
         elsif in_procname = 'stdinnerpack_nopart' or
               in_procname = 'stdinnerpack_nopart_plate' then
           it := null;
           open c_item(bt.custid, bt.item);
           fetch c_item into it;
           close c_item;
           if it.labeluom is not null then
              out_aux.seqof := out_aux.seqof
                  + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, it.labeluom,'Y');
           else
               out_aux.seqof := out_aux.seqof
                + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom,'Y');
           end if;
         else
         out_aux.seqof := out_aux.seqof
               + zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom);
         end if;
      end loop;
   else
      -- unpicked non-consolidated non-batch pick order
      for sp in (select custid, item, unitofmeasure, lotnumber,
                        sum(quantity) as quantity
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                  group by custid, item, unitofmeasure, lotnumber) loop
         app_msg('--<> ' || sp.custid || ' ' || sp.item || ' '|| sp.quantity || ' ' || in_procname);

         if in_procname = 'stdinnerpack' or
            in_procname = 'stdinnerpack_plate' then
           it := null;
           open c_item(sp.custid, sp.item);
           fetch c_item into it;
           close c_item;
           if it.labeluom is not null then
              out_aux.seqof := out_aux.seqof
                  + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
           else
               out_aux.seqof := out_aux.seqof
                + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
           end if;
         elsif in_procname = 'stdinnerpack_nopart' or
               in_procname = 'stdinnerpack_nopart_plate' then
           it := null;
           open c_item(sp.custid, sp.item);
           fetch c_item into it;
           close c_item;
           if it.labeluom is not null then
              out_aux.seqof := out_aux.seqof
                  + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
           else
               out_aux.seqof := out_aux.seqof
                + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
           end if;
         else
         out_aux.seqof := out_aux.seqof
               + zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
         end if;
      end loop;
   end if;
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
   out_aux.changeproc := 'zstdlabels.'||upper(in_procname);

   if in_action = 'A' then
      app_msg('delete 1 ' || pos);
      if pos = 0 then -- not a plate proc
      delete from ucc_standard_labels
         where orderid = in_orderid
           and shipid = in_shipid;
      delete from caselabels
         where orderid = in_orderid
           and shipid = in_shipid;
      end if;
      commit;
   end if;

   delete caselabels_temp;
   delete ucc_standard_labels_temp;

end init_lblgroup;


function sscc14_barcode
   (in_custid in varchar2,
    in_type   in varchar2,
    in_oh     in orderhdr%rowtype)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc, manufacturerucc_passthrufield
         from customer
         where custid = in_custid;
   manucc customer.manufacturerucc%type := null;
   barcode varchar2(14);
   manucc2 customer.manufacturerucc%type := null;
   manuccpass customer.manufacturerucc_passthrufield%type := null;
   seqname varchar2(30);
   seqval varchar2(5);
   ix integer;
   cc integer;
   cnt integer;
   cmdSql varchar2(200);
begin
   open c_cust;
   fetch c_cust into manucc,manuccpass;
   close c_cust;
   if manuccpass is not null then
      begin
         cmdSql := 'select substr(' || manuccpass || ',''1'',''7'') ' ||
                   ' from orderhdr ' ||
                   ' where orderid = ' || in_oh.orderid ||
                   '   and shipid = ' || in_oh.shipid;
         execute immediate cmdSql into manucc2;
      exception when no_data_found then
         manucc2 := null;
      end;
   end if;

   if manucc2 is not null then
      manucc := manucc2;
   end if;

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



procedure fill_cntnts
   (in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru,
    io_aux     in out auxdata)
is
   cursor c_od(in_orderid number, in_shipid number, in_item varchar2) is
      select dtlpassthruchar01,dtlpassthruchar02,dtlpassthruchar03
        from orderdtl
       where (orderid, shipid) in (select orderid, shipid
                                     from shippingplate
                                    where parentlpid = io_aux.lpid)
          and item = in_item;

begin
   cntntsx := 0;
   for sp in (select item, sum(quantity) as quantity
      from shippingplate
     where orderid = in_oh.orderid
       and shipid = in_oh.shipid
       and type in ('F','P')
     start with lpid = io_aux.lpid
        connect by prior lpid = parentlpid
          group by item
          order by item)
   loop
      cntntsx := cntntsx + 1;
      cntnts(cntntsx).itemqty := sp.quantity;
      open c_od(in_oh.orderid, in_oh.shipid, sp.item);
      fetch c_od into cntnts(cntntsx).dptchar01,
                      cntnts(cntntsx).dptchar02,
                      cntnts(cntntsx).dptchar03;
      close c_od;
   end loop;


end fill_cntnts;


procedure add_label
   (in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru,
    in_action  in varchar2,
    in_lbltype in varchar2,
    in_part    in varchar2,
    io_aux     in out auxdata)
is
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select item, descr,
             itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04,
             itmpassthrunum01, itmpassthrunum02, itmpassthrunum03, itmpassthrunum04
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
   l_manupass customer.manufacturerucc_passthrufield%type := null;
   hardcoded_manucc varchar2(10) := null;
   l_cnt integer;
   cmdSql varchar2(200);
   cursor c_sps(in_lpid varchar2) is
      select serialnumber, useritem1, useritem2, useritem3
        from shippingplate
       where type in ('F','P')
       start with lpid = in_lpid
     connect by prior lpid = parentlpid;
   sps c_sps%rowtype;
   cursor c_spd(in_lpid varchar2, in_item varchar2, in_lot varchar2) is
      select manufacturedate, expirationdate
         from shippingplate
         where type in ('F','P')
         and item = in_item
         and nvl(lotnumber,'(none)') = nvl(in_lot,'(none)')
         start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
   spd c_spd%rowtype;
begin
   if upper(io_aux.changeproc) = 'ZSTDLABELS.STDSSCCCNTNT_EXT4_PLATE' then
      l_labeltype := globalLabelType;
      l_barcodetype := '4';
      l_lbltypedesc := 'carton';
   elsif upper(io_aux.changeproc) = 'ZSTDLABELS.STDSSCCCNTNT_EXT4' then
      l_labeltype := globalLabelType;
      l_barcodetype := '4';
      l_lbltypedesc := 'carton';
   elsif in_lbltype = 'S' then
      l_labeltype := 'PL';
      if in_oh.shiptype = 'S' or
         io_aux.shippingtype = 'C' or
         (io_aux.rcpt_qty_is_full_qty = 'Y' and
          io_aux.shippingtype in ('F', 'P')) then
         l_labeltype := globalLabelType;
         l_barcodetype := '0';
         l_lbltypedesc := 'carton';
      else
         l_barcodetype := '1';
         l_lbltypedesc := 'pallet';
      end if;
   else
      l_labeltype := globalLabelType;
      l_barcodetype := '0';
      l_lbltypedesc := 'carton';
   end if;

   if io_aux.item is null then
      itm := null;
      itm.item := 'Mixed';
      itm.descr := 'Mixed';
   else
      open c_itm(in_oh.custid, io_aux.item);
      fetch c_itm into itm;
      close c_itm;
   end if;

   io_aux.seq := io_aux.seq + 1;
   io_aux.bigseq := io_aux.bigseq + 1;
   cntnts.delete;
   for cntntsx in 1..14 loop
      cntnts(cntntsx) := null;
   end loop;
   if io_aux.pptype = 'X' then
      cntnts(1).dptchar01 := in_od.dtlpassthruchar01;
      cntnts(1).dptchar02 := in_od.dtlpassthruchar02;
      cntnts(1).dptchar03 := in_od.dtlpassthruchar03;
      cntnts(1).itemqty := io_aux.quantity;
   else
      fill_cntnts(in_oh, in_od, io_aux);
   end if;

   if in_action = 'A' then
      if io_aux.sscctype = '18' then
         select manufacturerucc_passthrufield into l_manupass
            from customer
            where custid = in_oh.custid;
         if l_manupass is not null then
            if instr(l_manupass,'NUM') > 0 then
               cmdSql := 'select  to_char(' || l_manupass || ', ''FM0999999'') ' ||
                          ' from orderhdr where orderid = ' || in_oh.orderid || ' and shipid = ' || in_oh.shipid;
         else
               cmdSql := 'select  ' || l_manupass ||
                          ' from orderhdr where orderid = ' || in_oh.orderid || ' and shipid = ' || in_oh.shipid;
            end if;
            begin
               execute immediate cmdSql into hardcoded_manucc;
            exception when no_data_found then
               hardcoded_manucc := null;
            end;
         end if;
         if hardcoded_manucc is null then
            l_sscc := zlbl.caselabel_barcode(in_oh.custid, l_barcodetype);
            l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
         else
            l_sscc := zlbl.caselabel_barcode_var_manucc(in_oh.custid, l_barcodetype, hardcoded_manucc);
            -- zut.prt('zzcc 1 ' || l_sscc ||' <> ' || in_oh.custid || ' <> ' || l_barcodetype || ' <> ' || hardcoded_manucc);
            if length(hardcoded_manucc) = 9 then
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ????????? ??????? ?');
            elsif length(hardcoded_manucc) = 8  then
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
             else
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
            end if;
         end if;
      else
         l_sscc := sscc14_barcode(in_oh.custid, l_barcodetype, in_oh);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;
      sps := null;
      open c_sps(io_aux.lpid);
      fetch c_sps into sps;
      close c_sps;
      spd := null;
      open c_spd(io_aux.lpid, io_aux.item, io_aux.lotnumber);
      fetch c_spd into spd;
      close c_spd;
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
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          color,
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
          shipto_master,
          totalcases,
          serialnumber,
          useritem1,
          useritem2,
          useritem3,
          expirationdate,
          manufacturedate,
          bigseq,
          bigseqof
          )
      values
         (l_sscc,
          l_ssccfmt,
          io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          nvl(in_oh.original_wave_before_combine, in_oh.wave),
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
          in_oh.hdrpassthruchar33,
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
          in_oh.hdrpassthruchar50,
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
          decode(io_aux.item, null, 'Mixed', in_od.dtlpassthruchar02),
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
          itm.itmpassthruchar01,
          itm.itmpassthruchar02,
          itm.itmpassthruchar03,
          itm.itmpassthruchar04,
          itm.itmpassthrunum01,
          itm.itmpassthrunum02,
          itm.itmpassthrunum03,
          itm.itmpassthrunum04,
          in_od.consigneesku,
          in_od.upc,
          '420'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          '(420)'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          io_aux.color,
          cntnts(1).dptchar01,
          cntnts(1).dptchar02,
          cntnts(1).dptchar03,
          cntnts(1).itemqty,
          cntnts(2).dptchar01,
          cntnts(2).dptchar02,
          cntnts(2).dptchar03,
          cntnts(2).itemqty,
          cntnts(3).dptchar01,
          cntnts(3).dptchar02,
          cntnts(3).dptchar03,
          cntnts(3).itemqty,
          cntnts(4).dptchar01,
          cntnts(4).dptchar02,
          cntnts(4).dptchar03,
          cntnts(4).itemqty,
          cntnts(5).dptchar01,
          cntnts(5).dptchar02,
          cntnts(5).dptchar03,
          cntnts(5).itemqty,
          cntnts(6).dptchar01,
          cntnts(6).dptchar02,
          cntnts(6).dptchar03,
          cntnts(6).itemqty,
          cntnts(7).dptchar01,
          cntnts(7).dptchar02,
          cntnts(7).dptchar03,
          cntnts(7).itemqty,
          cntnts(8).dptchar01,
          cntnts(8).dptchar02,
          cntnts(8).dptchar03,
          cntnts(8).itemqty,
          cntnts(9).dptchar01,
          cntnts(9).dptchar02,
          cntnts(9).dptchar03,
          cntnts(9).itemqty,
          cntnts(10).dptchar01,
          cntnts(10).dptchar02,
          cntnts(10).dptchar03,
          cntnts(10).itemqty,
          cntnts(11).dptchar01,
          cntnts(11).dptchar02,
          cntnts(11).dptchar03,
          cntnts(11).itemqty,
          cntnts(12).dptchar01,
          cntnts(12).dptchar02,
          cntnts(12).dptchar03,
          cntnts(12).itemqty,
          cntnts(13).dptchar01,
          cntnts(13).dptchar02,
          cntnts(13).dptchar03,
          cntnts(13).itemqty,
          cntnts(14).dptchar01,
          cntnts(14).dptchar02,
          cntnts(14).dptchar03,
          cntnts(14).itemqty,
          in_oh.shipto_master,
          io_aux.totalcases,
          sps.serialnumber,
          sps.useritem1,
          sps.useritem2,
          sps.useritem3,
          spd.expirationdate,
          spd.manufacturedate,
          io_aux.bigseq,
          io_aux.bigseqof
          );
      if io_aux.sscctype = '14' then
         select count(1) into l_cnt
            from caselabels
            where barcode = l_sscc;
         if l_cnt > 0 then
            delete from caselabels where barcode = l_sscc;
         end if;
      end if;
      app_msg('insert caselabels ' || l_sscc);
            if upper(io_aux.changeproc) = upper('zstdlabels.stdpallet_mixeditem') then
         if  itm.item = 'Mixed' then
             io_aux.item := 'Mixed';
         end if;
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
          'UCC_STANDARD_LABELS',
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
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          color,
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
          shipto_master,
          totalcases,
          serialnumber,
          useritem1,
          useritem2,
          useritem3,
          expirationdate,
          manufacturedate,
          bigseq,
          bigseqof
          )
      values
         (io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          nvl(in_oh.original_wave_before_combine, in_oh.wave),
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
          in_oh.hdrpassthruchar33,
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
          in_oh.hdrpassthruchar50,
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
          decode(io_aux.item, null, 'Mixed', in_od.dtlpassthruchar02),
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
          itm.itmpassthruchar01,
          itm.itmpassthruchar02,
          itm.itmpassthruchar03,
          itm.itmpassthruchar04,
          itm.itmpassthrunum01,
          itm.itmpassthrunum02,
          itm.itmpassthrunum03,
          itm.itmpassthrunum04,
          in_od.consigneesku,
          in_od.upc,
          '420'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          '(420)'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          io_aux.color,
          cntnts(1).dptchar01,
          cntnts(1).dptchar02,
          cntnts(1).dptchar03,
          cntnts(1).itemqty,
          cntnts(2).dptchar01,
          cntnts(2).dptchar02,
          cntnts(2).dptchar03,
          cntnts(2).itemqty,
          cntnts(3).dptchar01,
          cntnts(3).dptchar02,
          cntnts(3).dptchar03,
          cntnts(3).itemqty,
          cntnts(4).dptchar01,
          cntnts(4).dptchar02,
          cntnts(4).dptchar03,
          cntnts(4).itemqty,
          cntnts(5).dptchar01,
          cntnts(5).dptchar02,
          cntnts(5).dptchar03,
          cntnts(5).itemqty,
          cntnts(6).dptchar01,
          cntnts(6).dptchar02,
          cntnts(6).dptchar03,
          cntnts(6).itemqty,
          cntnts(7).dptchar01,
          cntnts(7).dptchar02,
          cntnts(7).dptchar03,
          cntnts(7).itemqty,
          cntnts(8).dptchar01,
          cntnts(8).dptchar02,
          cntnts(8).dptchar03,
          cntnts(8).itemqty,
          cntnts(9).dptchar01,
          cntnts(9).dptchar02,
          cntnts(9).dptchar03,
          cntnts(9).itemqty,
          cntnts(10).dptchar01,
          cntnts(10).dptchar02,
          cntnts(10).dptchar03,
          cntnts(10).itemqty,
          cntnts(11).dptchar01,
          cntnts(11).dptchar02,
          cntnts(11).dptchar03,
          cntnts(11).itemqty,
          cntnts(12).dptchar01,
          cntnts(12).dptchar02,
          cntnts(12).dptchar03,
          cntnts(12).itemqty,
          cntnts(13).dptchar01,
          cntnts(13).dptchar02,
          cntnts(13).dptchar03,
          cntnts(13).itemqty,
          cntnts(14).dptchar01,
          cntnts(14).dptchar02,
          cntnts(14).dptchar03,
          cntnts(14).itemqty,
          in_oh.shipto_master,
          io_aux.totalcases,
          sps.serialnumber,
          sps.useritem1,
          sps.useritem2,
          sps.useritem3,
          spd.expirationdate,
          spd.manufacturedate,
          io_aux.bigseq,
          io_aux.bigseqof
          )
      returning rowid into l_rowid;

      if upper(io_aux.changeproc) = upper('zstdlabels.stdpallet_mixeditem') then
         if  itm.item = 'Mixed' then
             io_aux.item := 'Mixed';
         end if;
      end if;

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
exception when others then
  zut.prt(sqlcode|| ' '|| sqlerrm);

end add_label;

procedure match_labels
   (in_orderid in number,
    in_shipid  in number,
    out_stmt   out varchar2)
is
   l_match varchar2(1);
   l_cnt pls_integer;
   cntCombined pls_integer;
   cntPlate pls_integer;
   cntPP pls_integer;
   cntCarton pls_integer;
   l_labels_voided char(1);
begin
   out_stmt := null;
   app_msg('match_labels');

   select nvl(labels_voided, 'N') into l_labels_voided
     from orderhdr
    where orderid = in_orderid
      and shipid = in_shipid;
   select count(1) into cntCombined
      from caselabels
      where orderid = in_orderid
        and shipid = in_shipid
        and labeltype = 'CS'
        and nvl(combined,'N') = 'Y';


   select count(1) into cntPlate
      from caselabels
      where orderid = in_orderid
        and shipid = in_shipid
        and changeproc like '%_PLATE';

   select count(1) into cntPP
      from caselabels
      where orderid = in_orderid
        and shipid = in_shipid
        and labeltype = 'PP';
   app_msg('CntPP ' || cntPP);
   /* if preprinted and picked into cartons - the labels won't match
      allow closing of load by ignoring differences */
   if cntPP > 0 and
      nvl(globalConsOrderId,0) <> 0 then
      select count(1) into cntCarton
         from shippingplate
         where orderid = globalConsOrderId
           and shipid = 0
           and type = 'C';
      if cntCarton > 0 then
         app_msg('PP carton skip');
         out_stmt := 'Nothing for order';
         return;
      end if;

   end if;

-- match caselabels with temp ignoring barcode
   for lbl in (select * from caselabels
                  where orderid = in_orderid
                    and shipid = in_shipid) loop
      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop
           --app_msg('orderid   ' || nvl(tmp.orderid,0) || ' = ' || nvl(lbl.orderid,0));
           --app_msg('shipid    ' || nvl(tmp.shipid,0) || ' = ' || nvl(lbl.shipid,0));
           --app_msg('custid    ' || nvl(tmp.custid,'?') || ' = ' || nvl(lbl.custid,'?'));
           --app_msg('item      ' || nvl(tmp.item,'?') || ' = ' ||nvl(lbl.item,'?'));
           --app_msg('lotnumber ' || nvl(tmp.lotnumber,'?') || ' = ' ||nvl(lbl.lotnumber,'?'));
           --app_msg('lpid      ' || nvl(tmp.lpid,'?') || ' = ' ||nvl(lbl.lpid,'?'));
           --app_msg('seq       ' || nvl(tmp.seq,0) || ' = ' ||nvl(lbl.seq,0));
           --app_msg('seqof     ' || nvl(tmp.seqof,0) || ' = ' ||nvl(lbl.seqof,0));
           --app_msg('quantity  ' || nvl(tmp.quantity,0) || ' = ' ||nvl(lbl.quantity,0));
           --app_msg('labeltype ' || nvl(tmp.labeltype,'?') || ' = ' ||nvl(lbl.labeltype,'?'));
         if cntPlate > 0 then
            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
            and nvl(tmp.quantity,0) = nvl(lbl.quantity,0) then
               l_match := 'Y';
               update caselabels_temp
                  set matched = l_match
                  where rowid = tmp.rowid;
               exit;
            end if;
         else
            if l_labels_voided = 'Y' and
               nvl(lbl.labeltype, '?') <> 'PP' then
               if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
               and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
               and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
               and nvl(tmp.item,'?') = nvl(lbl.item,'?')
               and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
               and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
               and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
               and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then
                  l_match := 'Y';
                 update caselabels_temp
                     set matched = l_match
                     where rowid = tmp.rowid;
                  exit;
               end if;
            else
               if nvl(lbl.labeltype, '?') = 'PP' or
                  cntCombined > 0 then
                     if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
                     and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
                     and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
                     and nvl(tmp.item,'?') = nvl(lbl.item,'?')
                   --  and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
                     and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
                     and nvl(tmp.quantity,0) = nvl(lbl.quantity,0) then
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
               end if;
            end if;
         end if;
      end loop;

      if l_match = 'N' then
         app_msg('no match ' ||lbl.lpid);
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

procedure match_ca_labels
   (in_orderid in number,
    in_shipid  in number,
    out_stmt   out varchar2)
is
   l_match varchar2(1);
   l_cnt pls_integer;
begin
   out_stmt := null;
   app_msg('match_ca_labels');
-- match caselabels with temp ignoring barcode
   for lbl in (select * from caselabels
                  where orderid = in_orderid
                    and shipid = in_shipid order by item, lotnumber, quantity) loop
      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N' order by item, lotnumber, quantity) loop
            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
            and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
            and nvl(tmp.seq,0) = nvl(lbl.seq,0)
            and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
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

end match_ca_labels;

procedure merge_labels
   (in_oh    in orderhdr%rowtype,
    in_aux   in auxdata,
    out_stmt out varchar2)
is
   cursor c_alt(p_rowid varchar2) is
      select *
         from ucc_standard_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   l_match varchar2(1);
   l_sscc varchar2(20);
   l_ssccfmt varchar2(40);
   l_cnt integer;
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

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;

      if in_aux.sscctype = '18' then
         l_sscc := zlbl.caselabel_barcode(tmp.custid, tmp.barcodetype);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      else
         l_sscc := sscc14_barcode(tmp.custid, tmp.barcodetype, in_oh);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;

      if in_aux.sscctype = '14' then
         select count(1) into l_cnt
            from caselabels
            where barcode = l_sscc;
         if l_cnt > 0 then
            delete from caselabels where barcode = l_sscc;
         end if;
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
          'UCC_STANDARD_LABELS',
          'sscc',
          tmp.quantity,
          tmp.labeltype,
          in_aux.changeproc);

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
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          shiptocsz,
          shipfromcsz,
          changed,
          lbltypedesc,
          part,
          shipto,
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
          shipto_master,
          totalcases,
          serialnumber,
          useritem1,
          useritem2,
          useritem3,
          expirationdate,
          manufacturedate,
          bigseq,
          bigseqof
          )
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
          alt.itmpasschar01,
          alt.itmpasschar02,
          alt.itmpasschar03,
          alt.itmpasschar04,
          alt.itmpassnum01,
          alt.itmpassnum02,
          alt.itmpassnum03,
          alt.itmpassnum04,
          alt.consigneesku,
          alt.upc,
          alt.zipcodebar,
          alt.zipcodehuman,
          alt.shiptocsz,
          alt.shipfromcsz,
          'Y',
          alt.lbltypedesc,
          alt.part,
          alt.shipto,
          alt.dptchar01_01,
          alt.dptchar02_01,
          alt.dptchar03_01,
          alt.itemqty_01,
          alt.dptchar01_02,
          alt.dptchar02_02,
          alt.dptchar03_02,
          alt.itemqty_02,
          alt.dptchar01_03,
          alt.dptchar02_03,
          alt.dptchar03_03,
          alt.itemqty_03,
          alt.dptchar01_04,
          alt.dptchar02_04,
          alt.dptchar03_04,
          alt.itemqty_04,
          alt.dptchar01_05,
          alt.dptchar02_05,
          alt.dptchar03_05,
          alt.itemqty_05,
          alt.dptchar01_06,
          alt.dptchar02_06,
          alt.dptchar03_06,
          alt.itemqty_06,
          alt.dptchar01_07,
          alt.dptchar02_07,
          alt.dptchar03_07,
          alt.itemqty_07,
          alt.dptchar01_08,
          alt.dptchar02_08,
          alt.dptchar03_08,
          alt.itemqty_08,
          alt.dptchar01_09,
          alt.dptchar02_09,
          alt.dptchar03_09,
          alt.itemqty_09,
          alt.dptchar01_10,
          alt.dptchar02_10,
          alt.dptchar03_10,
          alt.itemqty_10,
          alt.dptchar01_11,
          alt.dptchar02_11,
          alt.dptchar03_11,
          alt.itemqty_11,
          alt.dptchar01_12,
          alt.dptchar02_12,
          alt.dptchar03_12,
          alt.itemqty_12,
          alt.dptchar01_13,
          alt.dptchar02_13,
          alt.dptchar03_13,
          alt.itemqty_13,
          alt.dptchar01_14,
          alt.dptchar02_14,
          alt.dptchar03_14,
          alt.itemqty_14,
          in_oh.shipto_master,
          alt.totalcases,
          alt.serialnumber,
          alt.useritem1,
          alt.useritem2,
          alt.useritem3,
          alt.expirationdate,
          alt.manufacturedate,
          alt.bigseq,
          alt.bigseqof
          );
   end loop;

   out_stmt := 'select L.*'
         || ' from lbl_stdlabels_view L, zseq Z'
         || ' where L.orderid = ' || in_oh.orderid
         || ' and L.shipid = ' || in_oh.shipid
         || ' and Z.seq <= ' || duplicate_cnt(in_oh)
         || ' and L.changed = ''Y'''
         || ' order by L.item, L.seq';

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
   l_mix pls_integer := 0;
begin
  app_msg('shipunit_label ' || io_aux.lpid);
  for od in c_od(io_aux.lpid) loop -- determine whether multiple orderdtl rows
      l_od := od;
      l_cnt := l_cnt + 1;
      exit when l_cnt > 1;
   end loop;

   if l_cnt > 1 then
      l_od := null;
      io_aux.lotnumber := null;
   else
      if io_aux.item is not null then
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
      if upper(io_aux.changeproc) = upper('zstdlabels.stdpallet_mixeditem') then
         select count(distinct item)
           into l_mix
           from shippingplate
          where type in ('F','P')
          start with lpid = io_aux.lpid
         connect by prior lpid = parentlpid;

         if l_mix > 1 then
           io_aux.item := null; -- Mixed items on plate
           app_msg('Mixed items on plate: '||io_aux.lpid);
         end if;
      end if;

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
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
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
             cia.itemalias
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
begin
   app_msg('case_label ' || io_aux.lpid);
   if in_picked then
      globalLabelType := 'CS';
      if nvl(in_consorderid,0) <> 0 then
        app_msg('picked cons  ');
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

                app_msg(upper(io_aux.changeproc));
               if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
                   upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
                   open c_item(sp.custid, sp.item);
                   fetch c_item into it;
                   close c_item;
                   --app_msg(it.item || '  ' ||it.labeluom);
                   if it.labeluom is not null then
                      app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
                   else
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
                   end if;
               elsif  (upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                      upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART_PLATE') then
                   open c_item(sp.custid, sp.item);
                   fetch c_item into it;
                   close c_item;
                   --app_msg(it.item || '  ' ||it.labeluom);
                   if it.labeluom is not null then
                      app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure,'Y');
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
                   else
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure,'Y');
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
                   end if;
               else
            l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
            l_cswt := l_csqty * sp.weight / sp.quantity;
            l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
               end if;

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
               add_label(in_oh, od, in_action, 'C', l_part, io_aux);

               sp.quantity := sp.quantity - io_aux.quantity;
               sp.weight := sp.weight - io_aux.weight;
               l_cnt := l_cnt - 1;
            end loop;
         end loop;
      else
         app_msg('picked not-cons  ');
         -- picked non-consolidated order
         for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                           sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                        from shippingplate
                        where type in ('F','P')
                              and parentlpid not in (select lpid from shippingplate where parentlpid = io_aux.lpid and type = 'C')
                        start with lpid = io_aux.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                        order by item, lotnumber, orderitem, orderlot) loop
            app_msg('--- ' || sp.custid || ' ' || sp.item || ' ' || sp.unitofmeasure ||
                    ' ' || sp.lotnumber || ' ' || sp.orderitem || ' ' || sp.orderlot || ' ' ||
                    sp.quantity || ' ' || sp.weight);
            if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
                upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
               open c_item(sp.custid, sp.item);
               fetch c_item into it;
               close c_item;
               --app_msg(it.item || '  ' ||it.labeluom);
               if it.labeluom is not null then
                  app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                  l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
                  l_cswt := l_csqty * sp.weight / sp.quantity;
                  l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
               else
                  l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
                  l_cswt := l_csqty * sp.weight / sp.quantity;
                  l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
               end if;
            elsif (upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                   upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART_PLATE') then
                open c_item(sp.custid, sp.item);
                fetch c_item into it;
                close c_item;

                if it.labeluom is not null then
                   app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                   l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure,'Y');
                   l_cswt := l_csqty * sp.weight / sp.quantity;
                   l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
                else
                   l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure,'Y');
                   l_cswt := l_csqty * sp.weight / sp.quantity;
                   l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
                end if;
            else
            l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
            l_cswt := l_csqty * sp.weight / sp.quantity;
            l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
            end if;
            --app_msg('zlbl.uom_qty_conv(''' || sp.custid || ''', ''' || sp.item || ''', ' || sp.quantity ||
            --        ', ''' || sp.unitofmeasure || ''', ''' || l_cartonsuom || ''')''');
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
               add_label(in_oh, od, in_action, 'C', l_part, io_aux);

               sp.quantity := sp.quantity - io_aux.quantity;
               sp.weight := sp.weight - io_aux.weight;
               l_cnt := l_cnt - 1;
            end loop;
         end loop;
      end if;
   elsif nvl(in_consorderid,0) <> 0 or in_usebatch then
      app_msg('case_label not-picked cons ');
      globalLabelType := 'PP';
      -- unpicked consolidated order or unpicked non-consolidated batch pick order
      for bt in (select custid, item, uom, orderitem, orderlot,
                        sum(qty) as qty, sum(nvl(weight,0)) as weight
                     from batchtasks
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, uom, orderitem, orderlot
                     order by item, orderitem, orderlot) loop



         if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
             upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
            open c_item(bt.custid, bt.item);
            fetch c_item into it;
            close c_item;
            --app_msg(it.item || '  ' ||it.labeluom);
            if it.labeluom is not null then
               l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, it.labeluom, bt.uom);
               l_cswt := l_csqty * bt.weight / bt.qty;
               l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, it.labeluom);
            else
               l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, l_cartonsuom, bt.uom);
               l_cswt := l_csqty * bt.weight / bt.qty;
               l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom);
            end if;
         elsif (upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART') then
             open c_item(bt.custid, bt.item);
             fetch c_item into it;
             close c_item;

             if it.labeluom is not null then
                app_msg('zlbl.uom_qty_conv('||bt.custid||','||bt.item||','||'1'||','||it.labeluom||','||bt.uom||')');
                l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, it.labeluom, bt.uom,'Y');
                l_cswt := l_csqty * bt.weight / bt.qty;
                l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, it.labeluom,'Y');
             else
                l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, l_cartonsuom, bt.uom,'Y');
                l_cswt := l_csqty * bt.weight / bt.qty;
                l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom,'Y');
             end if;
         else
         l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, l_cartonsuom, bt.uom);
         l_cswt := l_csqty * bt.weight / bt.qty;
         l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom);
         end if;

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
            add_label(in_oh, od, in_action, 'C', l_part, io_aux);

            bt.qty := bt.qty - io_aux.quantity;
            bt.weight := bt.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   else
      app_msg('case_label not-picked non-cons ');
      globalLabelType := 'PP';
      -- unpicked non-consolidated non-batch pick order
      for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                        sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                     from shippingplate
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                     order by item, lotnumber, orderitem, orderlot) loop
         app_msg('changeproc ' || io_aux.changeproc);

         if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
             upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
            open c_item(sp.custid, sp.item);
            fetch c_item into it;
            close c_item;
            --app_msg(it.item || '  ' ||it.labeluom);
            if it.labeluom is not null then
               app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
            else
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
            end if;
         elsif (upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART_PLATE') then
             open c_item(sp.custid, sp.item);
             fetch c_item into it;
             close c_item;

             if it.labeluom is not null then
                app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure,'Y');
                l_cswt := l_csqty * sp.weight / sp.quantity;
                l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
             else
                l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure,'Y');
                l_cswt := l_csqty * sp.weight / sp.quantity;
                l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
             end if;
         else
         l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
         l_cswt := l_csqty * sp.weight / sp.quantity;
         l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
         end if;

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
            add_label(in_oh, od, in_action, 'C', l_part, io_aux);

            sp.quantity := sp.quantity - io_aux.quantity;
            sp.weight := sp.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   end if;

end case_label;

procedure carton_label
   (in_oh          in orderhdr%rowtype,
    in_action      in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
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
begin
   app_msg('carton_label ' || io_aux.lpid);
   if in_picked then
      if nvl(in_consorderid,0) <> 0 then
        app_msg('picked cons  ' || io_aux.sscc_type);
         -- picked consolidated order
        if io_aux.sscc_type = 'CA' then
           for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                             sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                          from shippingplate
                          where type in ('F','P')
                            and orderid = in_oh.orderid
                            and shipid = in_oh.shipid
                            and parentlpid not in (select lpid from shippingplate
                                                    where orderid = in_oh.wave
                                                      and shipid = 0
                                                      and type = 'C')
                          group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                          order by item, lotnumber, orderitem, orderlot) loop
              io_aux.lpid := null;
              l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
              l_cswt := l_csqty * sp.weight / sp.quantity;
              l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
              --app_msg('zlbl.uom_qty_conv(''' || sp.custid || ''', ''' || sp.item || ''', ' || sp.quantity ||
              --        ', ''' || sp.unitofmeasure || ''', ''' || l_cartonsuom || ''')''');
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
                 add_label(in_oh, od, in_action, 'C', l_part, io_aux);
                 sp.quantity := sp.quantity - io_aux.quantity;
                 sp.weight := sp.weight - io_aux.weight;
                 l_cnt := l_cnt - 1;
              end loop;
           end loop;
           for pp in (select lpid, type, fromlpid, quantity, weight, item
                       from shippingplate
                       where orderid = in_oh.wave
                         and shipid = 0
                         and type = 'C'
                         and lpid in (select parentlpid from shippingplate
                                      where orderid = in_oh.orderid and shipid = in_oh.shipid)
                       order by lpid) loop
              app_msg(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
              io_aux.lpid := pp.lpid;
              io_aux.picktolp := pp.fromlpid;
              io_aux.shippingtype := pp.type;
              io_aux.quantity := pp.quantity;
              io_aux.weight := pp.weight;
              io_aux.item := pp.item;
              io_aux.pptype := 'C';
              shipunit_label(in_oh, in_action, 1, io_aux);
           end loop;

         /*
           for pp in (select lpid, type, fromlpid, quantity, weight, item
                       from shippingplate
                       where lpid in (select distinct parentlpid
                                       from shippingplate
                                       where orderid = in_oh.orderid
                                         and shipid = in_oh.shipid)) loop
              l_aux.lpid := pp.lpid;
              l_aux.picktolp := pp.fromlpid;
              l_aux.shippingtype := pp.type;
              if pp.type = 'C' then
                 l_aux.quantity := pp.quantity;
                 l_aux.weight := pp.weight;
                 l_aux.item := pp.item;
                 l_aux.pptype := 'C';
                 shipunit_label(in_oh, in_action, 1, l_aux);
              else
                 l_aux.pptype := 'X';
                 carton_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
              end if;
           end loop;
          */
        else
           app_msg('@cons check ' || in_oh.orderid || '-'|| in_oh.shipid || ' ' ||io_aux.lpid);
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
               if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
                   upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
                  open c_item(sp.custid, sp.item);
                  fetch c_item into it;
                  close c_item;
                  --app_msg(it.item || '  ' ||it.labeluom);
                  if it.labeluom is not null then
                     l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
                     l_cswt := l_csqty * sp.weight / sp.quantity;
                     l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
                  else
                     l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
                     l_cswt := l_csqty * sp.weight / sp.quantity;
                     l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
                  end if;
               elsif  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                      upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART_PLATE' then
                   open c_item(sp.custid, sp.item);
                   fetch c_item into it;
                   close c_item;
                   app_msg(sp.item || '  ' ||it.labeluom);

                   if it.labeluom is not null then
                      app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure,'Y');
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
                   else
                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure,'Y');
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
                   end if;
               else
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
               end if;

               --l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               --l_cswt := l_csqty * sp.weight / sp.quantity;
               --l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);

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
                  add_label(in_oh, od, in_action, 'C', l_part, io_aux);

                  sp.quantity := sp.quantity - io_aux.quantity;
                  sp.weight := sp.weight - io_aux.weight;
                  l_cnt := l_cnt - 1;
               end loop;
            end loop;
        end if;
      else
         if io_aux.sscc_type = 'CA' and
            in_oh.shiptype <> 'S' then
            app_msg('picked non-consolidated CA labels');
            for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                              sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                           from shippingplate
                           where type in ('F','P')
                             and orderid = in_oh.orderid
                             and shipid = in_oh.shipid
                             and parentlpid not in (select lpid from shippingplate
                                                     where orderid = in_oh.orderid
                                                       and shipid = in_oh.shipid
                                                       and type = 'C')
                           group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                           order by item, lotnumber, orderitem, orderlot) loop
               io_aux.lpid := null;
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
               app_msg('zlbl.uom_qty_conv(''' || sp.custid || ''', ''' || sp.item || ''', ' || sp.quantity ||
                       ', ''' || sp.unitofmeasure || ''', ''' || l_cartonsuom || ''')''' || ' = '|| l_cnt);
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
                  add_label(in_oh, od, in_action, 'C', l_part, io_aux);
                  sp.quantity := sp.quantity - io_aux.quantity;
                  sp.weight := sp.weight - io_aux.weight;
                  l_cnt := l_cnt - 1;
               end loop;
            end loop;
            for pp in (select lpid, type, fromlpid, quantity, weight, item
                        from shippingplate
                        where orderid = in_oh.orderid
                          and shipid = in_oh.shipid
                          and type = 'C'
                        order by lpid) loop
               app_msg(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
               io_aux.lpid := pp.lpid;
               io_aux.picktolp := pp.fromlpid;
               io_aux.shippingtype := pp.type;
               io_aux.quantity := pp.quantity;
               io_aux.weight := pp.weight;
               io_aux.item := pp.item;
               io_aux.pptype := 'C';
               shipunit_label(in_oh, in_action, 1, io_aux);
            end loop;
         else
            app_msg('picked not-cons CS ');
            -- picked non-consolidated order
            for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                              sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                           from shippingplate
                           where type in ('F','P')
                                 and parentlpid not in (select lpid from shippingplate where parentlpid = io_aux.lpid and type = 'C')
                           start with lpid = io_aux.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                           order by item, lotnumber, orderitem, orderlot) loop
               app_msg('--- ' || sp.custid || ' ' || sp.item || ' ' || sp.unitofmeasure ||
                       ' ' || sp.lotnumber || ' ' || sp.orderitem || ' ' || sp.orderlot || ' ' ||
                       sp.quantity || ' ' || sp.weight);
               app_msg(upper(io_aux.changeproc));
               if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
                   upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
                   open c_item(sp.custid, sp.item);
                   fetch c_item into it;
                   close c_item;
                   --app_msg(it.item || '  ' ||it.labeluom);
                   if it.labeluom is not null then
                       app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');

                      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
                      l_cswt := l_csqty * sp.weight / sp.quantity;
                      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
                   end if;
               else
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
               end if;
               --app_msg('zlbl.uom_qty_conv(''' || sp.custid || ''', ''' || sp.item || ''', ' || sp.quantity ||
               --        ', ''' || sp.unitofmeasure || ''', ''' || l_cartonsuom || ''')''');
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
                  add_label(in_oh, od, in_action, 'C', l_part, io_aux);

                  sp.quantity := sp.quantity - io_aux.quantity;
                  sp.weight := sp.weight - io_aux.weight;
                  l_cnt := l_cnt - 1;
               end loop;
            end loop;
         end if;
      end if;
   elsif nvl(in_consorderid,0) <> 0 or in_usebatch then
      app_msg('carton_label not-picked cons ');
      globalLabelType := 'PP';
      -- unpicked consolidated order or unpicked non-consolidated batch pick order
      for bt in (select custid, item, uom, orderitem, orderlot,
                        sum(qty) as qty, sum(nvl(weight,0)) as weight
                     from batchtasks
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, uom, orderitem, orderlot
                     order by item, orderitem, orderlot) loop

         l_csqty := zlbl.uom_qty_conv(bt.custid, bt.item, 1, l_cartonsuom, bt.uom);
         l_cswt := l_csqty * bt.weight / bt.qty;
         l_cnt := zlbl.uom_qty_conv(bt.custid, bt.item, bt.qty, bt.uom, l_cartonsuom);

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
            add_label(in_oh, od, in_action, 'C', l_part, io_aux);

            bt.qty := bt.qty - io_aux.quantity;
            bt.weight := bt.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   else
      app_msg('carton_label not-picked non-cons ');
      globalLabelType := 'PP';
      -- unpicked non-consolidated non-batch pick order
      for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                        sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                     from shippingplate
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                     group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                     order by item, lotnumber, orderitem, orderlot) loop

         if  upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK' or
             upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_PLATE' then
            open c_item(sp.custid, sp.item);
            fetch c_item into it;
            close c_item;
            --app_msg(it.item || '  ' ||it.labeluom);
            if it.labeluom is not null then
               app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom);
            else
               l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
               l_cswt := l_csqty * sp.weight / sp.quantity;
               l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
            end if;
         elsif (upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART' or
                upper(io_aux.changeproc) = 'ZSTDLABELS.STDINNERPACK_NOPART') then
             open c_item(sp.custid, sp.item);
             fetch c_item into it;
             close c_item;

             if it.labeluom is not null then
                app_msg('zlbl.uom_qty_conv('||sp.custid||','||sp.item||','||'1'||','||it.labeluom||','||sp.unitofmeasure||')');
                l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, it.labeluom, sp.unitofmeasure,'Y');
                l_cswt := l_csqty * sp.weight / sp.quantity;
                l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, it.labeluom,'Y');
             else
                l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure,'Y');
                l_cswt := l_csqty * sp.weight / sp.quantity;
                l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom,'Y');
             end if;
         else
         l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);
         l_cswt := l_csqty * sp.weight / sp.quantity;
         l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);
         end if;

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
            add_label(in_oh, od, in_action, 'C', l_part, io_aux);

            sp.quantity := sp.quantity - io_aux.quantity;
            sp.weight := sp.weight - io_aux.weight;
            l_cnt := l_cnt - 1;
         end loop;
      end loop;
   end if;

end carton_label;


procedure ctn_group
   (in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_sscc_type in varchar2,
    out_stmt    in out varchar2)
is
   l_aux auxdata;
   l_wave orderhdr.wave%type;
   l_consolidated char(1);
   l_cnt pls_integer;
   cursor c_lbl is
       select distinct labeltype from caselabels
             where orderid = in_oh.orderid
               and shipid = in_oh.shipid
          order by labeltype;
    l_lbltype caselabels.labeltype%type := null;
begin
   app_msg('ctn_group ' );
   if in_picked then
      app_msg('ctn_group picked ' || in_consorderid);
   else
      app_msg('ctn_group not picked ' || in_consorderid);
   end if;
   init_lblgroup(in_oh.orderid, in_oh.shipid, in_picked, in_consorderid, in_usebatch, in_sscctype,
                 in_procname, in_action, 'ctn', l_aux);
   begin
   select nvl(consolidated,'N') into l_consolidated
      from waves
      where wave = (select nvl(original_wave_before_combine, wave)
                       from orderhdr
                       where orderid = in_oh.orderid
                         and shipid = in_oh.shipid);
     exception when no_data_found then
     l_consolidated := 'N';
   end;
   l_aux.sscc_type := in_sscc_type;
   l_aux.totalcases := zstdlabels.calc_totalcases(in_oh.orderid, in_oh.shipid);

   if in_picked then
      if in_sscc_type = 'CA' and
         in_oh.shiptype <> 'S' then
         l_aux.lpid := null;
         l_aux.picktolp := null;
         l_aux.shippingtype := 'P';
         if nvl(in_consorderid,0) <> 0 then
            select count(1) into l_aux.bigseq
               from caselabels
               where (orderid, shipid) in (select orderid, shipid
                                             from orderhdr
                                            where wave = l_wave);
            l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, true);
         else
            l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
            l_aux.bigseq := 0;
         end if;
         carton_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
      else
         if l_consolidated = 'Y' then
            select count(1) into l_aux.bigseq
               from caselabels
               where (orderid, shipid) in (select orderid, shipid
                                             from orderhdr
                                            where wave = l_wave);
            l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, true);
            for pp in (select lpid, type, fromlpid, quantity, weight, item, parentlpid
                        from shippingplate
                        where lpid in (select distinct parentlpid
                                        from shippingplate
                                        where orderid = in_oh.orderid
                                          and shipid = in_oh.shipid)) loop
               l_aux.lpid := pp.lpid;
               l_aux.picktolp := pp.fromlpid;
               l_aux.shippingtype := pp.type;
               if (pp.type = 'C' or
                   (l_aux.rcpt_qty_is_full_qty = 'Y' and
                    pp.type = 'F' and
                    pp.parentlpid is null)) then
                  l_aux.quantity := pp.quantity;
                  l_aux.weight := pp.weight;
                  l_aux.item := pp.item;
                  l_aux.pptype := 'C';
                  shipunit_label(in_oh, in_action, 1, l_aux);
               else
                  l_aux.pptype := 'X';
                  carton_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
               end if;
            end loop;
         else
            if  l_aux.rcpt_qty_is_full_qty = 'Y' then
               l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
               l_aux.bigseq := 0;
               for pp in (select lpid, type, fromlpid, quantity, weight, item, trackingno, parentlpid
                           from shippingplate
                           where orderid = in_oh.orderid
                             and shipid = in_oh.shipid
                             and (parentlpid is null or
                                 (type in ('C','F') and parentlpid is not null))
                           union
                              select lpid, type, fromlpid, quantity, weight, item, trackingno, parentlpid
                               from shippingplate
                              where lpid in (select parentlpid
                                               from shippingplate
                                              where orderid = in_oh.orderid
                                                and shipid = in_oh.shipid
                                                and parentlpid is not null)
                                 and nvl(orderid,0) = 0
                           union
                              select lpid, type, fromlpid, quantity, weight, item, trackingno, parentlpid
                               from shippingplate s
                              where orderid = in_oh.orderid
                                and shipid = in_oh.shipid
                                and type = 'P'
                                and 'M' = (select type from shippingplate where lpid = s.parentlpid)
                           order by lpid) loop
                  app_msg(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
                  if pp.type = 'F' then
                     select count(1) into l_cnt
                        from shippingplate
                        where lpid = pp.parentlpid
                        and type = 'C';
                  else
                     l_cnt := 0;
                  end if;
                  if l_cnt = 0 then

                    l_aux.lpid := pp.lpid;
                    l_aux.picktolp := pp.fromlpid;
                    l_aux.shippingtype := pp.type;
                    if (pp.type = 'C' or
                        (l_aux.rcpt_qty_is_full_qty = 'Y' and
                         pp.type in ('F','P'))) then
                       l_aux.quantity := pp.quantity;
                       l_aux.weight := pp.weight;
                       l_aux.item := pp.item;
                       l_aux.pptype := 'C';
                       shipunit_label(in_oh, in_action, 1, l_aux);
                    else
                       l_aux.pptype := 'X';
                       case_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
                    end if;
                  end if;
               end loop;
            else
               l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
               l_aux.bigseq := 0;
               for pp in (select lpid, type, fromlpid, quantity, weight, item
                           from shippingplate
                           where orderid = in_oh.orderid
                             and shipid = in_oh.shipid
                             and status <> 'U'
                             and (parentlpid is null or
                                 (type = 'C' and parentlpid is not null))
                           order by lpid) loop
                  app_msg(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
                  l_aux.lpid := pp.lpid;
                  l_aux.picktolp := pp.fromlpid;
                  l_aux.shippingtype := pp.type;
                  if (pp.type = 'C' or
                      (l_aux.rcpt_qty_is_full_qty = 'Y' and
                       pp.type = 'F')) then
                     l_aux.quantity := pp.quantity;
                     l_aux.weight := pp.weight;
                     l_aux.item := pp.item;
                     l_aux.pptype := 'C';
                     shipunit_label(in_oh, in_action, 1, l_aux);
                  else
                     l_aux.pptype := 'X';
                  case_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
                  end if;
               end loop;
            end if;
         end if;
      end if;
   else
      -- unpicked order
      l_aux.lpid := null;
      l_aux.picktolp := null;
      l_aux.shippingtype := 'P';
      if nvl(in_consorderid,0) <> 0 then
         select count(1) into l_aux.bigseq
            from caselabels
            where (orderid, shipid) in (select orderid, shipid
                                          from orderhdr
                                         where wave = l_wave);
         l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, true);
      else
         l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
         l_aux.bigseq := 0;
      end if;
      case_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);

   end if;

   if in_action = 'A' then
      if in_procname = 'stdsscccntnt' or
         in_procname = 'stdsscccntnt_plate' then
         out_stmt := 'select L.*'
               || ' from lbl_stdcntnts_view L, zseq Z'
               || ' where L.orderid = ' || in_oh.orderid
               || ' and L.shipid = ' || in_oh.shipid
               || ' and Z.seq <= ' || duplicate_cnt(in_oh)
               || ' order by L.item, L.seq';
      else
         out_stmt := 'select L.*'
            || ' from lbl_stdlabels_view L, zseq Z'
            || ' where L.orderid = ' || in_oh.orderid
            || ' and L.shipid = ' || in_oh.shipid
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
      end if;
   elsif in_func = 'Q' then
      if(in_sscctype = '18') then
        open c_lbl;
         fetch c_lbl into l_lbltype;
         close c_lbl;
       if(l_lbltype = 'CA') then
           match_ca_labels(in_oh.orderid, in_oh.shipid, out_stmt);
       else
          match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
       end if;
     else
         match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
     end if;
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ctn_group;

procedure ccp_group
   (in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    out_stmt    out varchar2)
is
   l_aux auxdata;
   l_wave orderhdr.wave%type := null;
begin

   init_lblgroup(in_oh.orderid, in_oh.shipid, in_picked, in_consorderid, in_usebatch, in_sscctype, in_procname, in_action, 'ccp', l_aux);
   l_aux.totalcases := zstdlabels.calc_totalcases(in_oh.orderid, in_oh.shipid);

   for pp in (select lpid, type, item, fromlpid, quantity, weight
               from shippingplate
               where orderid = in_oh.orderid
                 and shipid = in_oh.shipid
                 and parentlpid is null
               order by lpid) loop
      l_aux.lpid := pp.lpid;
      l_aux.picktolp := pp.fromlpid;
      l_aux.shippingtype := pp.type;
      l_aux.quantity := pp.quantity;
      l_aux.weight := pp.weight;
      l_aux.item := pp.item;
      l_aux.pptype := 'X';
      if nvl(in_consorderid,0) <> 0 then
         select count(1) into l_aux.bigseq
            from caselabels
            where (orderid, shipid) in (select orderid, shipid
                                          from orderhdr
                                         where wave = l_wave);
         l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, true);
      else
         l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
         l_aux.bigseq := 0;
      end if;
      shipunit_label(in_oh, in_action, 1, l_aux);
   end loop;

   if in_action = 'A' then
      out_stmt := 'select L.*'
            || ' from lbl_stdlabels_view L, zseq Z'
            || ' where L.orderid = ' || in_oh.orderid
            || ' and L.shipid = ' || in_oh.shipid
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
   elsif in_func = 'Q' then
      match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ccp_group;

procedure set_debug_level is
begin
   begin
      select abbrev into debug_level
         from lbl_debug_level;
   exception when others then
      debug_level := '0';
   end;
   app_msg('debug level is ' || debug_level);
end set_debug_level;

procedure build_sscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_sscc_type in varchar2,
    in_auxdata in varchar2,
    in_oh in orderhdr%rowtype,
    out_stmt  in out varchar2)
is
   l_auxmsg varchar2(255);
   l_sscc_type varchar2(2);
   i pls_integer;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave
            or original_wave_before_combine = p_wave;
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   l_oh orderhdr%rowtype;
   cursor c_load(in_loadno number) is
      select prono
      from loads
      where loadno = in_loadno;
   ld c_load%rowtype;
   l_proc varchar2(32);
   l_view varchar2(50);

begin
   globalLabelType := 'CS';

   set_debug_level;
   l_sscc_type := in_sscc_type;
   app_msg('in_sscc_type ' || in_sscc_type);
   if in_sscc_type = 'CT' then
      l_sscc_type := '18';
      l_proc := 'stdsscccntnt';
   end if;

      if in_sscc_type = 'SW' then
      l_sscc_type := '18';
      l_proc := 'stdsscc_wave';
   elsif in_sscc_type = 'S4' then
      l_sscc_type := '14';
      l_proc := 'stdsscc14_wave';
   elsif in_sscc_type in ('LS', 'LW') then
      l_sscc_type := '18';
      l_proc := 'stdsscc_load';
   elsif in_sscc_type in ('L4', 'LC') then
      l_sscc_type := '14';
      l_proc := 'stdsscc14_load';
   elsif in_sscc_type = '18' then
      l_proc := 'stdsscc';
   elsif in_sscc_type = 'I1' then
      l_sscc_type := '18';
      l_proc := 'stdinnerpack';
   elsif in_sscc_type = 'I2' then
      l_sscc_type := '18';
      l_proc := 'stdinnerpack_nopart';
   elsif in_sscc_type = 'MU' then
      l_sscc_type := '18';
      l_proc := 'stdmultiuom';
   elsif in_sscc_type = '14' then
      l_sscc_type := '14';
      l_proc := 'stdsscc14';
   end if;
   app_msg( 'lpid ' || in_lpid || ' in_func ' || in_func || ' in_action ' || in_action || ' in_auxdata ' || in_auxdata);
   if in_sscc_type not in ('SW', 'S4', 'LS', 'L4') then /* wave or load has already built the data */
      verify_order(in_lpid, in_func, in_action, in_auxdata, in_sscc_type, l_oh, out_stmt);
      app_msg('out stmt ' || out_stmt);
   else
      out_stmt := 'Continue';
      l_oh := in_oh;
   end if;
   if l_proc = 'stdmultiuom' then
      open  c_load (l_oh.loadno);
      fetch c_load  into ld;
      close c_load;
      if ld.prono is not null then
        l_oh.prono := ld.prono;
      end if;
   end if;
   if out_stmt = 'Continue' then
      if nvl(globalConsorderid,0) = 0 then
         app_msg('not cons 1 ' || l_oh.orderid || ' ' || l_oh.shipid);
         app_msg('l_oh.orderid ' || l_oh.orderid);
         app_msg('l_sscc_type ' || l_sscc_type);
         app_msg('l_proc ' || l_proc);
         app_msg('in_func ' || in_func);
         app_msg('in_action ' || in_action);
         if ord_tbl(1).picked then
            app_msg('ord_tbl(1).picked true');
         else
            app_msg('ord_tbl(1).picked false');
         end if;

         app_msg('glboalConsorderid ' || globalConsorderid);
         if ord_tbl(1).usebatch then
            app_msg('ord_tbl(1).usebatch true');
         else
            app_msg('ord_tbl(1).usebatch false');

         end if;
         app_msg('in_sscc_type ' || in_sscc_type);
         ctn_group(l_oh, l_sscc_type , l_proc, in_func, in_action, ord_tbl(1).picked,
                     globalConsorderid, ord_tbl(1).usebatch, in_sscc_type, out_stmt);
         app_msg('after ctn_group');
      else
         for i in 1..ord_tbl.count loop
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            app_msg('CONS ' || l_oh.orderid || ' ' || l_oh.shipid);
            ctn_group(l_oh, l_sscc_type , l_proc, in_func, in_action, ord_tbl(i).picked,
                        globalConsorderid, ord_tbl(i).usebatch, in_sscc_type, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            out_stmt := 'Continue';
         end loop;
         if in_sscc_type <> 'CT' then
            l_view := ' lbl_stdlabels_view L, zseq Z';
         else
            l_view := ' lbl_stdcntnts_view L, zseq Z';
         end if;
         if in_action = 'A' then
            if globalConsorderid is not null then
               open c_wav(globalConsorderid);
               fetch c_wav into l_oh;
               close c_wav;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || l_view
                  || ' where L.wave = ' || globalConsorderid
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            else
               open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
               fetch c_oh into l_oh;
               close c_oh;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || l_view
                  || ' where L.orderid = ' || ord_tbl(1).orderid
                  || ' and L.shipid = ' || ord_tbl(1).shipid
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            end if;
         elsif in_func = 'X' then
            if globalConsorderid is not null then
               open c_wav(globalConsorderid);
               fetch c_wav into l_oh;
               close c_wav;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || l_view
                  || ' where L.wave = ' || globalConsorderid
                  || ' and L.changed = ''Y'''
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            else
               open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
               fetch c_oh into l_oh;
               close c_oh;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || l_view
                  || ' where L.orderid = ' || ord_tbl(1).orderid
                  || ' and L.shipid = ' || ord_tbl(1).shipid
                  || ' and L.changed = ''Y'''
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';

            end if;
         elsif out_stmt = 'Continue' then
            out_stmt := 'Nothing for order';
         else
            rollback;      -- mismatch, undo any lpid updates
         end if;
         commit;

      end if;
   end if;

end build_sscc;

/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   Plate procedures
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
procedure verify_plate_picked
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_type      in varchar2,
    in_view      in varchar2,
    out_lpid     out varchar2,
    out_oh       out orderhdr%rowtype,
    out_msg      out varchar2)
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
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
   l_consolidated char(1);
   l_wave orderhdr.wave%type := null;
begin
   out_msg := null;
   globalConsorderid := 0;

   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;

-- try to determine order from lpid (could be plate or shippingplate)
   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then            -- direct hit on XP
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then        -- try picked from lp
            l_cnt := 1;
            fetch c_inf into inp;
            if c_inf%found then     -- orderid/shipid not unique
               l_cnt := 2;
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
         l_cnt := 1;
      end if;
      close c_inp;
   end if;
   out_lpid := l_lpid;
   if l_cnt != 1 then
      if in_func = 'Q' then
         if l_cnt = 0 then
            out_msg := 'Order not found';
         else
            out_msg := 'Order not unique';
         end if;
      end if;
      return;
   end if;

-- insure order is for correct customer
   open c_oh(inp.orderid, inp.shipid);
   fetch c_oh into out_oh;
   close c_oh;
-- insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where lpid = in_lpid
        and status in ('U','P');

   if l_cnt != 0 then
      if in_func = 'Q' then
         out_msg := 'Plate has picks';
      end if;
      return;
   end if;
   ord_tbl.delete;
   if inp.shipid != 0 then
      begin
         select nvl(consolidated,'X'), wave into l_consolidated, l_wave
            from waves
            where wave = (select nvl(original_wave_before_combine, wave) from orderhdr
                            where orderid = inp.orderid and shipid =  inp.shipid);
      exception when no_data_found then
         l_consolidated := 'X';
      end;
      if l_consolidated = 'Y' then
         inp.orderid := l_wave;
         for oh in (select orderid, shipid
                      from orderhdr
                     where wave = inp.orderid
                    union
                      select orderid, shipid
                        from orderhdr
                       where original_wave_before_combine = inp.orderid) loop
            check_order(oh.orderid, oh.shipid, idx);
         end loop;
         globalConsorderid := inp.orderid;
      else
         app_msg('check order non cons ' || inp.orderid || ' ' || inp.shipid);
         check_order(inp.orderid, inp.shipid, idx);
      end if;
   else
      for oh in (select orderid, shipid from orderhdr
                  where wave = inp.orderid
                 union
                   select orderid, shipid from orderhdr
                    where original_wave_before_combine = inp.orderid) loop
         check_order(oh.orderid, oh.shipid, idx);
      end loop;
      globalConsorderid := inp.orderid;
   end if;


-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where lpid = l_lpid;
         if l_cnt = 0 then
            out_msg := 'Nothing for plate';
         else
            out_msg := 'OKAY';
         end if;
      else
         if in_type = 'C' then
            out_msg := 'select L.*'
               || ' from lbl_stdpalletcntnts_view L, zseq Z'
               || ' where L.lpid = ''' || l_lpid || ''''
               || ' and Z.seq <= ' || duplicate_cnt(out_oh)
               || ' order by L.item, L.seq';
         else
            out_msg := 'select L.*'
               || ' from ' || in_view || ' L, zseq Z'
               || ' where L.lpid = ''' || l_lpid || ''''
               || ' and Z.seq <= ' || duplicate_cnt(out_oh)
               || ' order by L.item, L.seq';
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

end verify_plate_picked;

procedure init_plate_lblgroup
   (in_lpid        in varchar2,
    in_orderid     in number,
    in_shipid      in number,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_sscctype    in varchar2,
    in_procname    in varchar2,
    in_action      in varchar2,
    in_group       in varchar2,
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
  l_consolidated char(1);
begin
   app_msg('init_plate_lblgroup');
   begin
      select upper(nvl(defaultvalue,'CTN')) into l_cartonsuom
         from systemdefaults
         where defaultid = 'CARTONSUOM';
   exception when no_data_found then
         l_cartonsuom := 'CTN';
   end;

   out_aux := null;
   out_aux.quantity := 0;
   out_aux.weight := 0;
   out_aux.seq := null;
   out_aux.seqof := null;
   begin
   select nvl(consolidated,'N') into l_consolidated
      from waves
      where wave = (select nvl(original_wave_before_combine, wave)
                       from orderhdr
                       where orderid = in_orderid
                         and shipid = in_shipid);
      exception when no_data_found then
      l_consolidated := 'N';
   end;

   if in_picked then
      app_msg('initp ' || l_consolidated || ' <> picked');
   else
      app_msg('initp ' || l_consolidated || ' <> not picked');
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
   out_aux.changeproc := 'zstdlabels.'||upper(in_procname);

   if in_action = 'A' then
      app_msg('$$$$$$$$$$$$$$$$delete 2 ');

      delete from ucc_standard_labels
         where lpid = in_lpid;
      delete from caselabels
         where lpid = in_lpid;
      commit;
   end if;

   delete caselabels_temp;
   delete ucc_standard_labels_temp;

end init_plate_lblgroup;

procedure ctn_plate_group
   (in_lpid     in varchar2,
    in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    in_sscc_type in varchar2,
    out_stmt    in out varchar2)
is
   l_aux auxdata;
   l_consolidated char(1);
   cursor c_lbl is
       select distinct labeltype from caselabels
             where orderid = in_oh.orderid
               and shipid = in_oh.shipid
          order by labeltype;
    l_lbltype caselabels.labeltype%type := null;
    l_wave orderhdr.wave%type;
begin
   app_msg('ctn_plate_group ' );
   if in_picked then
      app_msg('ctn_plate_group picked ' || in_consorderid);
   else
      app_msg('ctn_plate_group not picked ' || in_consorderid);
   end if;
   init_lblgroup(in_oh.orderid, in_oh.shipid, in_picked, in_consorderid, in_usebatch, in_sscctype,
                 in_procname, in_action, 'ctn', l_aux);

   begin
      select nvl(consolidated,'N') into l_consolidated
         from waves
         where wave = (select nvl(original_wave_before_combine, wave)
                        from orderhdr
                        where orderid = in_oh.orderid
                         and shipid = in_oh.shipid);
   exception when no_data_found then
      l_wave := -1;
   end;
   begin
      select nvl(consolidated,'N') into l_consolidated
         from waves
         where wave = l_wave;
   exception when no_data_found then
     l_consolidated := 'N';
   end;
   l_aux.sscc_type := in_sscc_type;
   l_aux.totalcases := zstdlabels.calc_totalcases(in_oh.orderid, in_oh.shipid);
   app_msg('l_consolidated ' || l_consolidated || ' ' || in_oh.orderid || ' ' || in_oh.shipid);
   if l_consolidated = 'Y' then
      l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, true);
      for pp in (select lpid, type, fromlpid, quantity, weight, item
                  from shippingplate
                  where lpid in (select distinct parentlpid
                                  from shippingplate
                                  where orderid = in_oh.orderid
                                    and shipid = in_oh.shipid
                                    and parentlpid = in_lpid)) loop
         l_aux.lpid := pp.lpid;
         l_aux.picktolp := pp.fromlpid;
         l_aux.shippingtype := pp.type;
         select count(1) into l_aux.bigseq
            from caselabels
            where (orderid, shipid) in (select orderid, shipid
                                          from orderhdr
                                         where wave = l_wave);
         if pp.type = 'C' then
            l_aux.quantity := pp.quantity;
            l_aux.weight := pp.weight;
            l_aux.item := pp.item;
            l_aux.pptype := 'C';
            shipunit_label(in_oh, in_action, 1, l_aux);
         else
            l_aux.pptype := 'X';
            carton_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
         end if;
      end loop;
   else
      l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
      for pp in (select lpid, type, fromlpid, quantity, weight, item
                  from shippingplate
                  where orderid = in_oh.orderid
                    and shipid = in_oh.shipid
                    and lpid = in_lpid
                  order by lpid) loop
         app_msg(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
         l_aux.lpid := pp.lpid;
         l_aux.picktolp := pp.fromlpid;
         l_aux.shippingtype := pp.type;
         select count(1) into l_aux.bigseq
            from caselabels
            where orderid = in_oh.orderid
              and shipid = in_oh.shipid;
         if pp.type = 'C' then
            l_aux.quantity := pp.quantity;
            l_aux.weight := pp.weight;
            l_aux.item := pp.item;
            l_aux.pptype := 'C';
            shipunit_label(in_oh, in_action, 1, l_aux);
         else
            l_aux.pptype := 'X';
            case_label(in_oh, in_action, in_picked, in_consorderid, in_usebatch, l_aux);
         end if;
      end loop;
   end if;

   if in_action = 'A' then
      if in_procname = 'stdsscccntnt' or
         in_procname = 'stdsscccnttn_plate' then
         out_stmt := 'select L.*'
               || ' from lbl_stdcntnts_view L, zseq Z'
               || ' where L.orderid = ' || in_oh.orderid
               || ' and L.shipid = ' || in_oh.shipid
               || ' and Z.seq <= ' || duplicate_cnt(in_oh)
               || ' order by L.item, L.seq';
      else
         out_stmt := 'select L.*'
            || ' from lbl_stdlabels_view L, zseq Z'
            || ' where L.orderid = ' || in_oh.orderid
            || ' and L.shipid = ' || in_oh.shipid
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
      end if;
   elsif in_func = 'Q' then
      if(in_sscctype = '18') then
        open c_lbl;
         fetch c_lbl into l_lbltype;
         close c_lbl;
       if(l_lbltype = 'CA') then
           match_ca_labels(in_oh.orderid, in_oh.shipid, out_stmt);
       else
          match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
       end if;
     else
         match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
     end if;
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ctn_plate_group;

procedure ccp_plate_group
   (in_lpid     in varchar2,
    in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    in_picked      in boolean,
    in_consorderid in number,
    in_usebatch    in boolean,
    out_stmt    out varchar2)
is
   l_aux auxdata;
begin
   app_msg('ccp_plate_group');
   init_plate_lblgroup(in_lpid, in_oh.orderid, in_oh.shipid, in_picked, in_consorderid, in_usebatch, in_sscctype, in_procname, in_action, 'ccp', l_aux);
   l_aux.totalcases := zstdlabels.calc_totalcases(in_oh.orderid, in_oh.shipid);
   l_aux.bigseqof := calc_bigseqof(in_oh.orderid, in_oh.shipid, in_oh.shiptype, false);
   select count(1) into l_aux.bigseq
      from caselabels
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid;

   for pp in (select lpid, type, item, fromlpid, quantity, weight
               from shippingplate
               where lpid = in_lpid
               order by lpid) loop
      l_aux.lpid := pp.lpid;
      l_aux.picktolp := pp.fromlpid;
      l_aux.shippingtype := pp.type;
      l_aux.quantity := pp.quantity;
      l_aux.weight := pp.weight;
      l_aux.item := pp.item;
      l_aux.pptype := 'X';
      l_aux.lpid := in_lpid;
      shipunit_label(in_oh, in_action, 1, l_aux);
   end loop;

   if in_action = 'A' then
      out_stmt := 'select L.*'
            || ' from lbl_stdlabels_view L, zseq Z'
            || ' where L.lpid = ''' || in_lpid || ''''
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
   elsif in_func = 'Q' then
      match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ccp_plate_group;




procedure build_plate_sscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_sscc_type in varchar2,
    out_stmt  in out varchar2)
is
   l_auxmsg varchar2(255);
   l_sscc_type varchar2(2);
   i pls_integer;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave
            or original_wave_before_combine = p_wave;

   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   l_oh orderhdr%rowtype;
   l_proc varchar2(32);
   l_view varchar2(50);
   l_lpid shippingplate.lpid%type;
   l_reprint_view varchar2(32);
   l_lpid2 shippingplate.lpid%type;
   l_cnt pls_integer;
   l_parentlpid shippingplate.lpid%type;
begin
   globalLabelType := 'CS';

   set_debug_level;
   l_sscc_type := in_sscc_type;

   app_msg('plate in_sscc_plate_type ' || in_sscc_type);
   l_reprint_view := 'lbl_stdlabels_view';
   if in_sscc_type = 'CT' then
      l_sscc_type := '18';
      l_proc := 'stdsscccntnt_plate';
      l_reprint_view := 'lbl_stdcntnts_view';
   end if;

   if in_sscc_type = '18' then
      l_proc := 'stdsscc_plate';
   elsif in_sscc_type = 'I1' then
      l_sscc_type := '18';
      l_proc := 'stdinnerpack_plate';
   elsif in_sscc_type = 'I2' then
      l_sscc_type := '18';
      l_proc := 'stdinnerpack_nopart_plate';
   elsif in_sscc_type = '14' then
      l_sscc_type := '14';
      l_proc := 'stdsscc14_plate';
   end if;
   l_lpid2 := in_lpid;
   if in_sscc_type <> 'CT' then
      l_view := ' lbl_stdlabels_view L, zseq Z';
   else
      l_view := ' lbl_stdcntnts_view L, zseq Z';
   end if;

   l_cnt := 1;
   while (l_cnt > 0) loop
      begin
         select parentlpid into l_parentlpid
            from shippingplate
            where lpid = l_lpid2;
      exception when no_data_found then
         l_parentlpid := null;
      end;
      if l_parentlpid is not null then
         l_lpid2 := l_parentlpid;
         app_msg('using parentlpid: '||l_lpid2);
      else
        l_cnt := 0;
      end if;
   end loop;

   app_msg( 'lpid p ' || l_lpid2 || ' in_func ' || in_func || ' in_action ' || in_action );
   out_stmt := null;
   verify_plate_picked(l_lpid2, in_func, in_action, 'P', l_reprint_view, l_lpid, l_oh, out_stmt);

   app_msg('bsp out stmt ' || out_stmt);
   if out_stmt = 'Continue' then
      if in_action = 'A' then
        app_msg('@@@@delete 3 ');
        delete from ucc_standard_labels
           where lpid = l_lpid2;
        delete from caselabels
           where lpid = l_lpid2;
        commit;
      end if;

      if nvl(globalConsorderid,0) = 0 then
         app_msg('p not cons 1 ' || l_oh.orderid || ' ' || l_oh.shipid);
         app_msg('p l_oh.orderid ' || l_oh.orderid);
         app_msg('p l_sscc_type ' || l_sscc_type);
         app_msg('p l_proc ' || l_proc);
         app_msg('p in_func ' || in_func);
         app_msg('p in_action ' || in_action);
         ord_tbl(1).picked := true;

         app_msg('p glboalConsorderid ' || globalConsorderid);
         if ord_tbl(1).usebatch then
            app_msg('p ord_tbl(1).usebatch true');
         else
            app_msg('p ord_tbl(1).usebatch false');

         end if;
         app_msg('p in_sscc_type ' || in_sscc_type);

         ctn_plate_group(l_lpid, l_oh, l_sscc_type, l_proc, in_func, in_action, ord_tbl(1).picked,
                     globalConsorderid, ord_tbl(1).usebatch, in_sscc_type, out_stmt);
         app_msg('p after ctn_group');
         if in_action = 'A' then
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view
               || ' where L.lpid = ''' || l_lpid2 || ''''
               || ' and Z.seq <= ' || duplicate_cnt(l_oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view
               || ' where L.lpid = ''' || l_lpid2 || ''''
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(l_oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
      else
         for i in 1..ord_tbl.count loop
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            app_msg('CONS ' || l_oh.orderid || ' ' || l_oh.shipid);
            ctn_plate_group(l_lpid2, l_oh, l_sscc_type , l_proc, in_func, in_action, true,
                        globalConsorderid, ord_tbl(i).usebatch, in_sscc_type, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            out_stmt := 'Continue';
         end loop;
         if in_action = 'A' then
            open c_wav(globalConsorderid);
            fetch c_wav into l_oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view
               || ' where L.lpid = ''' || l_lpid2 || ''''
               || ' and Z.seq <= ' || duplicate_cnt(l_oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         elsif in_func = 'X' then
            open c_wav(globalConsorderid);
            fetch c_wav into l_oh;
            close c_wav;
            out_stmt := 'select L.*, Z.seq as zseq_seq from '
               || l_view
               || ' where L.lpid = ''' || l_lpid2 || ''''
               || ' and L.changed = ''Y'''
               || ' and Z.seq <= ' || duplicate_cnt(l_oh)
               || ' order by L.item, L.orderid, L.shipid, L.seq';
         elsif out_stmt = 'Continue' then
            out_stmt := 'Nothing for order';
         else
            rollback;      -- mismatch, undo any lpid updates
         end if;
         commit;

      end if;
   end if;

end build_plate_sscc;

procedure generate_load_labels
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    in_sscctype in varchar2,
    out_stmt  out varchar2)
is
l_oh orderhdr%rowtype;
cursor c_oh(p_orderid number, p_shipid number) is
   select *
      from  orderhdr oh
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid;
type waverectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type,
   wave orderhdr.wave%type);
type wavetbltype is table of waverectype index by binary_integer;
wave_tbl wavetbltype;
j binary_integer;
wave_found boolean;
l_sscc_type varchar2(2);

begin
   /* in_sscctype will be 18 if called from stdsscc_load, 14 if called from stdsscc14_load
      this will be used to call build_sscc with the corret value for in_sscc_type */
   set_debug_level;
   verify_load(in_lpid, in_func, in_action, in_auxdata, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      j := 0;
      for i in 1..ord_tbl.count loop
         if ord_tbl(i).conswave is null then
            l_oh := null;
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            if in_sscctype = '18' then
               l_sscc_type := 'LS';
            else
               l_sscc_type := 'L4';
            end if;
            app_msg(ord_tbl(i).orderid ||'-' || ord_tbl(i).shipid || ' ->' || ord_tbl(i).conswave);
            build_sscc(in_lpid, in_func, in_action, l_sscc_type, 'ORDER|' || ord_tbl(i).orderid || '|' ||
                       ord_tbl(i).shipid, l_oh, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            if in_action = 'A' then
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                     || ' lbl_stdlabels_view L , zseq Z'
                     || ' where L.loadno = ' || l_oh.loadno
                     || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                     || ' order by L.item, L.orderid, L.shipid, L.seq';
            end if;
         else
            if j = 0 then
               j := 1;
               wave_tbl(j).wave := ord_tbl(i).conswave;
               wave_tbl(j).orderid := ord_tbl(i).orderid;
               wave_tbl(j).shipid := ord_tbl(i).shipid;
            else
               wave_found := false;
               for k in 1..wave_tbl.count loop
                  if wave_tbl(k).wave = ord_tbl(i).conswave then
                     wave_found := true;
                  end if;
               end loop;
               if not wave_found then
                  j := j + 1;
                  wave_tbl(j).wave := ord_tbl(i).conswave;
                  wave_tbl(j).orderid := ord_tbl(i).orderid;
                  wave_tbl(j).shipid := ord_tbl(i).shipid;
               end if;
            end if;
         end if;
      end loop;
      if j > 0 then
         for k in 1..wave_tbl.count loop
            l_oh := null;
            open c_oh(wave_tbl(k).orderid, wave_tbl(k).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            app_msg('load process cons ' || wave_tbl(k).orderid ||'-' || wave_tbl(k).shipid || ' ->' || wave_tbl(k).wave);
            if in_sscctype = '18' then
               l_sscc_type := 'LW';
            else
               l_sscc_type := 'LC';
            end if;

            build_sscc(in_lpid, in_func, in_action, l_sscc_type, 'ORDER|' || wave_tbl(k).wave || '|0',
                       l_oh, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            if in_action = 'A' then
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                     || ' lbl_stdlabels_view L , zseq Z'
                     || ' where L.loadno = ' || l_oh.loadno
                     || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                     || ' order by L.item, L.orderid, L.shipid, L.seq';
            end if;

         end loop;
      end if;
   end if;

end generate_load_labels;

procedure generate_wave_labels
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    in_sscctype in varchar2,
    out_stmt  out varchar2)
is
l_oh orderhdr%rowtype;
cursor c_oh(p_orderid number, p_shipid number) is
   select *
      from  orderhdr oh
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid;
l_sscc_type varchar2(2);
begin
   set_debug_level;
   verify_wave(in_lpid, in_func, in_action, in_auxdata, l_oh, out_stmt);
   if in_sscctype = '18' then
      l_sscc_type := 'SW';
   else
      l_sscc_type := 'S4';
   end if;

   if out_stmt = 'Continue' then
      if globalConsorderid <> 0 then
         build_sscc(in_lpid, in_func, in_action, l_sscc_type, 'ORDER|' || globalConsorderid || '|0', null, out_stmt);
      else
         for i in 1..ord_tbl.count loop
            l_oh := null;
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            build_sscc(in_lpid, in_func, in_action, l_sscc_type, 'ORDER|' || ord_tbl(i).orderid || '|' ||
                       ord_tbl(i).shipid, l_oh, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            if in_action = 'A' then
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                     || ' lbl_stdlabels_view L , zseq Z'
                     || ' where L.wave = ' || l_oh.wave
                     || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                     || ' order by L.item, L.orderid, L.shipid, L.seq';
            end if;
         end loop;

      end if;
   end if;

end generate_wave_labels;

-- Public

procedure stdsscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_sscc(in_lpid, in_func, in_action, '18', in_auxdata, null, out_stmt);
end stdsscc;

procedure stdcase
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
begin
   globalLabelType := 'CA';
   app_msg('globalLabelType: '||globalLabelType);
   build_sscc(in_lpid, in_func, in_action, 'CA', in_auxdata, null, out_stmt);
end stdcase;

procedure stdsscc14
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_sscc(in_lpid, in_func, in_action, '14', in_auxdata, null, out_stmt);
end stdsscc14;

procedure stdsscccntnt
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_sscc(in_lpid, in_func, in_action, 'CT', in_auxdata, null, out_stmt);
   /*
   set_debug_level;
   out_stmt := null;

   verify_order_picked(in_lpid, in_func, in_action, 'C', l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ctn_group(l_oh, '18', 'stdsscccntnt', in_func, in_action, true, 0, false, null, out_stmt);
   end if;
   */
end stdsscccntnt;

procedure stdpallet
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'PL';
   app_msg('globalLabelType: '||globalLabelType);
      set_debug_level;
   out_stmt := null;
   verify_order_picked(in_lpid, in_func, in_action, 'P', l_oh, out_stmt);
   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'stdpallet', in_func, in_action, true, 0, false, out_stmt);
   end if;
end stdpallet;

procedure stdinnerpack
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   out_stmt := null;
   build_sscc(in_lpid, in_func, in_action, 'I1', in_auxdata, null, out_stmt);
end stdinnerpack;

procedure stdinnerpack_nopart
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   out_stmt := null;
   build_sscc(in_lpid, in_func, in_action, 'I2', in_auxdata, null, out_stmt);
end stdinnerpack_nopart;

procedure stdmultiuom
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is

   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   out_stmt := null;
   build_sscc(in_lpid, in_func, in_action, 'MU', in_auxdata, null, out_stmt);
end stdmultiuom;

procedure stdpallet_plate
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
   l_lpid shippingplate.lpid%type;
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   set_debug_level;
   out_stmt := null;
   verify_plate_picked(in_lpid, in_func, in_action, 'P', null, l_lpid, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ccp_plate_group(l_lpid, l_oh, '18', 'stdpallet_plate', in_func, in_action, true, 0, false, out_stmt);
   end if;

end stdpallet_plate;


procedure stdsscc_plate
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_plate_sscc(in_lpid, in_func, in_action, '18', out_stmt);
end stdsscc_plate;

procedure stdsscc14_plate
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_plate_sscc(in_lpid, in_func, in_action, '14', out_stmt);
end stdsscc14_plate;

procedure stdsscccntnt_plate
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   build_plate_sscc(in_lpid, in_func, in_action, 'CT', out_stmt);
end stdsscccntnt_plate;

procedure stdinnerpack_plate
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_stmt   out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   out_stmt := null;
   build_plate_sscc(in_lpid, in_func, in_action, 'I1', out_stmt);
end stdinnerpack_plate;

procedure stdinnerpack_nopart_plate
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_stmt   out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
   out_stmt := null;
   build_plate_sscc(in_lpid, in_func, in_action, 'I2', out_stmt);
end stdinnerpack_nopart_plate;

procedure stdpallet_mixeditem
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   globalLabelType := 'CS';
   app_msg('globalLabelType: '||globalLabelType);
      set_debug_level;
   out_stmt := null;
   verify_order_picked(in_lpid, in_func, in_action, 'P', l_oh, out_stmt);
   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'stdpallet_mixeditem', in_func, in_action, true, 0, false, out_stmt);
   end if;
end stdpallet_mixeditem;

procedure stdsscc_load
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
begin
   generate_load_labels(in_lpid, in_func, in_action, in_auxdata, '18', out_stmt);
end stdsscc_load;

procedure stdsscc14_load
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
begin
   generate_load_labels(in_lpid, in_func, in_action, in_auxdata, '14', out_stmt);
end stdsscc14_load;

procedure stdsscc_wave
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
l_oh orderhdr%rowtype;
cursor c_oh(p_orderid number, p_shipid number) is
   select *
      from  orderhdr oh
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid;

begin
   generate_wave_labels(in_lpid, in_func, in_action, in_auxdata, '18', out_stmt);
end stdsscc_wave;

procedure stdsscc14_wave
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
l_oh orderhdr%rowtype;
cursor c_oh(p_orderid number, p_shipid number) is
   select *
      from  orderhdr oh
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid;

begin
   generate_wave_labels(in_lpid, in_func, in_action, in_auxdata, '14', out_stmt);
end stdsscc14_wave;

function calc_totalcases
   (in_orderid in number,
    in_shipid  in number)
return ucc_standard_labels.totalcases%type
is
   cursor c_wcl(p_orderid number, p_shipid number) is
      select totalcases
         from weber_case_labels
         where orderid = p_orderid
           and shipid = p_shipid;
   wcl c_wcl%rowtype := null;
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
         wcl.totalcases := wcl.totalcases + lbl_remainder_qty(sp.custid, sp.item,
                                                              sp.unitofmeasure, sp.quantity);
      end loop;
   end if;
   return wcl.totalcases;
end calc_totalcases;
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
               l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
               l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
                     l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
                     l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
                  l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
            l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
            l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
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
               l_bigseqof := l_bigseqof + lbl_remainder_qty(sp.custid, sp.item,
                     sp.unitofmeasure, sp.quantity);
            end loop;
         end if;
      end loop;
   end if;
   return l_bigseqof;
end calc_bigseqof;
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
exception when others then
   return 'N';
end part_of_carton;

procedure stdreprintbc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   l_auxdata varchar2(255);
   l_pos number;
   l_barcode varchar2(20);
   l_cnt pls_integer;

begin
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');

   if l_auxdata = '(none)' then
      if in_func = 'Q' then
         out_stmt := 'Nothing for barcode';
      else
         out_stmt := '';
      end if;
   end if;
   l_pos := instr(l_auxdata, '|');
   if l_pos = 0 then
      if in_func = 'Q' then
         out_stmt := 'Nothing for barcode';
      else
         out_stmt := '';
      end if;
   end if;
   if upper(substr(l_auxdata, 1, l_pos-1)) != 'BC' then
      if in_func = 'Q' then
         out_stmt := 'Nothing for barcode';
      else
         out_stmt := '';
      end if;
   end if;

   l_barcode := substr(l_auxdata, l_pos+1);

   if in_func = 'Q' then
      select count(1) into l_cnt
         from ucc_standard_labels
         where sscc = l_barcode;
      if l_cnt = 0 then
         out_stmt := 'Nothing for barcode';
      else
         out_stmt := 'OKAY';
      end if;
      return;
   end if;
   out_stmt := 'Select * from ucc_standard_labels where sscc = ''' || l_barcode ||'''';

end stdreprintbc;

end zstdlabels;
/
show error package body zstdlabels;
exit;
