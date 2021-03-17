create or replace package body pacam_becolbls as

strDebugYN char(1) := 'Y';
--zmsSeq number := 0;
strMsg varchar2(255);
cursor c_oh(p_orderid number, p_shipid number) is
   select OH.orderid,
          OH.shipid,
          OH.loadno,
          OH.custid,
          OH.wave,
          OH.po,
          OH.reference,
          OH.orderstatus,
          nvl(LD.prono,OH.prono) as prono,
          nvl(LD.billoflading,OH.billoflading) as billoflading,
          decode(CN.consignee,null,OH.shiptoname,CN.name) as shiptoname,
          decode(CN.consignee,null,OH.shiptoaddr1,CN.addr1) as shiptoaddr1,
          decode(CN.consignee,null,OH.shiptoaddr2,CN.addr2) as shiptoaddr2,
          decode(CN.consignee,null,OH.shiptocity,CN.city) as shiptocity,
          decode(CN.consignee,null,OH.shiptostate,CN.state) as shiptostate,
          decode(CN.consignee,null,OH.shiptopostalcode,CN.postalcode) as shiptopostalcode,
          CU.name as name,
          FA.addr1 as addr1,
          FA.addr2 as addr2,
          FA.city as city,
          FA.state as state,
          FA.postalcode as postalcode,
          FA.countrycode,
          CA.name as caname,
          CA.scac
      from orderhdr OH, facility FA, carrier CA, loads LD,
           consignee CN, customer CU
      where OH.orderid = p_orderid
        and OH.shipid = p_shipid
        and FA.facility = OH.fromfacility
        and OH.carrier = CA.carrier (+)
        and OH.loadno = LD.loadno(+)
        and oh.shipto = CN.consignee(+)
        and oh.custid = CU.custid(+);

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
   debugmsg('l_lpid ' || l_lpid);
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
         from pacam_beco_label_table
         where orderid = inp.orderid
           and shipid = inp.shipid;
   end if;

end verify_order;


procedure build_pblt_oh                   -- fill in the label_table info that comes from orderdhr
(
pblt in out pacam_beco_label_table%rowtype,
oh in c_oh%rowtype
)
is
l_dc varchar2(5);
l_dc_pos integer;
begin
   pblt.orderid := oh.orderid;
   pblt.shipid := oh.shipid;

   pblt.from_name := oh.name;
   pblt.fromaddr1 := oh.addr1;
   pblt.fromaddr2 := oh.addr2;
   pblt.fromcsz := oh.city||', '||oh.state||' '||oh.postalcode;
   pblt.toname := oh.shiptoname;
   pblt.toaddr1 := oh.shiptoaddr1;
   pblt.toaddr2 := oh.shiptoaddr2;
   pblt.tocsz := oh.shiptocity||', '||oh.shiptostate||' '||oh.shiptopostalcode;
   pblt.tozip := '(420) ' || oh.shiptopostalcode;
   pblt.tobczip := '420' || oh.shiptopostalcode;

   pblt.carname := oh.caname;
   pblt.pro := oh.prono;
   pblt.bol := oh.billoflading;
   pblt.po := oh.po;

   l_dc_pos := instr(oh.shiptoname,'-');
   if l_dc_pos = 0 then
      pblt.dc := '';
      pblt.fordc := '';
      pblt.bcfordc := '';
   else
      l_dc_pos := l_dc_pos + 2;
      l_dc := substr(oh.shiptoname,l_dc_pos,5);
      pblt.dc := 'DC 00' || l_dc;
      pblt.fordc := '(91) 00' || l_dc;
      pblt.bcfordc := '9100' || l_dc;
   end if;
   pblt.dept := '011';

end build_pblt_oh;

