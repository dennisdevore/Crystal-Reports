create or replace package body mass_man_lbls as
--
-- $Id: barrett_label_body.sql 1 2005-05-26 12:20:03Z ed $
--
CURSOR C_DFLT(in_id varchar2)
IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;

CURSOR C_ITEM(in_custid varchar2, in_item varchar2) IS
  select *
    from custitem
   where custid = in_custid
     and item = in_item;



procedure mass_man_labels
	(in_taskid in number,
	 in_func   in varchar2,
	 out_stmt  out varchar2)
is
   cursor c_tsk(p_taskid number) is
      select wave
         from tasks
         where taskid = p_taskid
           and tasktype = 'BP';
   tsk c_tsk%rowtype;
   cursor c_oh(p_wave number) is
      select *
         from orderhdr
         where wave = p_wave
         order by orderid, shipid;
   oh orderhdr%rowtype;
   cursor c_od(p_orderid number, p_shipid number) is
      select O.custid,
             O.item,
             O.lotnumber,
             O.qtyorder,
             O.uom,
             C.labeluom,
             O.dtlpassthruchar01,
             O.dtlpassthruchar02,
             O.dtlpassthruchar03,
             O.dtlpassthruchar04,
             O.dtlpassthruchar05,
             O.dtlpassthruchar06,
             O.dtlpassthruchar07,
             O.dtlpassthruchar08,
             O.dtlpassthruchar09,
             O.dtlpassthruchar10,
             O.dtlpassthruchar11,
             O.dtlpassthruchar12,
             O.dtlpassthruchar13,
             O.dtlpassthruchar14,
             O.dtlpassthruchar15,
             O.dtlpassthruchar16,
             O.dtlpassthruchar17,
             O.dtlpassthruchar18,
             O.dtlpassthruchar19,
             O.dtlpassthruchar20,
             O.dtlpassthrunum01,
             O.dtlpassthrunum02,
             O.dtlpassthrunum03,
             O.dtlpassthrunum04,
             O.dtlpassthrunum05,
             O.dtlpassthrunum06,
             O.dtlpassthrunum07,
             O.dtlpassthrunum08,
             O.dtlpassthrunum09,
             O.dtlpassthrunum10,
             O.dtlpassthrudate01,
             O.dtlpassthrudate02,
             O.dtlpassthrudate03,
             O.dtlpassthrudate04,
             O.dtlpassthrudoll01,
             O.dtlpassthrudoll02
         from orderdtl O, custitem C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and C.custid = O.custid
           and C.item = O.item;
   l_errno number;
   l_msg varchar2(255);
   i pls_integer;
   l_item_ctns pls_integer;
   l_cnt pls_integer;
   l_lpid plate.lpid%type;
   l_custid customer.custid%type := null;

   DFLT C_DFLT%rowtype;
   ITM custitem%rowtype;

begin
   out_stmt := null;

