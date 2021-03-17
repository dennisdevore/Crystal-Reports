create or replace package body sbay_aiuccpk as
--
-- $Id$
--


-- Private functions


-- Build an sscc14 barcode based upon the customer manufacture ucc
-- and an oracle sequence
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


function nextseq
   (in_orderid in orderhdr.orderid%type,
    in_shipid  in orderhdr.shipid%type)
return number
is
   l_seq ucc_standard_labels.seq%type := 1;
begin
   for sl in (select seq from ucc_standard_labels
               where orderid = in_orderid
                 and shipid = in_shipid
               order by seq) loop
      exit when l_seq != sl.seq;
      l_seq := l_seq + 1;
   end loop;
   return l_seq;

end nextseq;


-- Private procedures


-- insure the shippingplate family is 1 Master (each with 1 child and an XP
-- plate).  Each child should be for 1 case.
procedure single_case_masters
   (in_orderid    in number,
    in_shipid     in number,
    in_procname   in varchar2,
    out_multiship out varchar2,
    out_ok        out boolean)
is
   type mprectype is record (
      lpid shippingplate.lpid%type,
      item shippingplate.item%type,
      lotnumber shippingplate.lotnumber%type,
      quantity shippingplate.quantity%type,
      unitofmeasure shippingplate.unitofmeasure%type,
      lastuser shippingplate.lastuser%type,
      caseuom shippingplate.pickuom%type,
      caseqty shippingplate.quantity%type);
   type mptbltype is table of mprectype index by binary_integer;
   mp mptbltype;

   type flrectype is record (
      fromlpid shippingplate.fromlpid%type,
      pickedfromloc shippingplate.pickedfromloc%type);
   type fltbltype is table of flrectype index by binary_integer;
   fl fltbltype;

   cursor c_ord(p_orderid number, p_shipid number) is
      select OH.fromfacility, OH.custid, nvl(CA.multiship,'N') as multiship
         from orderhdr OH, carrier CA
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and CA.carrier (+) = OH.carrier;
   ord c_ord%rowtype := null;
   i binary_integer;
   j binary_integer;
   l_err varchar2(1);
   l_msg varchar2(255);
   l_auxmsg varchar2(255);
   l_mlip plate.lpid%type;
   l_toloc shippingplate.location%type;
   l_cust shippingplate.custid%type;
begin
   out_ok := false;     -- assume the worst

   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;
   out_multiship := ord.multiship;

   select distinct fromlpid, pickedfromloc
      bulk collect into fl
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
        and type in ('F','P');

   select SP.lpid, SP.item, SP.lotnumber, SP.quantity, CI.baseuom,
          SP.lastuser, null, 0
      bulk collect into mp
      from shippingplate SP, custitem CI
      where SP.orderid = in_orderid
        and SP.shipid = in_shipid
        and SP.parentlpid is null
        and CI.custid = SP.custid
        and CI.item = SP.item
      order by SP.item, SP.lotnumber;

-- Make a pass thru all top-level masters and split them into case quantity
-- masters
   for i in 1..mp.count loop
      if nvl(in_procname, 'none') in ('sbay_aiuccpk.order14plt', 'sbay_aiuccpk.order18plt') then
          mp(i).caseqty := zlbl.uom_qty_conv(ord.custid, mp(i).item, 1, 'PT', mp(i).unitofmeasure);
          mp(i).caseuom := 'PT';
      else
--        Try CS first
          mp(i).caseqty := zlbl.uom_qty_conv(ord.custid, mp(i).item, 1, 'CS', mp(i).unitofmeasure);
          if mp(i).caseqty != 0 then
             mp(i).caseuom := 'CS';
          else
--           Nothing, try CTN
             mp(i).caseqty := zlbl.uom_qty_conv(ord.custid, mp(i).item, 1, 'CTN', mp(i).unitofmeasure);
             mp(i).caseuom := 'CTN';
          end if;
      end if;

      zut.prt(i||': '||mp(i).item||'/'||mp(i).quantity||'/'||mp(i).unitofmeasure||'/'||mp(i).caseqty||'/'||mp(i).caseuom);
      if mp(i).caseqty > 0 and mp(i).quantity > mp(i).caseqty then
         loop
            mp(i).quantity := mp(i).quantity - mp(i).caseqty;

            zrf.get_next_lpid(l_mlip, l_msg);
            if l_msg is not null then
               zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                     'Next lpid error: '||l_msg, 'E', mp(i).lastuser, l_auxmsg);
               return;
            end if;

            zrfld.split_mast(mp(i).caseqty, mp(i).item, 'IT', mp(i).lotnumber, mp(i).lpid,
                  'M', ord.multiship, l_mlip, ord.multiship, mp(i).lastuser,
                  ord.custid, l_err, l_msg);
            if l_msg is not null then
               zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                     'Error: '||l_msg||' splitting '||mp(i).lpid, 'E', mp(i).lastuser,
                     l_auxmsg);
               return;
            end if;
            zut.prt('split master: '||mp(i).lpid||' >> '||l_mlip);
            exit when mp(i).quantity <= mp(i).caseqty;
         end loop;
      end if;
   end loop;

