create or replace PACKAGE BODY alps.zcommitment
IS
--
-- $Id$
--


-- Global variables


type mforectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type,
   facility orderhdr.fromfacility%type,
   wave orderhdr.wave%type);
type mfotbltype is table of mforectype index by binary_integer;
mfo_tbl mfotbltype;

type uodrectype is record (
   shipid orderdtl.shipid%type,
   item orderdtl.item%type,
   lotnumber orderdtl.lotnumber%type,
   min_days_to_expiration orderdtl.min_days_to_expiration%type);
type uodtbltype is table of uodrectype index by binary_integer;
uod_tbl uodtbltype;

type anyfactype is record (
   facility plate.facility%type,
   orderdate date);
type anyfaccur is ref cursor return anyfactype;


function get_mfo_wave               -- private procedure, not in spec
   (in_facility varchar2)
return number
is
   i binary_integer;
begin
   for i in 1..mfo_tbl.count loop
      if mfo_tbl(i).facility = in_facility then
         return mfo_tbl(i).wave;
      end if;
   end loop;

   return 0;

exception when others then
   return 0;
end get_mfo_wave;


function get_mfo_shipid             -- private procedure, not in spec
   (in_facility varchar2,
    in_orderid  number)
return number
is
   i binary_integer;
begin
   for i in 1..mfo_tbl.count loop
      if (mfo_tbl(i).facility = in_facility) and (mfo_tbl(i).orderid = in_orderid) then
         return mfo_tbl(i).shipid;
      end if;
   end loop;

   return 0;

exception when others then
   return 0;
end get_mfo_shipid;


function is_mfo_wave_used           -- private procedure, not in spec
   (in_wave number)
return boolean
is
   i binary_integer;
begin
   for i in 1..mfo_tbl.count loop
      if mfo_tbl(i).wave = in_wave then
         return true;
      end if;
   end loop;

   return false;

exception when others then
   return false;
end is_mfo_wave_used;


procedure multifac_order_bld_wave   -- private procedure, not in spec
   (in_wave     in number,
    in_facility in varchar2,
    in_userid   in varchar2,
    io_wave     in out number,
    io_errorno  in out number,
    io_msg      in out varchar2)
is
begin
   io_msg := '';
   io_errorno := 0;

   zwv.get_next_wave(io_wave, io_msg);

   if substr(io_msg, 1, 4) = 'OKAY' then
      insert into waves
         (wave, descr, wavestatus, schedrelease, actualrelease,
          facility, lastuser, lastupdate, stageloc, picktype,
          taskpriority, sortloc, job, childwave, batchcartontype,
          fromlot, tolot, orderlimit, openfacility, cntorder,
          qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
          cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
          consolidated, shiptype, carrier, servicelevel, shipcost,
          weight, tms_status, tms_status_update, mass_manifest, pick_by_zone,
          sdi_sortation_yn, sdi_sorter_process, sdi_sorter, sdi_max_units,
          sdi_sorter_mode, sdi_manual_picks_yn)
      select io_wave, W.descr, W.wavestatus, W.schedrelease, W.actualrelease,
             in_facility, in_userid, sysdate, null, W.picktype,
             W.taskpriority, null, W.job, W.childwave, W.batchcartontype,
             W.fromlot, W.tolot, W.orderlimit, in_facility, 0,
             null, null, null, null, null,
             null, null, null, null, W.replanned,
             W.consolidated, W.shiptype, W.carrier, W.servicelevel, W.shipcost,
             null, W.tms_status, W.tms_status_update, W.mass_manifest, W.pick_by_zone,
             W.sdi_sortation_yn, W.sdi_sorter_process, W.sdi_sorter, W.sdi_max_units,
             W.sdi_sorter_mode, W.sdi_manual_picks_yn
         from waves W
         where W.wave = in_wave;
   end if;

exception
   when OTHERS then
      io_msg := 'zcmmobw ' || sqlerrm;
      io_errorno := sqlcode;
end multifac_order_bld_wave;


procedure update_mfo_tbl            -- private procedure, not in spec
	(in_orderid  in number,
    in_shipid   in number,
    in_wave     in number,
    in_facility in varchar2)
is
   i binary_integer;
begin
   for i in 1..mfo_tbl.count loop
      if (mfo_tbl(i).orderid = in_orderid)
      and (mfo_tbl(i).shipid = in_shipid)
      and (mfo_tbl(i).facility = in_facility) then
         return;
      end if;
   end loop;
   i := mfo_tbl.count+1;
   mfo_tbl(i).orderid := in_orderid;
   mfo_tbl(i).shipid := in_shipid;
   mfo_tbl(i).wave := in_wave;
   mfo_tbl(i).facility := in_facility;
--   zut.prt('MFO: '||in_orderid||'/'||in_shipid||'/'||in_wave||'/'||in_facility);
end update_mfo_tbl;


procedure multifac_line_split          -- private procedure, not in spec
   (in_orderid       in number,
    in_shipid        in number,
    in_facility      in varchar2,
    in_userid        in varchar2,
    in_wave          in number,
    in_od_rowid      in rowid,
    in_next_facility in varchar2,
    out_shipid       out number,
    io_errorno       in out number,
    io_msg           in out varchar2)
is
   cursor c_od(p_rowid rowid) is
      select custid, item, lotnumber, qtycommit, nvl(qtyorder,0) - nvl(qtypick,0) as qty,
             weightcommit, cubecommit, amtcommit, fromfacility
         from orderdtl
         where rowid = p_rowid;
   od c_od%rowtype;
   l_shipid orderdtl.shipid%type := 0;
   l_wave waves.wave%type := 0;
   l_facility facility.facility%type;
begin
   io_msg := '';
   io_errorno := 0;
   out_shipid := in_shipid;

   open c_od(in_od_rowid);
   fetch c_od into od;
   close c_od;

--   zut.prt('Split: '||in_shipid||'/'||in_facility||'/'||in_wave||'/'||in_next_facility
--         ||'/'||od.item||'/'||od.fromfacility||'/'||od.qtycommit||'/'||od.qty);
   if od.fromfacility = in_facility then
--    commitment was to the orderdtl facility, split remaining into another (next)
--    facility for further processing
      l_facility := nvl(in_next_facility, in_facility);
   else
--    commitment was to other than the orderdtl facility, split committed quantity
--    into commitment facility and leave uncommitted quantity in orderdtl facility
      l_facility := in_facility;
   end if;

   l_wave := get_mfo_wave(l_facility);
   l_shipid := get_mfo_shipid(l_facility, in_orderid);
