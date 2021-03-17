CREATE OR REPLACE package body zclabels as
--
-- $Id: zuccbody.sql 815 2007-04-20 15:43:49Z ed $
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
   customeritem ucc_standard_labels.customeritem%type,
   department ucc_standard_labels.department%type,
   division ucc_standard_labels.division%type,
   itemsize ucc_standard_labels.itemsize%type,
   makrforstate ucc_standard_labels.makrforstate%type,
   markforaddr1 ucc_standard_labels.markforaddr1%type,
   markforaddr2 ucc_standard_labels.markforaddr2%type,
   markforcity ucc_standard_labels.markforcity%type,
   markforcountrycode ucc_standard_labels.markforcountrycode%type,
   markforname ucc_standard_labels.markforname%type,
   markforstate ucc_standard_labels.markforstate%type,
   markforzip ucc_standard_labels.markforzip%type,
   pptype shippingplate.type%type,
   storebarcode ucc_standard_labels.storebarcode%type,
   storehuman ucc_standard_labels.storehuman%type,
   storenum ucc_standard_labels.storenum%type,
   style ucc_standard_labels.style%type,
   vendorbar ucc_standard_labels.vendorbar%type,
   vendorhuman ucc_standard_labels.vendorhuman%type,
   vendoritem ucc_standard_labels.vendoritem%type);

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
   usebatch boolean);
type ordtbltype is table of ordrectype index by binary_integer;
ord_tbl ordtbltype;
globalConsorderid number(9);

-- Private
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

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   if oh.orderstatus in ('6','7','8','9') then
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

procedure verify_order_cons
   (in_lpid          in varchar2,
    in_func          in varchar2,
    in_action        in varchar2,
    in_customer      in varchar2,
    in_auxdata       in varchar2,
    out_oh           out orderhdr%rowtype,
    out_msg          out varchar2)
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

-- Load the translation table.

   if in_action not in ('A','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');
   if l_auxdata = '(none)' then
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
         l_orderid := inp.orderid;
         l_shipid := inp.shipid;
      end if;
   end if;

   if l_auxdata != '(none)' then
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

--    Load the translation table.

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
                        where wave = l_orderid) loop
               check_order(oh.orderid, oh.shipid, in_customer, idx);
            end loop;
            globalConsorderid := l_orderid;
         else
            check_order(l_orderid, l_shipid, in_customer, idx);
         end if;
      else
         for oh in (select orderid, shipid from orderhdr
                     where wave = l_orderid) loop
            check_order(oh.orderid, oh.shipid, in_customer, idx);
         end loop;
         globalConsorderid := l_orderid;
      end if;
      if ord_tbl.count = 0 then
         if in_func = 'Q' then
            out_msg := '3 Nothing for order';
         end if;
         return;
      end if;

      l_cnt := 0;
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
      if nvl(globalConsorderid,0) = 0 then
         open c_oh(l_orderid, l_shipid);
         fetch c_oh into out_oh;
         close c_oh;
      end if;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         if nvl(globalConsorderid,0) <> 0 then
            select count(1) into l_cnt
               from ucc_standard_labels
               where wave = globalConsorderid;
         else
--            app_msg('non cons reprint');
            select count(1) into l_cnt
               from ucc_standard_labels
               where orderid = l_orderid
                 and shipid = l_shipid;
         end if;
--         app_msg('l_cnt ' || l_cnt);
        if l_cnt = 0 then
            out_msg := '4 Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         if nvl(globalConsorderid,0) <> 0 then
            open c_wav(globalConsorderid);
            fetch c_wav into oh;
            close c_wav;
            out_msg := 'select * from '
                  || ' lbl_stdlabels_view  '
                  || ' where wave = ' || globalConsorderid
                  || ' order by item, orderid, shipid, seq';
         else
            open c_oh(l_orderid, l_shipid);
            fetch c_oh into oh;
            close c_oh;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_stdlabels_view '
                  || ' where orderid = ' || l_orderid
                  || ' and shipid = ' || l_shipid
                  || ' order by item, orderid, shipid, seq';
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

end verify_order_cons;

procedure verify_order
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_customer  in varchar2,
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
   order_cnt pls_integer := 0;
   sql_stmt varchar2(1024);
   l_instr pls_integer;