-- Make another pass only looking at non-zero quantity entries -- they should all
-- be less than a case
   i := 0;
   loop
      i := i + 1;
      exit when i >= mp.count;
      if mp(i).quantity > 0 then
         j := i + 1;
         loop
            if j > mp.count then
               i := j;
               exit;                   -- both loops are done
            end if;

            if mp(i).item != mp(j).item
            or nvl(mp(i).lotnumber,'(none)') != nvl(mp(j).lotnumber,'(none)') then
               i := j - 1;
               exit;                   -- switch to new item/lot and exit inner loop
            end if;

            if mp(j).quantity = 0 then -- skip zero quantity plates
               j := j + 1;

            elsif mp(i).quantity + mp(j).quantity = mp(i).caseqty then  -- full case
               zrfld.combine_mast(mp(j).lpid, mp(i).lpid, null, mp(i).lastuser, 'N', l_toloc,
                     l_cust, l_err, l_msg);
               if l_msg is not null then
                  zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                        'Error full: '||l_msg||' combining '||mp(j).lpid||' onto '||mp(i).lpid,
                        'E', mp(i).lastuser, l_auxmsg);
                  return;
               end if;
               i := j;
               exit;                   -- exit inner loop

            elsif mp(i).quantity + mp(j).quantity < mp(i).caseqty then  -- less than case
               zrfld.combine_mast(mp(j).lpid, mp(i).lpid, null, mp(i).lastuser, 'N', l_toloc,
                     l_cust, l_err, l_msg);
               if l_msg is not null then
                  zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                        'Error less: '||l_msg||' combining '||mp(j).lpid||' onto '||mp(i).lpid,
                        'E', mp(i).lastuser, l_auxmsg);
                  return;
               end if;
               j := j + 1;

            elsif mp(i).quantity != mp(i).caseqty then   -- more than case, need split and combine
               zrf.get_next_lpid(l_mlip, l_msg);
               if l_msg is not null then
                  zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                        'Next lpid error: '||l_msg, 'E', mp(i).lastuser, l_auxmsg);
                  return;
               end if;

               zrfld.split_mast(mp(i).caseqty - mp(i).quantity, mp(j).item, 'IT',
                     mp(j).lotnumber, mp(j).lpid, 'M', ord.multiship, l_mlip,
                     ord.multiship, mp(j).lastuser, ord.custid, l_err, l_msg);
               if l_msg is not null then
                  zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                        'Error: '||l_msg||' splitting '||mp(j).lpid, 'E', mp(j).lastuser,
                        l_auxmsg);
                  return;
               end if;
               mp(j).quantity := mp(j).quantity - (mp(i).caseqty - mp(i).quantity);

               zrfld.combine_mast(l_mlip, mp(i).lpid, null, mp(i).lastuser, 'N', l_toloc,
                     l_cust, l_err, l_msg);
               if l_msg is not null then
                  zms.log_autonomous_msg('AILABELS', ord.fromfacility, ord.custid,
                        'Error more: '||l_msg||' combining '||l_mlip||' onto '||mp(i).lpid,
                        'E', mp(i).lastuser, l_auxmsg);
                  return;
               end if;

               i := j;
               j := j + 1;
            else
               j := j + 1;
            end if;
         end loop;
      end if;
   end loop;

   for cp in (select rowid, item, lotnumber, quantity, unitofmeasure, pickqty, pickuom,
                     qtyentered, uomentered, fromlpid, pickedfromloc
               from shippingplate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and type in ('F','P')) loop

      j := 0;
      for i in 1..mp.count loop
         if cp.item = mp(i).item
         and nvl(cp.lotnumber, '(none)') = nvl(mp(i).lotnumber, '(none)') then
            j := i;
            exit;
         end if;
      end loop;

      if j != 0 then
         if cp.quantity = mp(j).caseqty then
            cp.pickqty := 1;
            cp.pickuom := mp(j).caseuom;
            cp.qtyentered := 1;
            cp.uomentered := mp(j).caseuom;
         else
            cp.pickqty := cp.quantity;
            cp.pickuom := cp.unitofmeasure;
            cp.qtyentered := cp.quantity;
            cp.uomentered := cp.unitofmeasure;
         end if;

         if cp.pickedfromloc is null then
            for j in 1..fl.count loop
               if cp.fromlpid = fl(j).fromlpid then
                  cp.pickedfromloc := fl(j).pickedfromloc;
                  exit;
               end if;
            end loop;
         end if;

         update shippingplate
            set pickqty = cp.pickqty,
                pickuom = cp.pickuom,
                qtyentered = cp.qtyentered,
                uomentered = cp.uomentered,
                pickedfromloc = cp.pickedfromloc
            where rowid = cp.rowid;
      end if;
   end loop;

   out_ok := true;

exception
  when others then
      out_ok := false;
      zms.log_autonomous_msg('AILABELS', null, null,
         in_orderid||'-'||in_shipid||' error: '||sqlerrm, 'E', null, l_auxmsg);

end single_case_masters;