-- Check if need to write out
    DFLT := null;
    OPEN C_DFLT('MULTISHIPITEMS');
    FETCH C_DFLT into DFLT;
    CLOSE C_DFLT;

   open c_tsk(in_taskid);
   fetch c_tsk into tsk;
   if c_tsk%notfound then
      tsk := null;
   end if;
   close c_tsk;

   if tsk.wave is null then
      select count(*) into l_cnt
         from shippingplate
         where taskid = in_taskid;
      if l_cnt = 0 then
         return;
      end if;
   end if;

   if in_func = 'Q' then
      out_stmt := 'OKAY';
      return;
   end if;

   if tsk.wave is null then   -- reprint request after all picks are complete
	   out_stmt := 'select * from mass_man_lblview where (orderid, shipid)'
            || ' in (select distinct orderid, shipid from shippingplate'
            || ' where taskid = ' || in_taskid || ')'
            || ' order by item, seq, orderid';
      return;
   end if;

	out_stmt := 'select * from mass_man_lblview where (orderid, shipid)'
         || ' in (select orderid, shipid from orderhdr '
         || ' where wave = ' || tsk.wave || ')'
         || ' order by item, seq, orderid';

   select count(1) into l_cnt
      from mass_manifest_ctn
      where wave = tsk.wave
        and used = 'Y';
   if l_cnt > 0 then
      return;                 -- reprint request before all picks are complete
   end if;

   delete multishipdtl
      where cartonid in
         (select ctnid from mass_manifest_ctn
            where (orderid, shipid) in
               (select orderid, shipid from orderhdr
                  where wave = tsk.wave));
   delete mass_manifest_ctn
      where (orderid, shipid) in
         (select orderid, shipid from orderhdr
            where wave = tsk.wave);
   commit;

   open c_oh(tsk.wave);
   loop
      fetch c_oh into oh;
      exit when c_oh%notfound;
      zmn.add_multishiphdr(oh, null, l_msg);

      l_cnt := 0;
      for od in c_od(oh.orderid, oh.shipid) loop

         if l_custid is null then
            l_custid := od.custid;
         end if;

         l_item_ctns := zlbl.uom_qty_conv(od.custid, od.item, od.qtyorder, od.uom, od.labeluom);
         for i in 1..l_item_ctns loop

            zrf.get_next_lpid(l_lpid, l_msg);

            begin
               insert into multishipdtl
                  (orderid,
                   shipid,
                   cartonid,
                   estweight,
                   status,
                   length,
                   width,
                   height,
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
                   dtlpassthrudate01,
                   dtlpassthrudate02,
                   dtlpassthrudate03,
                   dtlpassthrudate04,
                   dtlpassthrudoll01,
                   dtlpassthrudoll02)
               values
                  (oh.orderid,
                   oh.shipid,
                   l_lpid,
                   zci.item_weight(od.custid, od.item, od.labeluom),
                   decode(zcu.credit_hold(od.custid),'Y','HOLD','READY'),
                   zci.item_uom_length(od.custid, od.item, od.labeluom),
                   zci.item_uom_width(od.custid, od.item, od.labeluom),
                   zci.item_uom_height(od.custid, od.item, od.labeluom),
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
                   od.dtlpassthrudate01,
                   od.dtlpassthrudate02,
                   od.dtlpassthrudate03,
                   od.dtlpassthrudate04,
                   od.dtlpassthrudoll01,
                   od.dtlpassthrudoll02);
            exception when others then
              out_stmt := sqlerrm;
              zms.log_msg('mass_man_labels', oh.fromfacility, oh.custid,
                'MultishipDtl Insert: ' || out_stmt,
                'E', 'MULTISHIP', l_msg);
              return;
            end;

        -- Read item
            ITM := null;
            OPEN C_ITEM(od.custid, zci.item_code(od.custid,od.item));
            FETCH C_ITEM into ITM;
            CLOSE C_ITEM;

            if nvl(DFLT.defaultvalue, 'N') = 'Y' then
              insert into multishipitems (
                orderid,
                shipid,
                cartonid,
                item,
                lotnumber,
                quantity,
                uom,
                useramt1,
                useramt2,
                itmpassthruchar01,
                itmpassthruchar02,
                itmpassthruchar03,
                itmpassthruchar04,
                itmpassthrunum01,
                itmpassthrunum02,
                itmpassthrunum03,
                itmpassthrunum04,
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
                dtlpassthrudate01,
                dtlpassthrudate02,
                dtlpassthrudate03,
                dtlpassthrudate04,
                dtlpassthrudoll01,
                dtlpassthrudoll02
              )
              values ( 
                oh.orderid,
                oh.shipid,
                l_lpid,
                od.item,
                od.lotnumber,
                od.qtyorder,
                od.uom,
                zci.item_amt(null, oh.orderid, oh.shipid, od.item, od.lotnumber),
                ITM.useramt2,
                ITM.itmpassthruchar01,
                ITM.itmpassthruchar02,
                ITM.itmpassthruchar03,
                ITM.itmpassthruchar04,
                ITM.itmpassthrunum01,
                ITM.itmpassthrunum02,
                ITM.itmpassthrunum03,
                ITM.itmpassthrunum04,
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
                od.dtlpassthrudate01,
                od.dtlpassthrudate02,
                od.dtlpassthrudate03,
                od.dtlpassthrudate04,
                od.dtlpassthrudoll01,
                od.dtlpassthrudoll02
             );
            end if;


            l_cnt := l_cnt +1;
            insert into mass_manifest_ctn
               (ctnid,
                orderid,
                shipid,
                item,
                lotnumber,
                seq,
                used,
                wave)
            values
               (l_lpid,
                oh.orderid,
                oh.shipid,
                od.item,
                od.lotnumber,
                l_cnt,
                'N',
                tsk.wave);
         end loop;
      end loop;

      update mass_manifest_ctn
         set seqof = l_cnt
         where orderid = oh.orderid
           and shipid = oh.shipid;

   end loop;
   commit;

   ziem.impexp_request('E', null, null, 'Mass Manifest FedX Batch Export', null, 'NOW',
         tsk.wave, 0, 0, 'LABELS', null, null, null, null, null, null, null, l_errno, l_msg);