procedure insert_beco
(
 in_action in varchar2,
 pblt in pacam_beco_label_table%rowtype,
 in_custid varchar2
)
is
l_rowid varchar2(20);
begin
if in_action = 'A' then
   insert into pacam_beco_label_table
      (orderid,
       shipid,
       lpid,
       fromlpid,
       parentlpid,
       from_name,
       fromaddr1,
       fromaddr2,
       fromcsz,
       toname,
       toaddr1,
       toaddr2,
       tocsz,
       tozip,
       tobczip,
       carname,
       pro,
       bol,
       po,
       dept,
       style,
       color,
       isize,
       units,
       item,
       lotnumber,
       fordc,
       bcfordc,
       dc,
       sku,
       sscc,
       ssccfmt,
       buildseq,
       changed,
       crdt)
   values
       (pblt.orderid,
        pblt.shipid,
        pblt.lpid,
        pblt.fromlpid,
        pblt.parentlpid,
        pblt.from_name,
        pblt.fromaddr1,
        pblt.fromaddr2,
        pblt.fromcsz,
        pblt.toname,
        pblt.toaddr1,
        pblt.toaddr2,
        pblt.tocsz,
        pblt.tozip,
        pblt.tobczip,
        pblt.carname,
        pblt.pro,
        pblt.bol,
        pblt.po,
        pblt.dept,
        pblt.style,
        pblt.color,
        pblt.isize,
        pblt.units,
        pblt.item,
        pblt.lotnumber,
        pblt.fordc,
        pblt.bcfordc,
        pblt.dc,
        pblt.sku,
        pblt.sscc,
        pblt.ssccfmt,
        pblt.buildseq,
        null,
        sysdate);

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
         (pblt.orderid,
          pblt.shipid,
          in_custid,
          pblt.item,
          pblt.lotnumber,
          pblt.parentlpid,
          pblt.sscc,
          pblt.buildseq,
          null,
          sysdate,
          'pblt_beco_label_table',
          'sscc',
          pblt.units,
          'CS',
          'pacam_becolbls.pa_plate_beco');


else
   insert into pacam_beco_label_table_temp
      (orderid,
       shipid,
       lpid,
       fromlpid,
       parentlpid,
       from_name,
       fromaddr1,
       fromaddr2,
       fromcsz,
       toname,
       toaddr1,
       toaddr2,
       tocsz,
       tozip,
       tobczip,
       carname,
       pro,
       bol,
       po,
       dept,
       style,
       color,
       isize,
       units,
       item,
       lotnumber,
       fordc,
       bcfordc,
       dc,
       sku,
       buildseq)
   values
       (pblt.orderid,
        pblt.shipid,
        pblt.lpid,
        pblt.fromlpid,
        pblt.parentlpid,
        pblt.from_name,
        pblt.fromaddr1,
        pblt.fromaddr2,
        pblt.fromcsz,
        pblt.toname,
        pblt.toaddr1,
        pblt.toaddr2,
        pblt.tocsz,
        pblt.tozip,
        pblt.tobczip,
        pblt.carname,
        pblt.pro,
        pblt.bol,
        pblt.po,
        pblt.dept,
        pblt.style,
        pblt.color,
        pblt.isize,
        pblt.units,
        pblt.item,
        pblt.lotnumber,
        pblt.fordc,
        pblt.bcfordc,
        pblt.dc,
        pblt.sku,
        pblt.buildseq)
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
      (pblt.orderid,
       pblt.shipid,
       in_custid,
       pblt.item,
       pblt.lotnumber,
       pblt.parentlpid,
       null,
       null,
       pblt.units,
       'CS',
       '0',
       l_rowid,
       'N');

end if;

exception when others then
   debugmsg(sqlerrm);
end insert_beco;

procedure insert_tmp is
   cursor c_alt(p_rowid varchar2) is
      select *
         from pacam_beco_label_table_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   l_sscc varchar2(20);

begin
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
          null,
          sysdate,
          'pacam_beco_label_table',
          'sscc',
          tmp.quantity,
          'CS',
          'pacam_becolbls.pa_plate_beco');

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;

      insert into pacam_beco_label_table
         (orderid,
          shipid,
          lpid,
          fromlpid,
          parentlpid,
          from_name,
          fromaddr1,
          fromaddr2,
          fromcsz,
          toname,
          toaddr1,
          toaddr2,
          tocsz,
          tozip,
          tobczip,
          carname,
          pro,
          bol,
          po,
          dept,
          style,
          color,
          isize,
          units,
          item,
          lotnumber,
          fordc,
          bcfordc,
          dc,
          sku,
          sscc,
          ssccfmt,
          buildseq,
          changed,
          crdt)
      values
          (alt.orderid,
           alt.shipid,
           alt.lpid,
           alt.fromlpid,
           alt.parentlpid,
           alt.from_name,
           alt.fromaddr1,
           alt.fromaddr2,
           alt.fromcsz,
           alt.toname,
           alt.toaddr1,
           alt.toaddr2,
           alt.tocsz,
           alt.tozip,
           alt.tobczip,
           alt.carname,
           alt.pro,
           alt.bol,
           alt.po,
           alt.dept,
           alt.style,
           alt.color,
           alt.isize,
           alt.units,
           alt.item,
           alt.lotnumber,
           alt.fordc,
           alt.bcfordc,
           alt.dc,
           alt.sku,
           l_sscc,
           '(' || substr(l_sscc,1,2) || ') ' || substr(l_sscc,3,1) || ' ' ||
               substr(l_sscc,4,7) || ' ' || substr(l_sscc,11,9) || ' ' || substr(l_sscc,20,1),
           alt.buildseq,
           'Y',
           sysdate);
   end loop;