-- Verify the order from a shippingplate and return the orderid, and shipid
procedure verify_order
   (in_auxdata in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    io_ucc     in out ucc_standard_labels%rowtype,
    out_msg    out varchar2)
is
   cursor c_uc(p_orderid number, p_shipid number) is
      select seqof
         from ucc_standard_labels
         where orderid = p_orderid
           and shipid = p_shipid;
   uc c_uc%rowtype := null;
   cursor c_oh(p_orderid number, p_shipid number) is
      select orderstatus
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   l_pos number;
   l_cnt pls_integer := 0;
   l_order varchar2(255);
begin
   out_msg := null;

-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

-- Verify action
   if in_action not in ('A','P') then
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
            io_ucc.orderid := to_number(substr(l_order, 1, l_pos-1));
            io_ucc.shipid := to_number(substr(l_order, l_pos+1));

            open c_oh(io_ucc.orderid, io_ucc.shipid);
            fetch c_oh into oh;
            close c_oh;
         end if;
      end if;
   end if;

-- Verify order existence
   if oh.orderstatus is null then
      if in_func = 'Q' then
         out_msg := 'Order not found';
      end if;
      return;
   end if;

-- Verify order not shipped
   if oh.orderstatus = '9' then
      if in_func = 'Q' then
         out_msg := 'Order is shipped';
      end if;
      return;
   end if;

-- Insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where orderid = io_ucc.orderid
        and shipid = io_ucc.shipid
        and status in ('U','P');

   if l_cnt != 0 then
      if in_func = 'Q' then
         out_msg := 'Order has picks';
      end if;
      return;
   end if;

   select count(1) into l_cnt
      from ucc_standard_labels
      where orderid = io_ucc.orderid
        and shipid = io_ucc.shipid;

-- Process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         if l_cnt = 0 then
            out_msg := 'Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         out_msg := 'reprint';
      end if;
      return;
   end if;

   if in_func = 'Q' then
      out_msg := 'OKAY';
   elsif l_cnt = 0 then
      out_msg := 'build';
   else
      select count(1) into l_cnt
         from shippingplate SP
         where SP.orderid = io_ucc.orderid
           and SP.shipid = io_ucc.shipid
           and SP.parentlpid is null
           and not exists (select * from ucc_standard_labels UC
                              where UC.orderid = SP.orderid
                                and UC.shipid = SP.shipid
                                and UC.lpid = SP.lpid);

      if l_cnt != 0 then
         out_msg := 'rebuild';
      else
         select count(1) into l_cnt
            from shippingplate
            where orderid = io_ucc.orderid
              and shipid = io_ucc.shipid
              and parentlpid is null;
         open c_uc(io_ucc.orderid, io_ucc.shipid);
         fetch c_uc into uc;
         close c_uc;
         if l_cnt != nvl(uc.seqof,0) then
            out_msg := 'resequence';
         else
            out_msg := 'reprint';
         end if;
      end if;
   end if;

end verify_order;


-- Initialize columns in io_ucc from orderhdr, consignee, loads, facility,
-- carrier and customer tables
procedure load_hdr_data
   (io_ucc in out ucc_standard_labels%rowtype)
