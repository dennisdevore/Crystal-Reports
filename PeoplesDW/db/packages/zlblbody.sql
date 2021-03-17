create or replace package body alps.zlabels as
--
-- $Id$
--


-- Private procedures


procedure from_uom_to_uom
(
    in_custid   IN      varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_skips    in varchar2,
    io_level    in out integer,
    io_qty      in out number,
    io_errmsg   IN OUT     varchar2
)
is
begin

    zbut.from_uom_to_uom(in_custid, in_item, in_qty,
                    in_from_uom, in_to_uom,
                    in_skips, io_level,
            io_qty, io_errmsg);

   return;

end from_uom_to_uom;


procedure parse_db_object
   (in_object       in varchar2,
    out_schema      out varchar2,
    out_object_name out varchar2)
is
   l_pos number;
   l_obj varchar2(255) := upper(rtrim(ltrim(in_object)));
begin

   l_pos := instr(l_obj, '.');
   if l_pos = 0 then
      select user into out_schema from dual;
      out_object_name := l_obj;
   else
      out_schema := substr(l_obj, 1, l_pos-1);
      out_object_name := substr(l_obj, l_pos+1);
   end if;
end parse_db_object;


-- Public functions


function cs_labels
   (in_lpid in varchar2)
return number
is
   cursor c_lp is
      select custid, item, unitofmeasure, quantity
         from shippingplate
         where type in ('F','P')
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   msg varchar2(200);
   factor number;
   start_level integer;
   rtnqty number := 0;
begin

   for lp in c_lp loop
      start_level := 1;
      from_uom_to_uom(lp.custid, lp.item, 1, lp.unitofmeasure, 'CS', '', start_level, factor, msg);
      if msg = 'OKAY' then
         rtnqty := rtnqty + ceil(lp.quantity * factor);
      end if;
   end loop;
   return rtnqty;

exception
   when OTHERS then
      return 0;
end cs_labels;


function uom_qty_conv
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_floor_yn in varchar2 default null)
return number
is
   msg varchar2(200);
   factor number;
   start_level integer := 1;
   rtnqty number := 0;
begin

   from_uom_to_uom(in_custid, in_item, in_qty, in_from_uom, in_to_uom, '', start_level, factor, msg);
   if msg = 'OKAY' then
      if nvl(in_floor_yn, 'N') = 'Y' then
         rtnqty := floor(factor);
      else
      rtnqty := ceil(factor);
   end if;
   end if;
   return rtnqty;

exception
   when OTHERS then
      return 0;
end uom_qty_conv;


function extract_word
   (in_phrase in varchar2,
    in_wordno in number)         -- 1-relative
return varchar2
is
   word varchar2(255) := null;
   phrase varchar2(255) := ltrim(rtrim(in_phrase));
   wordno number := in_wordno;
begin

   loop
      exit when phrase is null;
      word := substr(phrase, 1, instr(phrase, ' ')-1);
      phrase := ltrim(substr(phrase, instr(phrase, ' ')));
      exit when wordno <= 1;
      wordno := wordno - 1;
   end loop;
   return word;

exception
   when OTHERS then
      return null;
end extract_word;


function p1pk_qty_conv
   (in_taskid   in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_totalize in varchar2)
return number
is
   cursor c_p1pk is
      select T.orderid, T.shipid, nvl(P.seqof, 0) seqof
         from tasks T, p1pkcaselabels P
         where T.taskid = in_taskid
           and P.orderid (+) = T.orderid
           and P.shipid (+) = T.shipid
           and P.custid (+) = in_custid
           and P.item (+) = in_item;
   p1pk c_p1pk%rowtype;
   msg varchar2(200);
   factor number;
   start_level integer := 1;
   buomqty number := 0;
   rtnqty number := 0;
begin

   if in_totalize = 'N' then
-- only consider task
      select nvl(sum(quantity), 0)
         into buomqty
         from shippingplate
         where taskid = in_taskid
           and custid = in_custid
           and item = in_item
           and type in ('F', 'P');

      from_uom_to_uom(in_custid, in_item, 1, in_from_uom, in_to_uom, '', start_level, factor, msg);
      if msg = 'OKAY' then
         rtnqty := ceil(buomqty * factor);
      end if;
      return rtnqty;
   end if;

-- use already calculated seqof
   open c_p1pk;
   fetch c_p1pk into p1pk;
   close c_p1pk;
   if p1pk.seqof > 0 then
      return p1pk.seqof;
   end if;

-- calculate seqof from all tasks
   for tsk in (select taskid from tasks
                  where orderid = p1pk.orderid and shipid = p1pk.shipid) loop
      select nvl(sum(quantity), 0)
         into buomqty
         from shippingplate
         where taskid = tsk.taskid
           and custid = in_custid
           and item = in_item
           and type in ('F', 'P');

      from_uom_to_uom(in_custid, in_item, 1, in_from_uom, in_to_uom, '', start_level, factor, msg);
      if msg = 'OKAY' then
         rtnqty := rtnqty + ceil(buomqty * factor);
      end if;
   end loop;
   return rtnqty;

exception
   when OTHERS then
      return 0;
end p1pk_qty_conv;


function p1pk_task_carton_count
   (in_taskid   in number)
return number
is
   msg varchar2(200);
   qty subtasks.pickqty%type;
   factor number;
   start_level integer := 1;
   ctncnt number := 0;
begin

   select nvl(sum(CTC.seqcnt), 0)
      into ctncnt
      from (select cartontype, count(distinct cartonseq) seqcnt
               from subtasks
               where taskid = in_taskid
                 and picktotype in ('PACK', 'TOTE')
               group by cartontype) CTC;

   for fpl in (select S.picktotype, S.labeluom, S.pickqty, S.pickuom, L.loctype,
                      I.baseuom, S.custid, S.item
               from subtasks S, location L, custitem I
               where S.taskid = in_taskid
                 and S.picktotype not in ('PACK', 'TOTE')
                 and L.facility = S.facility
                 and L.locid = S.fromloc
                 and I.custid = S.custid
                 and I.item = S.item) loop

      qty := 1;
      if fpl.picktotype not in ('FULL', 'PAL') then
         start_level := 1;
         msg := 'BAD';
         if fpl.loctype = 'PF' then
            from_uom_to_uom(fpl.custid, fpl.item, 1, fpl.pickuom, fpl.baseuom, '',
                  start_level, factor, msg);
         elsif fpl.labeluom is not null then
            from_uom_to_uom(fpl.custid, fpl.item, 1, fpl.pickuom, fpl.labeluom, '',
                  start_level, factor, msg);
         end if;
         if msg = 'OKAY' then
            qty := qty + ceil(fpl.pickqty * factor);
         end if;
      end if;
      ctncnt := ctncnt + qty;
   end loop;

   return ctncnt;

exception
   when OTHERS then
      return 0;
end p1pk_task_carton_count;


function p1pk_carton_cnt
   (in_taskid   in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_totalize in varchar2)
return number
is
   cursor c_p1pk is
      select T.orderid, T.shipid, nvl(P.seqof, 0) seqof
         from tasks T, p1pkcaselabels P
         where T.taskid = in_taskid
           and P.orderid (+) = T.orderid
           and P.shipid (+) = T.shipid
           and P.custid (+) = in_custid
           and P.item (+) = in_item;
   p1pk c_p1pk%rowtype;
begin

   if in_totalize = 'N' then
      return p1pk_task_carton_count(in_taskid);
   end if;

   open c_p1pk;
   fetch c_p1pk into p1pk;
   close c_p1pk;
   if p1pk.seqof <= 0 then
      p1pk.seqof := 0;
      for tsk in (select taskid from tasks
                     where orderid = p1pk.orderid and shipid = p1pk.shipid) loop
         p1pk.seqof := p1pk.seqof + p1pk_task_carton_count(tsk.taskid);
      end loop;
   end if;

   return p1pk.seqof;

exception
   when OTHERS then
      return 0;
end p1pk_carton_cnt;


function caselabel_barcode
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
   barcode varchar2(20);
   seqname varchar2(30);
   seqval varchar2(9);
   ix integer;
   cc integer;
   cnt integer;
   m_length integer;
   m_max_value varchar2(9);
   cmdSql varchar2(200);
begin
   open c_cust;
   fetch c_cust into manucc;
   close c_cust;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   seqname := 'CSLBL_' || manucc || '_SEQ';
   select count(1)
      into cnt
      from user_sequences
      where sequence_name = seqname;

   m_length := length(manucc);
   ix := 16 - m_length;

   if cnt = 0 then
      m_max_value := substr('999999999', 1,ix);
      cmdsql := 'create sequence ' || seqname
            || ' increment by 1 start with 1 maxvalue ' || m_max_value
            ||  ' minvalue 1 nocache cycle';
      execute immediate cmdSql;
   end if;

   cmdSql := 'select lpad(' || seqname ||
                     '.nextval, ' || ix || ', ''0'') from dual';
   execute immediate cmdSql into seqval;

   barcode := '00'|| lpad(substr(in_type, 1, 1), 1, '1') || manucc || seqval;

   cc := 0;
   for cnt in 1..19 loop
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
      return '00000000000000000000';
end caselabel_barcode;


function caselabel_barcode_var_manucc
   (in_custid in varchar2,
    in_type   in varchar2,
    in_manucc in varchar2)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc
         from customer
         where custid = in_custid;
   manucc varchar2(10) := null;
   barcode varchar2(20);
   seqname varchar2(30);
   seqval varchar2(9);
   ix integer;
   cc integer;
   cnt integer;
   m_length integer;
   m_max_value varchar2(9);
   cmdSql varchar2(200);
begin
   if in_manucc is null then
      open c_cust;
      fetch c_cust into manucc;
      close c_cust;
   else
      manucc := in_manucc;
   end if;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;


   seqname := 'CSLBL_' || manucc || '_SEQ';
   select count(1)
      into cnt
      from user_sequences
      where sequence_name = seqname;

   m_length := length(manucc);
   ix := 16 - m_length;
   if cnt = 0 then
      m_max_value := substr('999999999', 1,ix);
      cmdsql := 'create sequence ' || seqname
            || ' increment by 1 start with 1 maxvalue ' || m_max_value
            ||  ' minvalue 1 nocache cycle';
      execute immediate cmdSql;
   end if;

   cmdSql := 'select lpad(' || seqname ||
                     '.nextval, ' || ix || ', ''0'') from dual';
   execute immediate cmdSql into seqval;

   barcode := '00'|| lpad(substr(in_type, 1, 1), 1, '1') || manucc || seqval;

   cc := 0;
   for cnt in 1..19 loop
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
      return '00000000000000000000';
end caselabel_barcode_var_manucc;


function extract_qualified_data
   (in_phrase    in varchar2,
    in_qualifier in varchar2)
return varchar2
is
   data varchar2(255) := null;
   phrase varchar2(255) := in_phrase;
   pos number;