--   zut.prt('Split l_facility: '||l_facility||' l_wave: '||l_wave||' l_shipid: '||l_shipid);

   if (l_shipid = 0) or (l_shipid = in_shipid) then
      if l_wave = 0 then
         if not is_mfo_wave_used(in_wave) then
            l_wave := in_wave;
         else
           multifac_order_bld_wave(in_wave, l_facility, in_userid, l_wave, io_errorno, io_msg);
           if substr(io_msg, 1, 4) != 'OKAY' then
              return;
           end if;
         end if;
      end if;

      select max(shipid) + 1
         into l_shipid
         from orderhdr
         where orderid = in_orderid;
      zcl.clone_orderhdr(in_orderid, in_shipid, in_orderid, l_shipid, null, in_userid, io_msg);
      if substr(io_msg, 1 ,4) != 'OKAY' then
         return;
      end if;

      update orderhdr
         set fromfacility = l_facility,
             qtyorder = 0,
             weightorder = 0,
             cubeorder = 0,
             amtorder = 0,
             qtycommit = null,
             weightcommit = null,
             cubecommit = null,
             amtcommit = null,
             qtytotcommit = null,
             weighttotcommit = null,
             cubetotcommit = null,
             amttotcommit = null,
             lastuser = in_userid,
             lastupdate = sysdate,
             wave = l_wave,
             qtypick = null,
             weightpick = null,
             cubepick = null,
             amtpick = null,
             staffhrs = null
         where orderid = in_orderid
           and shipid = l_shipid;

      update_mfo_tbl(in_orderid, l_shipid, l_wave, l_facility);
   end if;

   if (od.qtycommit = od.qty) or (in_next_facility is null) then
      update commitments
         set shipid = l_shipid,
             facility = l_facility
         where orderid = in_orderid
           and shipid = in_shipid
           and orderitem = od.item
           and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)')
           and status = 'CM'
           and facility = in_facility;
      update orderdtl
         set shipid = l_shipid,
             fromfacility = l_facility,
             qtycommit = 0,
             weightcommit = 0,
             cubecommit = 0,
             amtcommit = 0,
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = in_od_rowid;
   else
      zcl.clone_table_row('ORDERDTL',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
               ||' and ITEM = '''||od.item||''''
               ||' and nvl(LOTNUMBER,''(none)'') = '''
               ||nvl(od.lotnumber,'(none)')||'''',
            in_orderid||','||l_shipid||','''||od.item
               ||''','''||od.lotnumber||''',0,0,0,0',
            'ORDERID,SHIPID,ITEM,LOTNUMBER,QTYCOMMIT,WEIGHTCOMMIT,CUBECOMMIT,AMTCOMMIT',
            null, in_userid, io_msg);
      if substr(io_msg, 1 ,4) != 'OKAY' then
         return;
      end if;

      if od.fromfacility = in_facility then
         update orderdtl
            set qtyentered = od.qtycommit,
                qtyorder = od.qtycommit,
                weightorder = od.weightcommit,
                cubeorder = od.cubecommit,
                amtorder = od.amtcommit,
                qtycommit = od.qtycommit,
                weightcommit = od.weightcommit,
                cubecommit = od.cubecommit,
                amtcommit = od.amtcommit,
                qtytotcommit = od.qtycommit,
                weighttotcommit = od.weightcommit,
                cubetotcommit = od.cubecommit,
                amttotcommit = od.amtcommit,
                lastuser = in_userid,
                lastupdate = sysdate
            where rowid = in_od_rowid;

         update orderdtl
            set fromfacility = in_next_facility,
                qtyentered = qtyentered - od.qtycommit,
                qtyorder = qtyorder - od.qtycommit,
                weightorder = weightorder - od.weightcommit,
                cubeorder = cubeorder - od.cubecommit,
                amtorder = amtorder - od.amtcommit,
                qtycommit = 0,
                weightcommit = 0,
                cubecommit = 0,
                amtcommit = 0,
                qtytotcommit = qtytotcommit - od.qtycommit,
                weighttotcommit = weighttotcommit - od.weightcommit,
                cubetotcommit = cubetotcommit - od.cubecommit,
                amttotcommit = amttotcommit - od.amtcommit,
                lastuser = in_userid,
                lastupdate = sysdate
            where orderid = in_orderid
              and shipid = l_shipid
              and item = od.item
              and nvl(lotnumber, '(none)') = nvl(od.lotnumber, '(none)');

         out_shipid := l_shipid;

      else

         if l_shipid != in_shipid then
            update commitments
               set shipid = l_shipid
               where orderid = in_orderid
                 and shipid = in_shipid
                 and orderitem = od.item
                 and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)')
                 and status = 'CM'
                 and facility = in_facility;
         end if;

         update orderdtl
            set qtyentered = qtyentered - od.qtycommit,
                qtyorder = qtyorder - od.qtycommit,
                weightorder = weightorder - od.weightcommit,
                cubeorder = cubeorder - od.cubecommit,
                amtorder = amtorder - od.amtcommit,
                qtycommit = 0,
                weightcommit = 0,
                cubecommit = 0,
                amtcommit = 0,
                qtytotcommit = qtytotcommit - od.qtycommit,
                weighttotcommit = weighttotcommit - od.weightcommit,
                cubetotcommit = cubetotcommit - od.cubecommit,
                amttotcommit = amttotcommit - od.amtcommit,
                lastuser = in_userid,
                lastupdate = sysdate
            where rowid = in_od_rowid;

         update orderdtl
            set fromfacility = in_facility,
                qtyentered = od.qtycommit,
                qtyorder = od.qtycommit,
                weightorder = od.weightcommit,
                cubeorder = od.cubecommit,
                amtorder = od.amtcommit,
                qtycommit = od.qtycommit,
                weightcommit = od.weightcommit,
                cubecommit = od.cubecommit,
                amtcommit = od.amtcommit,
                qtytotcommit = od.qtycommit,
                weighttotcommit = od.weightcommit,
                cubetotcommit = od.cubecommit,
                amttotcommit = od.amtcommit,
                lastuser = in_userid,
                lastupdate = sysdate
            where orderid = in_orderid
              and shipid = l_shipid
              and item = od.item
              and nvl(lotnumber, '(none)') = nvl(od.lotnumber, '(none)');

      end if;
   end if;

   if l_shipid != in_shipid then
      zrfrst.adjust_orderdtlline(od.custid, in_orderid, in_shipid, od.item, od.lotnumber,
            od.qtycommit, l_shipid, in_userid, io_msg);
      if io_msg is not null then
         return;
      end if;

      zcl.clone_table_row('ORDERHDRBOLCOMMENTS',
            'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid,
            l_shipid, 'SHIPID', null, in_userid, io_msg);

      zcl.clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
               ||' and ITEM = '''||od.item||''''
               ||' and nvl(LOTNUMBER,''(none)'') = '''
               ||nvl(od.lotnumber,'(none)')||'''',
            l_shipid, 'SHIPID', null, in_userid, io_msg);

   end if;

   io_msg := 'OKAY';

exception
   when OTHERS then
      io_msg := 'zcmmos ' || sqlerrm;
      io_errorno := sqlcode;
end multifac_line_split;


procedure multifac_line_update            -- private procedure, not in spec
   (in_orderid  in number,
    in_shipid   in number,
    in_facility in varchar2,
    in_userid   in varchar2,
    in_wave     in number,
    in_od_rowid in rowid,
    io_errorno  in out number,
    io_msg      in out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select fromfacility, rowid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   cursor c_od(p_rowid rowid) is
      select item, lotnumber, qtycommit, shipid, fromfacility,
             nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
         from orderdtl
         where rowid = p_rowid;
   od c_od%rowtype;
   i binary_integer;
   l_mf binary_integer := 0;        -- index of facility match
   l_mof binary_integer := 0;       -- index of orderid/facility match
   l_mosf binary_integer := 0;      -- index of orderid/shipid/facility match
   l_mw binary_integer := 0;        -- index of wave match
   l_wave orderhdr.wave%type := 0;
   l_shipid orderhdr.shipid%type;
begin
   io_msg := '';
   io_errorno := 0;

   open c_od(in_od_rowid);
   fetch c_od into od;
   close c_od;

--   zut.prt('Update: '||in_shipid||'/'||in_facility||'/'||in_wave||'/'
--         ||od.item ||'/'||od.fromfacility);
   for i in 1..mfo_tbl.count loop
      if mfo_tbl(i).facility = in_facility then
         l_mf := i;
         if mfo_tbl(i).orderid = in_orderid then
            l_mof := i;
            if mfo_tbl(i).shipid = in_shipid then
               l_mosf := i;
            end if;
         end if;
      end if;
      if mfo_tbl(i).wave = in_wave then
         l_mw := i;
      end if;
   end loop;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   if l_mosf != 0 then                       -- order/ship/facility; orderid/shipid
      null;

   elsif l_mof != 0 then                     -- order/facility (prev split)
      update commitments
         set shipid = in_shipid
         where orderid = in_orderid
           and shipid = od.shipid
           and orderitem = od.item
           and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)')
           and status = 'CM'
           and facility = in_facility;
      update orderdtl
         set shipid = in_shipid,
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = in_od_rowid;
      update_mfo_tbl(in_orderid, in_shipid, in_wave, in_facility);

   else
      l_wave := in_wave;
      if l_mw != 0 then
         if in_facility != mfo_tbl(l_mw).facility then
            multifac_line_split(in_orderid, in_shipid, in_facility, in_userid,
                  in_wave, in_od_rowid, null, l_shipid, io_errorno, io_msg);
            return;
         end if;
      else
         update waves
            set facility = in_facility
            where wave = in_wave
              and facility != in_facility;
         if l_mf != 0 then
            l_wave := mfo_tbl(l_mf).wave;
         end if;
      end if;
      update orderdtl
         set fromfacility = in_facility,
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = in_od_rowid
           and fromfacility != in_facility;

      update orderhdr
         set wave = l_wave,
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = oh.rowid
           and wave != l_wave;

      update orderhdr
         set fromfacility = in_facility,
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = oh.rowid
           and fromfacility != in_facility;

      update_mfo_tbl(in_orderid, in_shipid, l_wave, in_facility);
   end if;

   io_msg := 'OKAY';

exception
   when OTHERS then
      io_msg := 'zcmmou ' || sqlerrm;
      io_errorno := sqlcode;
end multifac_line_update;


procedure multifac_order_commit        -- private procedure, not in spec
   (in_orderid  in number,
    in_shipid   in number,
    in_facility in varchar2,
    in_userid   in varchar2,
    in_reqtype  in varchar2,
    in_wave     in number,
    in_tmsflag  in varchar2,
    in_resubmit in varchar2,
    in_enter_min_days_to_expire_yn in varchar2,
    io_errorno  in out number,
    io_msg      in out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.custid, OH.priority, FA.campus, OH.fromfacility
         from orderhdr OH, facility FA
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and FA.facility = OH.fromfacility;
   oh c_oh%rowtype;
   cursor c_od(p_orderid number, p_shipid number) is
      select item, uom, lotnumber, invstatusind, invstatus, invclassind, inventoryclass,
             nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty, rowid,
             nvl(min_days_to_expiration,0) as min_days_to_expiration
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and linestatus != 'X'
         order by item, lotnumber;
   cursor c_od_quantity(p_orderid number, p_shipid number, p_item varchar2, p_lot varchar2) is
      select nvl(qtyorder,0) as qtyorder, nvl(qtycommit,0) as qtycommit,
             nvl(qtypick,0) as qtypick
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lot, '(none)');
   odq c_od_quantity%rowtype;
   cursor c_ki(p_orderid number) is
      select nvl(sum(nvl(qtyorder,0)),0) as qtyorder
         from orderdtl od
         where orderid = p_orderid
           and exists (select 1 from custitemview ci
                     where od.custid = ci.custid
                       and od.item = ci.item
                       and ci.iskit != 'N');
   ki c_ki%rowtype;
   c_any_fac anyfaccur;
   fa anyfactype;
   fanext anyfactype;
   cursor c_uod(p_orderid number, p_shipid number, p_item varchar2, p_lot varchar2) is
      select uom, invstatusind, invstatus, invclassind, inventoryclass, rowid,
             nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty, fromfacility
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lot, '(none)');
   uod c_uod%rowtype;

   i binary_integer;
   l_qty orderhdr.qtyorder%type;
   l_qtyc orderhdr.qtycommit%type;
   l_qtyorder orderhdr.qtyorder%type;
   l_qtycommit orderhdr.qtycommit%type;
   l_msg varchar2(255);
   l_wave waves.wave%type;
   cust_errorno number(4);
   cust_errormsg varchar2(36);
   prt_qty number;
begin
   io_msg := '';
   io_errorno := 0;

   uod_tbl.delete;
   mfo_tbl.delete;
   for ohdr in (select orderid, shipid, wave, fromfacility from orderhdr
                  where orderid in (select orderid from orderhdr where wave = in_wave)) loop
      update_mfo_tbl(ohdr.orderid, ohdr.shipid, ohdr.wave, ohdr.fromfacility);
   end loop;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   for od in c_od(in_orderid, in_shipid) loop
      l_qty := 1;

--    any single facility oldest first

      if od.lotnumber is null then
         open c_any_fac for
            select PL.facility, min(nvl(PL.manufacturedate, PL.creationdate)) as orderdate
               from plate PL, facility FA
               where PL.custid = oh.custid
                 and PL.item = od.item
                 and (PL.facility = oh.fromfacility
                   or (FA.facility = PL.facility
                   and FA.campus = oh.campus))
               group by PL.facility
               order by 2;
      else
         open c_any_fac for
            select PL.facility, min(nvl(PL.manufacturedate, PL.creationdate)) as orderdate
               from plate PL, facility FA
               where PL.custid = oh.custid
                 and PL.item = od.item
                 and PL.lotnumber = od.lotnumber
                 and (PL.facility = oh.fromfacility
                   or (FA.facility = PL.facility
                   and FA.campus = oh.campus))
               group by PL.facility
               order by 2;
      end if;
      loop
         fetch c_any_fac into fa;
         exit when c_any_fac%notfound;

         savepoint oldest_first;
         zcm.commit_line(fa.facility, oh.custid, in_orderid, in_shipid, od.item,
               od.uom, od.lotnumber, od.invstatusind, od.invstatus, od.invclassind,
               od.inventoryclass, od.qty, oh.priority, in_reqtype,
               in_enter_min_days_to_expire_yn, od.min_days_to_expiration,
               in_userid, io_msg);

         if substr(io_msg, 1 ,4) != 'OKAY' then
            zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'W', in_userid, io_msg);
         end if;

         open c_od_quantity(in_orderid, in_shipid, od.item, od.lotnumber);
         fetch c_od_quantity into odq;
         if c_od_quantity%notfound then
            l_qty := 1;
         else
            l_qty := odq.qtyorder - odq.qtycommit - odq.qtypick;
         end if;
         close c_od_quantity;

         if l_qty > 0 then
            rollback to oldest_first;
         else
            multifac_line_update(in_orderid, in_shipid, fa.facility, in_userid, in_wave,
                  od.rowid, io_errorno, io_msg);
            if substr(io_msg, 1, 4) != 'OKAY' then
               zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'E', in_userid, io_msg);
               l_qty := 1;
               rollback to oldest_first;
            end if;
         end if;
         exit when (l_qty <= 0);
      end loop;
      close c_any_fac;

      if l_qty > 0 then
         i := uod_tbl.count+1;
         uod_tbl(i).shipid := in_shipid;
         uod_tbl(i).item := od.item;
         uod_tbl(i).lotnumber := od.lotnumber;
         uod_tbl(i).min_days_to_expiration := od.min_days_to_expiration;
      end if;
   end loop;

   for i in 1..uod_tbl.count loop
--    multi-facility oldest first
      if uod_tbl(i).lotnumber is null then
         open c_any_fac for
            select PL.facility, min(nvl(PL.manufacturedate, PL.creationdate)) as orderdate
               from plate PL, facility FA
               where PL.custid = oh.custid
                 and PL.item = uod_tbl(i).item
                 and (PL.facility = oh.fromfacility
                   or (FA.facility = PL.facility
                   and FA.campus = oh.campus))
               group by PL.facility
               order by 2;
      else
         open c_any_fac for
            select PL.facility, min(nvl(PL.manufacturedate, PL.creationdate)) as orderdate
               from plate PL, facility FA
               where PL.custid = oh.custid
                 and PL.item = uod_tbl(i).item
                 and PL.lotnumber = uod_tbl(i).lotnumber
                 and (PL.facility = oh.fromfacility
                   or (FA.facility = PL.facility
                   and FA.campus = oh.campus))
               group by PL.facility
               order by 2;
      end if;
      fetch c_any_fac into fa;
      if c_any_fac%found then
         loop
            fetch c_any_fac into fanext;
            if c_any_fac%notfound then
               fanext := null;
            end if;
--          zut.prt('Multi fac: '||fa.facility||' next: '||fanext.facility
--               ||' shipid: '||uod_tbl(i).shipid);

            open c_uod(in_orderid, uod_tbl(i).shipid, uod_tbl(i).item, uod_tbl(i).lotnumber);
            fetch c_uod into uod;
            close c_uod;

            zcm.commit_line(fa.facility, oh.custid, in_orderid, uod_tbl(i).shipid,
                  uod_tbl(i).item, uod.uom, uod_tbl(i).lotnumber, uod.invstatusind,
                  uod.invstatus, uod.invclassind, uod.inventoryclass, uod.qty,
                  oh.priority, in_reqtype, in_enter_min_days_to_expire_yn,
                  uod_tbl(i).min_days_to_expiration, in_userid, io_msg);

            if substr(io_msg, 1 ,4) != 'OKAY' then
               zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'W', in_userid, io_msg);
            end if;

            open c_od_quantity(in_orderid, uod_tbl(i).shipid, uod_tbl(i).item, uod_tbl(i).lotnumber);
            fetch c_od_quantity into odq;
            if c_od_quantity%notfound then
               l_qty := 1;
            else
               l_qty := odq.qtyorder - odq.qtycommit - odq.qtypick;
            end if;
            close c_od_quantity;

            if l_qty = 0 then
               multifac_line_update(in_orderid, uod_tbl(i).shipid, fa.facility,
                     in_userid, in_wave, uod.rowid, io_errorno, io_msg);
               if substr(io_msg, 1, 4) != 'OKAY' then
                  zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'E', in_userid, io_msg);
               end if;
               exit;
            end if;

            if fanext.facility is null then
               if (odq.qtycommit > 0) and (fa.facility != uod.fromfacility) then
                  if get_mfo_shipid(fa.facility, in_orderid) != uod_tbl(i).shipid then
                     multifac_line_split(in_orderid, uod_tbl(i).shipid, fa.facility, in_userid,
                           in_wave, uod.rowid, fanext.facility, uod_tbl(i).shipid,
                           io_errorno, io_msg);
                     if substr(io_msg, 1, 4) != 'OKAY' then
                        zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'E', in_userid,
                              io_msg);
                     end if;
                  end if;
               end if;
               exit;
            end if;

            if odq.qtycommit > 0 then
               multifac_line_split(in_orderid, uod_tbl(i).shipid, fa.facility, in_userid,
                     in_wave, uod.rowid, fanext.facility, uod_tbl(i).shipid,
                     io_errorno, io_msg);
               if substr(io_msg, 1, 4) != 'OKAY' then
                  zms.log_msg('WaveSelect', fa.facility, oh.custid, io_msg, 'E', in_userid, io_msg);
               end if;
            end if;

            fa.facility := fanext.facility;
         end loop;
      end if;
      close c_any_fac;
   end loop;

   l_qtyorder := 0;
   l_qtycommit := 0;
   for ohdr in (select fromfacility, shipid from orderhdr
                  where orderid = in_orderid
                    and orderstatus != 'X') loop
      l_wave := get_mfo_wave(ohdr.fromfacility);
      if l_wave = 0 then
         if not is_mfo_wave_used(in_wave) then
            l_wave := in_wave;
         else
           multifac_order_bld_wave(in_wave, ohdr.fromfacility, in_userid, l_wave, io_errorno,
               io_msg);
           if substr(io_msg, 1, 4) != 'OKAY' then
              return;
           end if;
         end if;
      else
         update waves
            set facility = ohdr.fromfacility
            where wave = l_wave
              and facility != ohdr.fromfacility;
      end if;

      update orderhdr
         set orderstatus = '2',
             commitstatus = '1',
             tms_status = decode(carrier,
                                 nvl(zci.default_value('TMS_CARRIER'),'x'), tms_status,
                                 decode(in_reqtype,
                              '4','1',
                              '1','X',
                                        decode(in_tmsflag,'Y','1','X'))),
             tms_status_update = sysdate,
             wave = l_wave,
             lastuser = in_userid,
             lastupdate = sysdate
         where orderid = in_orderid
           and shipid = ohdr.shipid
         returning qtyorder, qtycommit
         into l_qty, l_qtyc;

      l_qtyorder := l_qtyorder + l_qty;
      l_qtycommit := l_qtycommit + l_qtyc;

      update_mfo_tbl(in_orderid, ohdr.shipid, l_wave, ohdr.fromfacility);
   end loop;

   if (l_qtyorder > l_qtycommit) and (in_resubmit = 'Y') then
      ki.qtyorder := 0;
      open c_ki(in_orderid);
      fetch c_ki into ki;
      close c_ki;
      if (l_qtyorder - ki.qtyorder) > l_qtycommit then
         for i in 1..mfo_tbl.count loop
            if mfo_tbl(i).orderid = in_orderid then
               zcm.uncommit_order(in_orderid, mfo_tbl(i).shipid, mfo_tbl(i).facility,
                     in_userid, in_reqtype, mfo_tbl(i).wave, io_msg);
               zimp.translate_cust_errorcode(oh.custid, 104, 'Insufficient Stock',
                     cust_errorno, cust_errormsg);
               update orderhdr
                  set orderstatus = 'X',
                      lastuser = in_userid,
                      lastupdate = sysdate,
                      rejectcode = cust_errorno,
                      rejecttext = cust_errormsg
                  where orderid = in_orderid
                    and shipid = mfo_tbl(i).shipid;
            end if;
         end loop;
         io_errorno := 104;
         io_msg := 'Insufficient Stock';
         return;
      end if;
   end if;

   l_qty := 0;
   for i in 1..mfo_tbl.count loop
      if mfo_tbl(i).orderid = in_orderid then
         zlb.compute_order_labor(in_orderid, mfo_tbl(i).shipid, mfo_tbl(i).facility,
               in_userid, io_errorno, io_msg);
         if io_errorno != 0 then
            zms.log_msg('LABORCALC', mfo_tbl(i).facility, oh.custid, io_msg, 'E',
                  in_userid, l_msg);
            io_errorno := 0;
         end if;
         zoh.add_orderhistory(in_orderid, mfo_tbl(i).shipid,
               'Order Commited',
               'Order Commited Wave:'|| mfo_tbl(i).wave,
               in_userid, io_msg);
         l_qty := l_qty + 1;
      end if;
   end loop;

   if l_qty > 1 then
      io_msg := 'OKAYMULTI';
   else
      io_msg := 'OKAY';
   end if;

exception
   when OTHERS then
      io_msg := 'zcmmoc ' || sqlerrm;
      io_errorno := sqlcode;
end multifac_order_commit;

function tokenized_column_value
(in_wave_descr IN varchar2
,in_orderid IN number
,in_shipid IN number
) return varchar2

is

l_first_pos pls_integer;
l_next_pos pls_integer;
l_column_name user_tab_columns.column_name%type;
l_cnt pls_integer;
l_column_value varchar2(255);
l_cmd varchar2(4000);

begin

l_first_pos := instr(in_wave_descr,'%');
if l_first_pos = 0 then
  return null;
end if;

l_next_pos := instr(substr(in_wave_descr,l_first_pos+1,80),'%');
if l_next_pos = 0 then
  return null;
end if;

begin
  l_column_name := upper(substr(in_wave_descr,l_first_pos+1,l_next_pos-1));
exception when others then
  return null;
end;

select count(1)
  into l_cnt
  from user_tab_columns
 where table_name = 'LOADSORDERVIEW'
   and column_name = l_column_name;
if l_cnt = 0 then
  return null;
end if;

l_cmd := 'select ' ||
         zcm.column_select_sql('LOADSORDERVIEW',l_column_name);
l_cmd := l_cmd || ' from orderhdr where orderid = ' || in_orderid ||
         ' and shipid = ' || in_shipid;
execute immediate l_cmd
             into l_column_value;
  
return l_column_value;
  
exception when others then
  return null;
end;

function column_select_sql
(in_object_name IN varchar2
,in_column_name IN varchar2
) return varchar2

is

l_data_type user_tab_columns.data_type%type;
l_select_sql varchar2(255);

begin

l_data_type := zut.data_type(upper(in_object_name),in_column_name);
   
l_select_sql := '';

if l_data_type in ('CLOB','DATE','NUMBER') then
  l_select_sql := ' to_char(';
else
  l_select_sql := ' ';
end if;
l_select_sql := l_select_sql || in_column_name;
if l_data_type in ('CLOB','NUMBER') then
  l_select_sql := l_select_sql || ')';
elsif l_data_type = 'DATE' then
  l_select_sql := l_select_sql || ',''MM/DD/YY'')';
end if;

return l_select_sql;

exception when others then
  return in_column_name;
end;

function tokenized_wave_descr
(in_wave_descr IN varchar2
,in_column_value IN varchar2
) return varchar2

is 

l_out_descr waves.descr%type;
l_first_pos pls_integer;
l_next_pos pls_integer;
l_column_name user_tab_columns.column_name%type;
l_cnt pls_integer;

begin

l_first_pos := instr(in_wave_descr,'%');
if l_first_pos = 0 then
  return in_wave_descr;
end if;

l_next_pos := instr(substr(in_wave_descr,l_first_pos+1,80),'%');
if l_next_pos = 0 then
  return in_wave_descr;
end if;

begin
  l_column_name := upper(substr(in_wave_descr,l_first_pos+1,l_next_pos-1));
exception when others then
  return in_wave_descr;
end;

select count(1)
  into l_cnt
  from user_tab_columns
 where table_name = 'LOADSORDERVIEW'
   and column_name = l_column_name;
if l_cnt = 0 then
  return in_wave_descr;
end if;

l_out_descr := substr(trim(substr(in_wave_descr,1,l_first_pos-1) || ' ' ||
                      in_column_value || ' ' ||
                      substr(in_wave_descr,l_first_pos+l_next_pos+2,80)),1,80);
 
return  l_out_descr;
 
exception when others then
  return in_wave_descr;
end;

/*
** Checks for a column_name from loadsorderview surrounded by '%' signs
** in the wave description. If found, splits the orders in the wave into 
** separate waves based on the column's value
*/
procedure check_for_split_wave_token
(in_wave IN number
,in_userid IN varchar2
,out_msg IN OUT varchar2
) is

cursor curWaves is
  select wave,descr
    from waves
   where wave = in_wave;
WV curWaves%rowtype;

l_first_pos pls_integer;
l_next_pos pls_integer;
l_column_name user_tab_columns.column_name%type;
l_cnt pls_integer;
l_cmd varchar2(1000);
l_column_value varchar2(255);
l_wave pls_integer; 
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_rowid rowid;
l_order_wave orderhdr.wave%type;
l_str varchar2(255);

type cur_type is ref cursor;
l_ords cur_type;
type waverectype is record (
   wave waves.wave%type,
   column_value varchar2(255)
);
type wavetbltype is table of waverectype index by binary_integer;
wavetbl wavetbltype;
wavex pls_integer;
wavefoundx pls_integer;

begin

out_msg := 'BEGIN';

WV := null;
open curWaves;
fetch curWaves into WV;
close curWaves;

if WV.wave is null then
  out_msg := 'Wave not found when attempting to tokenize description';
  return;
end if;

l_first_pos := instr(WV.descr,'%');
if l_first_pos = 0 then
  out_msg := 'OKAY--No token symbol found';
  return;
end if;

l_next_pos := instr(substr(WV.descr,l_first_pos+1,80),'%');
if l_next_pos = 0 then
  out_msg := 'OKAY--Only one token symbol found';
  return;
end if;

begin
  l_column_name := upper(substr(WV.descr,l_first_pos+1,l_next_pos-1));
exception when others then
  out_msg := 'OKAY--Unable to set column name: ' || sqlerrm;
  return;
end;

select count(1)
  into l_cnt
  from user_tab_columns
 where table_name = 'LOADSORDERVIEW'
   and column_name = l_column_name;
if l_cnt = 0 then
  out_msg := l_column_name || ' is not a column_name in ''loadsorderview''';
  return;
end if;

l_cmd := 'select orderid, shipid, rowid, wave, ' ||
         zcm.column_select_sql('LOADSORDERVIEW',l_column_name);
l_cmd := l_cmd || ' from orderhdr where wave = ' || in_wave;

wavetbl.delete;

open l_ords for l_cmd;
loop

  fetch l_ords into l_orderid, l_shipid, l_rowid, l_order_wave, l_column_value;
  exit when l_ords%notfound;

  wavefoundx := 0;
  for wavex in 1 .. wavetbl.count
  loop
    if wavetbl(wavex).column_value = l_column_value then
      wavefoundx := wavex;
      exit;
    end if;     
  end loop;

  if wavefoundx = 0 then
    wavex := wavetbl.count + 1;
    if wavex = 1 then
      l_wave := in_wave;
    else
      zwv.get_next_wave(l_wave, out_msg);
      insert into waves
         (wave, descr, wavestatus, schedrelease, actualrelease,
          facility, lastuser, lastupdate, stageloc, picktype,
          taskpriority, sortloc, job, childwave, batchcartontype,
          fromlot, tolot, orderlimit, openfacility, cntorder,
          qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
          cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
          consolidated, shiptype, carrier, servicelevel, shipcost,
          weight, tms_status, tms_status_update, mass_manifest, pick_by_zone,
          sdi_sortation_yn, sdi_sorter_process, sdi_sorter, sdi_max_units,
          sdi_sorter_mode, sdi_manual_picks_yn)
      select l_wave, descr, wavestatus, null, null,
             facility, lastuser, sysdate, stageloc, picktype,
             taskpriority, sortloc, job, childwave, batchcartontype,
             fromlot, tolot, orderlimit, openfacility, 0,
             null, null, null, null, null,
             null, null, null, null, replanned,
             consolidated, shiptype, carrier, servicelevel, shipcost,
             null, tms_status, tms_status_update, mass_manifest, pick_by_zone,
             sdi_sortation_yn, sdi_sorter_process, sdi_sorter, sdi_max_units,
             sdi_sorter_mode, sdi_manual_picks_yn
         from waves
         where wave = in_wave;
    end if;
    wavetbl(wavex).wave := l_wave;
    wavetbl(wavex).column_value := l_column_value;    
  else
    wavex := wavefoundx;
  end if;

  if l_order_wave != wavetbl(wavex).wave then
    update orderhdr
       set wave = wavetbl(wavex).wave
     where rowid = l_rowid;       
    update orderlabor
       set wave = wavetbl(wavex).wave
     where orderid = l_orderid
       and shipid = l_shipid;
  end if;

end loop;

for wavex in 1 .. wavetbl.count
loop

  update waves
     set descr = zcm.tokenized_wave_descr(WV.descr,wavetbl(wavex).column_value)
   where wave = wavetbl(wavex).wave;
   
end loop;

out_msg := 'OKAY--tokenized';

exception when others then  
   out_msg := sqlerrm;
   zms.log_autonomous_msg('WAVEPLAN', null, null, out_msg, 'E', in_userid, l_str);
end;

PROCEDURE expand_simple_kit_item
(in_orderid number
,in_shipid number
,in_item varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
)  
is

cursor curOrderDtl is
  select rowid,orderdtl.*
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and lotnumber is null
     and linestatus != 'X';
od curOrderDtl%rowtype;
odl orderdtlline%rowtype;

cursor curItem(in_custid varchar2, in_item varchar2) is
  select baseuom
    from custitemview
   where custid = in_custid
     and item = in_item;
itm curItem%rowtype;

l_msg varchar2(255);
l_orderdtl_count pls_integer;
l_orig_qtyorder orderdtl.qtyorder%type;

begin

out_msg := 'OKAY';

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;

if od.item is null then
  out_msg := 'OrderDtl not found: ' || in_orderid || '-' || in_shipid || ' ' || in_item;
  return;
end if;

l_orig_qtyorder := od.qtyorder;

for woc in (select component,qty
              from workordercomponents
             where custid = od.custid
               and item = od.item
               and kitted_class = 'no')
loop
  itm := null;
  open curItem(od.custid,woc.component);
  fetch curItem into itm;
  close curItem;
  odl := null;
  select max(linenumber)
    into odl.linenumber
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  if odl.linenumber is null then
    odl.linenumber := 1;
  else
    odl.linenumber := odl.linenumber + 1;
  end if;
  select count(1)
    into l_orderdtl_count
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = woc.component
     and lotnumber is null;
  od.uom := itm.baseuom;
  od.uomentered := itm.baseuom;
  od.qtyorder := l_orig_qtyorder * woc.qty;
  od.qtyentered := l_orig_qtyorder * woc.qty;
  od.weightorder := zci.item_weight(od.custid,woc.component,od.uom) * l_orig_qtyorder;
  od.cubeorder := zci.item_cube(od.custid,woc.component,od.uom) * l_orig_qtyorder;
  -- PRN 25133 - changed signature of item_amt, calling this way should be the same as before
  od.amtorder := zci.item_amt(od.custid,null,null,woc.component,null) * l_orig_qtyorder;
  if l_orderdtl_count = 0 then
    insert into orderdtl
     (ORDERID,SHIPID,ITEM,CUSTID,FROMFACILITY,UOM,LINESTATUS,COMMITSTATUS,
      QTYENTERED,ITEMENTERED,UOMENTERED,QTYORDER,WEIGHTORDER,CUBEORDER,AMTORDER,
      QTYCOMMIT,WEIGHTCOMMIT,CUBECOMMIT,AMTCOMMIT,QTYSHIP,WEIGHTSHIP,CUBESHIP,
      AMTSHIP,QTYTOTCOMMIT,WEIGHTTOTCOMMIT,CUBETOTCOMMIT,AMTTOTCOMMIT,QTYRCVD,
      WEIGHTRCVD,CUBERCVD,AMTRCVD,QTYRCVDGOOD,WEIGHTRCVDGOOD,CUBERCVDGOOD,
      AMTRCVDGOOD,QTYRCVDDMGD,WEIGHTRCVDDMGD,CUBERCVDDMGD,AMTRCVDDMGD,COMMENT1,
      STATUSUSER,STATUSUPDATE,LASTUSER,LASTUPDATE,PRIORITY,LOTNUMBER,BACKORDER,
      ALLOWSUB,QTYTYPE,INVSTATUSIND,INVSTATUS,INVCLASSIND,INVENTORYCLASS,QTYPICK,
      WEIGHTPICK,CUBEPICK,AMTPICK,CONSIGNEESKU,CHILDORDERID,CHILDSHIPID,STAFFHRS,
      QTY2SORT,WEIGHT2SORT,CUBE2SORT,AMT2SORT,QTY2PACK,WEIGHT2PACK,CUBE2PACK,
      AMT2PACK,QTY2CHECK,WEIGHT2CHECK,CUBE2CHECK,AMT2CHECK,DTLPASSTHRUCHAR01,
      DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,
      DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,
      DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,
      DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,
      DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,
      DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,
      DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,
      DTLPASSTHRUNUM10,ASNVARIANCE,CANCELREASON,RFAUTODISPLAY,XDOCKORDERID,
      XDOCKSHIPID,XDOCKLOCID,QTYOVERPICK,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
      DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
      SHIPSHORTREASON,QTYORDERDIFF,LINEORDER,WEIGHT_ENTERED_LBS,WEIGHT_ENTERED_KGS,
      VARIANCEPCT,VARIANCEPCT_USE_DEFAULT,VARIANCEPCT_OVERAGE,
      MIN_DAYS_TO_EXPIRATION,DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23,
      DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27,
      DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,DTLPASSTHRUCHAR31,
      DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35,
      DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39,
      DTLPASSTHRUCHAR40,DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13,
      DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,DTLPASSTHRUNUM16,DTLPASSTHRUNUM17,
      DTLPASSTHRUNUM18,DTLPASSTHRUNUM19,DTLPASSTHRUNUM20)
     values
     (od.ORDERID,od.SHIPID,woc.component,od.CUSTID,od.FROMFACILITY,od.UOM,od.LINESTATUS,
      od.COMMITSTATUS,od.QTYENTERED,woc.component,od.UOMENTERED,od.QTYORDER,
      od.WEIGHTORDER,od.CUBEORDER,od.AMTORDER,od.QTYCOMMIT,od.WEIGHTCOMMIT,od.CUBECOMMIT,
      od.AMTCOMMIT,od.QTYSHIP,od.WEIGHTSHIP,od.CUBESHIP,od.AMTSHIP,od.QTYTOTCOMMIT,
      od.WEIGHTTOTCOMMIT,od.CUBETOTCOMMIT,od.AMTTOTCOMMIT,od.QTYRCVD,od.WEIGHTRCVD,
      od.CUBERCVD,od.AMTRCVD,od.QTYRCVDGOOD,od.WEIGHTRCVDGOOD,od.CUBERCVDGOOD,
      od.AMTRCVDGOOD,od.QTYRCVDDMGD,od.WEIGHTRCVDDMGD,od.CUBERCVDDMGD,od.AMTRCVDDMGD,
      od.COMMENT1,od.STATUSUSER,od.STATUSUPDATE,od.LASTUSER,od.LASTUPDATE,od.PRIORITY,
      od.LOTNUMBER,od.BACKORDER,od.ALLOWSUB,od.QTYTYPE,od.INVSTATUSIND,od.INVSTATUS,
      od.INVCLASSIND,od.INVENTORYCLASS,od.QTYPICK,od.WEIGHTPICK,od.CUBEPICK,od.AMTPICK,
      od.CONSIGNEESKU,od.CHILDORDERID,od.CHILDSHIPID,od.STAFFHRS,od.QTY2SORT,
      od.WEIGHT2SORT,od.CUBE2SORT,od.AMT2SORT,od.QTY2PACK,od.WEIGHT2PACK,od.CUBE2PACK,
      od.AMT2PACK,od.QTY2CHECK,od.WEIGHT2CHECK,od.CUBE2CHECK,od.AMT2CHECK,
      od.DTLPASSTHRUCHAR01,od.DTLPASSTHRUCHAR02,od.DTLPASSTHRUCHAR03,
      od.DTLPASSTHRUCHAR04,od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,
      od.DTLPASSTHRUCHAR07,od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,
      od.DTLPASSTHRUCHAR10,od.DTLPASSTHRUCHAR11,od.DTLPASSTHRUCHAR12,
      od.DTLPASSTHRUCHAR13,od.DTLPASSTHRUCHAR14,od.DTLPASSTHRUCHAR15,
      od.DTLPASSTHRUCHAR16,od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,
      od.DTLPASSTHRUCHAR19,od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,
      od.DTLPASSTHRUNUM03,od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,
      od.DTLPASSTHRUNUM07,od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,
      od.ASNVARIANCE,od.CANCELREASON,od.RFAUTODISPLAY,od.XDOCKORDERID,od.XDOCKSHIPID,
      od.XDOCKLOCID,od.QTYOVERPICK,od.DTLPASSTHRUDATE01,od.DTLPASSTHRUDATE02,
      od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01,
      od.DTLPASSTHRUDOLL02,od.SHIPSHORTREASON,od.QTYORDERDIFF,od.LINEORDER,
      od.WEIGHT_ENTERED_LBS,od.WEIGHT_ENTERED_KGS,od.VARIANCEPCT,
      od.VARIANCEPCT_USE_DEFAULT,od.VARIANCEPCT_OVERAGE,od.MIN_DAYS_TO_EXPIRATION,
      od.DTLPASSTHRUCHAR21,od.DTLPASSTHRUCHAR22,od.DTLPASSTHRUCHAR23,
      od.DTLPASSTHRUCHAR24,od.DTLPASSTHRUCHAR25,od.DTLPASSTHRUCHAR26,
      od.DTLPASSTHRUCHAR27,od.DTLPASSTHRUCHAR28,od.DTLPASSTHRUCHAR29,
      od.DTLPASSTHRUCHAR30,od.DTLPASSTHRUCHAR31,od.DTLPASSTHRUCHAR32,
      od.DTLPASSTHRUCHAR33,od.DTLPASSTHRUCHAR34,od.DTLPASSTHRUCHAR35,
      od.DTLPASSTHRUCHAR36,od.DTLPASSTHRUCHAR37,od.DTLPASSTHRUCHAR38,
      od.DTLPASSTHRUCHAR39,od.DTLPASSTHRUCHAR40,od.DTLPASSTHRUNUM11,od.DTLPASSTHRUNUM12,
      od.DTLPASSTHRUNUM13,od.DTLPASSTHRUNUM14,od.DTLPASSTHRUNUM15,od.DTLPASSTHRUNUM16,
      od.DTLPASSTHRUNUM17,od.DTLPASSTHRUNUM18,od.DTLPASSTHRUNUM19,od.DTLPASSTHRUNUM20);
  else
    update orderdtl
       set qtyentered = qtyentered + od.qtyentered,
           qtyorder = qtyorder + od.qtyorder,
           weightorder = weightorder + od.weightorder,
           cubeorder = cubeorder + od.cubeorder,
           amtorder = amtorder + od.amtorder,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid
       and item = woc.component
       and lotnumber is null;
  end if;
  insert into orderdtlline
   (ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER,QTY,DTLPASSTHRUCHAR01,
    DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,
    DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,
    DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,
    DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,
    DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,
    DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,
    DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,
    DTLPASSTHRUNUM10,LASTUSER,LASTUPDATE,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
    DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
    QTYAPPROVED,UOMENTERED,QTYENTERED,SHIPTO,XDOCK,CONSIGNEE,CARRIER,
    DELIVERYSERVICE,SATURDAYDELIVERY,SHIPTYPE,SHIPTERMS,SHIPDATE,ARRIVALDATE,
    STAGELOC,PRONO,SHIPPINGCOST,SHIPTONAME,SHIPTOADDR1,SHIPTOADDR2,SHIPTOCITY,
    SHIPTOSTATE,SHIPTOPOSTALCODE,SHIPTOCOUNTRYCODE,COD,COMPANYCHECKOK,AMTCOD,
    SHIPTOCONTACT,SHIPTOPHONE,SHIPTOFAX,SHIPTOEMAIL,SPECIALSERVICE1,
    SPECIALSERVICE2,SPECIALSERVICE3,SPECIALSERVICE4,BILLTONAME,BILLTOADDR1,
    BILLTOADDR2,BILLTOCITY,BILLTOSTATE,BILLTOPOSTALCODE,BILLTOCOUNTRYCODE,
    BILLTOCONTACT,BILLTOPHONE,BILLTOFAX,BILLTOEMAIL,WEIGHT_ENTERED_LBS,
    WEIGHT_ENTERED_KGS,DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23,
    DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27,
    DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,DTLPASSTHRUCHAR31,
    DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35,
    DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39,
    DTLPASSTHRUCHAR40,DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13,
    DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,DTLPASSTHRUNUM16,DTLPASSTHRUNUM17,
    DTLPASSTHRUNUM18,DTLPASSTHRUNUM19,DTLPASSTHRUNUM20,ORDERED_KIT)
   values
   (od.ORDERID,od.SHIPID,woc.component,od.LOTNUMBER,odl.LINENUMBER,od.QTYORDER,od.DTLPASSTHRUCHAR01,
    od.DTLPASSTHRUCHAR02,od.DTLPASSTHRUCHAR03,od.DTLPASSTHRUCHAR04,
    od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,od.DTLPASSTHRUCHAR07,
    od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,od.DTLPASSTHRUCHAR10,
    od.DTLPASSTHRUCHAR11,od.DTLPASSTHRUCHAR12,od.DTLPASSTHRUCHAR13,
    od.DTLPASSTHRUCHAR14,od.DTLPASSTHRUCHAR15,od.DTLPASSTHRUCHAR16,
    od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,od.DTLPASSTHRUCHAR19,
    od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,od.DTLPASSTHRUNUM03,
    od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,od.DTLPASSTHRUNUM07,
    od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,od.LASTUSER,
    od.LASTUPDATE,od.DTLPASSTHRUDATE01,od.DTLPASSTHRUDATE02,od.DTLPASSTHRUDATE03,
    od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01,od.DTLPASSTHRUDOLL02,odl.QTYAPPROVED,
    od.UOMENTERED,od.QTYENTERED,odl.SHIPTO,odl.XDOCK,odl.CONSIGNEE,odl.CARRIER,
    odl.DELIVERYSERVICE,odl.SATURDAYDELIVERY,odl.SHIPTYPE,odl.SHIPTERMS,odl.SHIPDATE,
    odl.ARRIVALDATE,odl.STAGELOC,odl.PRONO,odl.SHIPPINGCOST,odl.SHIPTONAME,odl.SHIPTOADDR1,
    odl.SHIPTOADDR2,odl.SHIPTOCITY,odl.SHIPTOSTATE,odl.SHIPTOPOSTALCODE,
    odl.SHIPTOCOUNTRYCODE,odl.COD,odl.COMPANYCHECKOK,odl.AMTCOD,odl.SHIPTOCONTACT,
    odl.SHIPTOPHONE,odl.SHIPTOFAX,odl.SHIPTOEMAIL,odl.SPECIALSERVICE1,odl.SPECIALSERVICE2,
    odl.SPECIALSERVICE3,odl.SPECIALSERVICE4,odl.BILLTONAME,odl.BILLTOADDR1,odl.BILLTOADDR2,
    odl.BILLTOCITY,odl.BILLTOSTATE,odl.BILLTOPOSTALCODE,odl.BILLTOCOUNTRYCODE,
    odl.BILLTOCONTACT,odl.BILLTOPHONE,odl.BILLTOFAX,odl.BILLTOEMAIL,od.WEIGHT_ENTERED_LBS,
    od.WEIGHT_ENTERED_KGS,od.DTLPASSTHRUCHAR21,od.DTLPASSTHRUCHAR22,
    od.DTLPASSTHRUCHAR23,od.DTLPASSTHRUCHAR24,od.DTLPASSTHRUCHAR25,
    od.DTLPASSTHRUCHAR26,od.DTLPASSTHRUCHAR27,od.DTLPASSTHRUCHAR28,
    od.DTLPASSTHRUCHAR29,od.DTLPASSTHRUCHAR30,od.DTLPASSTHRUCHAR31,
    od.DTLPASSTHRUCHAR32,od.DTLPASSTHRUCHAR33,od.DTLPASSTHRUCHAR34,
    od.DTLPASSTHRUCHAR35,od.DTLPASSTHRUCHAR36,od.DTLPASSTHRUCHAR37,
    od.DTLPASSTHRUCHAR38,od.DTLPASSTHRUCHAR39,od.DTLPASSTHRUCHAR40,
    od.DTLPASSTHRUNUM11,od.DTLPASSTHRUNUM12,od.DTLPASSTHRUNUM13,od.DTLPASSTHRUNUM14,
    od.DTLPASSTHRUNUM15,od.DTLPASSTHRUNUM16,od.DTLPASSTHRUNUM17,od.DTLPASSTHRUNUM18,
    od.DTLPASSTHRUNUM19,od.DTLPASSTHRUNUM20,od.ITEM);
end loop;

update orderdtl
   set linestatus = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
 where rowid = od.rowid;
 
exception when others then
  zms.log_autonomous_msg('SIMPLEKIT', od.fromfacility, od.custid,
      sqlerrm, 'E', in_userid, l_msg);
end expand_simple_kit_item;

function ineligible_expiration_days_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
,in_orderlot varchar2
,in_invstatus varchar2
,in_inventoryclass varchar2
,in_min_days_to_expire number
) return number