is
   l_zip_prefix varchar2(3);
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.loadno,
             OH.wave,
             nvl(LD.prono, OH.prono),
             OH.po,
             OH.reference,
             OH.custid,
             OH.fromfacility,
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
             OH.hdrpassthruchar11,
             OH.hdrpassthruchar12,
             OH.hdrpassthruchar13,
             OH.hdrpassthruchar14,
             OH.hdrpassthruchar15,
             OH.hdrpassthruchar16,
             OH.hdrpassthruchar17,
             OH.hdrpassthruchar18,
             OH.hdrpassthruchar19,
             OH.hdrpassthruchar20,
             OH.hdrpassthruchar21,
             OH.hdrpassthruchar22,
             OH.hdrpassthruchar23,
             OH.hdrpassthruchar24,
             OH.hdrpassthruchar25,
             OH.hdrpassthruchar26,
             OH.hdrpassthruchar27,
             OH.hdrpassthruchar28,
             OH.hdrpassthruchar29,
             OH.hdrpassthruchar30,
             OH.hdrpassthruchar31,
             OH.hdrpassthruchar32,
             nvl(OH.hdrpassthruchar33,OH.hdrpassthruchar50),
             OH.hdrpassthruchar34,
             OH.hdrpassthruchar35,
             OH.hdrpassthruchar36,
             OH.hdrpassthruchar37,
             OH.hdrpassthruchar38,
             OH.hdrpassthruchar39,
             OH.hdrpassthruchar40,
             OH.hdrpassthruchar41,
             OH.hdrpassthruchar42,
             OH.hdrpassthruchar43,
             OH.hdrpassthruchar44,
             OH.hdrpassthruchar45,
             OH.hdrpassthruchar46,
             OH.hdrpassthruchar47,
             OH.hdrpassthruchar48,
             OH.hdrpassthruchar49,
             nvl(OH.hdrpassthruchar50,OH.hdrpassthruchar33),
             OH.hdrpassthruchar51,
             OH.hdrpassthruchar52,
             OH.hdrpassthruchar53,
             OH.hdrpassthruchar54,
             OH.hdrpassthruchar55,
             OH.hdrpassthruchar56,
             OH.hdrpassthruchar57,
             OH.hdrpassthruchar58,
             OH.hdrpassthruchar59,
             OH.hdrpassthruchar60,
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
             OH.hdrpassthrudate01,
             OH.hdrpassthrudate02,
             OH.hdrpassthrudate03,
             OH.hdrpassthrudate04,
             OH.hdrpassthrudoll01,
             OH.hdrpassthrudoll02,
             OH.shipto,
             decode(CN.consignee,null,OH.shiptoname, CN.name),
             decode(CN.consignee,null,OH.shiptoaddr1, CN.addr1),
             decode(CN.consignee,null,OH.shiptoaddr2, CN.addr2),
             decode(CN.consignee,null,OH.shiptocontact, CN.contact),
             decode(CN.consignee,null,OH.shiptocity, CN.city),
             decode(CN.consignee,null,OH.shiptostate, CN.state),
             decode(CN.consignee,null,OH.shiptopostalcode, CN.postalcode),
             decode(CN.consignee,null,OH.shiptocountrycode, CN.countrycode),
             FA.name,
             FA.addr1,
             FA.addr2,
             FA.city,
             FA.state,
             FA.postalcode,
             FA.countrycode,
             CA.name,
             CA.scac,
             CU.name
         from orderhdr OH, consignee CN, loads LD, facility FA, carrier CA, customer CU
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and CN.consignee (+) = OH.shipto
           and LD.loadno (+) = OH.loadno
           and FA.facility = OH.fromfacility
           and CA.carrier (+) = OH.carrier
           and CU.custid = OH.custid;
   cursor c_cust (in_custid varchar2) is
      select name
         from customer
         where custid = in_custid;

   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select item, descr, weight
         from custitem
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;

begin
   open c_oh(io_ucc.orderid, io_ucc.shipid);
   fetch c_oh into
      io_ucc.loadno,
      io_ucc.wave,
      io_ucc.pro,
      io_ucc.po,
      io_ucc.reference,
      io_ucc.custid,
      io_ucc.facility,
      io_ucc.hdrpasschar01,
      io_ucc.hdrpasschar02,
      io_ucc.hdrpasschar03,
      io_ucc.hdrpasschar04,
      io_ucc.hdrpasschar05,
      io_ucc.hdrpasschar06,
      io_ucc.hdrpasschar07,
      io_ucc.hdrpasschar08,
      io_ucc.hdrpasschar09,
      io_ucc.hdrpasschar10,
      io_ucc.hdrpasschar11,
      io_ucc.hdrpasschar12,
      io_ucc.hdrpasschar13,
      io_ucc.hdrpasschar14,
      io_ucc.hdrpasschar15,
      io_ucc.hdrpasschar16,
      io_ucc.hdrpasschar17,
      io_ucc.hdrpasschar18,
      io_ucc.hdrpasschar19,
      io_ucc.hdrpasschar20,
      io_ucc.hdrpasschar21,
      io_ucc.hdrpasschar22,
      io_ucc.hdrpasschar23,
      io_ucc.hdrpasschar24,
      io_ucc.hdrpasschar25,
      io_ucc.hdrpasschar26,
      io_ucc.hdrpasschar27,
      io_ucc.hdrpasschar28,
      io_ucc.hdrpasschar29,
      io_ucc.hdrpasschar30,
      io_ucc.hdrpasschar31,
      io_ucc.hdrpasschar32,
      io_ucc.hdrpasschar33,
      io_ucc.hdrpasschar34,
      io_ucc.hdrpasschar35,
      io_ucc.hdrpasschar36,
      io_ucc.hdrpasschar37,
      io_ucc.hdrpasschar38,
      io_ucc.hdrpasschar39,
      io_ucc.hdrpasschar40,
      io_ucc.hdrpasschar41,
      io_ucc.hdrpasschar42,
      io_ucc.hdrpasschar43,
      io_ucc.hdrpasschar44,
      io_ucc.hdrpasschar45,
      io_ucc.hdrpasschar46,
      io_ucc.hdrpasschar47,
      io_ucc.hdrpasschar48,
      io_ucc.hdrpasschar49,
      io_ucc.hdrpasschar50,
      io_ucc.hdrpasschar51,
      io_ucc.hdrpasschar52,
      io_ucc.hdrpasschar53,
      io_ucc.hdrpasschar54,
      io_ucc.hdrpasschar55,
      io_ucc.hdrpasschar56,
      io_ucc.hdrpasschar57,
      io_ucc.hdrpasschar58,
      io_ucc.hdrpasschar59,
      io_ucc.hdrpasschar60,
      io_ucc.hdrpassnum01,
      io_ucc.hdrpassnum02,
      io_ucc.hdrpassnum03,
      io_ucc.hdrpassnum04,
      io_ucc.hdrpassnum05,
      io_ucc.hdrpassnum06,
      io_ucc.hdrpassnum07,
      io_ucc.hdrpassnum08,
      io_ucc.hdrpassnum09,
      io_ucc.hdrpassnum10,
      io_ucc.hdrpassdate01,
      io_ucc.hdrpassdate02,
      io_ucc.hdrpassdate03,
      io_ucc.hdrpassdate04,
      io_ucc.hdrpassdoll01,
      io_ucc.hdrpassdoll02,
      io_ucc.shipto,
      io_ucc.shiptoname,
      io_ucc.shiptoaddr1,
      io_ucc.shiptoaddr2,
      io_ucc.shiptocontact,
      io_ucc.shiptocity,
      io_ucc.shiptostate,
      io_ucc.shiptozip,
      io_ucc.shiptocountrycode,
      io_ucc.fromfacility,
      io_ucc.fromaddr1,
      io_ucc.fromaddr2,
      io_ucc.fromcity,
      io_ucc.fromstate,
      io_ucc.fromzip,
      io_ucc.shipfromcountrycode,
      io_ucc.carriername,
      io_ucc.scac,
      io_ucc.custname;
   close c_oh;

   io_ucc.bol := zedi.get_custom_bol(io_ucc.orderid, io_ucc.shipid);
   io_ucc.shiptocsz := io_ucc.shiptocity||', '||io_ucc.shiptostate ||' '||io_ucc.shiptozip;
   io_ucc.shipfromcsz := io_ucc.fromcity||', '||io_ucc.fromstate ||' '||io_ucc.fromzip;
   io_ucc.vendhuman := '(90)'|| io_ucc.hdrpasschar05;
   io_ucc.vendbar := '90'|| io_ucc.hdrpasschar05;

   if nvl(io_ucc.shiptocountrycode,'USA') in ('US','USA','840') then
      l_zip_prefix := '420';
   else
      l_zip_prefix := '421';
   end if;

   if length(io_ucc.shiptozip) = 7 then
      io_ucc.zipcodebar := l_zip_prefix||substr(io_ucc.shiptozip,1,7);
      io_ucc.zipcodehuman := '('||l_zip_prefix||')'||substr(io_ucc.shiptozip,1,7);
   else
      io_ucc.zipcodebar := l_zip_prefix ||substr(io_ucc.shiptozip,1,5);
      io_ucc.zipcodehuman := '(' || l_zip_prefix || ')'||substr(io_ucc.shiptozip,1,5);
   end if;

   open c_cust(io_ucc.custid);
   fetch c_cust into io_ucc.custname;
   close c_cust;

   if io_ucc.item is null then
      itm.item := 'Mixed';
      itm.descr := 'Mixed';
      itm.weight := null;
      io_ucc.iteminner := 0;
   else
      open c_itm(io_ucc.custid, io_ucc.item);
      fetch c_itm into itm;
      close c_itm;
      io_ucc.iteminner := zuccnicelabels.item_in_uom_to_innerpack(io_ucc.custid,io_ucc.item);
   end if;
   io_ucc.item := itm.item;
   io_ucc.itemdescr := itm.descr;
   io_ucc.itemweight := itm.weight;