end mass_man_labels;


procedure mass_man_nolabels
	(in_wave in number)
is

   cursor c_tsk(p_wave number) is
      select taskid, wave
         from tasks
         where wave = p_wave
           and tasktype = 'BP'
        order by taskid;

   cursor c_oh(p_wave number) is
      select *
         from orderhdr
         where wave = p_wave
         order by orderid, shipid;
   oh orderhdr%rowtype;
   cursor c_od(p_orderid number, p_shipid number) is
      select O.custid,
             O.item,
             O.lotnumber,
             O.qtyorder,
             O.uom,
             C.labeluom,
             O.dtlpassthruchar01,
             O.dtlpassthruchar02,
             O.dtlpassthruchar03,
             O.dtlpassthruchar04,
             O.dtlpassthruchar05,
             O.dtlpassthruchar06,
             O.dtlpassthruchar07,
             O.dtlpassthruchar08,
             O.dtlpassthruchar09,
             O.dtlpassthruchar10,
             O.dtlpassthruchar11,
             O.dtlpassthruchar12,
             O.dtlpassthruchar13,
             O.dtlpassthruchar14,
             O.dtlpassthruchar15,
             O.dtlpassthruchar16,
             O.dtlpassthruchar17,
             O.dtlpassthruchar18,
             O.dtlpassthruchar19,
             O.dtlpassthruchar20,
             O.dtlpassthrunum01,
             O.dtlpassthrunum02,
             O.dtlpassthrunum03,
             O.dtlpassthrunum04,
             O.dtlpassthrunum05,
             O.dtlpassthrunum06,
             O.dtlpassthrunum07,
             O.dtlpassthrunum08,
             O.dtlpassthrunum09,
             O.dtlpassthrunum10,
             O.dtlpassthrudate01,
             O.dtlpassthrudate02,
             O.dtlpassthrudate03,
             O.dtlpassthrudate04,
             O.dtlpassthrudoll01,
             O.dtlpassthrudoll02
         from orderdtl O, custitem C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and C.custid = O.custid
           and C.item = O.item;
   l_errno number;
   l_msg varchar2(255);
   i pls_integer;
   l_item_ctns pls_integer;
   l_cnt pls_integer;
   l_lpid plate.lpid%type;
   l_custid customer.custid%type := null;

   DFLT C_DFLT%rowtype;
   ITM custitem%rowtype;

begin

-- Check if need to write out
    DFLT := null;
    OPEN C_DFLT('MULTISHIPITEMS');
    FETCH C_DFLT into DFLT;
    CLOSE C_DFLT;