end insert_tmp;


procedure do_labels
   (oh            in c_oh%rowtype,
    in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_stmt      out varchar2)
is
   l_sscc varchar2(20);
   l_seq pls_integer;
   l_seqof pls_integer;
   l_cnt pls_integer;
   l_qty shippingplate.quantity%type;
   l_buildseq number := 0;
   l_rowid varchar2(20);
   l_match varchar2(1);
   recCount number;
   l_lpid varchar2(15);
   l_fromlpid varchar2(15);
   l_item varchar2(30);
   l_citem varchar2(30);
   l_quantity integer;
   l_units integer;
   l_style varchar2(15);
   l_color varchar2(15);
   l_size varchar2(15);
   l_casepack integer;
   pblt pacam_beco_label_table%rowtype;
   l_sku varchar2(20);



begin
   out_stmt := null;
--   debugmsg('do_labels');
   --zmsSeq := --zmsSeq + 1;
   --zms.log_msg('lbl', 'lbl', '','order labels ' || zmsSeq, 'I', 'JCT', strMsg);
   build_pblt_oh(pblt,oh);
   if in_action != 'P' then
      for sp in (select sp.custid, sp.item, sp.type, sp.quantity,
                  sp.unitofmeasure, sp.lotnumber, sp.fromlpid, sp.parentlpid
                  from shippingplate sp
                  where sp.lpid in (select lpid from shippingplate
                                    start with lpid = in_lpid
                                    connect by prior lpid = parentlpid)
                    and sp.type in ('F','P')
                  order by sp.item) loop
--         debugmsg('sp loop ' || sp.item);
         l_qty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, 'CS', sp.unitofmeasure);
         l_seqof := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, 'CS');

         for l_seq in 1..l_seqof loop