begin
   out_msg := null;

   if in_action not in ('A','P') then
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
         out_msg := 'select * from '
               || ' lbl_stdlabels_view '
               || ' where orderid = ' || inp.orderid
               || ' and shipid = ' || inp.shipid
               || ' order by item, seq';
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

procedure verify_load
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_customer  in varchar2,
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
   order_cnt pls_integer := 0;
   sql_stmt varchar2(1024);
   l_instr pls_integer;
begin
   out_msg := null;

   if in_action not in ('A','P') then
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
            out_msg := 'Load not found';
         else
            out_msg := 'Load not unique';
         end if;
      end if;
      return;
   end if;


-- insure order is for correct customer
   open c_oh(inp.orderid, inp.shipid);
   fetch c_oh into out_oh;
   close c_oh;

   if out_oh.loadno is null then
      out_msg := 'No loadno';


   end if;

-- insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where loadno = out_oh.loadno
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
         out_msg := 'select * from '
               || ' lbl_stdlabels_view'
               || ' where loadno = ' || out_oh.loadno
               || ' order by item, seq';
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
   (in_orderid  in number,
    in_shipid   in number,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_action   in varchar2,
    in_group    in varchar2,
    out_aux     out auxdata)
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
   out_aux := null;
   out_aux.quantity := 0;
   out_aux.weight := 0;
   out_aux.seq := 0;

   out_aux.seqof := 0;
   for pp in (select lpid, type, quantity from shippingplate
               where lpid in (select parentlpid
                                from shippingplate
                                where orderid = in_orderid
                                  and shipid = in_shipid
                                  and parentlpid is not null)) loop
         out_aux.seqof := out_aux.seqof + 1;
   end loop;


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
   out_aux.changeproc := 'zclblbody.'||upper(in_procname);

   if in_action = 'A' then
      delete from ucc_standard_labels
         where orderid = in_orderid
           and shipid = in_shipid;
      commit;
   end if;

end init_lblgroup;


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
   l_upc ucc_standard_labels.upc%type;
   l_manupass customer.manufacturerucc_passthrufield%type := null;
   l_cnt integer;
   cmdSql varchar2(200);
begin
   l_labeltype := 'PL';
   l_barcodetype := '1';
   l_lbltypedesc := 'pallet';

   if io_aux.item is null then
      itm := null;
      itm.item := 'Mixed';
      itm.descr := 'Mixed';
   else
      open c_itm(in_oh.custid, io_aux.item);
      fetch c_itm into itm;
      close c_itm;
   end if;

   if in_action = 'A' then
      l_sscc := zlbl.caselabel_barcode(in_oh.custid, l_barcodetype);
      l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
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
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          color,
          customeritem,
          department,
          division,
          itemsize,
          makrforstate,
          markforaddr1,
          markforaddr2,
          markforcity,
          markforcountrycode,
          markforname,
          markforstate,
          markforzip,
          storenum,
          style,
          vendoritem
      )
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
          l_upc,
          '420'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          '(420)'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          io_aux.storebarcode,
          io_aux.storehuman,
          io_aux.vendorbar,
          io_aux.vendorhuman,
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          io_aux.color,
          io_aux.customeritem,
          io_aux.department,
          io_aux.division,
          io_aux.itemsize,
          io_aux.makrforstate,
          io_aux.markforaddr1,
          io_aux.markforaddr2,
          io_aux.markforcity,
          io_aux.markforcountrycode,
          io_aux.markforname,
          io_aux.markforstate,
          io_aux.markforzip,
          io_aux.storenum,
          io_aux.style,
          io_aux.vendoritem
          );
      end if;
exception when others then
  zut.prt(sqlcode|| ' '|| sqlerrm);

end add_label;




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
   l_orderid orderhdr.orderid%type;
   l_count pls_integer;
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
      if io_aux.shippingtype != 'F' then
         select orderid into l_orderid
            from shippingplate
            where lpid = io_aux.lpid;
         if (l_orderid = 0 or
             nvl(globalconsorderid,0) != 0) then
            select sum(quantity) into io_aux.quantity
               from shippingplate
               where parentlpid = io_aux.lpid
                 and orderid = in_oh.orderid
                 and shipid = in_oh.shipid;
            select sum(weight) into io_aux.weight
               from shippingplate
               where parentlpid = io_aux.lpid
                 and orderid = in_oh.orderid
                 and shipid = in_oh.shipid;
            select count(distinct item) into l_count
               from shippingplate
               where parentlpid = io_aux.lpid
                 and orderid = in_oh.orderid
                 and shipid = in_oh.shipid;
            if l_count > 1 then
               io_aux.item := null;
            else
               select distinct item into io_aux.item
                  from shippingplate
                  where parentlpid = io_aux.lpid
                 and orderid = in_oh.orderid
                 and shipid = in_oh.shipid;
            end if;
         end if;
      end if;
      add_label(in_oh, l_od, in_action, 'S', null, io_aux);

      l_lblcount := l_lblcount - 1;
   end loop;