for tsk in c_tsk(in_wave)
loop
   if tsk.wave is null then
      select count(*) into l_cnt
         from shippingplate
         where taskid = tsk.taskid;
      if l_cnt = 0 then
         return;
      end if;
   end if;

   select count(1) into l_cnt
      from mass_manifest_ctn
      where wave = tsk.wave
        and used = 'Y';
   if l_cnt > 0 then
      return;                 -- reprint request before all picks are complete
   end if;

   delete multishipdtl
      where cartonid in
         (select ctnid from mass_manifest_ctn
            where (orderid, shipid) in
               (select orderid, shipid from orderhdr
                  where wave = tsk.wave));
   delete mass_manifest_ctn
      where (orderid, shipid) in
         (select orderid, shipid from orderhdr
            where wave = tsk.wave);
   commit;

   open c_oh(tsk.wave);
   loop
      fetch c_oh into oh;
      exit when c_oh%notfound;
      zmn.add_multishiphdr(oh, null, l_msg);

      l_cnt := 0;
      for od in c_od(oh.orderid, oh.shipid) loop

         if l_custid is null then
            l_custid := od.custid;
         end if;

         l_item_ctns := zlbl.uom_qty_conv(od.custid, od.item, od.qtyorder, od.uom, od.labeluom);
         for i in 1..l_item_ctns loop

            zrf.get_next_lpid(l_lpid, l_msg);

            insert into multishipdtl
               (orderid,
                shipid,
                cartonid,
                estweight,
                status,
                length,
                width,
                height,
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
                dtlpassthrudate01,
                dtlpassthrudate02,
                dtlpassthrudate03,
                dtlpassthrudate04,
                dtlpassthrudoll01,
                dtlpassthrudoll02)
            values
               (oh.orderid,
                oh.shipid,
                l_lpid,
                zci.item_weight(od.custid, od.item, od.labeluom),
                'READY',
                zci.item_uom_length(od.custid, od.item, od.labeluom),
                zci.item_uom_width(od.custid, od.item, od.labeluom),
                zci.item_uom_height(od.custid, od.item, od.labeluom),
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
                od.dtlpassthrudate01,
                od.dtlpassthrudate02,
                od.dtlpassthrudate03,
                od.dtlpassthrudate04,
                od.dtlpassthrudoll01,
                od.dtlpassthrudoll02);

            --zmn.add_multishipitems(OH.orderid, OH.shipid,
            --        zmn.correct_fromlpid(CH.fromlpid), errmsg);

        -- Read item
            ITM := null;
            OPEN C_ITEM(od.custid, zci.item_code(od.custid,od.item));
            FETCH C_ITEM into ITM;
            CLOSE C_ITEM;

            if nvl(DFLT.defaultvalue, 'N') = 'Y' then
              insert into multishipitems (
                orderid,
                shipid,
                cartonid,
                item,
                lotnumber,
                quantity,
                uom,
                useramt1,
                useramt2,
                itmpassthruchar01,
                itmpassthruchar02,
                itmpassthruchar03,
                itmpassthruchar04,
                itmpassthrunum01,
                itmpassthrunum02,
                itmpassthrunum03,
                itmpassthrunum04,
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
                dtlpassthrudate01,
                dtlpassthrudate02,
                dtlpassthrudate03,
                dtlpassthrudate04,
                dtlpassthrudoll01,
                dtlpassthrudoll02
              )
              values ( 
                oh.orderid,
                oh.shipid,
                l_lpid,
                od.item,
                od.lotnumber,
                od.qtyorder,
                od.uom,
                zci.item_amt(null, oh.orderid, oh.shipid, od.item, od.lotnumber),
                ITM.useramt2,
                ITM.itmpassthruchar01,
                ITM.itmpassthruchar02,
                ITM.itmpassthruchar03,
                ITM.itmpassthruchar04,
                ITM.itmpassthrunum01,
                ITM.itmpassthrunum02,
                ITM.itmpassthrunum03,
                ITM.itmpassthrunum04,
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
                od.dtlpassthrudate01,
                od.dtlpassthrudate02,
                od.dtlpassthrudate03,
                od.dtlpassthrudate04,
                od.dtlpassthrudoll01,
                od.dtlpassthrudoll02
             );
            end if;

            l_cnt := l_cnt +1;
            insert into mass_manifest_ctn
               (ctnid,
                orderid,
                shipid,
                item,
                lotnumber,
                seq,
                used,
                wave)
            values
               (l_lpid,
                oh.orderid,
                oh.shipid,
                od.item,
                od.lotnumber,
                l_cnt,
                'N',
                tsk.wave);
         end loop;
      end loop;

      update mass_manifest_ctn
         set seqof = l_cnt
         where orderid = oh.orderid
           and shipid = oh.shipid;

   end loop;

end loop;

commit;


end mass_man_nolabels;


end mass_man_lbls;
/

show errors package body mass_man_lbls;
exit;