--            debugmsg(l_seq || ' of ' || l_seqof);
            l_buildseq := l_buildseq + 1;
            pblt.buildseq := l_buildseq;
            pblt.item := sp.item;
            select dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03 into
                   l_style, l_color, l_size
               from orderdtl
               where orderid = oh.orderid
                 and shipid = oh.shipid
                 and item = sp.item;

            pblt.style := l_style;
            pblt.color := l_color;
            pblt.isize := l_size;
            pblt.units := l_qty;
            pblt.lotnumber := sp.lotnumber;
            pblt.lpid := in_lpid;
            pblt.fromlpid := sp.fromlpid;
            pblt.parentlpid := sp.parentlpid;

            select count(1) into l_cnt
               from custitemuom
               where custid = sp.custid
                 and item = sp.item
                 and fromuom = 'EA'
                 and touom = 'CS';
            if l_cnt > 1 then
               select qty into l_casepack
                  from custitemuom
                  where custid = sp.custid
                    and item = sp.item
                    and fromuom = 'EA'
                    and touom = 'CS';
            else
               l_casepack := 1;
            end if;
            l_sku := null;
            select count(1) into l_cnt
               from custitemalias
               where custid = sp.custid
                 and item = sp.item
                 and aliasdesc = 'SKU';
            if l_cnt > 0 then
               select nvl(itemalias,'') into l_sku
                  from custitemalias
                  where custid = sp.custid
                    and item = sp.item
                    and aliasdesc = 'SKU';
            end if;

            pblt.sku := l_sku;
            if in_action = 'A' then
               l_sscc := zlbl.caselabel_barcode(oh.custid, '0');
               pblt.sscc := l_sscc;
               pblt.ssccfmt := '(' || substr(l_sscc,1,2) || ') ' || substr(l_sscc,3,1) || ' ' ||
                               substr(l_sscc,4,7) || ' ' || substr(l_sscc,11,9) || ' ' || substr(l_sscc,20,1);

            end if;
            insert_beco(in_action, pblt, oh.custid);
            sp.quantity := sp.quantity - l_qty;
         end loop;
      end loop;
      if in_action = 'A' then
         commit;
      end if;
   end if; -- if acation != 'P'

   if in_action != 'C' then
      out_stmt := 'select * from pacam_beco_label_table where orderid = ' || oh.orderid
            || ' and shipid = ' || oh.shipid
            || ' and (lpid = ''' || in_lpid || ''''
                 || ' or fromlpid = ''' || in_lpid || '''' || ')';
      return;
   end if;

   if in_func = 'Q' then
--    match caselabels with temp ignoring barcode
      for lbl in (select * from caselabels
                  where orderid = oh.orderid
                    and shipid = oh.shipid
                    and lpid = in_lpid
                       and labeltype = 'CS') loop

         l_match := 'N';
         for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                        where matched = 'N') loop

            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
            and nvl(tmp.seq,'0') = nvl(lbl.seq,0) then
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

      delete caselabels_temp;
      delete pacam_beco_label_table_temp;
      return;
   end if;

-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
               where orderid = oh.orderid
                 and shipid = oh.shipid
                 and lpid = in_lpid
                 and labeltype = 'CS') loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
         and nvl(tmp.seq,0) = nvl(lbl.seq,0) then
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

-- delete unmatched pblt data
   delete pacam_beco_label_table
     where orderid = oh.orderid
        and shipid = oh.shipid
        and lpid = in_lpid
        and sscc in (select barcode from caselabels
                     where orderid = oh.orderid
                       and shipid = oh.shipid
                       and labeltype = 'CS'
                       and matched = 'N');
   delete caselabels
      where orderid = oh.orderid
        and shipid = oh.shipid
        and lpid = in_lpid
        and labeltype = 'CS'
        and matched = 'N';

-- add new data
   update pacam_beco_label_table
      set changed = 'N'
      where orderid = oh.orderid
        and shipid = oh.shipid
        and lpid = in_lpid;

   select nvl(max(buildseq),0) into l_buildseq
      from pacam_beco_label_table
      where orderid = oh.orderid
        and shipid = oh.shipid
        and lpid = in_lpid;

   insert_tmp();

   commit;

   out_stmt := 'select * from pacam_beco_label_table where orderid = ' || oh.orderid
         || ' and shipid = ' || oh.shipid
         || ' and lpid = ''' || in_lpid || ''''
         || ' and changed = ''Y'''
         || ' order by buildseq';

end do_labels;


-- public

procedure pa_plate_beco
      (in_lpid   in varchar2,
       in_func   in varchar2,
       in_action in varchar2,
       out_stmt  out varchar2)
   is
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
   l_seq number;
   oh c_oh%rowtype;
   a_msg varchar2(180);
   spCnt pls_integer;