is

out_qty integer;
cmdSql varchar2(1000);

TYPE cur_typ is REF CURSOR;
cmc cur_typ;
cmdays integer;
cmqty integer;

type expdate_rcd is record
(expdate plate.expirationdate%type
,qty plate.quantity%type
);

type expdate_tbl is table of expdate_rcd
  index by binary_integer;

cmdErt varchar2(1000);
erc cur_typ;
ert expdate_tbl;
erx integer;
ertloaded boolean;
ertfound boolean;
erdate date;
erqty integer;
currdate date;
enddate date;
cmenddate date;
cntRows integer;
strMsg varchar2(255);

begin

out_qty := 0;
currdate := trunc(sysdate);
enddate := currdate + in_min_days_to_expire;

cmdSql :=
'select nvl(sum(quantity),0) ' ||
' from plate ' ||
' where facility = ''' || in_facility || '''' ||
' and custid = ''' || in_custid || '''' ||
' and item = ''' || in_item || '''' ||
' and invstatus||'''' = ''' || in_invstatus || '''' ||
' and inventoryclass||'''' = ''' || in_inventoryclass || '''' ||
' and status = ''A''' ||
' and type = ''PA''';

if rtrim(in_orderlot) is not null then
  cmdSql := cmdSql ||
   ' and lotnumber = ''' || in_orderlot || '''';
end if;

execute immediate cmdSql into out_qty;

ert.Delete;
ertloaded := False;

cmdSql :=
'select nvl(od.min_days_to_expiration,0), ' ||
' nvl(sum(cm.qty),0) ' ||
' from orderdtl od, commitments cm ' ||
' where cm.facility = ''' || in_facility || '''' ||
' and cm.custid = ''' || in_custid || '''' ||
' and cm.item = ''' || in_item || '''' ||
' and cm.invstatus||'''' = ''' || in_invstatus || '''' ||
' and cm.inventoryclass||'''' = ''' || in_inventoryclass || '''' ||
' and cm.orderid = od.orderid ' ||
' and cm.shipid = od.shipid ' ||
' and cm.item = od.item ' ||
' and nvl(cm.orderlot,''x'') = nvl(od.lotnumber,''x'') ';

if rtrim(in_orderlot) is not null then
  cmdSql := cmdSql ||
   ' and cm.orderlot = ''' || in_orderlot || '''';
end if;

cmdSql := cmdSql || ' group by nvl(od.min_days_to_expiration,0) ';
cmdSql := cmdSql || ' order by nvl(od.min_days_to_expiration,0) ';

open cmc for cmdSql;
loop
  fetch cmc into cmdays, cmqty;
  exit when cmc%notfound;
  if ertLoaded = False then
    cmdErt := 'select nvl(trunc(expirationdate),''' || enddate || ''')' || ', sum(quantity) '  ||
    ' from plate ' ||
    ' where facility = ''' || in_facility || '''' ||
    ' and custid = ''' || in_custid || '''' ||
    ' and item = ''' || in_item || '''' ||
    ' and invstatus||'''' = ''' || in_invstatus || '''' ||
    ' and inventoryclass||'''' = ''' || in_inventoryclass || '''' ||
    ' and status = ''A''' ||
    ' and type = ''PA''';
    if rtrim(in_orderlot) is not null then
      cmdSql := cmdSql ||
       ' and lotnumber = ''' || in_orderlot || '''';
    end if;
    cmdErt := cmdErt ||
    ' group by nvl(trunc(expirationdate),''' || enddate || ''')' ||
    ' order by nvl(trunc(expirationdate),''' || enddate || ''')';
    open erc for cmdErt;
    loop
      fetch erc into erdate, erqty;
      exit when erc%notfound;
      erx := ert.count + 1;
      ert(erx).expdate := erdate;
      ert(erx).qty := erqty;
    end loop;
    if erc%isopen then
      close erc;
    end if;
    ertLoaded := True;
  end if;
  ertFound := False;
  cmenddate := trunc(currdate) + cmdays;
  for erx in 1..ert.count
  loop
    if (cmenddate <= ert(erx).expdate) or
       (cmdays = 0) then
      if ert(erx).qty >= cmqty then
        ert(erx).qty := ert(erx).qty - cmqty;
        out_qty := out_qty - least(out_qty, cmqty);
        cmqty := 0;
      else
        cmqty := cmqty - ert(erx).qty;
        out_qty := out_qty - least(out_qty, ert(erx).qty);
        ert(erx).qty := 0;
      end if;
    end if;
    if cmqty = 0 then
      exit;
    end if;
  end loop;
end loop;
if cmc%isopen then
  close cmc;
end if;

for erx in 1..ert.count
loop
  if enddate <= ert(erx).expdate then
    if out_qty < ert(erx).qty then
      out_qty := 0;
    else
      out_qty := out_qty - ert(erx).qty;
    end if;
    if out_qty = 0 then
      exit;
    end if;
  end if;
end loop;

return out_qty;

exception when others then
  return out_qty;
end;


function in_str_clause
(in_indicator varchar2
,in_values varchar2
) return varchar2 is

returnstr varchar2(255);
wkstr varchar2(255);
position integer;
needcomma boolean;

begin

returnstr := '';

if upper(nvl(rtrim(in_indicator),'I')) = 'E' then
  returnstr := 'not ';
end if;

returnstr := returnstr || 'in (';

wkstr := rtrim(in_values);
needcomma := False;
while length(wkstr) <> 0
loop
  position := instr(wkstr,',');
  if needcomma then
    returnstr := returnstr || ',';
  else
    needcomma := true;
  end if;
  if position = 0 then
    returnstr := returnstr || '''' || wkstr || '''';
    wkstr := '';
  else
    returnstr := returnstr || '''' || substr(wkstr,1,position-1) || '''';
    wkstr := substr(wkstr,position+1,length(wkstr)-position);
  end if;
end loop;

returnstr := returnstr || ')';

return returnstr;

exception when others then
  return returnstr;
end in_str_clause;


procedure match_template_parms
(in_wavetemplate varchar2
,in_orderid number
,in_shipid number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is
cursor curOrderHdr is
  select orderid,
         shipid,
         loadno,
         fromfacility,
         custid,
         carrier,
         deliveryservice,
         ordertype,
         shiptype,
         shipto,
         priority,
         shipdate,
         apptdate,
         qtyorder
 	 from orderhdr
  	where orderid = in_orderid
  	  and shipid = in_shipid;
oh curOrderHdr%rowtype;
cursor curTemplate(in_facility varchar2) is
  select str01 as custid,
         str02 as shipto,
         str16 as state,
         str06 as postalcode,
         str03 as carrier,
         str13 as deliveryservice,
         num01 as shipfromdays,
         num02 as shiptodays,
         num05 as apptfromdays,
         num06 as appttodays,
         str07 as item,
         str10 as orderid,
         num03 as loadno,
         flag04 as ieordertype,
         str04 as ordertype,
         flag05 as ieorderpriority,
         str05 as orderpriority,
		   flag08 as ieproductgroup,
      	str08 as productgroup,
		   flag09 as ieshiptype,
      	str09 as shiptype,
         str11 as fromlot,
         str12 as tolot,
         flag01 as singlesku,
         str14 as userdefinedcolumn,
         str15 as userdefinedvalue,
         num07 as fromlinecount,
         num08 as tolinecount,
         idx01 as date1idx,
         date01 as date1from,
         date02 as date1to,
         idx02 as date2idx,
         date03 as date2from,
         date04 as date2to,
         idx03 as date3idx,
         date05 as date3from,
         date06 as date3to,
         option03 as picktype,
         option01 as stageloc,
         flag03 as taskpriority,
         option04 as batchcartontype,
         option02 as sortloc,
         num04 as orderlimit,
         flag18 as mass_manifest,
         descr,
         option06 as allocrule,
         nvl(num10,0) as maxqtyorder,
         flag07 as sdi_sortation_yn,
         option08 as sdi_sorter_process,
         option07 as sdi_sorter,
         nvl(num11,0) as sdi_max_units,
         flag10 as sdi_sorter_mode,
         flag20 as sdi_manual_picks_yn,
         where_clause,
         str18 as bbb_custid_template
  	from requests
   where facility = in_facility
     and reqtype = 'WaveSelect'
     and descr = in_wavetemplate;
tp curTemplate%rowtype;
cnt pls_integer;
l_cnt pls_integer;

function idx_to_date_col
	(in_idx in number)
return varchar2
is
date_col varchar2(64);
begin
  if in_idx = 0 then
    date_col := 'apptdate';
  elsif in_idx = 1 then
    date_col := 'arrivaldate';
  elsif in_idx = 2 then
    date_col := 'cancel_after';
  elsif in_idx = 3 then
    date_col := 'cancel_if_not_delivered_by';
  elsif in_idx = 4 then
    date_col := 'delivery_requested';
  elsif in_idx = 5 then
    date_col := 'do_not_deliver_after';
  elsif in_idx = 6 then
    date_col := 'do_not_deliver_before';
  elsif in_idx = 7 then
    date_col := 'entrydate';
  elsif in_idx = 8 then
    date_col := 'requested_ship';
  elsif in_idx = 9 then
    date_col := 'shipdate';
  elsif in_idx = 10 then
    date_col := 'ship_no_later';
  elsif in_idx = 11 then
    date_col := 'ship_not_before';
  else
    date_col := 'statusupdate';
  end if;

  return date_col;
exception
   when OTHERS then
      return null;
end idx_to_date_col;

begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -13;
  out_msg := 'Order not found ' || in_orderid || '-' || in_shipid;
  return;
end if;

tp := null;
open curTemplate(oh.fromfacility);
fetch curTemplate into tp;
close curTemplate;
if tp.descr is null then
  out_errorno := -12;
  out_msg := 'Wave template not found: ' || in_wavetemplate;
  return;
end if;

if trim(tp.where_clause) is not null then
  begin
    execute immediate 'select count(1) from waveselectview ' ||
       tp.where_clause || ' and orderid = ' || in_orderid || 
       ' and shipid = ' || in_shipid
              into l_cnt;
    if l_cnt = 0 then
      out_errorno := -35;
      out_msg := 'Order doesn''t match wave select query';
      return;
    end if;
  exception when others then
    out_errorno := sqlcode;
    out_msg := sqlerrm;
    return;
  end;
end if;

-- if selection parms indicate order is not included then
-- return a negative error code to caller
if tp.carrier is not null then
  if oh.carrier != tp.carrier then
    out_errorno := -1;
    out_msg := 'Not selected (carrier): ' || tp.carrier || ' ' || oh.carrier;
    return;
  end if;
end if;
if tp.shiptype is not null then
  if tp.ieshiptype = 'E' then
    if instr(tp.shiptype,oh.shiptype) <> 0 then
      out_errorno := -2;
      out_msg := 'Not selected (shipment type): ' || tp.shiptype || ' ' || oh.shiptype;
      return;
    end if;
  elsif instr(tp.shiptype,oh.shiptype) = 0 then
    out_errorno := -3;
    out_msg := 'Not selected (shipment type): ' || tp.shiptype || ' ' || oh.shiptype;
    return;
  end if;
end if;
if tp.deliveryservice is not null then
  if instr(tp.deliveryservice,oh.deliveryservice) = 0 then
    out_errorno := -4;
    out_msg := 'Not selected (delivery service): ' || tp.deliveryservice || ' ' || oh.deliveryservice;
    return;
  end if;
end if;

	if oh.ordertype in ('R','Q','T','P','A','C','I','U') then
    	out_errorno := -34;
    	out_msg := 'Order wrong type: ' || oh.ordertype;
    	return;
	end if;

	if (tp.custid is not null) and (oh.custid != tp.custid) then
    	out_errorno := -5;
    	out_msg := 'Not selected (customer): ' || tp.custid || ' ' || oh.custid;
    	return;
	end if;

	if (tp.shipto is not null) and (oh.shipto != tp.shipto) then
    	out_errorno := -6;
    	out_msg := 'Not selected (ship to): ' || tp.shipto || ' ' || oh.shipto;
    	return;
	end if;

	if tp.ordertype is not null then
  		if tp.ieordertype = 'E' then
    		if instr(tp.ordertype,oh.ordertype) <> 0 then
      		out_errorno := -7;
      		out_msg := 'Not selected (order type): ' || tp.ordertype || ' ' || oh.ordertype;
      		return;
    		end if;
  		elsif instr(tp.ordertype,oh.ordertype) = 0 then
    		out_errorno := -8;
    		out_msg := 'Not selected (order type): ' || tp.ordertype || ' ' || oh.ordertype;
    		return;
  		end if;
	end if;

	if tp.orderpriority is not null then
  		if tp.ieorderpriority = 'E' then
    		if instr(tp.orderpriority,oh.priority) <> 0 then
      		out_errorno := -9;
      		out_msg := 'Not selected (order priority): ' || tp.orderpriority || ' ' || oh.priority;
      		return;
    		end if;
  		elsif instr(tp.orderpriority,oh.priority) = 0 then
    		out_errorno := -10;
    		out_msg := 'Not selected (order priority): ' || tp.orderpriority || ' ' || oh.priority;
    		return;
  		end if;
	end if;

	if tp.productgroup is not null then
   	select count(1) into cnt
      	from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and instr(','||tp.productgroup||',', ','||zci.product_group(custid, item)||',') != 0;
  		if (tp.ieproductgroup = 'E') and (cnt != 0) then
      	out_errorno := -11;
      	out_msg := 'Not selected (product group): ' || tp.productgroup;
      	return;
		end if;
  		if (tp.ieproductgroup != 'E') and (cnt = 0) then
      	out_errorno := -14;
      	out_msg := 'Not selected (product group): ' || tp.productgroup;
      	return;
		end if;
	end if;

	if trunc(oh.shipdate) < trunc(sysdate)+tp.shipfromdays then
      out_errorno := -15;
      out_msg := 'Before ship date ' || to_char(trunc(sysdate)+tp.shipfromdays)
      		|| ' ' || trunc(oh.shipdate);
      return;
	end if;

	if trunc(oh.shipdate) > trunc(sysdate)+tp.shiptodays then
      out_errorno := -16;
      out_msg := 'After ship date ' || to_char(trunc(sysdate)+tp.shiptodays)
      		|| ' ' || trunc(oh.shipdate);
      return;
	end if;

	if trunc(oh.apptdate) < trunc(sysdate)+tp.apptfromdays then
      out_errorno := -17;
      out_msg := 'Before appt date ' || to_char(trunc(sysdate)+tp.apptfromdays)
      		|| ' ' || trunc(oh.apptdate);
      return;
	end if;

	if trunc(oh.apptdate) > trunc(sysdate)+tp.appttodays then
      out_errorno := -18;
      out_msg := 'After appt date ' || to_char(trunc(sysdate)+tp.appttodays)
      		|| ' ' || trunc(oh.apptdate);
      return;
	end if;

	if tp.item is not null then
   	select count(1) into cnt
      	from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and item = tp.item
           and linestatus != 'X';
		if cnt = 0 then
      	out_errorno := -19;
      	out_msg := 'Not selected (item): ' || tp.item;
	      return;
		end if;
	end if;

   if tp.orderid is not null then
   	if (instr(tp.orderid, '-') = 0) then
			if (oh.orderid != tp.orderid) then
     			out_errorno := -20;
        	end if;
		else
      	if (oh.orderid != substr(tp.orderid, 1, instr(tp.orderid, '-')-1))
      	or    (oh.shipid != substr(tp.orderid, instr(tp.orderid, '-')+1)) then
      		out_errorno := -20;
			end if;
		end if;
      if out_errorno != 0 then
      	out_msg := 'Not selected (order): ' || tp.orderid;
	      return;
		end if;
	end if;

	if tp.state is not null then
   	execute immediate 'select count(1) from consignee where consignee=''' || oh.shipto
      		|| ''' and state ' || in_str_clause('I',tp.state)
			into cnt;
		if cnt = 0 then
      	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      	 	  || ' and shipid=' || oh.shipid || ' and shiptostate ' || in_str_clause('I',tp.state)
      	  into cnt;
      	if cnt = 0 then
      	 	  out_errorno := -34;
      	 	  out_msg := 'Not selected (state): ' || tp.state;
      	 	  return;
      	end if;
		end if;
	end if;

	if tp.postalcode is not null then
   	execute immediate 'select count(1) from consignee where consignee=''' || oh.shipto
      		|| ''' and postalcode ' || in_str_clause('I',tp.postalcode)
			into cnt;
		if cnt = 0 then
      	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      	 	  || ' and shipid=' || oh.shipid || ' and shiptopostalcode ' || in_str_clause('I',tp.postalcode)
			    into cnt;
    		if cnt = 0 then
          	out_errorno := -21;
          	out_msg := 'Not selected (postal code): ' || tp.postalcode;
    	      return;
    		end if;
  	end if;
	end if;

	if (tp.loadno is not null) and ((oh.loadno is null) or (oh.loadno != tp.loadno)) then
    	out_errorno := -22;
    	out_msg := 'Not selected (load): ' || tp.loadno || ' ' || oh.loadno;
    	return;
	end if;

	if tp.singlesku = 'Y' then
   	if zoe.line_count(oh.orderid, oh.shipid) != 1 then
   	 	out_errorno := -23;
	    	out_msg := 'Not single sku';
    		return;
    	end if;
	end if;

   if tp.fromlot is not null then
   	select count(1) into cnt
      	from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and lotnumber >= tp.fromlot
           and lotnumber <= tp.tolot
           and linestatus != 'X';
		if cnt = 0 then
      	out_errorno := -24;
      	out_msg := 'Not selected lotnumber range';
	      return;
		end if;
	end if;

   if (tp.userdefinedcolumn is not null) and (tp.userdefinedvalue is not null) then
   	execute immediate
           'select count(1) from orderhdr where orderid = ' || oh.orderid
             || ' and shipid = ' || oh.shipid
             || ' and to_char(' || tp.userdefinedcolumn || ') '
             ||  in_str_clause('I',tp.userdefinedvalue)
               into cnt;
        if cnt = 0 then
      	  out_errorno := -25;
      	   out_msg := 'Not selected (user field): ' ||      tp.userdefinedcolumn || ' '
         		|| tp.userdefinedvalue;
	      return;
		end if;
	end if;

	if tp.fromlinecount is not null then
   	if zoe.line_count(oh.orderid, oh.shipid) < tp.fromlinecount then
   	 	out_errorno := -26;
	    	out_msg := 'Below from linecount';
    		return;
    	end if;
	end if;

	if tp.tolinecount is not null then
   	if zoe.line_count(oh.orderid, oh.shipid) < tp.tolinecount then
   	 	out_errorno := -27;
	    	out_msg := 'Above to linecount';
    		return;
    	end if;
	end if;

	if (tp.date1idx is not null) and (tp.date1from is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date1idx) || '<''' || tp.date1from || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -28;
      	out_msg := 'Not selected (from ' || idx_to_date_col(tp.date1idx) || '): '
         		|| tp.date1from;
	      return;
		end if;
	end if;

	if (tp.date1idx is not null) and (tp.date1to is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date1idx) || '>''' || tp.date1to || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -29;
      	out_msg := 'Not selected (until ' || idx_to_date_col(tp.date1idx) || '): '
         		|| tp.date1to;
	      return;
		end if;
   end if;

	if (tp.date2idx is not null) and (tp.date2from is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date2idx) || '<''' || tp.date2from || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -30;
      	out_msg := 'Not selected (from ' || idx_to_date_col(tp.date2idx) || '): '
         		|| tp.date2from;
	      return;
		end if;
	end if;

	if (tp.date2idx is not null) and (tp.date2to is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date2idx) || '>''' || tp.date2to || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -31;
      	out_msg := 'Not selected (until ' || idx_to_date_col(tp.date2idx) || '): '
         		|| tp.date2to;
	      return;
		end if;
   end if;

	if (tp.date3idx is not null) and (tp.date3from is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date3idx) || '<''' || tp.date3from || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -32;
      	out_msg := 'Not selected (from ' || idx_to_date_col(tp.date3idx) || '): '
         		|| tp.date3from;
	      return;
		end if;
	end if;

	if (tp.date3idx is not null) and (tp.date3to is not null) then
   	execute immediate 'select count(1) from orderhdr where orderid=' || oh.orderid
      		|| ' and shipid=' || oh.shipid
            || ' and ' || idx_to_date_col(tp.date3idx) || '>''' || tp.date3to || ''''
			into cnt;
		if cnt != 0 then
      	out_errorno := -33;
      	out_msg := 'Not selected (until ' || idx_to_date_col(tp.date3idx) || '): '
         		|| tp.date3to;
	      return;
		end if;
   end if;

   if (tp.maxqtyorder > 0) and (oh.qtyorder > tp.maxqtyorder) then
     out_errorno := -34;
     out_msg := 'Order quantity of ' || oh.qtyorder || ' exceeds maximum of ' ||
                tp.maxqtyorder;
   end if;
   
exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end;

function committed_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_lotnumber varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
) return number is

curQty integer;
cntRows integer;
cmdsql varchar2(2000);
qtyCommit number(16);

begin

begin
  cmdsql := 'select nvl(sum(qty),0) as qty ' ||
   ' from commitments ' ||
   'where facility = ''' || nvl(in_facility,'x') || ''' and custid = ''' ||
   nvl(in_custid,'x') || ''' and orderitem = ''' || nvl(in_orderitem,'x') || ''' and uom = ''' ||
   nvl(in_uom,'x') || ''' and orderid = ' || in_orderid || ' and shipid = ' ||
   in_shipid;
  if rtrim(in_lotnumber) is not null then
    cmdsql := cmdsql || ' and lotnumber = ''' || in_lotnumber || '''';
  end if;
  if rtrim(in_invstatus) is not null then
    cmdsql := cmdsql || ' and invstatus ' ||
      in_str_clause(in_invstatusind,in_invstatus);
  end if;
  if rtrim(in_inventoryclass) is not null then
    cmdsql := cmdsql || ' and inventoryclass ' ||
      in_str_clause(in_invclassind, in_inventoryclass);
  end if;
  curQty := dbms_sql.open_cursor;
  dbms_sql.parse(curQty, cmdsql, dbms_sql.native);
  dbms_sql.define_column(curQty,1,qtyCommit);
  cntRows := dbms_sql.execute_and_fetch(curQty);
  dbms_sql.column_value(curQty,1,qtyCommit);
  dbms_sql.close_cursor(curQty);
exception when no_data_found then
  qtyCommit := 0;
  dbms_sql.close_cursor(curQty);
end;

return qtyCommit;

exception when others then
  return -1;
end committed_qty;

function allocable_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_lotnumber varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
) return number is

curQty integer;
cntRows integer;
cmdsql varchar2(2000);
qtyAllocable number(16);
qtyCommit number(16);

begin

begin
  cmdsql := 'select nvl(sum(qty),0) as qty ' ||
   ' from custitemtotsumavailview ' ||
   'where facility = ''' || nvl(in_facility,'x') || ''' and custid = ''' ||
   nvl(in_custid,'x') || ''' and item = ''' || nvl(in_orderitem,'x') || ''' and uom = ''' ||
   nvl(in_uom,'x') || '''';
  if rtrim(in_lotnumber) is not null then
    cmdsql := cmdsql || ' and lotnumber = ''' || in_lotnumber || '''';
  end if;
  if rtrim(in_invstatus) is not null then
    cmdsql := cmdsql || ' and invstatus ' ||
      in_str_clause(in_invstatusind,in_invstatus);
  end if;
  if rtrim(in_inventoryclass) is not null then
    cmdsql := cmdsql || ' and inventoryclass ' ||
      in_str_clause(in_invclassind, in_inventoryclass);
  end if;
  curQty := dbms_sql.open_cursor;
  dbms_sql.parse(curQty, cmdsql, dbms_sql.native);
  dbms_sql.define_column(curQty,1,qtyAllocable);
  cntRows := dbms_sql.execute_and_fetch(curQty);
  dbms_sql.column_value(curQty,1,qtyAllocable);
  dbms_sql.close_cursor(curQty);
exception when no_data_found then
  qtyAllocable := 0;
  dbms_sql.close_cursor(curQty);
end;

qtyAllocable := qtyAllocable +
    committed_qty
      (in_facility
      ,in_custid
      ,in_orderid
      ,in_shipid
      ,in_orderitem
      ,in_uom
      ,in_lotnumber
      ,in_invstatusind
      ,in_invstatus
      ,in_invclassind
      ,in_inventoryclass
      );

return qtyAllocable;

exception when others then
  return -1;
end allocable_qty;

function order_allocable_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
) return number is

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

qtyAllocable number(16);

begin

qtyAllocable := 0;

for od in curOrderdtl
loop
  qtyAllocable := qtyAllocable +
    allocable_qty
      (in_facility
      ,in_custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      );
end loop;

return qtyAllocable;

exception when others then
  return -1;
end order_allocable_qty;

PROCEDURE commit_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_orderlot varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_enter_min_days_to_expire_yn varchar2
,in_min_days_to_expiration number
,in_userid varchar2
,out_msg  IN OUT varchar2
) is

cursor curItemList is
  select in_orderitem as itemsub,
         -1 as seq
    from dual
   union all
  select itemsub,
         seq
    from custitemsubs
   where custid = in_custid
     and item = in_orderitem
   order by 2,1;

cursor curItem is
  select iskit, expdaterequired, lotrequired
    from custitemview
   where custid = in_custid
     and item = in_orderitem;
ci curItem%rowtype;

cursor curOrderdtl is
  select nvl(qtyorder,0) qtyorder, nvl(qtycommit,0) qtycommit
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderdtl%rowtype;

cursor curOrderhdr is
  select ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

totRemain number(16);
qtyCommit number(16);
curQty integer;
curRule integer;
cntRows integer;
cmdSql varchar2(2000);
ar allocrulesdtl%rowtype;
cm commitments%rowtype;
cntColumn integer;
qtyOrderByWeight orderdtl.qtyOrder%type;
qtyExpired number;
qtyTasked subtasks.qty%type;
multiInvStatus boolean;

begin

totRemain := in_qty;
multiInvStatus := false;
out_msg := '';

oh := null;
open curOrderhdr;
fetch curOrderhdr into oh;
close curOrderhdr;

od := null;
open curOrderdtl;
fetch curOrderdtl into od;
close curOrderdtl;
if ( od.qtycommit >= od.qtyorder ) then
  out_msg := 'Quantity already committed';
  return;
end if;


ci := null;
open curItem;
fetch curItem into ci;
close curItem;
if ( (ci.iskit = 'C') and (oh.ordertype = 'O') ) or
   ( (ci.iskit = 'K') and (oh.ordertype in ('W','K')) ) then
  out_msg := 'OKAY';
  return;
end if;

if ((instr(in_invstatus,',') <> 0) or (instr(in_inventoryclass,',') <> 0)) then
  multiInvStatus := true;
end if;

for itm in curItemList -- process ordered item and any substitutes
loop
--  zut.prt('checking item ' || itm.itemsub);
  if totRemain = 0 then
    exit;
  end if;
  begin -- get the allocation rule for the item
    select allocrule
      into ar.allocrule
      from custitemfacilityview
     where custid = in_custid
       and facility = in_facility
       and item = itm.itemsub
       and rownum < 2;
  exception when no_data_found then
    ar.allocrule := '';
  end;
--  zut.prt('COMMITLINE ' || in_facility || ' ' || in_custid ||
--    'Rule is: ' || ar.allocrule);
  if ar.allocrule is not null then
    cmdSql := 'select inventoryclass, invstatus, lifofifo, datetype from (' ||
      'select inventoryclass, invstatus, ';
      if (multiInvStatus) then
          cmdSql := cmdsql || 'nvl(lifofifo,''F'') as lifofifo, nvl(datetype,''M'') as datetype, ';
      else
          cmdSql := cmdsql || 'null as lifofifo, null as datetype, ';
      end if;
      cmdSql := cmdSql ||
      'min(priority) as priority ' ||
      'from allocrulesdtl ' ||
      'where facility = ''' || nvl(in_facility,'x') ||
      ''' and allocrule = ''' || ar.allocrule || '''';
    if rtrim(in_invstatus) is not null then
      cmdSql := cmdSql || ' and ( (invstatus is null) or ' ||
        '(invstatus ' || in_str_clause(in_invstatusind,in_invstatus) ||
        ') ) ';
    end if;
    if rtrim(in_inventoryclass) is not null then
      cmdSql := cmdSql || ' and ( (inventoryclass is null) or ' ||
        '(inventoryclass ' ||
        in_str_clause(in_invclassind,in_inventoryclass) ||
        ') ) ';
    end if;
    cmdSql := cmdsql || ' group by inventoryclass, invstatus';
    if (multiInvStatus) then
        cmdSql := cmdsql || ' , nvl(lifofifo,''F''), nvl(datetype,''M'')';
    end if;
    cmdSql := cmdsql || ') order by priority';
    begin
    curRule := dbms_sql.open_cursor;
    dbms_sql.parse(curRule, cmdsql, dbms_sql.native);
    dbms_sql.define_column(curRule,1,ar.inventoryclass,2);
    dbms_sql.define_column(curRule,2,ar.invstatus,2);
    dbms_sql.define_column(curRule,3,ar.lifofifo,1);
    dbms_sql.define_column(curRule,4,ar.datetype,1);
    cntRows := dbms_sql.execute(curRule);
    while (1=1)
    loop -- allocation rules
      cntRows := dbms_sql.fetch_rows(curRule);
      if cntRows <= 0 then
        exit;
      end if;
      dbms_sql.column_value(curRule,1,ar.inventoryclass);
      dbms_sql.column_value(curRule,2,ar.invstatus);
      dbms_sql.column_value(curRule,3,ar.lifofifo);
      dbms_sql.column_value(curRule,4,ar.datetype);
      begin
      cmdSql := 'select inventoryclass, invstatus, ';
      if in_orderlot is not null then
        cmdSql := cmdSql || 'lotnumber, ';
      end if;
      
      cmdSql := cmdSql ||
       'nvl(sum(qty),0) as qty ';

      if (multiInvStatus) then
        if rtrim(ar.datetype) = 'M' then
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ',max(maxmanufacturedate) as maxmanufacturedate ';
          else
            cmdSql := cmdSql || ',min(minmanufacturedate) as minmanufacturedate ';
          end if;
        elsif rtrim(ar.datetype) = 'E' then
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ',max(maxexpirationdate) as maxexpirationdate ';
          else
            cmdSql := cmdSql || ',min(minexpirationdate) as minexpirationdate ';
          end if;
        else
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ',max(maxcreationdate) as maxcreationdate ';
          else
            cmdSql := cmdSql || ',min(mincreationdate) as mincreationdate ';
          end if;
        end if;
        cmdSql := cmdSql ||
         'from custitemtotcommitview ';
      else
        cmdSql := cmdSql ||
         'from custitemtotsumavailview ';
      end if;

      cmdSql := cmdSql ||
       'where facility = ''' || nvl(in_facility,'x') || ''' and custid = ''' ||
       nvl(in_custid,'x') || ''' and item = ''' || nvl(itm.itemsub,'x') || ''' and uom = ''' ||
       nvl(in_uom,'x') || '''';
      if rtrim(in_orderlot) is not null then
        cmdSql := cmdSql || ' and lotnumber = ''' || in_orderlot || '''';
      end if;
      if rtrim(ar.invstatus) is not null then
        cmdSql := cmdSql || ' and invstatus ' ||
          in_str_clause('I',ar.invstatus);
      elsif rtrim(in_invstatus) is not null then
        cmdSql := cmdSql || ' and invstatus ' ||
          in_str_clause(in_invstatusind,in_invstatus);
      end if;
      if rtrim(ar.inventoryclass) is not null then
        cmdSql := cmdSql || ' and inventoryclass ' ||
          in_str_clause('I', ar.inventoryclass);
      elsif rtrim(in_inventoryclass) is not null then
        cmdSql := cmdSql || ' and inventoryclass ' ||
          in_str_clause(in_invclassind, in_inventoryclass);
      end if;
      cmdSql := cmdSql || ' group by inventoryclass,invstatus';
      if rtrim(in_orderlot) is not null then
        cmdSql := cmdSql || ',lotnumber ';
      end if;
      cmdSql := cmdsql || ' having nvl(sum(qty),0) > 0';

      if (multiInvStatus) then
        if rtrim(ar.datetype) = 'M' then
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ' order by maxmanufacturedate desc ';
          else
            cmdSql := cmdSql || ' order by minmanufacturedate ';
          end if;
        elsif rtrim(ar.datetype) = 'E' then
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ' order by maxexpirationdate desc ';
          else
            cmdSql := cmdSql || ' order by minexpirationdate ';
          end if;
        else
          if rtrim(ar.lifofifo) = 'L' then
            cmdSql := cmdSql || ' order by maxcreationdate desc ';
          else
            cmdSql := cmdSql || ' order by mincreationdate ';
          end if;
        end if;
      end if;
--      cntRows := 1;
--      while (cntRows * 60) < (Length(cmdSql)+60)
--      loop
--        zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
--        cntRows := cntRows + 1;
--      end loop;
      curQty := dbms_sql.open_cursor;
      dbms_sql.parse(curQty, cmdsql, dbms_sql.native);
      dbms_sql.define_column(curQty,1,cm.inventoryclass,2);
      dbms_sql.define_column(curQty,2,cm.invstatus,2);
      if rtrim(in_orderlot) is not null then
        dbms_sql.define_column(curQty,3,cm.lotnumber,30);
        cntColumn := 4;
      else
        cntColumn := 3;
      end if;
      dbms_sql.define_column(curQty,cntColumn,cm.qty);
      cntRows := dbms_sql.execute(curQty);
      while (1=1)
      loop
        cntRows := dbms_sql.fetch_rows(curQty);
        if cntRows <= 0 then
          exit;
        end if;
        dbms_sql.column_value(curQty,1,cm.inventoryclass);
        dbms_sql.column_value(curQty,2,cm.invstatus);
        if rtrim(in_orderlot) is not null then
          dbms_sql.column_value(curQty,3,cm.lotnumber);
        end if;
        dbms_sql.column_value(curQty,cntColumn,cm.qty);
--        zut.prt('alloc ' || cm.inventoryclass || ' ' ||
--               cm.invstatus || ' ' ||
--               cm.lotnumber || ' ' ||
--               cm.qty);
        if (ci.lotrequired = 'S') and (rtrim(in_orderlot) is not null) then
          qtyCommit := 0;
          select nvl(sum(qty),0)
            into qtyCommit
            from custitemtotsumavailview
           where facility = nvl(in_facility,'x')
             and custid = nvl(in_custid,'x')
             and item = nvl(itm.itemsub,'x')
             and uom = nvl(in_uom,'x')
             and inventoryclass = cm.inventoryclass
             and invstatus = cm.invstatus;
          qtyTasked := 0;
          select nvl(sum(st.qty),0)
            into qtyTasked
            from subtasks st, plate pl
           where st.facility = nvl(in_facility,'x')
             and st.custid = nvl(in_custid,'x')
             and st.item = nvl(itm.itemsub,'x')
             and nvl(st.orderlot,'(none)') = '(none)'
             and pl.lpid = st.lpid
             and pl.inventoryclass = cm.inventoryclass
             and pl.invstatus = cm.invstatus
             and nvl(pl.lotnumber,'(none)') = in_orderlot;
          cm.qty := cm.qty - qtyTasked;
          if (qtyCommit < cm.qty) then
            cm.qty := qtyCommit;
          end if;
        end if;
        if (ci.expdaterequired = 'Y') and
           (in_enter_min_days_to_expire_yn = 'Y') and
           (in_min_days_to_expiration > 0) then
          qtyExpired := zcm.ineligible_expiration_days_qty(in_facility,
            in_custid, in_orderid, in_shipid, itm.itemsub, in_orderlot,
            cm.invstatus, cm.inventoryclass, in_min_days_to_expiration);
          cm.qty := cm.qty - nvl(qtyExpired,0);
          if (cm.qty < 0) then
            cm.qty := 0;
          end if;
        end if;
        if cm.qty < totRemain then
          qtyCommit := cm.qty;
        else
          qtyCommit := totRemain;
        end if;
        begin
--          zut.prt('insert commit ' || qtyCommit);
          insert into commitments
          (facility, custid, item, inventoryclass,
           invstatus, status, lotnumber, uom,
           qty, orderid, shipid, orderitem, orderlot,
           priority, lastuser, lastupdate)
          values
          (in_facility, in_custid, itm.itemsub, cm.inventoryclass,
           cm.invstatus, 'CM', in_orderlot, in_uom,
           qtyCommit, in_orderid, in_shipid, in_orderitem, in_orderlot,
           in_priority, in_userid, sysdate);
        exception when dup_val_on_index then
--          zut.prt('update commit ' || qtyCommit);
          update commitments
             set qty = qty + qtyCommit,
                 priority = in_priority,
                 lastuser = in_userid,
                 lastupdate = sysdate
           where facility = in_facility
             and custid = in_custid
             and item = itm.itemsub
             and inventoryclass = cm.inventoryclass
             and invstatus = cm.invstatus
             and status = 'CM'
             and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
             and orderid = in_orderid
             and shipid = in_shipid
             and orderitem = in_orderitem
             and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
        end;
        totRemain := totRemain - qtyCommit;
        if totRemain = 0 then
          exit;
        end if;
      end loop;
      dbms_sql.close_cursor(curQty);
      exception when no_data_found then
        cm.qty := 0;
        dbms_sql.close_cursor(curQty);
      end;
      if totRemain = 0 then
        exit;
      end if;
    end loop; -- allocation rules
    dbms_sql.close_cursor(curRule);
    exception when no_data_found then
      dbms_sql.close_cursor(curRule);
    end;
  end if;
--  zut.prt('remain is ' || totRemain);
--  zut.prt('in qty is ' || in_qty);
  if totRemain != 0 then -- if more try to commit per order
    begin
    cmdSql := 'select inventoryclass, invstatus, ';
    if in_orderlot is not null then
      cmdSql := cmdSql || ' lotnumber, ';
    end if;
    cmdSql := cmdSql ||
     ' nvl(sum(qty),0) as qty ' ||
     ' from custitemtotsumavailview ' ||
     'where facility = ''' || nvl(in_facility,'x') || ''' and custid = ''' ||
     nvl(in_custid,'x') || ''' and item = ''' || nvl(itm.itemsub,'x') || ''' and uom = ''' ||
     nvl(in_uom,'x') || '''';
    if rtrim(in_orderlot) is not null then
      cmdSql := cmdSql || ' and lotnumber = ''' || in_orderlot || '''';
    end if;
    if rtrim(in_invstatus) is not null then
      cmdSql := cmdSql || ' and invstatus ' ||
        in_str_clause(in_invstatusind,in_invstatus);
    end if;
    if rtrim(in_inventoryclass) is not null then
      cmdSql := cmdSql || ' and inventoryclass ' ||
        in_str_clause(in_invclassind, in_inventoryclass);
    end if;
    cmdSql := cmdSql || ' group by inventoryclass,invstatus';
    if rtrim(in_orderlot) is not null then
      cmdSql := cmdSql || ',lotnumber ';
    end if;
    cmdSql := cmdsql || ' having nvl(sum(qty),0) > 0';
--    cntRows := 1;
--    while (cntRows * 60) < (Length(cmdSql)+60)
--    loop
--      zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
--      cntRows := cntRows + 1;
--    end loop;
    curQty := dbms_sql.open_cursor;
    dbms_sql.parse(curQty, cmdsql, dbms_sql.native);
    dbms_sql.define_column(curQty,1,cm.inventoryclass,2);
    dbms_sql.define_column(curQty,2,cm.invstatus,2);
    if rtrim(in_orderlot) is not null then
      dbms_sql.define_column(curQty,3,cm.lotnumber,30);
      cntColumn := 4;
    else
      cntColumn := 3;
    end if;
    dbms_sql.define_column(curQty,cntColumn,cm.qty);
    cntRows := dbms_sql.execute(curQty);
    while (1=1)
    loop
      cntRows := dbms_sql.fetch_rows(curQty);
      if cntRows <= 0 then
        exit;
      end if;
      dbms_sql.column_value(curQty,1,cm.inventoryclass);
      dbms_sql.column_value(curQty,2,cm.invstatus);
      if rtrim(in_orderlot) is not null then
        dbms_sql.column_value(curQty,3,cm.lotnumber);
      end if;
      dbms_sql.column_value(curQty,cntColumn,cm.qty);
--      zut.prt('order pass ' ||
--             cm.inventoryclass || ' ' ||
--             cm.invstatus || ' ' ||
--             cm.lotnumber || ' ' ||
--             cm.qty);
      if (ci.expdaterequired = 'Y') and
         (in_enter_min_days_to_expire_yn = 'Y') and
         (in_min_days_to_expiration > 0) then
        qtyExpired := zcm.ineligible_expiration_days_qty(in_facility,
          in_custid, in_orderid, in_shipid, itm.itemsub, in_orderlot,
          cm.invstatus, cm.inventoryclass, in_min_days_to_expiration);
        cm.qty := cm.qty - nvl(qtyExpired,0);
        if (cm.qty < 0) then
          cm.qty := 0;
        end if;
      end if;
      if cm.qty < totRemain then
        qtyCommit := cm.qty;
      else
        qtyCommit := totRemain;
      end if;
      begin
        insert into commitments
        (facility, custid, item, inventoryclass,
         invstatus, status, lotnumber, uom,
         qty, orderid, shipid, orderitem, orderlot,
         priority, lastuser, lastupdate)
        values
        (in_facility, in_custid, itm.itemsub, cm.inventoryclass,
         cm.invstatus, 'CM', in_orderlot, in_uom,
         qtyCommit, in_orderid, in_shipid, in_orderitem, in_orderlot,
         in_priority, in_userid, sysdate);
      exception when dup_val_on_index then
        update commitments
           set qty = qty + qtyCommit,
               priority = in_priority,
               lastuser = in_userid,
               lastupdate = sysdate
         where facility = in_facility
           and custid = in_custid
           and item = itm.itemsub
           and inventoryclass = cm.inventoryclass
           and invstatus = cm.invstatus
           and status = 'CM'
           and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
           and orderid = in_orderid
           and shipid = in_shipid
           and orderitem = in_orderitem
           and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
      end;
      totRemain := totRemain - qtyCommit;
      if totRemain = 0 then
        exit;
      end if;
    end loop;
    dbms_sql.close_cursor(curQty);
    exception when no_data_found then
      cm.qty := 0;
      dbms_sql.close_cursor(curQty);
    end;
  end if;
end loop; -- process item and any substitutes
out_msg := 'OKAY';

delete from commitments
 where orderid = in_orderid
   and shipid = in_shipid
   and orderitem = in_orderitem
   and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
   and facility = in_facility
   and custid = in_custid
   and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
   and status = 'CM'
   and qty = 0;

if zwt.is_ordered_by_weight(in_orderid,in_shipid,in_orderitem,in_orderlot) = 'Y' then

  qtyOrderByWeight := zwt.order_by_weight_qty (in_orderid,in_shipid,in_orderitem,in_orderlot);
  update orderdtl
     set qtyorder = qtyOrderByWeight,
         weightorder = zci.item_weight(custid,item,uom) * qtyOrderByWeight,
         cubeorder = zci.item_cube(custid,item,uom) * qtyOrderByWeight,
         amtorder =  zci.item_amt(custid,orderid,shipid,item,lotnumber) * qtyOrderByWeight -- prn 25133
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and qtyOrder != qtyOrderByWeight;

end if;

exception when others then
  out_msg := 'zcmcl ' || sqlerrm;
end commit_line;

PROCEDURE uncommit_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_orderlot varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
) is

qtyOrderByWeight orderdtl.qtyOrder%type;

begin

delete
  from commitments
 where orderid = in_orderid
   and shipid = in_shipid
   and orderitem = in_orderitem
   and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');

if zwt.is_ordered_by_weight(in_orderid,in_shipid,in_orderitem,in_orderlot) = 'Y' then

  qtyOrderByWeight := zwt.order_by_weight_qty (in_orderid,in_shipid,in_orderitem,in_orderlot);
  update orderdtl
     set qtyorder = qtyOrderByWeight,
         weightorder = zci.item_weight(custid,item,uom) * qtyOrderByWeight,
         cubeorder = zci.item_cube(custid,item,uom) * qtyOrderByWeight,
         amtorder =  zci.item_amt(custid,orderid,shipid,item,lotnumber) * qtyOrderByWeight --PRN 25133
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and qtyOrder != qtyOrderByWeight;

end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zcmul ' || sqlerrm;
end uncommit_line;


procedure commit_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid IN OUT varchar2
,in_reqtype varchar2 -- '1':wave select (manual) '2':import order (auto)
                     -- '3':auto wave plan '4':TMS (manual)
,in_wave IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderhdr is
  select fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority,
         ordertype,
         nvl(wave,0) as wave,
         nvl(xdockprocessing,'S') as xdockprocessing,
         loadno,
         stopno,
         shipno
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curWaves is
  select wavestatus,
         facility,
         tms_status,
         descr,
         schedrelease
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(zwt.order_by_weight_qty(in_orderid, in_shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty,
         xdockorderid,
         xdockshipid,
         nvl(backorder,'N') as backorder,
         nvl(min_days_to_expiration,0) as min_days_to_expiration
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curCust(in_custid varchar2) is
  select nvl(cu.resubmitorder, 'N') as resubmitorder,
         nvl(cu.multifac_picking, 'N') as multifac_picking,
         nvl(ca.enter_min_days_to_expire_yn,'N') as enter_min_days_to_expire_yn,
         auto_load_assign_column
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and ca.custid = cu.custid;
cs curCust%rowtype;

cursor curSimpleKitItems is
  select item, qtyorder, custid, fromfacility
    from orderdtl od
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and exists (select 1 from custitemview ci
                  where od.custid = ci.custid
                    and od.item = ci.item
                    and ci.iskit = 'S');

cursor curKitItems is
  select nvl(sum(nvl(qtyorder,0)),0) as qtyorder
    from orderdtl od
   where orderid = in_orderid
     and shipid = in_shipid
     and exists (select 1 from custitemview ci
                  where od.custid = ci.custid
                    and od.item = ci.item
                    and ci.iskit != 'N');
ki curKitItems%rowtype;

qtyOrder orderhdr.qtyorder%type;
qtyCommit orderhdr.qtycommit%type;
cust_errorno number(4);
cust_errormsg varchar2(36);
strMsg varchar2(255);
tmsflag varchar2(1);
l_msg varchar2(255);
l_txt varchar2(255);
l_next_release date;
errmsg varchar2(255);
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_errorno pls_integer;
l_trailer loads.trailer%type;
l_non_null_orderdtl_invclass pls_integer;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := in_orderid || '-' || in_shipid || ': ' || out_msg;
  zms.log_msg('WaveSelect', oh.fromfacility, oh.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin

out_msg := '';
out_errorno := 0;

if in_userid = '(none)' then
  in_userid := 'IMPORDER';
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  out_msg := ' Order not found';
  order_msg('E');
  return;
end if;
close curOrderhdr;

-- validate ASN receipt order
if oh.ordertype in ('R','Q','P','A','C','I') then
  return;
end if;

tmsflag := 'N';

if in_reqtype in ('1','4') then
  if oh.orderstatus != '1' then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    order_msg('W');
    if oh.orderstatus = 'X' then
      out_errorno := -1;
    else
      out_errorno := 1;
    end if;
    return;
  end if;
  if oh.commitstatus != '0' then
    out_msg := ' Invalid commitment status: ' || oh.commitstatus;
    order_msg('W');
    out_errorno := 2;
    return;
  end if;
end if;

if in_reqtype in ('2', '3') then -- imported order auto-select wave or auto plan
  if oh.orderstatus > '2' then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    order_msg('W');
    out_errorno := 1;
    return;
  end if;
  if oh.commitstatus > '1' then
    out_msg := ' Invalid commitment status: ' || oh.commitstatus;
    order_msg('W');
    out_errorno := 2;
    return;
  end if;
  if in_reqtype = '2' then  -- auto plan has already found a wave skip call
    if oh.wave = 0 then
      zcm.find_open_wave(oh.fromfacility,oh.custid,in_userid,
        in_orderid,in_shipid,null,in_wave,tmsflag,out_errorno,out_msg);
      if out_errorno != 0 then
        if out_errorno > 0 then -- error occurred trying to assign to wave
          order_msg('E');
          out_errorno := 10;
        else
          out_errorno := 0; -- wave assignment did not apply
        end if;
        return;
      end if;
    else
      in_wave := oh.wave;
    end if;
  end if;
end if;

open curWaves;
fetch curWaves into wv;
if curWaves%notfound then
  close curWaves;
  out_msg := ' Wave not found: ' || in_wave;
  order_msg('E');
  out_errorno := 3;
  return;
end if;
close curWaves;

if nvl(wv.tms_status,'X') != 'X' then
    tmsflag := 'Y';
end if;

if wv.wavestatus not in ('1','2') then
  out_msg := ' Invalid wave status: ' || wv.wavestatus;
  order_msg('W');
  out_errorno := 4;
  return;
end if;

-- Check for scheduling a release
if in_reqtype = '2' then
    if wv.wavestatus = '1' and wv.schedrelease is null then
        zcm.find_next_release(wv.facility, wv.descr,
            l_next_release, errmsg);
        if errmsg = 'OKAY' and l_next_release is not null then
            update waves
              set schedrelease = l_next_release
             where wave = in_wave;
        end if;
    end if;
end if;

open curCust(oh.custid);
fetch curCust into cs;
if curCust%notfound then
  cs.resubmitorder := 'N';
  cs.multifac_picking := 'N';
  cs.enter_min_days_to_expire_yn := 'N';
  cs.auto_load_assign_column := null;
end if;
close curCust;

if cs.multifac_picking = 'Y' then
  multifac_order_commit(in_orderid, in_shipid, in_facility, in_userid, in_reqtype,
      in_wave, tmsflag, cs.resubmitorder, cs.enter_min_days_to_expire_yn,
      out_errorno, out_msg);
  return;
end if;

if oh.xdockprocessing != 'A' then
  for ski in curSimpleKitItems
  loop
    zcm.expand_simple_kit_item(in_orderid,in_shipid,ski.item,in_userid,l_msg);
    if l_msg <> 'OKAY' then
      zms.log_autonomous_msg('SIMPLEKIT', ski.fromfacility, ski.custid,
        l_msg, 'E', in_userid, errmsg);
    end if;
  end loop;  
  for od in curOrderdtl
  loop
    zcm.commit_line
        (oh.fromfacility
        ,oh.custid
        ,in_orderid
        ,in_shipid
        ,od.item
        ,od.uom
        ,od.lotnumber
        ,od.invstatusind
        ,od.invstatus
        ,od.invclassind
        ,od.inventoryclass
        ,od.qty
        ,oh.priority
        ,in_reqtype
        ,cs.enter_min_days_to_expire_yn
        ,od.min_days_to_expiration
        ,in_userid
        ,out_msg
        );
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('WaveSelect', oh.fromfacility, oh.custid,
          out_msg, 'W', in_userid, out_msg);
    end if;
  end loop;
end if;

if (oh.ordertype = 'O') and
   (tmsflag != 'Y') and
   (nvl(oh.loadno,0) = 0) and
   (cs.auto_load_assign_column is not null) then
  zcm.find_open_load(oh.fromfacility,
                     oh.custid,
                     in_userid,
                     in_orderid,
                     in_shipid,
                     cs.auto_load_assign_column,
                     l_loadno,
                     l_stopno,
                     l_shipno,
                     l_errorno,
                     l_msg);
  if l_errorno < 0 then
    zms.log_autonomous_msg(	
      in_author   => 'AUTOLOAD',
      in_facility => oh.fromfacility,
      in_custid   => oh.custid,
      in_msgtext  => l_msg,
      in_msgtype  => 'T',
      in_userid   => in_userid,
      out_msg		=> l_txt);
    l_loadno := null;
    l_stopno := null;
    l_shipno := null;
  end if;
else
  l_loadno := oh.loadno;
  l_stopno := oh.stopno;
  l_shipno := oh.shipno;
end if;
update orderhdr
   set orderstatus = '2',
       commitstatus = '1',
       tms_status = decode(carrier,
                           nvl(zci.default_value('TMS_CARRIER'),'x'), tms_status,
                           decode(in_reqtype,
                        '4','1',
                        '1','X',
                                  decode(tmsflag,'Y','1','X'))),
       tms_status_update = sysdate,
       wave = in_wave,
       lastuser = in_userid,
       lastupdate = sysdate,
       loadno = l_loadno,
       stopno = l_stopno,
       shipno = l_shipno
 where orderid = in_orderid
   and shipid = in_shipid
 returning qtyorder, qtycommit
  into qtyOrder, qtyCommit;
if cs.auto_load_assign_column is not null then
  begin
    select count(1)
      into l_non_null_orderdtl_invclass
      from orderdtl od, orderhdr oh
      where oh.loadno = l_loadno
        and oh.orderstatus != 'X'
        and od.orderid = oh.orderid
        and od.shipid = oh.shipid
        and od.linestatus != 'X'
        and od.inventoryclass is not null;
  exception when others then
    l_non_null_orderdtl_invclass := 0;
  end;
  if l_non_null_orderdtl_invclass != 0 then
    l_trailer := null;
  else
    l_trailer := 'LOCAL';
  end if;
  update loads
     set trailer = l_trailer
   where loadno = l_loadno
     and nvl(trailer,'x') != nvl(l_trailer,'x');
end if;

if qtyOrder > qtyCommit then
  if cs.resubmitorder = 'Y' then
    ki.qtyorder := 0;
    open curKitItems;
    fetch curKitItems into ki;
    close curKitItems;
    if (qtyOrder - ki.qtyorder) > qtyCommit then
      zcm.uncommit_order(in_orderid,in_shipid,oh.fromfacility,
        in_userid,in_reqtype,in_wave,out_msg);
      zimp.translate_cust_errorcode
      (oh.custid, 104, 'Insufficient Stock', cust_errorno, cust_errormsg);
      update orderhdr
         set orderstatus = 'X',
             lastuser = in_userid,
             lastupdate = sysdate,
             rejectcode = cust_errorno,
             rejecttext = cust_errormsg
       where orderid = in_orderid
         and shipid = in_shipid;
      out_errorno := 104;
      out_msg := 'Insufficient Stock';
      return;
    end if;
  else
    if in_reqtype in ('2', '3') then
      for od in curOrderDtl
      loop
        if od.qty = 0 then
          goto continue_orderdtl_loop;
        end if;
        if od.backorder = 'X' then
          zoe.cancel_item(in_orderid,in_shipid,od.item,od.lotnumber,
            oh.fromfacility,in_userid,out_msg);
          if substr(out_msg,1,4) != 'OKAY' then
            zms.log_msg('CommitOrders', oh.fromfacility, oh.custid,
              'Cancel Item: ' || in_orderid || '-' || in_shipid || ' ' ||
              od.item || ' ' || od.lotnumber || ' ' ||
              out_msg, 'E', in_userid, strMsg);
          end if;
        end if;
        update orderdtl
           set cancelreason = 'NOSTOCK'
         where orderid = in_orderid
           and shipid = in_shipid
           and item = od.item
           and nvl(lotnumber,'(none)') = nvl(od.lotnumber,'(none)');
      << continue_orderdtl_loop >>
        null;
      end loop;
      update orderhdr
         set rejectcode = '104',
             rejecttext = 'Insufficient Stock'
       where orderid = in_orderid
         and shipid = in_shipid
         and orderstatus = 'X';
       if sql%rowcount = 1 then
         out_errorno := 104;
         out_msg := 'Insufficient Stock';
         return;
       end if;
    end if;
  end if;
end if;

zlb.compute_order_labor(in_orderid,in_shipid,oh.fromfacility,in_userid,
  out_errorno,out_msg);
if out_errorno != 0 then
  zms.log_msg('LABORCALC', oh.fromfacility, oh.custid,
      out_msg, 'E', in_userid, strMsg);
  out_errorno := 0;
end if;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Commited',
     'Order Commited Wave:'|| in_wave,
     in_userid, out_msg);

out_msg := 'OKAY';

exception when others then
  out_msg := 'zcmco ' || sqlerrm;
  out_errorno := sqlcode;
end commit_order;

procedure uncommit_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid varchar2
,in_reqtype varchar2 -- '1' wave release form
,in_wave number
,out_msg IN OUT varchar2
) is

cursor curOrderhdr is
  select fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curWaves is
  select wavestatus,
         facility,
         descr
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(zwt.order_by_weight_qty(in_orderid, in_shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

msg varchar2(255);
cntRows integer;
out_errorno integer;
l_job_count pls_integer;
l_uncommit_job boolean; -- uncommitting via oracle job

begin
if out_msg = 'uncommitjob' then
  l_uncommit_job := True;
else
  l_uncommit_job := False;
end if;

out_msg := '';

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  msg := in_orderid || '-' || in_shipid ||
         ' Order not found';
  zms.log_msg('WaveSelect', in_facility, '',
       msg, 'W', in_userid, out_msg);
  out_msg := msg;
  return;
end if;
close curOrderhdr;

if in_reqtype = '1' then
  if oh.orderstatus != '2' then
    msg := in_orderid || '-' || in_shipid ||
           ': Invalid order status ' || oh.orderstatus;
    zms.log_msg('WaveSelect', in_facility, oh.custid,
        msg, 'W', in_userid, out_msg);
    out_msg := msg;
    return;
  end if;
  if oh.commitstatus != '1' then
    msg := in_orderid || '-' || in_shipid ||
           ' Invalid commitment status: ' || oh.commitstatus;
    zms.log_msg('WaveSelect', in_facility, oh.custid,
        msg, 'W', in_userid, out_msg);
    out_msg := msg;
    return;
  end if;
end if;

open curWaves;
fetch curWaves into wv;
if curWaves%notfound then
  close curWaves;
  msg := in_orderid || '-' || in_shipid ||
         ' Wave not found: ' || in_wave;
  zms.log_msg('WaveSelect', in_facility, oh.custid,
       msg, 'W', in_userid, out_msg);
  out_msg := msg;
  return;
end if;
close curWaves;

if wv.wavestatus not in ('1','2') then
  msg := in_orderid || '-' || in_shipid ||
         ' Invalid wave status: ' || wv.wavestatus;
  zms.log_msg('WaveSelect', in_facility, oh.custid,
      msg, 'W', in_userid, out_msg);
  out_msg := msg;
  return;
end if;
if l_uncommit_job = False then
  begin
    select count(1)
      into l_job_count
      from user_jobs
     where what like 'zbbb.uncommit_wave%' || in_wave || '%';
  exception when others then
    l_job_count := 0;
  end;
  if l_job_count <> 0 then
    out_msg := 'Note: All orders in this wave are currently being uncommitted.' ||
                chr(13) ||
               'Uncommitting individual orders in this wave is currently not allowed.';
    return;
  end if;
end if;

for od in curOrderdtl
loop
  if (wv.descr = 'Direct Release') and (in_reqtype = '1') then
    zwv.unrelease_line(
      oh.fromfacility,
      oh.custid,
      in_orderid,
      in_shipid,
      od.item,
      od.uom,
      od.lotnumber,
      od.invstatusind,
      od.invstatus,
      od.invclassind,
      od.inventoryclass,
      od.qty,
      oh.priority,
      in_reqtype,
      'N',
      in_userid,
      out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('WaveSelect', in_facility, oh.custid,
          out_msg, 'W', in_userid, out_msg);
    end if;
  end if;

  uncommit_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,od.qty
      ,oh.priority
      ,in_reqtype
      ,in_userid
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveSelect', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
  end if;
end loop;

update orderhdr
   set orderstatus = '1',
       commitstatus = '0',
       tms_status = 'X',
       wave = 0,
       shipshort = 'N',
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

zlb.compute_order_labor(in_orderid,in_shipid,oh.fromfacility,in_userid,
  out_errorno,out_msg);
if out_errorno != 0 then
  zms.log_msg('LABORCALC', oh.fromfacility, oh.custid,
      out_msg, 'E', in_userid, msg);
end if;

select count(1)
  into cntRows
  from orderhdr
 where fromfacility = oh.fromfacility
   and wave = in_wave;

if cntRows = 0 then
  update waves
     set wavestatus = '4',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = in_wave
     and wavestatus < '4';
end if;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order UnCommited',
     'Order UnCommited Wave: '||in_wave,
     in_userid, out_msg);

out_msg := 'OKAY';

exception when others then
  out_msg := substr('zcmuo ' || sqlerrm,1,255);
end uncommit_order;

PROCEDURE find_open_wave
(in_facility varchar2
,in_custid varchar2
,in_userid varchar2
,in_orderid number
,in_shipid number
,in_template varchar2
,out_wave IN OUT number
,out_tms IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curCustTemplate is
  select nvl(in_template, wavetemplate) as wavetemplate,
         nvl(paperbased, 'N') as paperbased,
         tms_orders_to_plan_format
    from customer
   where custid = in_custid;
ct curCustTemplate%rowtype;

cursor curCustFacility is
  select waveprofile
    from custfacility
   where custid = in_custid
     and facility = in_facility;

 cf curCustFacility%rowtype;

cursor curOrderHdr is
  select orderid,
         shipid,
         carrier,
         deliveryservice,
         shiptype,
         fromfacility
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOpenWave (in_template varchar2) is
  select wave,
         nvl(orderlimit,0) as orderlimit,
         nvl(sdi_max_units,0) as sdi_max_units
    from waves
   where wavestatus = '1'
     and facility = in_facility
     and descr = in_template;
ow curOpenWave%rowtype;

cursor curTemplate(in_template varchar2) is
  select option03 as picktype,
         option01 as stageloc,
         flag03 as taskpriority,
         option04 as batchcartontype,
         option02 as sortloc,
         num04 as orderlimit,
         str01 as custid,
         str02 as shipto,
         str03 as carrier,
         str07 as item,
         str16 as state,
         str06 as postalcode,
         str13 as deliveryservice,
         flag04 as ieordertype,
         str04 as ordertype,
         flag05 as ieorderpriority,
         str05 as orderpriority,
         flag08 as ieproductgroup,
         str08 as productgroup,
         flag09 as ieshiptype,
         str09 as shiptype,
         flag02 as tmsoptimize,
         flag18 as mass_manifest,
         str17 as parallel_pick_zones,
         flag07 as sdi_sortation_yn,
         option08 as sdi_sorter_process,
         option07 as sdi_sorter,
         nvl(num11,0) as sdi_max_units,
         flag10 as sdi_sorter_mode,
         flag20 as sdi_manual_picks_yn,
         descr,
         where_clause,
         option06 as allocrule,
	 str18 as bbb_custid_template
    from requests
   where facility = in_facility
     and reqtype = 'WaveSelect'
     and descr = in_template;
tp curTemplate%rowtype;

cursor curCustomer(in_custid varchar2) is
  select defconsolidated,defshiptype,defcarrier,
         defservicelevel,defshipcost
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

ordercount integer;
qtyorder integer;
begin

out_errorno := 0;
out_msg := '';
out_tms := 'N';

open curCustTemplate;
fetch curCustTemplate into ct;
if curCustTemplate%notfound then
  close curCustTemplate;
  out_errorno := 1;
  out_msg := 'Customer not found: ' || in_custid;
  return;
end if;
close curCustTemplate;

cf := null;
open curCustFacility;
fetch curCustFacility into cf;
close curCustFacility;

if ct.wavetemplate is null and cf.waveprofile is null then
  out_errorno := -100;
  out_msg := 'No wave template or profile defined';
  return;
end if;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := 13;
  out_msg := 'Order not found ' || in_orderid || '-' || in_shipid;
  return;
end if;

out_errorno := -1;

-- First check for the facility defined profile
if cf.waveprofile is not null and in_template is null then

  for wp in (select wavedescr from waveprofiledtl
              where facility = in_facility
                and profile = cf.waveprofile
              order by priority) loop

    tp := null;
    open curTemplate(wp.wavedescr);
    fetch curTemplate into tp;
    close curTemplate;
    if tp.descr is null then
      out_errorno := 12;
      out_msg := 'Wave template not found: ' || wp.wavedescr;
      return;
    end if;

    out_tms := tp.tmsoptimize;

    zcm.match_template_parms(wp.wavedescr,oh.orderid,oh.shipid,
        out_errorno,out_msg);

    exit when out_errorno = 0;

  end loop;

end if;

if out_errorno <> 0 and ct.wavetemplate is null then
    return;
end if;

-- Next check for the customer defined wave template
if out_errorno <> 0 then
    tp := null;
    open curTemplate(ct.wavetemplate);
    fetch curTemplate into tp;
    close curTemplate;
    if tp.descr is null then
      out_errorno := 12;
      out_msg := 'Wave template not found: ' || ct.wavetemplate;
      return;
    end if;

    out_tms := tp.tmsoptimize;

    zcm.match_template_parms(ct.wavetemplate,oh.orderid,oh.shipid,
            out_errorno,out_msg);

end if;

if out_errorno <> 0 then

    return;
end if;


if tp.tmsoptimize = 'Y' and ct.tms_orders_to_plan_format is null then
    out_errorno := -5;
    out_msg := 'TMS optimize set but non-TMS customer';
    return;
end if;


ow := null;
open curOpenWave(zcm.tokenized_wave_descr(tp.descr,
                 zcm.tokenized_column_value(tp.descr,in_orderid,in_shipid)));
fetch curOpenWave into ow;
close curOpenWave;
if ow.wave is null then
  open curOpenWave(tp.descr);
  fetch curOpenWave into ow;  
  close curOpenWave;
end if;

if ow.wave is null then
  zwv.get_next_wave(out_wave,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 2;
    return;
  end if;
  cu := null;
  if tp.custid is not null then
    open curCustomer(tp.custid);
    fetch curCustomer into cu;
    close curCustomer;
  end if;
  insert into waves
   (wave, descr, wavestatus,
    facility, lastuser, lastupdate,
    stageloc,picktype,sortloc,batchcartontype,
    taskpriority,orderlimit,
    tms_status, tms_status_update,consolidated,
    shiptype,carrier,servicelevel,shipcost, mass_manifest,
    allocrule, parallel_pick_zones,
    sdi_sortation_yn, sdi_sorter_process, sdi_sorter, sdi_max_units,
    sdi_sorter_mode, sdi_manual_picks_yn,
    bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
  values
    (out_wave, zcm.tokenized_wave_descr(tp.descr,
     zcm.tokenized_column_value(tp.descr,in_orderid,in_shipid)), '1',
     in_facility, in_userid, sysdate,
     tp.stageloc, tp.picktype, tp.sortloc, tp.batchcartontype,
     tp.taskpriority,tp.orderlimit,
     decode(tp.tmsoptimize,'Y','1','X'),sysdate,
     cu.defconsolidated,cu.defshiptype,cu.defcarrier,
     cu.defservicelevel,cu.defshipcost, tp.mass_manifest,
     tp.allocrule, tp.parallel_pick_zones,
     tp.sdi_sortation_yn, tp.sdi_sorter_process, tp.sdi_sorter, tp.sdi_max_units,
     tp.sdi_sorter_mode, tp.sdi_manual_picks_yn,
     tp.bbb_custid_template, 'Y', nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE'));
else
  ordercount := 0;
  begin
    select count(1)
      into ordercount
      from orderhdr OH, customer CU
     where OH.fromfacility = in_facility
       and OH.wave = ow.wave
       and OH.orderstatus != 'X'
       and CU.custid = OH.custid
       and nvl(CU.paperbased, 'N') != ct.paperbased;
  exception when others then
    ordercount := 0;
  end;
  if ordercount != 0 then
  	 out_errorno := 15;
    out_msg := 'Incompatible Aggregate Inventory wave found: ' || ow.wave;
  	 return;
  end if;

  ordercount := 0;
  begin
    select count(1)
      into ordercount
      from orderhdr
     where fromfacility = in_facility
       and wave = ow.wave
       and orderstatus != 'X'
       and ordertype not in ('O','W','K');
  exception when others then
    ordercount := 0;
  end;
  if ordercount != 0 then
  	 out_errorno := 16;
    out_msg := 'Unplannable order type found in wave: ' || ow.wave;
  	 return;
  end if;

  out_wave := ow.wave;

  if tp.tmsoptimize = 'Y' then
      ordercount := 0;
      begin
        select count(1)
          into ordercount
          from customer C, orderhdr O
         where O.wave = out_wave
           and O.custid = C.custid
           and (tms_status != '1'
            or C.tms_orders_to_plan_format != ct.tms_orders_to_plan_format);
      exception when others then
        ordercount := 0;
      end;
      if ordercount > 0 then
        out_errorno := -6;
        out_msg := 'TMS optimize set but existing wave doesn''t match';
        return;
      end if;
  end if;

  ordercount := 0;
  qtyorder := 0;
  begin
    select count(1), sum(qtyorder)
      into ordercount, qtyorder
      from orderhdr
     where fromfacility = in_facility
       and wave = out_wave
       and orderhdr.orderstatus != 'X';
  exception when others then
    ordercount := 0;
    qtyorder := 0;
  end;
  if ((ow.orderlimit != 0) and (ordercount >= (ow.orderlimit - 1))) or
     ((ow.sdi_max_units != 0) and (qtyorder >= (ow.sdi_max_units - 1))) then
    zwv.ready_wave(out_wave,'1',in_facility,
      in_userid,out_msg);
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zcmfow ' || sqlerrm;
  out_errorno := sqlcode;
end find_open_wave;


procedure auto_wave_plan
(in_facility varchar2
,in_custid varchar2
,in_wave_prefix varchar2
)
is
type awp_ord_type is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type);
type awp_ord_cur is ref cursor return awp_ord_type;
c_awp_ord awp_ord_cur;
oh awp_ord_type;

cursor c_tp(p_pfx varchar2) is
   select descr
     from requests
    where facility = in_facility
      and reqtype = 'WaveSelect'
      and descr like p_pfx
    order by descr;

l_errno number;
l_msg varchar2(255);
l_wave waves.wave%type;
l_userid userheader.nameid%type := 'AUTO_PLAN';
tmsflag varchar2(1);
l_text varchar2(6);
l_plan_onhold systemdefaults.defaultvalue%type;
begin

   begin
      select upper(nvl(defaultvalue,'N')) into l_plan_onhold
         from systemdefaults
         where defaultid = 'AUTO_PLAN_ONHOLD_ORDERS';
   exception
      when OTHERS then
         l_plan_onhold := 'N';
   end;

   if l_plan_onhold = 'Y' then
      open c_awp_ord for
         select orderid, shipid
            from orderhdr
            where fromfacility = in_facility
              and custid = in_custid
              and source = 'EDI'
              and commitstatus = '0'
              and orderstatus != 'X'
              and nvl(xdockorderid,0) = 0;
   else
      open c_awp_ord for
         select orderid, shipid
            from orderhdr
            where fromfacility = in_facility
              and custid = in_custid
              and source = 'EDI'
              and commitstatus = '0'
              and orderstatus not in ('X','0')
              and nvl(xdockorderid,0) = 0;
   end if;

   loop
      fetch c_awp_ord into oh;
      exit when c_awp_ord%notfound;

      l_text := 'Wave';
      for tp in c_tp(in_wave_prefix||'%')
      loop
         l_errno := -999;
         tmsflag := 'N';
         zcm.find_open_wave(in_facility, in_custid, l_userid, oh.orderid,
               oh.shipid, tp.descr, l_wave, tmsflag, l_errno, l_msg);
         if l_errno = 0 then
            zcm.commit_order(oh.orderid, oh.shipid, in_facility, l_userid, '3',
                  l_wave, l_errno, l_msg);
            l_text := 'Commit';
            exit;
         end if;
      end loop;
      if l_errno != 0 then
         rollback;
         zms.log_msg('AUTOWAVEPLAN', in_facility, in_custid,
               'Unable to plan order: ' || oh.orderid || '-' || oh.shipid ||
               '(' || l_text || ': ' || l_errno || ')',
               'W', l_userid, l_msg);
      else
         zms.log_msg('AUTOWAVEPLAN', in_facility, in_custid,
               'Order ' || oh.orderid || '-' || oh.shipid || ' assigned to wave ' || l_wave,
               'I', l_userid, l_msg);
      end if;
      commit;
   end loop;
   close c_awp_ord;

exception when others then
   rollback;
   zms.log_msg('AUTOWAVEPLAN', in_facility, in_custid, sqlerrm, 'E', l_userid, l_msg);
   commit;
end auto_wave_plan;


procedure find_next_release
(in_facility varchar2
,in_descr varchar2
,out_next_release IN OUT date
,out_msg IN OUT varchar2
)
is
CURSOR C_WP(in_facility varchar2, in_descr varchar2)
IS
    SELECT flag11 mon, flag12 tue, flag13 wed, flag14 thu, flag15 fri,
           flag16 sat, flag17 sun,
           date07 fromtime, date08 totime, num09 interval
      FROM requests
     WHERE reqtype = 'WaveSelect'
       AND facility = in_facility
       AND descr = in_descr;

WP C_WP%rowtype;
l_day varchar2(10);
next_datetime date;
use_datetime date;
l_sysdate date;

begin
    out_msg := 'OKAY';
    out_next_release := null;


    WP := null;
    OPEN C_WP(in_facility, in_descr);
    FETCH C_WP into WP;
    CLOSE C_WP;

    if nvl(WP.mon,'N') != 'Y'
    and nvl(WP.tue,'N') != 'Y'
    and nvl(WP.wed,'N') != 'Y'
    and nvl(WP.thu,'N') != 'Y'
    and nvl(WP.fri,'N') != 'Y'
    and nvl(WP.sat,'N') != 'Y'
    and nvl(WP.sun,'N') != 'Y' then
        out_msg := 'Not an auto release wave. No dates set.';
        return;
    end if;

    if WP.fromtime is null or WP.totime is null or WP.interval is null
    then
        out_msg := 'Not an auto release wave.No time or interval set.';
        return;
    end if;

    l_sysdate := sysdate + 10/(86400);
    next_datetime := l_sysdate;
    l_day := to_char(next_datetime,'dy');


    if l_day = 'mon' and nvl(WP.mon,'N') = 'Y'
    or l_day = 'tue' and nvl(WP.tue,'N') = 'Y'
    or l_day = 'wed' and nvl(WP.wed,'N') = 'Y'
    or l_day = 'thu' and nvl(WP.thu,'N') = 'Y'
    or l_day = 'fri' and nvl(WP.fri,'N') = 'Y'
    or l_day = 'sat' and nvl(WP.sat,'N') = 'Y'
    or l_day = 'sun' and nvl(WP.sun,'N') = 'Y' then


    -- If it is for today before the start use the start
        if next_datetime < trunc(l_sysdate) + (WP.fromtime-trunc(WP.fromtime))
        then
            out_next_release := trunc(l_sysdate) + (WP.fromtime-trunc(WP.fromtime));
            return;

        end if;


        if next_datetime >= trunc(l_sysdate) + (WP.fromtime-trunc(WP.fromtime))
        and next_datetime <= trunc(l_sysdate) + (WP.totime-trunc(WP.totime)) then
            use_datetime := trunc(l_sysdate) + (WP.fromtime-trunc(WP.fromtime));
            loop
                exit when use_datetime >= next_datetime
                         or use_datetime >= trunc(l_sysdate)
                                + (WP.totime-trunc(WP.totime));
                use_datetime := use_datetime + WP.interval/1440;
            end loop;

            if use_datetime <= trunc(l_sysdate) + (WP.totime-trunc(WP.totime)) then
                out_next_release := use_datetime;

                return;
            end if;

        end if;

    end if;

    use_datetime := trunc(next_datetime);

    loop
        use_datetime := use_datetime + 1;
        l_day := to_char(use_datetime,'dy');

        if l_day = 'mon' and nvl(WP.mon,'N') = 'Y'
        or l_day = 'tue' and nvl(WP.tue,'N') = 'Y'
        or l_day = 'wed' and nvl(WP.wed,'N') = 'Y'
        or l_day = 'thu' and nvl(WP.thu,'N') = 'Y'
        or l_day = 'fri' and nvl(WP.fri,'N') = 'Y'
        or l_day = 'sat' and nvl(WP.sat,'N') = 'Y'
        or l_day = 'sun' and nvl(WP.sun,'N') = 'Y' then
            exit;
        end if;
    end loop;

    use_datetime := use_datetime + (WP.fromtime-trunc(WP.fromtime));

    out_next_release := use_datetime;

exception when others then
    out_msg := sqlerrm;
end find_next_release;

PROCEDURE find_open_load
(in_facility varchar2
,in_custid varchar2
,in_userid varchar2
,in_orderid number
,in_shipid number
,in_column_name varchar2
,out_loadno IN OUT number
,out_stopno IN OUT number
,out_shipno IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is
l_load_count pls_integer;
l_column_value varchar2(4000);
l_cmd varchar2(4000);
type cur_type is ref cursor;
ld_cur cur_type;
oh_cur cur_type;
ld loads%rowtype;
ls loadstop%rowtype;
lss loadstopship%rowtype;
l_msg varchar2(255);
l_auto_stop_assign_column customer_aux.auto_stop_assign_column%type;
begin
out_errorno := 0;
out_loadno := 0;
out_msg := 'NONE';
l_load_count := 0;
l_cmd := 'select ' ||
         zcm.column_select_sql('ORDERHDR',in_column_name) ||
         ' from orderhdr where orderid = ' || in_orderid ||
         ' and shipid = ' || in_shipid;
execute immediate l_cmd
             into l_column_value;
l_cmd := 'select loadno from loads where facility = ''' ||
         in_facility || ''' and loadstatus <= ''6'' and exists ' ||
         '(select 1 from orderhdr where orderhdr.loadno = loads.loadno  and ' ||
         zcm.column_where_sql('ORDERHDR',in_column_name) || ' = ''' ||
         l_column_value || ''')';
zld.ld_debug_msg('LDDEBUG', in_facility, null,
             l_cmd, 'T', in_userid);
ld := null;
ls := null;
lss := null;
open ld_cur for l_cmd;
loop
  fetch ld_cur into ld.loadno;
  exit when ld_cur%notfound;
  exit;
end loop;
if ld.loadno is null then
  zld.get_next_loadno(ld.loadno, l_msg);
  insert into loads
    (loadno, entrydate, loadstatus, facility, carrier,
     statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
  values
      (ld.loadno, sysdate, '1', in_facility, null,
       in_userid, sysdate, in_userid, sysdate, 'OUTC', 'T');
end if;
begin
  select auto_stop_assign_column
    into l_auto_stop_assign_column
    from customer_aux
   where custid = in_custid;
exception when others then
  l_auto_stop_assign_column := null;
end;
if l_auto_stop_assign_column is not null then
  l_cmd := 'select to_number(' || l_auto_stop_assign_column ||
           ') from orderhdr where orderid = ' || in_orderid ||
           ' and shipid = ' || in_shipid;
  zld.ld_debug_msg('LDDEBUG', in_facility, null,
             l_cmd,'T', in_userid);
  begin
    open oh_cur for l_cmd;
    loop
      fetch oh_cur into ls.stopno;
      exit when oh_cur%notfound;
      exit;
    end loop;
  exception when others then
    ls.stopno := 1;
  end;
  if (nvl(ls.stopno,0) <= 0) or
     (nvl(ls.stopno,0) > 9999999) then
    ls.stopno := 1;
  end if;
else
  ls.stopno := 1;
end if;
begin
  insert into loadstop
    (loadno, stopno, entrydate, loadstopstatus,
     statususer, statusupdate, lastuser, lastupdate, facility,
     delpointtype)
    values
    (ld.loadno, ls.stopno, sysdate, '1',
     in_userid, sysdate, in_userid, sysdate, in_facility,'C');
exception when others then
  null;
end;
lss.shipno := 1;
begin
  insert into loadstopship
    (loadno, stopno, shipno, entrydate,
     qtyorder, weightorder, cubeorder, amtorder,
     qtyship, weightship, cubeship, amtship,
     qtyrcvd, weightrcvd, cubercvd, amtrcvd,
     lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
    values
    (ld.loadno, ls.stopno, lss.shipno, sysdate,
     0, 0, 0, 0,
     0, 0, 0, 0,
     0, 0, 0, 0,
     in_userid, sysdate, 0, 0);
exception when others then
  null;
end;
out_loadno := ld.loadno;
out_stopno := ls.stopno;
out_shipno := lss.shipno;
exception when others then
  out_msg := 'zcmfol ' || sqlerrm;
  out_errorno := sqlcode;
end find_open_load;
function column_where_sql
(in_table_name IN varchar2
,in_column_name IN varchar2
) return varchar2
is
l_data_type user_tab_columns.data_type%type;
l_where_sql varchar2(255);
begin
l_data_type := zut.data_type(upper(in_table_name),in_column_name);
l_where_sql := '';
if l_data_type in ('CLOB','DATE','NUMBER') then
  l_where_sql := ' to_char(';
else
  l_where_sql := ' ';
end if;
l_where_sql := l_where_sql || in_table_name || '.' || in_column_name;
if l_data_type in ('CLOB','NUMBER') then
  l_where_sql := l_where_sql || ')';
elsif l_data_type = 'DATE' then
  l_where_sql := l_where_sql || ',''MM/DD/YY'')';
end if;
return l_where_sql;
exception when others then
  return in_column_name;
end column_where_sql;
end zcommitment;
/

show error package body zcommitment;

exit;