end load_hdr_data;


-- Initialize or null-out columns in io_ucc from orderdtl table
procedure load_dtl_data
   (in_orderitem in shippingplate.orderitem%type,
    in_orderlot  in shippingplate.orderlot%type,
    io_ucc       in out ucc_standard_labels%rowtype)
is
   cursor c_od(p_orderid number, p_shipid number, p_orderitem varchar2, p_orderlot varchar2) is
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
             consigneesku
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_orderitem
           and nvl(lotnumber, '(none)') = nvl(p_orderlot, '(none)');
   od c_od%rowtype := null;
begin
   if in_orderitem is not null then
      open c_od(io_ucc.orderid, io_ucc.shipid, in_orderitem, in_orderlot);
      fetch c_od into od;
      close c_od;
   end if;

   io_ucc.dtlpasschar01 := od.dtlpassthruchar01;
   io_ucc.dtlpasschar02 := od.dtlpassthruchar02;
   io_ucc.dtlpasschar03 := od.dtlpassthruchar03;
   io_ucc.dtlpasschar04 := od.dtlpassthruchar04;
   io_ucc.dtlpasschar05 := od.dtlpassthruchar05;
   io_ucc.dtlpasschar06 := od.dtlpassthruchar06;
   io_ucc.dtlpasschar07 := od.dtlpassthruchar07;
   io_ucc.dtlpasschar08 := od.dtlpassthruchar08;
   io_ucc.dtlpasschar09 := od.dtlpassthruchar09;
   io_ucc.dtlpasschar10 := od.dtlpassthruchar10;
   io_ucc.dtlpasschar11 := od.dtlpassthruchar11;
   io_ucc.dtlpasschar12 := od.dtlpassthruchar12;
   io_ucc.dtlpasschar13 := od.dtlpassthruchar13;
   io_ucc.dtlpasschar14 := od.dtlpassthruchar14;
   io_ucc.dtlpasschar15 := od.dtlpassthruchar15;
   io_ucc.dtlpasschar16 := od.dtlpassthruchar16;
   io_ucc.dtlpasschar17 := od.dtlpassthruchar17;
   io_ucc.dtlpasschar18 := od.dtlpassthruchar18;
   io_ucc.dtlpasschar19 := od.dtlpassthruchar19;
   io_ucc.dtlpasschar20 := od.dtlpassthruchar20;
   io_ucc.dtlpasschar21 := od.dtlpassthruchar21;
   io_ucc.dtlpasschar22 := od.dtlpassthruchar22;
   io_ucc.dtlpasschar23 := od.dtlpassthruchar23;
   io_ucc.dtlpasschar24 := od.dtlpassthruchar24;
   io_ucc.dtlpasschar25 := od.dtlpassthruchar25;
   io_ucc.dtlpasschar26 := od.dtlpassthruchar26;
   io_ucc.dtlpasschar27 := od.dtlpassthruchar27;
   io_ucc.dtlpasschar28 := od.dtlpassthruchar28;
   io_ucc.dtlpasschar29 := od.dtlpassthruchar29;
   io_ucc.dtlpasschar30 := od.dtlpassthruchar30;
   io_ucc.dtlpasschar31 := od.dtlpassthruchar31;
   io_ucc.dtlpasschar32 := od.dtlpassthruchar32;
   io_ucc.dtlpasschar33 := od.dtlpassthruchar33;
   io_ucc.dtlpasschar34 := od.dtlpassthruchar34;
   io_ucc.dtlpasschar35 := od.dtlpassthruchar35;
   io_ucc.dtlpasschar36 := od.dtlpassthruchar36;
   io_ucc.dtlpasschar37 := od.dtlpassthruchar37;
   io_ucc.dtlpasschar38 := od.dtlpassthruchar38;
   io_ucc.dtlpasschar39 := od.dtlpassthruchar39;
   io_ucc.dtlpasschar40 := od.dtlpassthruchar40;
   io_ucc.dtlpassnum01 := od.dtlpassthrunum01;
   io_ucc.dtlpassnum02 := od.dtlpassthrunum02;
   io_ucc.dtlpassnum03 := od.dtlpassthrunum03;
   io_ucc.dtlpassnum04 := od.dtlpassthrunum04;
   io_ucc.dtlpassnum05 := od.dtlpassthrunum05;
   io_ucc.dtlpassnum06 := od.dtlpassthrunum06;
   io_ucc.dtlpassnum07 := od.dtlpassthrunum07;
   io_ucc.dtlpassnum08 := od.dtlpassthrunum08;
   io_ucc.dtlpassnum09 := od.dtlpassthrunum09;
   io_ucc.dtlpassnum10 := od.dtlpassthrunum10;
   io_ucc.dtlpassnum11 := od.dtlpassthrunum11;
   io_ucc.dtlpassnum12 := od.dtlpassthrunum12;
   io_ucc.dtlpassnum13 := od.dtlpassthrunum13;
   io_ucc.dtlpassnum14 := od.dtlpassthrunum14;
   io_ucc.dtlpassnum15 := od.dtlpassthrunum15;
   io_ucc.dtlpassnum16 := od.dtlpassthrunum16;
   io_ucc.dtlpassnum17 := od.dtlpassthrunum17;
   io_ucc.dtlpassnum18 := od.dtlpassthrunum18;
   io_ucc.dtlpassnum19 := od.dtlpassthrunum19;
   io_ucc.dtlpassnum20 := od.dtlpassthrunum20;
   io_ucc.dtlpassdate01 := od.dtlpassthrudate01;
   io_ucc.dtlpassdate02 := od.dtlpassthrudate02;
   io_ucc.dtlpassdate03 := od.dtlpassthrudate03;
   io_ucc.dtlpassdate04 := od.dtlpassthrudate04;
   io_ucc.dtlpassdoll01 := od.dtlpassthrudoll01;
   io_ucc.dtlpassdoll02 := od.dtlpassthrudoll02;
   io_ucc.consigneesku := od.consigneesku;