begin

   loop
      exit when phrase is null;
      pos := instr(phrase, '|');
      if instr(phrase, in_qualifier) = 1 then
         if pos > 0 then
            data := substr(phrase, length(in_qualifier)+1, pos-length(in_qualifier)-1);
         else
            data := substr(phrase, length(in_qualifier)+1);
         end if;
         exit;
      end if;

      if pos <= 0 then
         exit;
      end if;
      phrase := substr(phrase, pos+1);
   end loop;
   return data;

exception
   when OTHERS then
      return null;
end extract_qualified_data;


function format_string
   (in_string in varchar2,
    in_format in varchar2)
return varchar2
is
   fx integer := 1;
   sx integer := 1;
   fmt_string varchar2(255) := null;
begin

   for fx in 1..nvl(length(in_format), 0)
   loop
      if substr(in_format, fx, 1) = '?' then
         if sx <= nvl(length(in_string), 0) then
            fmt_string := fmt_string || substr(in_string, sx, 1);
            sx := sx + 1;
         end if;
      else
         fmt_string := fmt_string || substr(in_format, fx, 1);
      end if;
   end loop;
   return fmt_string;

exception
   when OTHERS then
      return null;
end format_string;


function is_lp_unprocessed_autogen
   (in_lpid  in varchar2)
return varchar2
is
   cursor c_lp(p_lpid varchar2) is
      select facility, location, status
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype := null;
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select prtlps_on_load_arrival, prtlps_profid,
             prtlps_def_handling
         from custitemview
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype := null;
   l_cnt pls_integer;
   l_item_cnt pls_integer := 0;
   l_result varchar2(1) := 'Y';
begin

   open c_lp(in_lpid);
   fetch c_lp into lp;
   if c_lp%found
   and (nvl(lp.status,'?') = 'U') then
      l_result := zrf.is_location_physical(lp.facility, lp.location);
   else
      l_result := 'N';
   end if;
   close c_lp;

   if l_result = 'Y' then
      for lp in (select distinct custid, item
                     from plate
                     where type ='PA'
                     start with lpid = in_lpid
                     connect by prior lpid = parentlpid) loop

         l_item_cnt := l_item_cnt + 1;
         open c_ci(lp.custid, lp.item);
         fetch c_ci into ci;
         if c_ci%found
         and (nvl(ci.prtlps_on_load_arrival,'N') = 'Y')
         and (ci.prtlps_profid is not null)
         and (ci.prtlps_def_handling is not null) then
            select count(1)
               into l_cnt
               from labelprofileline
               where profid = ci.prtlps_profid
                 and businessevent = 'RECA'
                 and is_passthru_satisfied('P', in_lpid, null,
                        passthrufield, passthruvalue) = 'Y';
            if l_cnt = 0 then
               l_result := 'N';
            end if;
         else
            l_result := 'N';
         end if;
         close c_ci;
         exit when l_result = 'N';
      end loop;
      if l_item_cnt = 0 then
         l_result := 'N';
      end if;
   end if;

   return l_result;

exception
   when OTHERS then
      return 'N';
end is_lp_unprocessed_autogen;


function is_order_satisfied
   (in_orderid        in number,
    in_shipid         in number,
    in_field          in varchar2,
    in_value          in varchar2,
    in_calledfromwave in varchar2 default 'N')
return varchar2
is
   l_value varchar2(255);
   l_tests varchar2(255) := trim(in_value);
   l_neg boolean := false;
   l_pos number;
   l_wave orderhdr.wave%type;
begin

   if in_calledfromwave = 'N' then
      l_wave := zcord.cons_orderid(in_orderid, in_shipid);
      if l_wave != 0 then
         return is_wave_satisfied(l_wave, in_field, in_value);
      end if;
   end if;

   execute immediate
         'select trim(to_char(' || in_field || ')) from orderhdr '
         || ' where orderid = ' || in_orderid
         || ' and shipid = ' || in_shipid
      into l_value;

-- null test
   if l_tests is null then
      if l_value is null then
         return 'Y';
      else
         return 'N';
      end if;
   end if;

-- not null test
   if l_tests in ('!','*') then
      if l_value is null then
         return 'N';
      else
         return 'Y';
      end if;
   end if;

-- negation
   if substr(l_tests, 1, 1) = '!' then
      if l_value is null then    -- null will match any negation except a single !
         return 'Y';
      end if;
      l_neg := true;
      l_tests := substr(l_tests, 2);
   end if;

-- a null value cannot match anything at this point
   if l_value is null then
      return 'N';
   end if;

-- both test and value are non-null
   l_pos := instr(l_tests, '|');
   if l_pos != 0 then
-- disjunction
      l_pos := instr('|'||l_tests||'|', '|'||l_value||'|');
      if (l_pos > 0 and not l_neg)
      or (l_pos = 0 and l_neg) then
         return 'Y';
      end if;
   elsif (l_tests = l_value and not l_neg)
      or (l_tests != l_value and l_neg) then
         return 'Y';
   end if;

   return 'N';

exception
   when OTHERS then
      return 'Y';
end is_order_satisfied;


function is_wave_satisfied
   (in_wave  in number,
    in_field in varchar2,
    in_value in varchar2)
return varchar2
is
   l_retcode varchar2(1) := 'Y';
begin
   for wv in (select orderid, shipid from orderhdr
               where (wave = in_wave or
                      original_wave_before_combine = in_wave)
                 and orderstatus != 'X') loop
      l_retcode := is_order_satisfied(wv.orderid, wv.shipid, in_field, in_value, 'Y');
      exit when l_retcode = 'N';
   end loop;
   return l_retcode;
end is_wave_satisfied;


function is_load_satisfied
   (in_loadno in number,
    in_field  in varchar2,
    in_value  in varchar2)
return varchar2
is
   l_retcode varchar2(1) := 'Y';
begin
   for ld in (select orderid, shipid from orderhdr
               where loadno = in_loadno
                 and orderstatus != 'X') loop
      l_retcode := is_order_satisfied(ld.orderid, ld.shipid, in_field, in_value);
      exit when l_retcode = 'N';
   end loop;
   return l_retcode;
end is_load_satisfied;

function is_lpid_satisfied
   (in_lpid   in varchar2,
    in_field  in varchar2,
    in_value  in varchar2)
return varchar2
is
   l_retcode varchar2(1) := 'Y';
begin
   for ld in (select oh.orderid, oh.shipid 
				from shippingplate sp, orderhdr oh
               where (sp.lpid = in_lpid or sp.fromlpid = in_lpid)
				 and oh.orderid = sp.orderid and oh.shipid = sp.shipid
                 and oh.orderstatus != 'X') loop
      l_retcode := is_order_satisfied(ld.orderid, ld.shipid, in_field, in_value);
      exit when l_retcode = 'N';
   end loop;
   return l_retcode;
end is_lpid_satisfied;

function is_bc_satisfied
   (in_barcode in varchar2,
    in_field   in varchar2,
    in_value   in varchar2)
return varchar2
is
   l_retcode varchar2(1) := 'Y';
begin
   for bc in (select o.orderid, o.shipid
                from ucc_standard_labels u, orderhdr o
               where sscc = in_barcode
                 and o.orderid = u.orderid
                 and o.shipid = u.shipid
                 and o.orderstatus != 'X') loop
      l_retcode := zlbl.is_order_satisfied(bc.orderid, bc.shipid, in_field, in_value, 'Y');
      exit when l_retcode = 'N';
   end loop;
   return l_retcode;
end is_bc_satisfied;

function is_passthru_satisfied
   (in_type          in varchar2,
    in_lpid          in varchar2,
    in_auxdata       in varchar2,
    in_passthrufield in varchar2,
    in_passthruvalue in varchar2)
return varchar2
is
   cursor c_slp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_lp(p_lpid varchar2) is
      select orderid, shipid
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype := null;
   l_pos number;
   l_obj varchar2(255);
begin

   if in_passthrufield is null then
      return 'Y';
   end if;

   if in_lpid is null then
      l_pos := instr(in_auxdata, '|');
      if l_pos != 0 then
         l_obj := upper(substr(in_auxdata, 1, l_pos-1));
         if l_obj = 'WAVE' then
            return is_wave_satisfied(to_number(substr(in_auxdata, l_pos+1)),
                  in_passthrufield, in_passthruvalue);
         elsif l_obj = 'LOAD' then
            return is_load_satisfied(to_number(substr(in_auxdata, l_pos+1)),
                  in_passthrufield, in_passthruvalue);
         elsif l_obj = 'LPID' then
            return is_lpid_satisfied(substr(in_auxdata, l_pos+1),
                  in_passthrufield, in_passthruvalue);
         elsif l_obj = 'ORDER' then
            l_obj := substr(in_auxdata, l_pos+1);
            l_pos := instr(l_obj, '|');
            if l_pos != 0 then
               if to_number(substr(l_obj, l_pos+1)) = 0 then
                  return is_wave_satisfied(to_number(substr(l_obj, 1, l_pos-1)),
                        in_passthrufield, in_passthruvalue);
               else
                  return is_order_satisfied(to_number(substr(l_obj, 1, l_pos-1)),
                        to_number(substr(l_obj, l_pos+1)), in_passthrufield, in_passthruvalue);
               end if;
            end if;
         elsif l_obj = 'BC' then
            return is_bc_satisfied(substr(in_auxdata, l_pos+1),
                                   in_passthrufield, in_passthruvalue);
         end if;
      end if;
      return 'N';
   end if;

   if in_type = 'S' then
      open c_slp(in_lpid);
      fetch c_slp into lp;
      close c_slp;
   else
      open c_lp(in_lpid);
      fetch c_lp into lp;
      close c_lp;
   end if;
   if lp.shipid = 0 then
      return is_wave_satisfied(lp.orderid, in_passthrufield, in_passthruvalue);
   else
      return is_order_satisfied(lp.orderid, lp.shipid, in_passthrufield, in_passthruvalue);
   end if;

end is_passthru_satisfied;


-- Public procedures


procedure print_a_plate
   (in_lpid        in varchar2,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2,
    in_action      in varchar2 := 'A')
is
begin
   out_message := null;
   print_a_plate_copies(in_lpid, in_label_rowid, in_printer, in_facility, in_user,
      in_action, 1, null, out_message);
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_a_plate;