end shipunit_label;

procedure ccp_group
   (in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    out varchar2)
is
   l_aux auxdata;
begin

   init_lblgroup(in_oh.orderid, in_oh.shipid, in_sscctype, in_procname, in_action, 'ccp', l_aux);
   for pp in (select lpid, type, item, fromlpid, quantity, weight
               from shippingplate
               where lpid in (select parentlpid
                                from shippingplate
                                where orderid = in_oh.orderid
                                  and shipid = in_oh.shipid
                                  and parentlpid is not null)) loop
      l_aux.lpid := pp.lpid;
      l_aux.picktolp := pp.fromlpid;
      l_aux.shippingtype := pp.type;
      l_aux.quantity := pp.quantity;
      l_aux.weight := pp.weight;
      l_aux.item := pp.item;
      l_aux.pptype := 'X';
      shipunit_label(in_oh, in_action, 1, l_aux);
   end loop;

   if in_action = 'A' then
      out_stmt := 'select *'
            || ' from lbl_stdlabels_view '
            || ' where orderid = ' || in_oh.orderid
            || ' and shipid = ' || in_oh.shipid
            || ' order by item, seq';
   end if;
   commit;

end ccp_group;


-- Public


procedure pallet_order
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;
   verify_order(in_lpid, in_func, in_action, '*', l_oh, out_stmt);
   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'pallet_order', in_func, in_action, out_stmt);
   end if;

end pallet_order;

procedure pallet_load
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
   l_loadno orderhdr.loadno%type;
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;

begin
   out_stmt := null;

   verify_load(in_lpid, in_func, in_action, '*', l_oh, out_stmt);
   if out_stmt = 'Continue' then
      l_loadno := l_oh.loadno;
      for oh in (select orderid, shipid from orderhdr where loadno = l_loadno)  loop
         open c_oh(oh.orderid, oh.shipid);
         fetch c_oh into l_oh;
         close c_oh;
         ccp_group(l_oh, '18', 'pallet_load', in_func, in_action, out_stmt);
      end loop;
      out_stmt := 'select * from '
            || ' lbl_stdlabels_view '
            || ' where loadno = ' || l_loadno
            || ' order by orderid, item, seq';
   end if;

end pallet_load;

procedure pallet_cons
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   l_auxmsg varchar2(255);
   i pls_integer;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   l_oh orderhdr%rowtype;

begin
   out_stmt := null;
   verify_order_cons(in_lpid, in_func, in_action, '*', in_auxdata, l_oh, out_stmt);
   if out_stmt = 'Continue' then
      if globalConsorderid = 0 then
         ccp_group(l_oh, '18', 'pallet_cons', in_func, in_action, out_stmt);
      else
         for i in 1..ord_tbl.count loop
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            ccp_group(l_oh, '18', 'pallet_cons', in_func, in_action, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            out_stmt := 'Continue';
         end loop;

         if in_action = 'A' then
            if nvl(globalConsorderid,0) <> 0 then
               open c_wav(globalConsorderid);
               fetch c_wav into l_oh;
               close c_wav;
               out_stmt := 'select * from '
                  || ' lbl_stdlabels_view  '
                  || ' where wave = ' || globalConsorderid
                  || ' order by item, orderid, shipid, seq';
            else
               open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
               fetch c_oh into l_oh;
               close c_oh;
               out_stmt := 'select *  from '
                  || ' lbl_stdlabels_view  '
                  || ' where orderid = ' || ord_tbl(1).orderid
                  || ' and shipid = ' || ord_tbl(1).shipid
                  || ' order by item, orderid, shipid, seq';
            end if;
         elsif out_stmt = 'Continue' then
            out_stmt := 'A Nothing for order';
         else
            rollback;      -- mismatch, undo any lpid updates
         end if;
         commit;

      end if;
   end if;

end pallet_cons;

end zclabels;
/
show error package body zclabels;
exit;