end load_dtl_data;


-- Initialize or null-out columns in io_ucc from custitem table
procedure load_itm_data
   (io_ucc in out ucc_standard_labels%rowtype)
is
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select CI.descr, IA.itemalias as upc, CI.weight
         from custitem CI, custitemalias IA
         where CI.custid = p_custid
           and CI.item = p_item
           and IA.custid (+) = CI.custid
           and IA.item (+) = CI.item
           and IA.aliasdesc (+) like 'UPC%';
   itm c_itm%rowtype := null;
begin
   if io_ucc.item is null then
      io_ucc.item := 'Mixed';
      itm.descr := 'Mixed';
      itm.weight := null;
   else
      open c_itm(io_ucc.custid, io_ucc.item);
      fetch c_itm into itm;
      close c_itm;
   end if;

   io_ucc.itemdescr := itm.descr;
   io_ucc.upc := itm.upc;
   io_ucc.itemweight := itm.weight;

end load_itm_data;


-- Add a single label to either the "real" table
procedure add_label
   (io_ucc        in out ucc_standard_labels%rowtype,
    in_sscctype   in varchar2,
    in_procname   in varchar2)
is
   l_rowid varchar2(20);
   l_barcodetype varchar2(1);
   l_labeltype caselabels.labeltype%type;
   l_lbltypedesc ucc_standard_labels.lbltypedesc%type;