begin
   out_stmt := null;
   debugmsg('pa_plate_beco');
   --zmsSeq := --zmsSeq + 1;
   --zms.log_msg('lbl', 'lbl', '',in_lpid ||' ord_sa_all ' || --zmsSeq, 'I', 'JCT', strMsg);
   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);
   debugmsg('cnt ' || l_order_cnt);
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
   debugmsg('oh');
   open c_oh(l_orderid, l_shipid);
   fetch c_oh into oh;
   if c_oh%notfound then
      oh := null;
   end if;
   close c_oh;

   select count(1) into l_label_cnt from pacam_beco_label_table
      where orderid = oh.orderid
        and shipid =  oh.shipid
        and (parentlpid =  in_lpid
             or fromlpid = in_lpid);

   if in_func = 'Q' then
      if in_action in ('A','N') then
         out_stmt := 'OKAY';
      elsif in_action = 'P' then
         if l_label_cnt = 0 then
            out_stmt := 'Nothing for order';
         else
            out_stmt := 'OKAY';
         end if;
      else
         out_stmt := 'Unsupported Action';
      end if;
      return;
   end if;

   if in_action = 'A' then
      delete from pacam_beco_label_table
         where orderid = l_orderid
           and l_shipid = l_shipid
           and (parentlpid =  in_lpid
                 or fromlpid = in_lpid);

      delete from caselabels
         where orderid = l_orderid
           and l_shipid = l_shipid
           and lpid =  in_lpid;
   end if;

   if in_action != 'P' then
      l_seq := 0;
      if in_action = 'N' then
         select count(1) into l_cnt
          from pacam_beco_label_table
          where orderid = oh.orderid
            and l_shipid = oh.shipid;
      else
         l_cnt := 0;
      end if;
      if l_cnt = 0 then
         do_labels(oh, in_lpid, in_func, in_action,l_msg);
      end if;
   end if;



   out_stmt := 'select * from pacam_beco_label_table where orderid = ' || l_orderid
         || ' and shipid = ' || l_shipid
         || ' and (parentlpid = ''' || in_lpid || ''''
              || ' or fromlpid = ''' || in_lpid || ''''
              || ' or lpid = ''' || in_lpid || ''''
         || ')';


end pa_plate_beco;

procedure pa_lp_beco_r
      (in_lpid   in varchar2,
       in_func   in varchar2,
       in_action in varchar2,
       out_stmt  out varchar2)
   is
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
   l_seq number;
   oh c_oh%rowtype;
   a_msg varchar2(180);
   spCnt pls_integer;
begin
   out_stmt := null;
   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);
   debugmsg('cnt ' || l_order_cnt);
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

   select count(1) into l_label_cnt from pacam_beco_label_table
      where orderid = oh.orderid
        and shipid =  oh.shipid
        and (parentlpid =  in_lpid
             or fromlpid = in_lpid);

   if in_func = 'Q' then
      if l_label_cnt = 0 then
         out_stmt := 'Nothing for order';
      else
         out_stmt := 'OKAY';
      end if;
      return;
   end if;


   out_stmt := 'select * from pacam_beco_label_table where orderid = ' || l_orderid
         || ' and shipid = ' || l_shipid
         || ' and (parentlpid = ''' || in_lpid || ''''
              || ' or fromlpid = ''' || in_lpid || ''''
              || ' or lpid = ''' || in_lpid || ''''
         || ')';


end pa_lp_beco_r;

procedure pa_order_beco
      (in_lpid   in varchar2,
       in_func   in varchar2,
       in_action in varchar2,
       out_stmt  out varchar2)
   is
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
   l_seq number;
   oh c_oh%rowtype;
   a_msg varchar2(180);
   spCnt pls_integer;
begin
   out_stmt := null;
   debugmsg('pa_order_beco');
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
   open c_oh(l_orderid, l_shipid);
   fetch c_oh into oh;
   if c_oh%notfound then
      oh := null;
   end if;
   close c_oh;


   if in_func = 'Q' then
      if in_action in ('A','N') then
         out_stmt := 'OKAY';
      elsif in_action = 'P' then
         if l_label_cnt = 0 then
            out_stmt := 'Nothing for order';
         else
            out_stmt := 'OKAY';
         end if;
      else
         out_stmt := 'Unsupported Action';
      end if;
      return;
   end if;

   if in_action = 'A' then
      delete from pacam_beco_label_table
         where orderid = l_orderid
           and l_shipid = l_shipid;

      delete from caselabels
         where orderid = l_orderid
           and l_shipid = l_shipid;
   end if;

   if in_action != 'P' then
      l_seq := 0;
      if in_action = 'N' then
         select count(1) into l_cnt
          from pacam_beco_label_table
          where orderid = oh.orderid
            and l_shipid = oh.shipid;
      else
         l_cnt := 0;
      end if;
      if l_cnt = 0 then
         for mp in (select lpid, fromlpid
                     from shippingplate
                     where orderid = oh.orderid
                       and shipid = oh.shipid
                       and parentlpid is null) loop
            debugmsg('order lip ' || mp.lpid);
            pa_plate_beco(mp.lpid, in_func, in_action,out_stmt);
         end loop;
      end if;
   end if;



   out_stmt := 'select * from pacam_beco_label_table where orderid = ' || l_orderid
         || ' and shipid = ' || l_shipid
         || ' order by orderid, shipid, item, buildseq';


end pa_order_beco;

end pacam_becolbls;
/

show errors package body pacam_becolbls;
exit;