procedure print_a_plate_copies
   (in_lpid        in varchar2,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_action      in varchar2,
    in_copies      in number,
    in_auxdata     in varchar2,
    out_message    out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   cursor c_prt is
      select queue
         from printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from spoolerqueues
         order by oraclepipe desc;
   queuename varchar2(32);
   status number;
   l_msg varchar2(1000);
begin
   out_message := null;

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   l_msg := 'PLATE' || chr(9) ||
            nvl(in_lpid, '(none)') || chr(9) ||
            in_label_rowid || chr(9) ||
            in_printer || chr(9) ||
            in_facility || chr(9) ||
            in_user || chr(9) ||
            in_action || chr(9) ||
            in_copies || chr(9) ||
            nvl(in_auxdata, '(none)') || chr(9);

   status := zqm.send(LABEL_DEFAULT_QUEUE,'MSG',l_msg,1,queuename);
   commit;

   if (status != 1) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
   rollback;
end print_a_plate_copies;


procedure print_order
   (in_orderid     in number,
    in_shipid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2)
is
begin
   out_message := null;
   print_order_copies(in_orderid, in_shipid, in_label_rowid, in_printer, in_facility,
         in_user, 1, out_message);
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_order;


procedure print_order_copies
   (in_orderid     in number,
    in_shipid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_copies      in number,
    out_message    out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   cursor c_prt is
      select queue
         from printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from spoolerqueues
         order by oraclepipe desc;
   queuename varchar2(32);
   status number;
   l_msg varchar2(1000);
begin
   out_message := null;

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   l_msg := 'ORDER' || chr(9) ||
            in_orderid || chr(9) ||
            in_shipid || chr(9) ||
            in_label_rowid || chr(9) ||
            in_printer || chr(9) ||
            in_facility || chr(9) ||
            in_user || chr(9) ||
            in_copies || chr(9);

   status := zqm.send(LABEL_DEFAULT_QUEUE,'MSG',l_msg,1,queuename);
   commit;

   if (status != 1) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
   rollback;
end print_order_copies;


procedure print_task
   (in_taskid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2)
is
  cnt number;
  strOutMsg appmsgs.msgtext%type;
begin
   out_message := null;
   select count(1)
     into cnt
     from tasks tk, waves wv
    where tk.taskid = in_taskid
      and wv.wave = tk.wave
      and nvl(mass_manifest,'N') = 'Y';

   if cnt >= 1 then
     zms.log_msg('WaveRelease', null, null,
                 'Print task ' || in_taskid,
                 'T', in_user, strOutMsg);
   end if;

   print_task_copies(in_taskid, in_label_rowid, in_printer, in_facility,
         in_user, 1, out_message);
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_task;


procedure print_task_copies
   (in_taskid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_copies      in number,
    out_message    out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   cursor c_prt is
      select queue
         from printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from spoolerqueues
         order by oraclepipe desc;
   queuename varchar2(32);
   status number;
   l_msg varchar2(1000);
begin
   out_message := null;

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   l_msg := 'TASK' || chr(9) ||
            in_taskid || chr(9) ||
            in_label_rowid || chr(9) ||
            in_printer || chr(9) ||
            in_facility || chr(9) ||
            in_user || chr(9) ||
            in_copies || chr(9);

   status := zqm.send(LABEL_DEFAULT_QUEUE,'MSG',l_msg,1,queuename);
   commit;

   if (status != 1) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
      rollback;
end print_task_copies;


procedure p1pk_postprocess
   (in_orderid   in number,
    in_shipid    in number,
    in_custid    in varchar2,
    in_stkno     in varchar2,
    in_seq       in number,
    in_seqof     in number,
    in_barcode   in varchar2,
    in_lpid      in varchar2,
    in_lotnumber in varchar2)
is
begin
   if in_seq = in_seqof then
      delete p1pkcaselabels
         where orderid = in_orderid
           and shipid = in_shipid
           and custid = in_custid
           and item = in_stkno;
   else
      update p1pkcaselabels
         set seq = in_seq
         where orderid = in_orderid
           and shipid = in_shipid
           and custid = in_custid
           and item = in_stkno;
      if sql%rowcount = 0 then
         insert into p1pkcaselabels
            (orderid, shipid, custid, item, seq, seqof)
         values (in_orderid, in_shipid, in_custid, in_stkno, in_seq, in_seqof);
      end if;
   end if;

   insert into caselabels
      (orderid, shipid, custid, item, lotnumber, lpid,
       barcode, seq, seqof, created)
   values (in_orderid, in_shipid, in_custid, in_stkno, in_lotnumber, in_lpid,
      in_barcode, in_seq, in_seqof, sysdate);

   commit;
exception
   when OTHERS then
      rollback;
end p1pk_postprocess;


procedure print_a_label
   (in_label_format_path in varchar2,
    in_label_data        in varchar2,
    in_printer           in varchar2,
    in_facility          in varchar2,
    in_copies            in varchar2,
    in_user              in varchar2,
    out_message    out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   cursor c_prt is
      select queue
         from printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from spoolerqueues
         order by oraclepipe desc;
   queuename varchar2(32);
   status number;
   l_msg varchar2(4000);
begin
   out_message := 'OKAY';

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   l_msg := 'LABELREQ' || chr(9) ||
            in_label_format_path || chr(9) ||
            in_label_data || chr(9) ||
            in_printer || chr(9) ||
            in_facility || chr(9) ||
            in_copies || chr(9) ||
            in_user || chr(9);

   status := zqm.send(LABEL_DEFAULT_QUEUE,'MSG',l_msg,1,queuename);
   commit;

   if (status != 1) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
      rollback;
end print_a_label;


procedure get_plate_profid
   (in_event   in varchar2,
    in_lpid    in varchar2,
    in_type    in varchar2,
    in_action  in varchar2,
    out_uom    out varchar2,
    out_profid out varchar2,
    out_msg    out varchar2)
is
begin
   out_uom := null;
   out_profid := null;
   out_msg := null;
   get_plate_profid_aux(in_event, in_lpid, in_type, in_action, null, out_uom, out_profid,
         out_msg);
exception
   when OTHERS then
      out_profid := null;
end get_plate_profid;


procedure get_plate_profid_aux
   (in_event  in varchar2,
    in_lpid    in varchar2,
    in_type    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_uom    out varchar2,
    out_profid out varchar2,
    out_msg    out varchar2)
is
   cursor c_lp is
      select custid, item, uomentered as uom,
             zcord.cons_shipto(orderid, shipid) as consignee
         from plate
         where lpid = in_lpid;
   cursor c_dlp is
      select custid, item, uomentered as uom,
             zcord.cons_shipto(orderid, shipid) as consignee
         from deletedplate
         where lpid = in_lpid;
   cursor c_sp is
      select custid, item, pickuom as uom,
             zcord.cons_shipto(orderid, shipid) as consignee
         from shippingplate
         where lpid = in_lpid;
   cursor c_wave(p_wave number) is
      select OH.custid, OD.item, OD.uom,
             zcord.cons_shipto(OH.orderid, OH.shipid) as consignee
         from orderhdr OH, orderdtl OD
         where ((OH.original_wave_before_combine is not null and
                 OH.original_wave_before_combine  = p_wave) or
                 (OH.original_wave_before_combine is null and
                  OH.wave = p_wave))
           and OH.orderstatus != 'X'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
         order by 1, 2, 4;
   cursor c_load(p_loadno number) is
      select OH.custid, OD.item, OD.uom,
             zcord.cons_shipto(OH.orderid, OH.shipid) as consignee
         from orderhdr OH, orderdtl OD
         where OH.loadno = p_loadno
           and OH.orderstatus != 'X'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
         order by 1, 2, 4;
   cursor c_order(p_orderid number, p_shipid number) is
      select custid, item, uom,
             zcord.cons_shipto(orderid, shipid) as consignee
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
         order by 1, 2, 4;
   cursor c_bc(p_barcode varchar2) is
      select OH.custid, OD.item, OD.uom,
             zcord.cons_shipto(OH.orderid, OH.shipid) as consignee
         from orderhdr OH, orderdtl OD, ucc_standard_labels U
         where U.sscc = p_barcode
           and OH.orderid = U.orderid
           and OH.shipid = U.shipid
           and OH.orderstatus != 'X'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
         order by 1, 2, 4;
   lp c_lp%rowtype;
   cursor c_lbl_all(p_custid varchar2, p_item varchar2, p_consignee varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item = p_item
           and consignee = p_consignee;
   cursor c_lbl_cus_cons(p_custid varchar2, p_consignee varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee = p_consignee;
   cursor c_lbl_cus_item(p_custid varchar2, p_item varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item = p_item
           and consignee is null;
   cursor c_lbl_cus(p_custid varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee is null;
   lbl c_lbl_all%rowtype;
   l_found boolean := false;
   l_pos number;
   l_obj varchar2(255);

   function any_key_data
      (in_view    in varchar2,
       in_keycol  in varchar2,
       in_key     in varchar2,
       in_auxdata in varchar2,
       in_type    in varchar2)
   return boolean
   is
      cursor c_tab_cols(p_owner varchar2, p_table varchar2, p_column varchar2) is
         select data_type, data_length
            from all_tab_columns
            where owner = p_owner
              and table_name = p_table
              and column_name = p_column;
      tc c_tab_cols%rowtype;
      l_found boolean;
      l_out varchar2(255) := null;
      l_cnt pls_integer;
      l_schema varchar2(255);
      l_obj varchar2(255);
      l_pos number;
      l_aux varchar2(255);
      l_sql varchar2(1024);
      l_lptbl varchar2(20);
   begin
      parse_db_object(in_view, l_schema, l_obj);
      open c_tab_cols(l_schema, l_obj, in_keycol);
      fetch c_tab_cols into tc;
      l_found := c_tab_cols%found;
      close c_tab_cols;
      if l_found then
         if (tc.data_length != 15) or (substr(upper(tc.data_type),1,7) != 'VARCHAR') then
            l_found := false;       -- keycol not of "type" lpid
         else
            l_sql := 'select count(1) from ' || in_view || ' where ' || in_keycol;

            if in_key is not null then
               l_sql := l_sql || ' = ''' || in_key || '''';
               execute immediate l_sql into l_cnt;
               if l_cnt = 0 then
                  l_found := false;
               end if;
            else
               if in_type = 'S' then
                  l_lptbl := 'shippingplate';
               else
                  l_lptbl := 'plate';
               end if;

               l_pos := instr(in_auxdata, '|');
               if l_pos != 0 then
                  l_aux := upper(substr(in_auxdata, 1, l_pos-1));
                  if l_aux = 'WAVE' then
                     l_sql := l_sql
                        || ' in (select P.lpid from orderhdr O, ' || l_lptbl || ' P'
                        || '   where O.wave = ' || to_number(substr(in_auxdata, l_pos+1))
                        || '     and P.orderid = O.orderid and P.shipid = O.shipid)';
                     execute immediate l_sql into l_cnt;
                     if l_cnt = 0 then
                        l_found := false;
                     end if;
                  elsif l_aux = 'LOAD' then
                     l_sql := l_sql
                        || ' in (select lpid from ' || l_lptbl
                        || ' where loadno = ' || to_number(substr(in_auxdata, l_pos+1)) || ')';
                     execute immediate l_sql into l_cnt;
                     if l_cnt = 0 then
                        l_found := false;
                     end if;
                  elsif l_aux = 'LPID' then
                     l_sql := l_sql
                        || ' in (select lpid from ' || l_lptbl
                        || ' where lpid = ''' || substr(in_auxdata, l_pos+1) || ''')';
                     execute immediate l_sql into l_cnt;
                     if l_cnt = 0 then
                        l_found := false;
                     end if;
                  elsif l_aux = 'ORDER' then
                     l_aux := substr(in_auxdata, l_pos+1);
                     l_pos := instr(l_aux, '|');
                     if l_pos != 0 then
                        if to_number(substr(l_aux, l_pos+1)) = 0 then
                           l_sql := l_sql
                              || ' in (select P.lpid from orderhdr O, ' || l_lptbl || ' P'
                              || '   where O.wave = ' || to_number(substr(l_aux, 1, l_pos-1))
                              || '     and P.orderid = O.orderid and P.shipid = O.shipid)';
                           execute immediate l_sql into l_cnt;
                           if l_cnt = 0 then
                              l_found := false;
                           end if;
                        else
                           l_sql := l_sql
                              || ' in (select lpid from ' || l_lptbl
                              || ' where orderid = ' || to_number(substr(l_aux, 1, l_pos-1))
                              || ' and shipid = ' || to_number(substr(l_aux, l_pos+1)) || ')';
                           execute immediate l_sql into l_cnt;
                           if l_cnt = 0 then
                              l_found := false;
                           end if;
                        end if;
                     else
                        l_found := false;
                     end if;
                  else
                     l_found := false;
                  end if;
               else
                  l_found := false;
               end if;
            end if;
         end if;
      else
         select count(1) into l_cnt
            from user_arguments
            where package_name = l_schema
              and object_name = l_obj;
         if l_cnt = 4 then
            l_sql := 'begin ' || in_view || '(''' || in_key || ''', ''Q'', '''
                  || in_action || ''', :OUT1); end;';
            execute immediate l_sql
                  using out l_out;
         elsif l_cnt = 5 then
            l_sql := 'begin ' || in_view || '(''' || in_key || ''', ''Q'', '''
                  || in_action || ''', ''' || in_auxdata || ''', :OUT1); end;';
            execute immediate l_sql
                  using out l_out;
         end if;
         if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
            l_found := true;
         else
            out_msg := l_out;
         end if;
      end if;
      return l_found;
   exception
      when OTHERS then
         return false;
   end any_key_data;

   procedure any_proflines
      (in_profid  in varchar2,
       in_event   in varchar2,
       in_uom     in varchar2,
       in_type    in varchar2,
       in_lpid    in varchar2,
       in_auxdata in varchar2,
       out_uom    out varchar2,
       out_found  out boolean)
   is
      cursor c_pf is
         select viewname, viewkeycol, uom, passthrufield, passthruvalue
            from labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and nvl(viewkeyorigin,'?') = in_type
              and (uom = in_uom or uom is null)
            order by uom;               -- uom appears before null
      pf c_pf%rowtype;
      l_found boolean := false;
      l_passthruok varchar2(2);
   begin
      out_uom := null;
      open c_pf;
      loop
         fetch c_pf into pf;
         exit when c_pf%notfound;

         l_passthruok := 'Y';
         if pf.passthrufield is not null then
            l_passthruok := is_passthru_satisfied(in_type, in_lpid, in_auxdata,
                  pf.passthrufield, pf.passthruvalue);
         end if;

         if l_passthruok = 'Y' then
            l_found := any_key_data(pf.viewname, pf.viewkeycol, in_lpid, in_auxdata, in_type);
            if l_found then
               out_uom := pf.uom;
               exit;
            end if;
         end if;
      end loop;
      close c_pf;
      out_found := l_found;
   exception
      when OTHERS then
         out_found := false;
   end any_proflines;
begin
   out_uom := null;
   out_profid := null;
   out_msg := null;

   if in_lpid is null then
      l_pos := instr(in_auxdata, '|');
      if l_pos != 0 then
         l_obj := upper(substr(in_auxdata, 1, l_pos-1));
         if l_obj = 'WAVE' then
            open c_wave(to_number(substr(in_auxdata, l_pos+1)));
            fetch c_wave into lp;
            l_found := c_wave%found;
            close c_wave;
         elsif l_obj = 'LOAD' then
            open c_load(to_number(substr(in_auxdata, l_pos+1)));
            fetch c_load into lp;
            l_found := c_load%found;
            close c_load;
         elsif l_obj = 'ORDER' then
            l_obj := substr(in_auxdata, l_pos+1);
            l_pos := instr(l_obj, '|');
            if l_pos != 0 then
               if to_number(substr(l_obj, l_pos+1)) = 0 then
                  open c_wave(to_number(substr(l_obj, 1, l_pos-1)));
                  fetch c_wave into lp;
                  l_found := c_wave%found;
                  close c_wave;
               else
                  open c_order(to_number(substr(l_obj, 1, l_pos-1)),
                        to_number(substr(l_obj, l_pos+1)));
                  fetch c_order into lp;
                  l_found := c_order%found;
                  close c_order;
               end if;
            end if;
         elsif l_obj = 'BC' then
            open c_bc(substr(in_auxdata, l_pos+1));
            fetch c_bc into lp;
            l_found := c_bc%found;
            close c_bc;
         end if;
      end if;
      if not l_found then
         return;
      end if;
   elsif in_type = 'P' then
      open c_lp;
      fetch c_lp into lp;
      l_found := c_lp%found;
      close c_lp;
      if not l_found then
         open c_dlp;
         fetch c_dlp into lp;
         l_found := c_dlp%found;
         close c_dlp;
      end if;
   else
      open c_sp;
      fetch c_sp into lp;
      l_found := c_sp%found;
      close c_sp;
   end if;
   if not l_found then
      return;         -- plate not found
   end if;

   if lp.consignee is not null then   -- try all 3 first if there is a consignee
      open c_lbl_all(lp.custid, lp.item, lp.consignee);
      fetch c_lbl_all into lbl;
      l_found := c_lbl_all%found;
      close c_lbl_all;
      if l_found then
         any_proflines(lbl.profid, in_event, lp.uom, in_type, in_lpid, in_auxdata,
               out_uom, l_found);
         if l_found then
            out_profid := lbl.profid;
            return;
         end if;
      end if;

      open c_lbl_cus_cons(lp.custid, lp.consignee);  -- cust / consignee
      fetch c_lbl_cus_cons into lbl;
      l_found := c_lbl_cus_cons%found;
      close c_lbl_cus_cons;
      if l_found then
         any_proflines(lbl.profid, in_event, lp.uom, in_type, in_lpid, in_auxdata,
               out_uom, l_found);
         if l_found then
            out_profid := lbl.profid;
            return;
         end if;
      end if;
   end if;

   open c_lbl_cus_item(lp.custid, lp.item);        -- cust / item
   fetch c_lbl_cus_item into lbl;
   l_found := c_lbl_cus_item%found;
   close c_lbl_cus_item;
   if l_found then
      any_proflines(lbl.profid, in_event, lp.uom, in_type, in_lpid, in_auxdata,
            out_uom, l_found);
      if l_found then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

   open c_lbl_cus(lp.custid);                  -- cust only
   fetch c_lbl_cus into lbl;
   l_found := c_lbl_cus%found;
   close c_lbl_cus;
   if l_found then
      any_proflines(lbl.profid, in_event, lp.uom, in_type, in_lpid, in_auxdata,
            out_uom, l_found);
      if l_found then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_profid := null;
end get_plate_profid_aux;


procedure get_order_profid
   (in_event  in varchar2,
    in_orderid in number,
    in_shipid  in varchar2,
    out_profid out varchar2)
is
   cursor c_ord is
      select zcord.cons_custid(in_orderid, in_shipid) as custid,
             zcord.cons_shipto(in_orderid, in_shipid) as consignee
         from dual;
   ord c_ord%rowtype;
   cursor c_lbl_cus_cons(p_custid varchar2, p_consignee varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee = p_consignee;
   cursor c_lbl_cus(p_custid varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee is null;
   lbl c_lbl_cus_cons%rowtype;
   l_found boolean;

   function any_key_data
      (in_view    in varchar2,
       in_orderid in number,
       in_shipid  in number)
   return boolean
   is
      cursor c_tab_cols(p_owner varchar2, p_table varchar2, p_column varchar2) is
         select data_type
            from all_tab_columns
            where owner = p_owner
              and table_name = p_table
              and column_name = p_column;
      tc c_tab_cols%rowtype;
      l_found boolean;
      l_out varchar2(255);
      l_cnt pls_integer;
      l_schema varchar2(255);
      l_obj varchar2(255);
   begin
      parse_db_object(in_view, l_schema, l_obj);
      open c_tab_cols(l_schema, l_obj, 'ORDERID');
      fetch c_tab_cols into tc;
      l_found := c_tab_cols%found;
      close c_tab_cols;
      if l_found and (substr(upper(tc.data_type),1,6) = 'NUMBER') then
         open c_tab_cols(l_schema, l_obj, 'SHIPID');
         fetch c_tab_cols into tc;
         l_found := c_tab_cols%found;
         close c_tab_cols;
         if l_found and (substr(upper(tc.data_type),1,6) = 'NUMBER') then
            execute immediate 'select count(1) from ' || in_view || ' where orderid = '
                  || in_orderid || ' and shipid = ' || in_shipid
                  into l_cnt;
            if l_cnt != 0 then
               return true;
            end if;
            return false;
         end if;
      end if;
      execute immediate 'begin ' || in_view || '(' || in_orderid || ',' || in_shipid
            || ', ''Q'', :OUT1); end;'
            using out l_out;
      if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
         return true;
      end if;
      return false;
   exception
      when OTHERS then
         return false;
   end any_key_data;

   function any_proflines
      (in_profid  in varchar2,
       in_event   in varchar2,
       in_orderid in number,
       in_shipid  in number)
   return boolean
   is
      cursor c_pf is
         select viewname, passthrufield, passthruvalue
            from labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and uom is null;
      pf c_pf%rowtype;
      l_found boolean := false;
      l_passthruok varchar2(2);
   begin
      open c_pf;
      loop
         fetch c_pf into pf;
         exit when c_pf%notfound;

         l_passthruok := 'Y';
         if pf.passthrufield is not null then
            l_passthruok := is_order_satisfied(in_orderid, in_shipid, pf.passthrufield,
                  pf.passthruvalue);
         end if;

         if l_passthruok = 'Y' then
            l_found := any_key_data(pf.viewname, in_orderid, in_shipid);
            exit when l_found;
         end if;
      end loop;
      close c_pf;
      return l_found;
   exception
      when OTHERS then
         return false;
   end any_proflines;
begin
   out_profid := null;

   open c_ord;
   fetch c_ord into ord;
   l_found := c_ord%found;
   close c_ord;
   if not l_found then
      return;                 -- order not found
   end if;
   if ord.custid is null then       -- no customer in order
      return;
   end if;

   if ord.consignee is not null then
      open c_lbl_cus_cons(ord.custid, ord.consignee);  -- cust / consignee
      fetch c_lbl_cus_cons into lbl;
      l_found := c_lbl_cus_cons%found;
      close c_lbl_cus_cons;
      if l_found then
         if any_proflines(lbl.profid, in_event, in_orderid, in_shipid) then
            out_profid := lbl.profid;
            return;
         end if;
      end if;
   end if;

   open c_lbl_cus(ord.custid);                 -- cust only
   fetch c_lbl_cus into lbl;
   l_found := c_lbl_cus%found;
   close c_lbl_cus;
   if l_found then
      if any_proflines(lbl.profid, in_event, in_orderid, in_shipid) then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_profid := null;
end get_order_profid;


procedure get_task_profid
   (in_event    in varchar2,
    in_taskid   in number,
    out_profid  out varchar2,
    out_orderid out number,
    out_shipid  out number)
is
   cursor c_tsk is
      select custid, zcord.cons_shipto(orderid, shipid) as consignee,
             orderid, shipid
         from tasks
         where taskid = in_taskid;
   tsk c_tsk%rowtype;
   cursor c_slp is
      select custid, zcord.cons_shipto(orderid, shipid) as consignee,
             orderid, shipid
         from shippingplate
         where taskid = in_taskid
           and type in ('F','P');
   cursor c_lbl_cus_cons(p_custid varchar2, p_consignee varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee = p_consignee;
   cursor c_lbl_cus(p_custid varchar2) is
      select profid
         from custitemlabelprofiles
         where custid = p_custid
           and item is null
           and consignee is null;
   lbl c_lbl_cus_cons%rowtype;
   l_found boolean;

   function any_key_data
      (in_view   in varchar2,
       in_taskid in number)
   return boolean
   is
      cursor c_tab_cols(p_owner varchar2, p_table varchar2, p_column varchar2) is
         select data_type
            from all_tab_columns
            where owner = p_owner
              and table_name = p_table
              and column_name = p_column;
      tc c_tab_cols%rowtype;
      l_found boolean;
      l_out varchar2(255);
      l_cnt pls_integer;
      l_schema varchar2(255);
      l_obj varchar2(255);
   begin
      parse_db_object(in_view, l_schema, l_obj);
      open c_tab_cols(l_schema, l_obj, 'TASKID');
      fetch c_tab_cols into tc;
      l_found := c_tab_cols%found;
      close c_tab_cols;
      if l_found and (substr(upper(tc.data_type),1,6) = 'NUMBER') then
         execute immediate 'select count(1) from ' || in_view || ' where taskid = ' || in_taskid
               into l_cnt;
         if l_cnt != 0 then
            return true;
         end if;
         return false;
      end if;
      execute immediate 'begin ' || in_view || '(' || in_taskid || ', ''Q'', :OUT1); end;'
            using out l_out;
      if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
         return true;
      end if;
      return false;
   exception
      when OTHERS then
         return false;
   end any_key_data;

   function any_proflines
      (in_profid  in varchar2,
       in_event   in varchar2,
       in_taskid  in number,
       in_orderid in number,
       in_shipid  in number)
   return boolean
   is
      cursor c_pf is
         select viewname, passthrufield, passthruvalue
            from labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and uom is null;
      pf c_pf%rowtype;
      l_found boolean := false;
      l_passthruok varchar2(2);
   begin
      open c_pf;
      loop
         fetch c_pf into pf;
         exit when c_pf%notfound;
         l_passthruok := 'Y';
         if pf.passthrufield is not null then
            l_passthruok := is_order_satisfied(in_orderid, in_shipid, pf.passthrufield,
                  pf.passthruvalue);
         end if;

         if l_passthruok = 'Y' then
            l_found := any_key_data(pf.viewname, in_taskid);
            exit when l_found;
         end if;
      end loop;
      close c_pf;
      return l_found;
   exception
      when OTHERS then
         return false;
   end any_proflines;
begin
   out_profid := null;
   out_orderid := null;
   out_shipid := null;

   open c_tsk;
   fetch c_tsk into tsk;
   l_found := c_tsk%found;
   close c_tsk;
   if not l_found then
      open c_slp;
      fetch c_slp into tsk;
      l_found := c_slp%found;
      close c_slp;
      if not l_found then
         return;                -- task not found
      end if;
   end if;
   if tsk.custid is null then       -- no customer for task
      return;
   end if;

   out_orderid := tsk.orderid;
   out_shipid := tsk.shipid;
   if tsk.consignee is not null then
      open c_lbl_cus_cons(tsk.custid, tsk.consignee); -- cust / consignee
      fetch c_lbl_cus_cons into lbl;
      l_found := c_lbl_cus_cons%found;
      close c_lbl_cus_cons;
      if l_found then
         if any_proflines(lbl.profid, in_event, in_taskid, tsk.orderid, tsk.shipid) then
            out_profid := lbl.profid;
            return;
         end if;
      end if;
   end if;

   open c_lbl_cus(tsk.custid);                 -- cust only
   fetch c_lbl_cus into lbl;
   l_found := c_lbl_cus%found;
   close c_lbl_cus;
   if l_found then
      if any_proflines(lbl.profid, in_event, in_taskid, tsk.orderid, tsk.shipid) then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_profid := null;
end get_task_profid;


procedure print_aiwave_labels
   (in_wave     in varchar2
   ,in_trace    in varchar2
   ,in_printer  in varchar2
   ,in_facility in varchar2
   ,in_user     in varchar2
   ,out_errorno in out number
   ,out_msg     in out varchar2)
is

-- Return the orders in the wave
cursor curOrders is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         custid,
         qtyorder
  from orderhdr
  where wave = in_wave
     and orderstatus != 'X'
  order by orderid, shipid;

-- Return the order details
cursor curOrderDtls(p_orderid varchar2, p_shipid varchar2) is
  select item as orderitem,
         lotnumber,
         qtyorder,
         uom
  from orderdtl
  where orderid = p_orderid
    and shipid = p_shipid
    and linestatus != 'X'
  order by item, lotnumber;

cursor curCustItem(p_custid varchar2, p_item varchar2) is
  select custid,
         item,
         labeluom,
         labelqty
  from custitem
  where custid = p_custid
    and item = p_item;
ci curCustItem%rowtype;

-- Return Cases (or other LabelUOM) per Pallet
cursor curCustItemUOM(p_custid varchar2, p_item varchar2, p_fromuom varchar2) is
  select custid,
         item,
         fromuom,
         touom,
         qty
  from custitemuom
  where custid = p_custid
    and item = p_item
    and fromuom = p_fromuom
    and touom = 'PLT';
cu curCustItemUOM%rowtype;

cursor curShippingLP(p_orderid varchar2, p_shipid varchar2, p_item varchar2, p_lot varchar2) is
  select lpid,
         orderid,
         shipid,
         item,
         orderitem,
         lotnumber,
         orderlot
  from shippingplate
  where orderid = p_orderid
    and shipid = p_shipid
    and item = p_item
    and nvl(orderlot, '(none)') = nvl(p_lot, '(none)');
sp curShippingLP%rowtype;

cursor curLabelProfLine1(p_profid varchar2, p_event varchar2, p_orderid number,
                         p_shipid number) is
  select profid,
         seq,
         rowid
  from labelprofileline
  where profid = p_profid
    and businessevent = p_event
    and uom is null
    and is_order_satisfied(p_orderid, p_shipid, passthrufield, passthruvalue) = 'Y';
pl1 curLabelProfLine1%rowtype;

cursor curLabelProfLine2(p_profid varchar2, p_event varchar2, p_uom varchar2,
                         p_orderid number, p_shipid number) is
  select profid,
         seq,
         rowid
  from labelprofileline
  where profid = p_profid
    and businessevent = p_event
    and uom = p_uom
    and is_order_satisfied(p_orderid, p_shipid, passthrufield, passthruvalue) = 'Y';
pl2 curLabelProfLine2%rowtype;

ohcount integer;
lblx integer;
lbltoprt integer;
usedivisor integer;
useprintqty integer;
useshiplp varchar2(15);
profile varchar2(12);
profileuom varchar2(4);
profilerowid varchar2(20);
useprofilerowid varchar2(20);
useuomqty custitemuom.qty%type;
uselabelqty custitem.labelqty%type;
uselabeluom varchar2(4);
useitemqty number;
useitem varchar2(50);

-- print a message to the app logs
procedure trace_msg(in_msg varchar2, in_custid varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Wave ' || in_wave || ' - ' || in_msg;
  zms.log_msg('AIWAVE', in_facility, in_custid,
    substr(out_msg,1,254), 'T', 'AIWAVE', strMsg);
end;

begin

out_msg := '';
out_errorno := 0;

-- Verify orders in this wave
select count(1)
  into ohcount
  from orderhdr
 where wave = in_wave
   and orderstatus != 'X';

if ohcount = 0 then
  out_msg := 'No open orders are assigned to this wave';
  out_errorno := -3;
  return;
end if;

for oh in curOrders
loop
  lblx := 1;

  useitem := null;
  usedivisor := 9999;
  -- Loop through the Order items to get lowest cases (or other label uom) per pallet value
  for od in curOrderDtls(oh.orderid, oh.shipid)
  loop

    sp := null;
    open curShippingLP(oh.orderid, oh.shipid, od.orderitem, od.lotnumber);
    fetch curShippingLP into sp;
    close curShippingLP;

    if in_trace = 'Y' then
      trace_msg('Order ' || oh.orderid || ' / Ship ID ' || oh.shipid ||
          ' / OrderItem ' || od.orderitem || ' / ShippingLPID ' || sp.lpid, oh.custid);
    end if;
    zlbl.get_plate_profid('RWAV', sp.lpid ,'S', 'A', profileuom, profile, out_msg);

    if profile is not null then
      if in_trace = 'Y' then
        trace_msg('Order ' || oh.orderid || ' / Ship ID ' || oh.shipid ||
            ' / OrderItem ' || od.orderitem || ' / Profile ' || profile, oh.custid);
      end if;
      pl1 := null;
      pl2 := null;

      if profileuom is null then
        open curLabelProfLine1(profile, 'RWAV', oh.orderid, oh.shipid);
        fetch curLabelProfLine1 into pl1;
        close curLabelProfLine1;
        profilerowid := rowidtochar(pl1.rowid);
      else
        open curLabelProfLine2(profile, 'RWAV', profileuom, oh.orderid, oh.shipid);
        fetch curLabelProfLine2 into pl2;
        close curLabelProfLine2;
        profilerowid := rowidtochar(pl2.rowid);
      end if;

      if in_trace = 'Y' then
        trace_msg('Order ' || oh.orderid || ' / Ship ID ' || oh.shipid ||
              ' / Profile RowID ' || profilerowid, oh.custid);
      end if;

      ci := null;
      open curCustItem(oh.custid, od.orderitem);
      fetch curCustItem into ci;
      close curCustItem;

      -- Default to cases for the label uom
      uselabeluom := nvl(ci.labeluom, 'CS');

      -- if the ordered uom is not equal to the labeluom, convert qty to labeluom
      if od.uom != uselabeluom then
        useitemqty := zlbl.uom_qty_conv(oh.custid, od.orderitem, nvl(od.qtyorder,1), od.uom, uselabeluom);
      else
        useitemqty := nvl(od.qtyorder, 1);
      end if;

      cu := null;
      open curCustItemUOM(oh.custid, od.orderitem, uselabeluom);
      fetch curCustItemUOM into cu;
      close curCustItemUOM;

      useuomqty := nvl(cu.qty, 1);

      -- Make sure uom conversion value is greater than zero.
      if (useuomqty > 0) and (usedivisor > useuomqty) then
        usedivisor := useuomqty;
        useitem := od.orderitem;
        -- Get the number of labels to print for each label uom value
        uselabelqty := nvl(ci.labelqty, 1);
        -- set the label rowid and shiplpid
        useprofilerowid := profilerowid;
        useshiplp := sp.lpid;
      end if;
    else
      if in_trace = 'Y' then
        trace_msg('Order ' || oh.orderid || ' / Ship ID ' || oh.shipid ||
          ' / OrderItem ' || od.orderitem || ' / ** NO PROFILE ** ', oh.custid);
      end if;
    end if;

  end loop;

  -- calculate total number of labels to print for this order
  lbltoprt := ceil(oh.qtyorder / usedivisor) * uselabelqty;

  if in_trace = 'Y' then
    trace_msg('Order ' || oh.orderid || ' / Print Qty ' || lbltoprt || ' / Item ' || useitem
           || ' / Divisor ' || usedivisor || ' / Labels UOM Qty ' || uselabelqty, oh.custid);
  end if;

  -- print the labels for the order
  zlbl.print_a_plate_copies(useshiplp, useprofilerowid, in_printer, in_facility, in_user,
       'A', lbltoprt, null, out_msg);

end loop;

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end print_aiwave_labels;


procedure check_load_arrival_lps
   (in_event    in varchar2,
    in_loadno   in number,
    out_message out varchar2)
is
   cursor c_od(p_loadno number) is
      select distinct OH.orderid, OH.shipid, OD.custid, OD.item
         from orderhdr OH, orderdtl OD
         where OH.loadno = p_loadno
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.qtyorder > nvl(OD.qtyrcvd,0);
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select prtlps_on_load_arrival, prtlps_profid,
             prtlps_def_handling
         from custitemview
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype;
   l_cnt pls_integer;
begin
   out_message := 'NONE';

   for od in c_od(in_loadno) loop
      ci := null;
      open c_ci(od.custid, od.item);
      fetch c_ci into ci;
      close c_ci;
      if (nvl(ci.prtlps_on_load_arrival,'N') = 'Y')
      and (ci.prtlps_profid is not null)
      and (ci.prtlps_def_handling is not null) then
         select count(1)
            into l_cnt
            from labelprofileline
            where profid = ci.prtlps_profid
              and businessevent = in_event
              and is_order_satisfied(od.orderid, od.shipid, passthrufield,
                  passthruvalue) = 'Y';
         if l_cnt > 0 then
            out_message := 'OKAY';
            return;
         end if;
      end if;
   end loop;

exception
   when OTHERS then
      out_message := 'NONE';
end check_load_arrival_lps;


procedure print_load_arrival_lps
   (in_event    in varchar2,
    in_loadno   in number,
    in_printer  in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_od(p_loadno number) is
      select distinct OH.orderid, OH.shipid, OH.tofacility, OD.custid, OD.item
         from orderhdr OH, orderdtl OD
         where OH.loadno = p_loadno
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and nvl(OD.qtyorder,0) != nvl(OD.qtyrcvd,0)
         order by OD.item;
   od c_od%rowtype;
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select prtlps_profid
         from custitemview
         where custid = p_custid
           and item = p_item
           and nvl(prtlps_on_load_arrival,'N') = 'Y'
           and prtlps_def_handling is not null;
   ci c_ci%rowtype;
   cursor c_pf(p_profid varchar2, p_event varchar2, p_orderid number, p_shipid number) is
      select rowid
         from labelprofileline
         where profid = p_profid
           and businessevent = p_event
           and is_order_satisfied(p_orderid, p_shipid, passthrufield,
                  passthruvalue) = 'Y'
         order by seq;
   pf c_pf%rowtype;
   l_found boolean;
   l_msg varchar2(255);

   procedure print_it
      (out_message out varchar2)
   is
      cursor c_prt is
         select queue
            from printer
            where facility = od.tofacility
              and prtid = in_printer;
      prt c_prt%rowtype;
      cursor c_Q is
         select oraclepipe
            from spoolerqueues
            where prtqueue = prt.queue;
      q c_Q%rowtype;
      cursor c_defQ is
         select oraclepipe
            from spoolerqueues
            order by oraclepipe desc;
      l_queuename varchar2(32);
      l_status number;
      l_msg varchar2(1000);
   begin
      out_message := 'OKAY';

      open c_prt;
      fetch c_prt into prt;
      close c_prt;

      open c_Q;
      fetch c_Q into q;
      if c_Q%found then
         l_queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
      else
         open c_defQ;
         fetch c_defQ into q;
         if c_defQ%found then
            l_queuename := LABEL_DEFAULT_QUEUE || q.oraclepipe;
         end if;
         close c_defQ;
      end if;
      close c_Q;

      l_msg := 'LPAA' || chr(9) ||
                od.orderid || chr(9) ||
                od.shipid || chr(9) ||
                od.item || chr(9) ||
                rowidtochar(pf.rowid) || chr(9) ||
                in_printer || chr(9) ||
                od.tofacility || chr(9) ||
                in_user || chr(9);

      l_status := zqm.send(LABEL_DEFAULT_QUEUE,'MSG',l_msg,1,l_queuename);
      commit;

      if (l_status != 1) then
         out_message := 'Send error ' || l_status;
      end if;

   exception
      when OTHERS then
         out_message := substr(sqlerrm, 1, 80);
   end print_it;
begin
   out_message := 'OKAY';

   open c_od(in_loadno);
   loop
      fetch c_od into od;
      exit when c_od%notfound;

      open c_ci(od.custid, od.item);
      fetch c_ci into ci;
      l_found := c_ci%found;
      close c_ci;
      if l_found then
         open c_pf(ci.prtlps_profid, in_event, od.orderid, od.shipid);
         fetch c_pf into pf;
         l_found := c_pf%found;
         close c_pf;
         if l_found then
            print_it(l_msg);
            if l_msg != 'OKAY' then
               out_message := l_msg;
            end if;
         end if;
      end if;
   end loop;
   close c_od;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_load_arrival_lps;


procedure ld_arrival_lpprt
   (in_orderid in number,
    in_shipid  in number,
    in_item    in varchar2,
    in_uom     in varchar2,
    in_user    in varchar2,
    out_stmt   out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select custid, po, tofacility, loadno, stopno, shipno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2) is
      select lotnumber, uom, nvl(qtyorder,0) as qtyorder, nvl(qtyrcvd,0) as qtyrcvd
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(qtyorder,0) != nvl(qtyrcvd,0);
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select prtlps_def_handling, shelflife, expiryaction,
             nvl(recvinvstatus,'AV') as recvinvstatus,
             nvl(status, 'x') as status,
             nvl(use_catch_weights, 'N') as use_catch_weights,
			 nvl(lotrequired, 'N') as lotrequired
         from custitemview
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype;
   cursor c_ld(p_loadno number) is
      select doorloc
         from loads
         where loadno = p_loadno;
   ld c_ld%rowtype;
   cursor c_lp(p_orderid number, p_shipid number, p_item varchar2) is
      select lpid, facility, location
         from plate
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and disposition = 'PUT';
   l_found boolean;
   l_qty_remain orderdtl.qtyorder%type;
   l_qty_per_lp plate.quantity%type;
   l_qty plate.quantity%type;
   l_lpid plate.lpid%type;
   l_msg varchar2(255);
   l_err varchar2(1);
   l_disposition plate.disposition%type;
   l_qtyentered plate.qtyentered%type;
   l_uomentered plate.uomentered%type;
   l_weight plate.weight%type;
   l_putfac plate.facility%type;
   l_putloc plate.location%type;
   l_qtyrcvd orderdtl.qtyrcvd%type;
   l_weightrcvd orderdtl.weightrcvd%type;
   l_cubercvd orderdtl.cubercvd%type;
   l_amtrcvd orderdtl.amtrcvd%type;
   l_lowlpid plate.lpid%type := null;
   l_existing_over_qty orderdtl.qtyorder%type;
   l_cnt pls_integer;
   v_autolot plate.lotnumber%type;
   v_count number;

   procedure log_err
      (p_msg varchar2)
   is
      l_msg varchar2(255);
   begin
      rollback;
      zms.log_msg('LDARRIVALLPS', oh.tofacility, oh.custid, p_msg, 'E', in_user, l_msg);
      commit;
   exception
      when others then
         null;
   end log_err;
begin
   out_stmt := null;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   l_found := c_oh%found;
   close c_oh;
   if not l_found then
      log_err('Order '||in_orderid||'-'||in_shipid||': header not found');
      return;
   end if;

   open c_ld(oh.loadno);
   fetch c_ld into ld;
   l_found := c_ld%found;
   close c_ld;
   if not l_found then
      log_err('Order '||in_orderid||'-'||in_shipid||': load '||oh.loadno||' not found');
      return;
   end if;

   open c_ci(oh.custid, in_item);
   fetch c_ci into ci;
   l_found := c_ci%found;
   close c_ci;
   if not l_found then
      log_err('Order '||in_orderid||'-'||in_shipid||': data for item '
            ||in_item||' not found');
      return;
   end if;
   if ci.status != 'ACTV' then
      log_err('Order '||in_orderid||'-'||in_shipid||': data for item '
            ||in_item||' is not active');
      return;
   end if;

   v_autolot := null;
   if (ci.lotrequired = 'A') then
		zrec.get_autoinc_value(oh.custid, in_item, null, 'LOT', in_orderid, in_shipid, v_autolot, l_msg);
		if (l_msg <> 'OKAY') then
		log_err('Order '||in_orderid||'-'||in_shipid||': error with autoseq for item ' || in_item);
      return;
      end if;

      select count(1) into v_count
      from orderdtl
      where orderid = in_orderid and shipid = in_shipid and item = in_item
         and lotnumber is null;

      if (v_count > 0) then
         update orderdtl
         set lotnumber = v_autolot
         where orderid = in_orderid and shipid = in_shipid and item = in_item
            and lotnumber is null;
      end if;
   end if;

   select count(1) into l_cnt
      from asncartondtl
      where orderid = in_orderid
        and shipid = in_shipid;

   if l_cnt = 0 then
      for od in c_od(in_orderid, in_shipid, in_item) loop

         if od.qtyrcvd > od.qtyorder then    -- overship
            select nvl(sum(quantity),0) into l_existing_over_qty
               from plate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and item = in_item
                 and nvl(lotnumber,'(none)') = nvl(od.lotnumber,'(none)');

            l_qty_remain := od.qtyrcvd - l_existing_over_qty;
         else
            l_qty_remain := od.qtyorder - od.qtyrcvd;
         end if;

         l_qty_per_lp := uom_qty_conv(oh.custid, in_item, 1, in_uom, od.uom);
         if l_qty_per_lp <= 0 then
            log_err('Order '||in_orderid||'-'||in_shipid||': item '||in_item
                  ||' has no uom conversion between '||od.uom||' and '||in_uom);
            return;
         end if;

         l_qtyrcvd := 0;
         l_weightrcvd := 0;
         while l_qty_remain > 0 loop

            zrf.get_next_lpid(l_lpid, l_msg);
            if l_msg is not null then
               log_err('Order '||in_orderid||'-'||in_shipid||': next lpid error '||l_msg);
               return;
            end if;
            l_lowlpid := nvl(l_lowlpid, l_lpid);

            l_qty := least(l_qty_remain, l_qty_per_lp);
            l_qtyrcvd := l_qtyrcvd + l_qty;

            if l_qty = l_qty_per_lp then
               l_qtyentered := 1;
               l_uomentered := in_uom;
            else
               l_qtyentered := l_qty;
               l_uomentered := od.uom;
            end if;
            l_weight := zci.item_weight(oh.custid, in_item, l_uomentered) * l_qtyentered;
            l_weightrcvd := l_weightrcvd + l_weight;

            l_disposition := 'PUT';

            insert into plate
               (lpid, item, custid,
                facility, location, status,
                unitofmeasure, quantity, type,
                lotnumber, creationdate, expirationdate,
                expiryaction, po, recmethod,
                lastoperator, disposition, lastuser,
                lastupdate, invstatus, qtyentered,
                itementered, uomentered, inventoryclass,
                loadno, stopno, shipno,
                orderid, shipid, weight,
                qtyrcvd, parentfacility, parentitem)
            values
               (l_lpid, in_item, oh.custid,
                oh.tofacility, ld.doorloc, 'U',
                od.uom, l_qty, 'PA',
                nvl(od.lotnumber, v_autolot), sysdate, zrf.calc_expiration(null, null, ci.shelflife),
                ci.expiryaction, oh.po, ci.prtlps_def_handling,
                in_user, l_disposition, in_user,
                sysdate, ci.recvinvstatus, l_qtyentered,
                in_item, l_uomentered, 'RG',
                oh.loadno, oh.stopno, oh.shipno,
                in_orderid, in_shipid, l_weight,
                l_qty,  oh.tofacility, in_item);

            zxdk.add_xdock_plate(l_lpid, '(none)', in_user, ld.doorloc, l_err, l_msg);
            if l_err = 'Y' then
               log_err('Order '||in_orderid||'-'||in_shipid||': add xdock plate error '||l_msg);
               return;
            end if;

            insert into orderdtlrcpt
               (orderid, shipid, orderitem, orderlot, facility,
                custid, item, lotnumber, uom, inventoryclass,
                invstatus, lpid, qtyrcvd, lastuser, lastupdate,
                qtyrcvdgood, qtyrcvddmgd, weight)
            values
               (in_orderid, in_shipid, in_item, nvl(od.lotnumber, v_autolot), oh.tofacility,
                oh.custid, in_item, nvl(od.lotnumber, v_autolot), od.uom, 'RG',
                ci.recvinvstatus, l_lpid, l_qty, in_user, sysdate,
                l_qty, 0, l_weight);

            l_qty_remain := l_qty_remain - l_qty;
         end loop;

         l_cubercvd := zci.item_cube(oh.custid, in_item, od.uom) * l_qtyrcvd;
         l_amtrcvd := zci.item_amt(oh.custid, in_orderid, in_shipid, in_item, od.lotnumber) * l_qtyrcvd;  --prn 25133

         update loadstopship
            set qtyrcvd = nvl(qtyrcvd, 0) + l_qtyrcvd,
                weightrcvd = nvl(weightrcvd, 0) + l_weightrcvd,
                weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                               + nvl(zwt.from_lbs_to_kgs(oh.custid,l_weightrcvd),0),
                cubercvd = nvl(cubercvd, 0) + l_cubercvd,
                amtrcvd = nvl(amtrcvd, 0) + l_amtrcvd,
              lastuser = in_user,
              lastupdate = sysdate
          where loadno = oh.loadno
            and stopno = oh.stopno
            and shipno = oh.shipno;

         if od.qtyorder > od.qtyrcvd then
            zrec.update_receipt_dtl
               (in_orderid, in_shipid, in_item, od.lotnumber, od.uom, in_item, in_uom,
                l_qtyrcvd, l_qtyrcvd, 0,
                l_weightrcvd, l_weightrcvd, 0,
                l_cubercvd, l_cubercvd, 0,
                l_amtrcvd, l_amtrcvd, 0,
                in_user, null, l_msg);
            if l_msg != 'OKAY' then
               log_err('Order '||in_orderid||'-'||in_shipid||': update receipt error '||l_msg);
               return;
            end if;
         end if;
      end loop;
   else
      for asn in (select * from asncartondtl
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and item = in_item) loop

         zrf.get_next_lpid(l_lpid, l_msg);
         if l_msg is not null then
            log_err('Order '||in_orderid||'-'||in_shipid||': next lpid error '||l_msg);
            return;
         end if;
         l_lowlpid := nvl(l_lowlpid, l_lpid);

         if ci.use_catch_weights = 'Y' then
            l_weight := asn.weight;
         else
            l_weight := zci.item_weight(oh.custid, in_item, asn.uom) * asn.qty;
         end if;

         insert into plate
            (lpid, item, custid,
             facility, location, status,
             unitofmeasure, quantity, type,
             serialnumber, lotnumber, creationdate,
             expirationdate, expiryaction, po,
             recmethod, lastoperator, useritem1,
             useritem2, useritem3, disposition,
             lastuser, lastupdate, invstatus,
             qtyentered, itementered, uomentered,
             inventoryclass, loadno, stopno,
             shipno, orderid, shipid,
             weight, qtyrcvd, parentfacility,
             parentitem)
         values
            (l_lpid, in_item, oh.custid,
             oh.tofacility, ld.doorloc, 'U',
             asn.uom, asn.qty, 'PA',
             asn.serialnumber, nvl(asn.lotnumber, v_autolot), sysdate,
             zrf.calc_expiration(asn.expdate, asn.manufacturedate, ci.shelflife), ci.expiryaction, oh.po,
             ci.prtlps_def_handling, in_user, asn.useritem1,
             asn.useritem2, asn.useritem3, 'PUT',
             in_user, sysdate, ci.recvinvstatus,
             asn.qty, in_item, asn.uom,
             asn.inventoryclass, oh.loadno, oh.stopno,
             oh.shipno, in_orderid, in_shipid,
             l_weight, asn.qty, oh.tofacility,
             in_item);

         zxdk.add_xdock_plate(l_lpid, '(none)', in_user, ld.doorloc, l_err, l_msg);
         if l_err = 'Y' then
            log_err('Order '||in_orderid||'-'||in_shipid||': add xdock plate error '||l_msg);
            return;
         end if;

         zrf.tally_lp_receipt(l_lpid, in_user, l_msg);
         if l_msg is not null then
            log_err('Order '||in_orderid||'-'||in_shipid||': tally lp receipt '||l_msg);
            return;
         end if;

         l_cubercvd := zci.item_cube(oh.custid, in_item, asn.uom) * asn.qty;
         l_amtrcvd := zci.item_amt(oh.custid, in_orderid, in_shipid, in_item, asn.lotnumber) * asn.qty; --prn 25133

         update loadstopship
            set qtyrcvd = nvl(qtyrcvd, 0) + asn.qty,
                weightrcvd = nvl(weightrcvd, 0) + l_weight,
                weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                               + nvl(zwt.from_lbs_to_kgs(oh.custid,l_weight),0),
                cubercvd = nvl(cubercvd, 0) + l_cubercvd,
                amtrcvd = nvl(amtrcvd, 0) + l_amtrcvd,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and stopno = oh.stopno
              and shipno = oh.shipno;

         zrec.update_receipt_dtl
            (in_orderid, in_shipid, in_item, asn.lotnumber, asn.uom, in_item, asn.uom,
             asn.qty, asn.qty, 0,
             l_weight, l_weight, 0,
             l_cubercvd, l_cubercvd, 0,
             l_amtrcvd, l_amtrcvd, 0,
             in_user, null, l_msg);
         if l_msg != 'OKAY' then
            log_err('Order '||in_orderid||'-'||in_shipid||': update receipt error '||l_msg);
            return;
         end if;
      end loop;
   end if;
   commit;

   out_stmt := 'select row_number() over (order by null) as seq, '
            || '   count(*) over () as seqof, a.* '
            || ' from ld_arrival_lpprt_view a '
            || ' where a.orderid = ' || in_orderid
            || ' and a.shipid = ' || in_shipid
            || ' and a.item = ''' || in_item || ''''
            || ' and a.lpid >= ''' || l_lowlpid || ''''
            || ' order by a.lpid';

end ld_arrival_lpprt;


procedure is_object_a_view
   (in_obj_name in varchar2,
    out_is_view out varchar2)
is
   l_schema varchar2(255);
   l_obj varchar2(255);
   l_cnt pls_integer;
begin
   out_is_view := 'N';

   parse_db_object(in_obj_name, l_schema, l_obj);
   select count(1) into l_cnt
      from all_objects
      where owner = l_schema
        and object_name = l_obj
        and object_type = 'VIEW';

   if l_cnt != 0 then
      out_is_view := 'Y';
   end if;

exception
   when OTHERS then
      out_is_view := 'N';
end is_object_a_view;


procedure print_aiorder_labels
   (in_profid   in varchar2,
    in_event    in varchar2,
    in_uom      in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_msg     out varchar2)
is
   type proflinetype is record (
      viewname labelprofileline.viewname%type,
      viewkeycol labelprofileline.viewkeycol%type,
      rid rowid);
   type proflinecur is ref cursor return proflinetype;
   c_profline proflinecur;
   pl proflinetype;
   l_auxdata varchar2(32);

   cursor c_sp(p_orderid number, p_shipid number) is
      select lpid from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid;
   sp c_sp%rowtype := null;

   function any_key_data
      (in_view    in varchar2,
       in_keycol  in varchar2,
       in_key     in varchar2,
       in_auxdata in varchar2)
   return boolean
   is
      cursor c_tab_cols(p_owner varchar2, p_table varchar2, p_column varchar2) is
         select data_type, data_length
            from all_tab_columns
            where owner = p_owner
              and table_name = p_table
              and column_name = p_column;
      tc c_tab_cols%rowtype;
      l_found boolean;
      l_out varchar2(255) := null;
      l_cnt pls_integer;
      l_schema varchar2(255);
      l_obj varchar2(255);
      l_pos number;
      l_aux varchar2(255);
      l_sql varchar2(1024);
   begin
      parse_db_object(in_view, l_schema, l_obj);
      open c_tab_cols(l_schema, l_obj, in_keycol);
      fetch c_tab_cols into tc;
      l_found := c_tab_cols%found;
      close c_tab_cols;
      if l_found then
         if (tc.data_length != 15) or (substr(upper(tc.data_type),1,7) != 'VARCHAR') then
            l_found := false;       -- keycol not of "type" lpid
         else
            l_sql := 'select count(1) from ' || in_view || ' where ' || in_keycol;

            if in_key is not null then
               l_sql := l_sql || ' = ''' || in_key || '''';
               execute immediate l_sql into l_cnt;
               if l_cnt = 0 then
                  l_found := false;
               end if;
            else
               l_pos := instr(in_auxdata, '|');
               if l_pos != 0 then
                  l_aux := upper(substr(in_auxdata, 1, l_pos-1));
                  if l_aux = 'ORDER' then
                     l_aux := substr(in_auxdata, l_pos+1);
                     l_pos := instr(l_aux, '|');
                     if l_pos != 0 then
                        if to_number(substr(l_aux, l_pos+1)) = 0 then
                           l_sql := l_sql
                              || ' in (select P.lpid from orderhdr O, shippingplate P'
                              || '   where O.wave = ' || to_number(substr(l_aux, 1, l_pos-1))
                              || '     and P.orderid = O.orderid and P.shipid = O.shipid)';
                           execute immediate l_sql into l_cnt;
                           if l_cnt = 0 then
                              l_found := false;
                           end if;
                        else
                           l_sql := l_sql
                              || ' in (select lpid from shippingplate'
                              || ' where orderid = ' || to_number(substr(l_aux, 1, l_pos-1))
                              || ' and shipid = ' || to_number(substr(l_aux, l_pos+1)) || ')';
                           execute immediate l_sql into l_cnt;
                           if l_cnt = 0 then
                              l_found := false;
                           end if;
                        end if;
                     else
                        l_found := false;
                     end if;
                  else
                     l_found := false;
                  end if;
               else
                  l_found := false;
               end if;
            end if;
         end if;
      else
         select count(1) into l_cnt
            from user_arguments
            where package_name = l_schema
              and object_name = l_obj;
         if l_cnt = 4 then
            execute immediate 'begin ' || in_view || '(''' || in_key || ''', ''Q'', ''A'', '
                  || ' :OUT1); end;'
                  using out l_out;
         elsif l_cnt = 5 then
            execute immediate 'begin ' || in_view || '(''' || in_key || ''', ''Q'', ''A'', '''
                  || in_auxdata || ''', :OUT1); end;'
                  using out l_out;
         end if;
         if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
            l_found := true;
         else
            out_msg := l_out;
         end if;
      end if;
      return l_found;
   exception
      when OTHERS then
         return false;
   end any_key_data;

begin
   out_msg := null;

-- find an lp for the order
   open c_sp(in_orderid, in_shipid);
   fetch c_sp into sp;
   close c_sp;

   if in_uom is null then
      open c_profline for
         select viewname, viewkeycol, rowid
            from labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and uom is null
              and nvl(viewkeyorigin,'?') = 'S'
              and is_order_satisfied(in_orderid, in_shipid, passthrufield, passthruvalue) = 'Y';
   else
      open c_profline for
         select viewname, viewkeycol, rowid
            from labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and uom = in_uom
              and nvl(viewkeyorigin,'?') = 'S'
              and is_order_satisfied(in_orderid, in_shipid, passthrufield, passthruvalue) = 'Y';
   end if;

   l_auxdata := 'ORDER|' || in_orderid || '|' || in_shipid;
   loop
      fetch c_profline into pl;
      exit when c_profline%notfound;

      if any_key_data(pl.viewname, pl.viewkeycol, sp.lpid, l_auxdata) then
         print_a_plate_copies(sp.lpid, rowidtochar(pl.rid), in_printer, in_facility,
               in_user, 'A', 1, l_auxdata, out_msg);
      end if;
      exit when out_msg is not null;
   end loop;
   close c_profline;

   if out_msg is null then
      out_msg := 'OKAY';
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end print_aiorder_labels;

procedure any_ai_wave_labels
   (in_wave    in number,
    in_facility in varchar2,
    out_any    out number,
    out_ready  out number)
is
cntRows pls_integer;
cursor curOrder is
   select orderid, shipid
     from orderhdr
    where wave = in_wave;
OH curOrder%rowtype;
out_profid varchar2(255);
out_uom varchar2(3);
auxdata varchar2(255);
out_msg varchar2(255);
begin
   out_any := 0;
   out_ready := 0;
   select count(1) into cntRows
      from orderhdr oh, customer cu
      where oh.wave = in_wave and
            oh.orderstatus <> 'X' and
            oh.custid = cu.custid and
            oh.fromfacility = in_facility and
            nvl(paperbased,'N') = 'Y';
   if cntRows = 0 then
      return;
   end if;
   for OH in curOrder  loop
      auxdata := 'ORDER|' || OH.orderid || '|' || OH.shipid;
      ZLBL.GET_PLATE_PROFID_AUX('SOUL', '', 'S', 'A', auxdata, out_uom, out_profid, out_msg);
      if out_profid is not null then
         exit;
      end if;
   end loop;

   if out_profid is not null then
      out_any := 1;
   end if;
   select count(1) into cntRows
      from orderhdr
      where wave = in_wave and
            orderstatus not in ('6','7','8','9', 'X');
   if cntRows > 0 then
      out_ready := 0;
   else
      out_ready := 1;
   end if;

end any_ai_wave_labels;

procedure print_ai_wave_labels
   (in_wave    in number,
    in_printer in varchar2,
    in_user    in varchar2,
    in_facility in varchar2,
    out_msg    out varchar2)
is
cntRows pls_integer;
cursor curOrder is
   select orderid, shipid
     from orderhdr
    where wave = in_wave;
OH curOrder%rowtype;
out_profid varchar2(255);
out_uom varchar2(3);
auxdata varchar2(255);
begin
   for OH in curOrder  loop
      auxdata := 'ORDER|' || OH.orderid || '|' || OH.shipid;
      zlbl.get_plate_profid_aux('SOUL', '', 'S', 'A', auxdata, out_uom, out_profid, out_msg);
      if out_profid is not null then
         zlbl.print_aiorder_labels(out_profid, 'SOUL', out_uom, OH.orderid, OH.shipid,
                                   in_printer, in_facility, in_user, out_msg);
      end if;

   end loop;


end print_ai_wave_labels;


procedure print_lpid
   (in_lpid        in varchar2,
    in_event       in varchar2,
    in_printer     in varchar2,
    in_termid      in varchar2,
    in_userid      in varchar2,
    out_message    out varchar2)
is

cursor cProfile(in_profid varchar2, in_uom varchar2, in_platetype varchar2) is
   select rowid
     from labelprofileline
    where profid = in_profid
      and (nvl(uom,'(none)') = nvl(in_uom,'(none)')
       or  uom is null)
      and businessevent = in_event
      and nvl(viewkeyorigin,'?') = in_platetype
      and print = 'Y';
cp cProfile%rowtype;

lptoprint plate.lpid%type;
lptype plate.type%type;
xrefid plate.lpid%type;
xreftype plate.type%type;
parentid plate.lpid%type;
parenttype plate.type%type;
topid plate.lpid%type;
toptype plate.type%type;
platetype char(1);
plunitofmeasure plate.unitofmeasure%type;
lblprid labelprofileline.profid%type;
plfacility plate.facility%type;

begin
   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype,
      parentid, parenttype, topid, toptype, out_message);

   if (lptype = '?') then
      out_message := 'Unknown Plate';
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   if (xrefid is not null) then
      lptype := xreftype;
      lptoprint := xrefid;
   else
      lptoprint := in_lpid;
   end if;

   if (lptype in('C','F','M','P')) then
      platetype := 'S';
      select facility
        into plfacility
        from shippingplate
       where lpid = lptoprint;
   else
      platetype := 'P';
      select facility
        into plfacility
        from plate
       where lpid = lptoprint;
   end if;

   zlbl.get_plate_profid(in_event, lptoprint, platetype, 'A',
      plunitofmeasure, lblprid, out_message);

   if (lblprid is null) then
      out_message := 'Label profile not found';
      return;
   end if;

   open cProfile(lblprid, plunitofmeasure, platetype);
   loop
      fetch cProfile into cp;
      exit when cProfile%notfound;
      zlbl.print_a_plate_copies(lptoprint, cp.rowid, in_printer, plfacility, in_userid,
            'A', 1, in_termid, out_message);
   end loop;
   close cProfile;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_lpid;

function ohl_combe_sku
   (in_orderid in number,
    in_shipid  in number)
return varchar2
is
   sku orderdtl.consigneesku%type := null;
   cnt number := 0;
begin
   select count(distinct item)
      into cnt
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid;
   if cnt != 1 then
      return 'MIXED';
   end if;

   select consigneesku
      into sku
      from orderdtl
      where orderid = in_orderid
        and shipid = in_shipid
        and rownum = 1;

   return sku;

exception
   when others then
      return null;
end ohl_combe_sku;

procedure nicewatch_delimiter
   (out_delimiter out varchar2,
    out_decimal out number)
is
strDelimiter varchar2(10);
cmdSql varchar2(60);
begin
out_decimal := 0;
begin
   select defaultvalue into strDelimiter
      from systemdefaults
      where defaultid = 'NICEWATCHDELIMITER';
exception
   when others then
      out_delimiter := '|';
      return;
end;
if out_delimiter = '^' then
   out_delimiter := chr(9);
   return;
end if;
if length(strDelimiter) = 1 then
   out_delimiter := strDelimiter;
   return;
end if;
if length(strDelimiter) != 3 then
   out_delimiter := '|';
   return;
end if;
out_delimiter := null;
out_decimal := to_number(strDelimiter);
exception when others then
   out_delimiter := '|';
   zut.prt('others');
end nicewatch_delimiter;
end zlabels;
/

show errors package body zlabels;
exit;