begin
   if nvl(in_procname, 'none') in ('sbay_aiuccpk.order14plt', 'sbay_aiuccpk.order18plt') then
      l_labeltype := 'PL';
      l_barcodetype := '1';
      l_lbltypedesc := 'pallet';
   else
      l_labeltype := 'CS';
      l_barcodetype := '0';
      l_lbltypedesc := 'case';
   end if;
   
   if in_sscctype = 'CS14' then
      io_ucc.sscc := sscc14_barcode(io_ucc.custid, l_barcodetype);
   else
      io_ucc.sscc := zlbl.caselabel_barcode(io_ucc.custid, l_barcodetype);
   end if;
   io_ucc.ssccfmt := zlbl.format_string(io_ucc.sscc, '(??) ? ??????? ????????? ?');

   zut.prt('adding label: '||io_ucc.ssccfmt||' for lpid: '||io_ucc.lpid);
   insert into ucc_standard_labels values io_ucc;

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
      (io_ucc.orderid,
       io_ucc.shipid,
       io_ucc.custid,
       io_ucc.item,
       io_ucc.lotnumber,
       io_ucc.lpid,
       io_ucc.sscc,
       io_ucc.seq,
       io_ucc.seqof,
       sysdate,
       'ucc_standard_labels',
       'sscc',
       io_ucc.quantity,
       l_labeltype,
       in_procname);

end add_label;


-- Generate all labels for an order
procedure do_order
   (io_ucc       in out ucc_standard_labels%rowtype,
    in_sscctype  in varchar2,
    in_multiship in varchar2,
    in_procname  in varchar2,
    io_stmt      in out varchar2)
is
   cursor c_cp(p_lpid varchar2) is
      select orderitem, orderlot
         from shippingplate
         where parentlpid = p_lpid;
   cp c_cp%rowtype;
begin
   if io_stmt = 'build' then
      delete ucc_standard_labels
         where orderid = io_ucc.orderid
           and shipid = io_ucc.shipid;
      delete caselabels
         where orderid = io_ucc.orderid
           and shipid = io_ucc.shipid;
   end if;

   io_ucc.created := sysdate;
   load_hdr_data(io_ucc);

   select count(1) into io_ucc.seqof
      from shippingplate
      where orderid = io_ucc.orderid
        and shipid = io_ucc.shipid
        and parentlpid is null;

   io_ucc.seq := 1;
   if nvl(in_procname, 'none') in ('sbay_aiuccpk.order14plt', 'sbay_aiuccpk.order18plt') then
        io_ucc.lbltype := 'P';
        io_ucc.lbltypedesc := 'pallet';
    else
      io_ucc.lbltype := 'C';
      io_ucc.lbltypedesc := 'case';
    end if;
    
   for pp in (select SP.lpid, SP.fromlpid, SP.type, SP.item, SP.lotnumber, SP.quantity,
                     SP.weight
               from shippingplate SP
               where SP.orderid = io_ucc.orderid
                 and SP.shipid = io_ucc.shipid
                 and SP.parentlpid is null
                 and not exists (select * from ucc_standard_labels UC
                                    where UC.orderid = SP.orderid
                                      and UC.shipid = SP.shipid
                                      and UC.lpid = SP.lpid)) loop

--    1 label per case
      io_ucc.lpid := pp.lpid;
      io_ucc.picktolp := pp.fromlpid;
      io_ucc.shippingtype := pp.type;

      io_ucc.item := pp.item;
      io_ucc.lotnumber := pp.lotnumber;

--    Masters don't have orderitem or orderlot, so get it from any child plate
      cp := null;
      open c_cp(pp.lpid);
      fetch c_cp into cp;
      close c_cp;

      load_dtl_data(cp.orderitem, cp.orderlot, io_ucc);
      load_itm_data(io_ucc);

      io_ucc.quantity := pp.quantity;
      io_ucc.weight := pp.weight;

      if io_stmt = 'rebuild' then
         io_ucc.seq := nextseq(io_ucc.orderid, io_ucc.shipid);
      end if;

      add_label(io_ucc, in_sscctype, in_procname);

      update shippingplate
         set ucc128 = io_ucc.sscc
         where lpid = pp.lpid;

      if in_multiship = 'Y' then
         update multishipdtl
            set cartonid = io_ucc.sscc
            where cartonid = io_ucc.picktolp;
      end if;

      io_ucc.seq := io_ucc.seq + 1;
   end loop;

   if io_stmt = 'build' then
      io_stmt := 'select * from lbl_sb_view'
            || ' where orderid = ' || io_ucc.orderid
            || '   and shipid = ' || io_ucc.shipid
            || ' order by item';
   end if;

end do_order;


procedure reprint_order
   (in_orderid in number,
    in_shipid  in number,
    io_stmt    in out varchar2)
is
   l_seqof pls_integer;
   l_seq pls_integer := 1;
begin

   if io_stmt = 'resequence' then
      select count(1) into l_seqof
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and parentlpid is null;

      for uc in (select rowid, sscc from ucc_standard_labels
                  where orderid = in_orderid
                    and shipid = in_shipid
                  order by seq) loop

         update ucc_standard_labels
            set seq = l_seq,
                seqof = l_seqof
            where rowid = uc.rowid;

         update caselabels
            set seq = l_seq,
                seqof = l_seqof
            where barcode = uc.sscc;

         l_seq := l_seq + 1;
      end loop;
   end if;

   io_stmt := 'select UC.* from lbl_sb_view UC, shippingplate SP'
         || ' where UC.orderid = ' || in_orderid
         || '   and UC.shipid = ' || in_shipid
         || '   and SP.lpid = UC.lpid'
         || '   and SP.status = ''S'''
         || ' order by UC.item';

end reprint_order;


-- Public procedures


procedure order18lbl
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_ucc ucc_standard_labels%rowtype := null;
   l_ok boolean := true;
   l_multiship carrier.multiship%type;
begin
   out_stmt := null;

   verify_order(in_auxdata, in_func, in_action, l_ucc, out_stmt);
   zut.prt(out_stmt);
   if nvl(out_stmt,'(null)') in ('build', 'rebuild') then
      single_case_masters(l_ucc.orderid, l_ucc.shipid, 'sbay_aiuccpk.order18lbl', l_multiship, l_ok);
      if l_ok then
         do_order(l_ucc, '18', l_multiship, 'sbay_aiuccpk.order18lbl', out_stmt);
         if out_stmt = 'rebuild' then
            out_stmt := 'resequence';
            reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
         end if;
         commit;
      else
         out_stmt := null;
         rollback;
      end if;
   elsif nvl(out_stmt,'(null)') in ('resequence', 'reprint') then
      reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
      commit;
   end if;

end order18lbl;


procedure order14lbl
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_ucc ucc_standard_labels%rowtype := null;
   l_ok boolean := true;
   l_multiship carrier.multiship%type;
begin
   out_stmt := null;

   verify_order(in_auxdata, in_func, in_action, l_ucc, out_stmt);
   zut.prt(out_stmt);
   if nvl(out_stmt,'(null)') in ('build', 'rebuild') then
      single_case_masters(l_ucc.orderid, l_ucc.shipid, 'sbay_aiuccpk.order14lbl', l_multiship, l_ok);
      if l_ok then
         do_order(l_ucc, '14', l_multiship, 'sbay_aiuccpk.order14lbl', out_stmt);
         if out_stmt = 'rebuild' then
            out_stmt := 'resequence';
            reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
         end if;
         commit;
      else
         out_stmt := null;
         rollback;
      end if;
   elsif nvl(out_stmt,'(null)') in ('resequence', 'reprint') then
      reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
      commit;
   end if;

end order14lbl;

procedure order18plt
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_ucc ucc_standard_labels%rowtype := null;
   l_ok boolean := true;
   l_multiship carrier.multiship%type;
begin
   out_stmt := null;

   verify_order(in_auxdata, in_func, in_action, l_ucc, out_stmt);
   zut.prt(out_stmt);

   if nvl(out_stmt,'(null)') in ('build', 'rebuild') then  
      single_case_masters(l_ucc.orderid, l_ucc.shipid, 'sbay_aiuccpk.order18plt', l_multiship, l_ok);
      if l_ok then
         do_order(l_ucc, '18', l_multiship, 'sbay_aiuccpk.order18plt', out_stmt);
         if out_stmt = 'rebuild' then
            out_stmt := 'resequence';
            reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
         end if;
         commit;
      else
         out_stmt := null;
         rollback;
      end if;
   elsif nvl(out_stmt,'(null)') in ('resequence', 'reprint') then
      reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
      commit;
   end if;

end order18plt;

procedure order14plt
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_ucc ucc_standard_labels%rowtype := null;
   l_ok boolean := true;
   l_multiship carrier.multiship%type;
begin
   out_stmt := null;

   verify_order(in_auxdata, in_func, in_action, l_ucc, out_stmt);
   zut.prt(out_stmt);

   if nvl(out_stmt,'(null)') in ('build', 'rebuild') then
      single_case_masters(l_ucc.orderid, l_ucc.shipid, 'sbay_aiuccpk.order14plt', l_multiship, l_ok);
      if l_ok then
         do_order(l_ucc, '14', l_multiship, 'sbay_aiuccpk.order14plt', out_stmt);
         if out_stmt = 'rebuild' then
            out_stmt := 'resequence';
            reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
         end if;
         commit;
      else
         out_stmt := null;
         rollback;
      end if;
   elsif nvl(out_stmt,'(null)') in ('resequence', 'reprint') then
      reprint_order(l_ucc.orderid, l_ucc.shipid, out_stmt);
      commit;
   end if;

end order14plt;

end sbay_aiuccpk;
/

show errors package body sbay_aiuccpk;
exit;
