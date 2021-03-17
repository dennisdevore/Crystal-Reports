create or replace package body alps.zdirectrelease as
--
-- $Id: zdrbody.sql 3438 2009-04-14 16:13:58Z eric $
--

procedure direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_picktype          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
cursor curOrderhdr is
  select orderid,
         fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority,
         ordertype,
         stageloc,
         nvl(manual_picks_yn,'N') as manual_picks_yn,
         loadno,
         stopno,
         shipno
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(zwt.order_by_weight_qty(in_orderid, in_shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty,
         nvl(qtyorder,0) qtyorder,
         nvl(qtycommit,0) qtycommit,
         nvl(qtypick,0) qtypick,
         nvl(min_days_to_expiration,0) as min_days_to_expiration
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curCustomer(in_custid varchar2) is
  select cu.custid,
         nvl(caux.allow_direct_release_yn,'N') as allow_direct_release_yn,
         nvl(caux.allow_manual_pick_select_yn,'N') as allow_manual_pick_select_yn,
         nvl(caux.enter_min_days_to_expire_yn,'N') as enter_min_days_to_expire_yn,
         nvl(cu.paperbased,'N') paperbased,
	 auto_load_assign_column
    from customer cu, customer_aux caux
   where cu.custid = in_custid
     and cu.custid = caux.custid (+);
cu curCustomer%rowtype;

qtyOrder orderhdr.qtyorder%type;
qtyCommit orderhdr.qtycommit%type;
qtyTasked subtasks.qty%type;
lWave waves.wave%type;
l_picktype zone.picktype%type;
errorCount number(5);
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_errorno pls_integer;
l_msg varchar2(255);
l_txt varchar2(255);

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := in_orderid || '-' || in_shipid || ': ' || out_msg;
  zms.log_autonomous_msg('ORDERRELEASE', oh.fromfacility, oh.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin
  out_msg := 'OKAY';
  out_errorno := 0;
  errorCount := 0;


  open curOrderhdr;
  fetch curOrderhdr into oh;
  if curOrderhdr%notfound then
    close curOrderhdr;
    out_msg := 'Order not found';
    out_errorno := -1;
    order_msg('E');
    return;
  end if;
  close curOrderhdr;

  cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;
  if cu.custid is null then
    out_msg := 'Customer not found: ' || oh.custid;
    out_errorno := -101;
    order_msg('E');
    return;
  end if;

  if oh.ordertype in ('R','Q','P','A','C','I') then
    out_msg := 'Invalid order type: ' || oh.ordertype;
    order_msg('W');
    out_errorno := -2;
    return;
  end if;

  if oh.orderstatus > '1' then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    order_msg('W');
    out_errorno := -3;
    return;
  end if;

  if oh.commitstatus != '0' then
    out_msg := ' Invalid commitment status: ' || oh.commitstatus;
    order_msg('W');
    out_errorno := -4;
    return;
  end if;

  if cu.allow_direct_release_yn <> 'Y' then
    out_msg := 'Direct release not allowed for this customer: ' || oh.custid;
    out_errorno := -102;
    order_msg('E');
    return;
  end if;

  if oh.manual_picks_yn = 'Y' then
	  if cu.allow_manual_pick_select_yn <> 'Y' then
	    out_msg := 'Manual pick selection not allowed for this customer: ' || oh.custid;
	    out_errorno := -102;
	    order_msg('E');
	    return;
	  end if;
    complete_direct_release(in_orderid, in_shipid, in_userid, in_picktype, out_errorno, out_msg);
    return;
  end if;

  delete from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  delete from subtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  delete from tasks
   where orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  delete from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and priority = '9'
     and not exists
         (select * from subtasks
           where subtasks.taskid = batchtasks.taskid);

  zwv.get_next_wave(lWave,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := -5;
    order_msg('W');
    return;
  end if;
  if in_picktype = 'Line' then
    l_picktype := 'LINE';
  elsif in_picktype = 'Order' then
    l_picktype := 'ORDR';
  else
    l_picktype := '';
  end if;
  insert into waves
   (wave, descr, wavestatus, facility, lastuser, lastupdate, taskpriority, picktype)
   values
   (lWave, 'Direct Release', '1', oh.fromfacility, in_userid, sysdate, '9', l_picktype);

  update orderhdr
     set wave=lWave,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

  for od in curOrderdtl
  loop
    zcm.commit_line(
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
      null,
      cu.enter_min_days_to_expire_yn,
      od.min_days_to_expiration,
      in_userid,
      out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_errorno := -6;
      order_msg('W');
      return;
    end if;

    zwv.release_line(
      in_orderid,
      in_shipid,
      od.item,
      od.lotnumber,
      null,
      oh.fromfacility,
      '9',
      null,
      'N',
      oh.stageloc,
      null,
      null,
      'N',
      in_userid,
      'N',
      1,
      out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_errorno := -7;
      order_msg('W');
      return;
    end if;
  end loop;

  if (oh.ordertype = 'O') and
     (nvl(oh.loadno,0) = 0) and
     (cu.auto_load_assign_column is not null) then
    zcm.find_open_load(oh.fromfacility,
                       oh.custid,
                       in_userid,
                       in_orderid,
                       in_shipid,
                       cu.auto_load_assign_column,
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
         lastuser = in_userid,
         lastupdate = sysdate,
         loadno = l_loadno,
         stopno = l_stopno,
         shipno = l_shipno
   where orderid = in_orderid
     and shipid = in_shipid
   returning qtycommit
    into qtyCommit;
    
  select sum(qtyorder)
  into qtyOrder
  from orderdtl
  where orderid = in_orderid and shipid = in_shipid
    and linestatus <> 'X';

  zwv.complete_pick_tasks(lWave,oh.fromfacility,in_orderid,in_shipid,'9',
  	'9', null, in_userid, null, null, 'N',
  	'N', out_errorno, out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := -8;
    order_msg('W');
    return;
  end if;

  if cu.paperbased = 'Y' then
    for st in (select S.taskid, S.lpid, S.shippinglpid, S.qty
                 from subtasks S, tasks T
                 where S.orderid = in_orderid
                   and S.shipid = in_shipid
                   and T.taskid = S.taskid
                   and T.touserid is null) loop
      insert into agginvtasks
        (shippinglpid, lpid, qty)
      values
        (st.shippinglpid, st.lpid, st.qty);
      update shippingplate
         set type ='P'
         where lpid = st.shippinglpid;
      update subtasks
         set shippingtype = 'P'
         where taskid = st.taskid;
    end loop;
    update tasks
      set touserid = '(AggInven)'
      where touserid is null
        and orderid = in_orderid
        and shipid = in_shipid
        and tasktype in ('OP','PK');
  end if;
  select nvl(sum(qty),0)
    into qtyTasked
    from subtasks
   where wave = lWave
     and orderid = in_orderid
     and shipid = in_shipid;

  if (qtyCommit < qtyOrder) or (qtyTasked < qtyCommit) then
    for od in curOrderdtl
    loop
      select nvl(sum(qty),0)
        into qtyTasked
        from subtasks
       where wave = lWave
         and orderid = in_orderid
         and shipid = in_shipid
         and orderitem = od.item
         and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)');

      if (nvl(od.qtyCommit,0) < nvl(od.qtyOrder,0)) or (qtyTasked < nvl(od.qtyCommit,0)) then
        errorCount := errorCount + 1;
        if (nvl(od.qtyCommit,0) < nvl(od.qtyOrder,0)) then
          insert into direct_release_warnings
            (orderid, shipid, item, lotnumber, qtyorder, qtycommit, qtytasked, warning_msg)
          values
            (in_orderid, in_shipid, od.item, od.lotnumber, od.qtyorder, od.qtycommit, qtyTasked,
             'Committed quantity less than ordered quantity');
        else
          insert into direct_release_warnings
            (orderid, shipid, item, lotnumber, qtyorder, qtycommit, qtytasked, warning_msg)
          values
            (in_orderid, in_shipid, od.item, od.lotnumber, od.qtyorder, od.qtycommit, qtyTasked,
             'Tasked quantity less than committed quantity');
        end if;
      end if;
    end loop;
    out_errorno := errorCount;
    out_msg := 'Warnings found';
  else
    complete_direct_release(in_orderid, in_shipid, in_userid, in_picktype, out_errorno, out_msg);
    return;
  end if;

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end direct_release;

procedure undo_direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
cursor curOrderhdr is
  select fromfacility,
         orderstatus,
         commitstatus,
         custid,
         ordertype,
         priority,
         wave
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(zwt.order_by_weight_qty(in_orderid, in_shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty,
         nvl(qtyorder,0),
         nvl(qtycommit,0),
         nvl(qtypick,0)
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := in_orderid || '-' || in_shipid || ': ' || out_msg;
  zms.log_msg('ORDERRELEASE', oh.fromfacility, oh.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin
  out_msg := 'OKAY';
  out_errorno := 0;

  open curOrderhdr;
  fetch curOrderhdr into oh;
  if curOrderhdr%notfound then
    close curOrderhdr;
    out_msg := ' Order not found';
    out_errorno := -1;
    order_msg('E');
    return;
  end if;
  close curOrderhdr;

  if oh.ordertype in ('R','Q','P','A','C','I') then
    out_msg := 'Invalid order type: ' || oh.ordertype;
    order_msg('W');
    out_errorno := -2;
    return;
  end if;

  if oh.orderstatus > '4' then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    order_msg('W');
    out_errorno := -3;
    return;
  end if;

  if oh.commitstatus > '3' then
    out_msg := ' Invalid commitment status: ' || oh.commitstatus;
    order_msg('W');
    out_errorno := -4;
    return;
  end if;

  for od in curOrderdtl
  loop
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
      '0',
      in_userid,
      'N',
      out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_errorno := -5;
      order_msg('W');
      return;
    end if;

    zcm.uncommit_line(
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
      null,
      in_userid,
      out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_errorno := -5;
      order_msg('W');
      return;
    end if;
  end loop;

  update orderhdr
     set orderstatus = '1',
         commitstatus = '0',
         wave = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

  delete
    from waves
   where wave = oh.wave;

  delete from direct_release_warnings
   where orderid = in_orderid
     and shipid = in_shipid;

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end undo_direct_release;

procedure complete_direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_picktype          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
cursor curOrderhdr is
  select fromfacility,
         custid,
         orderstatus,
         ordertype,
         wave,
         nvl(manual_picks_yn,'N') as manual_picks_yn
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := in_orderid || '-' || in_shipid || ': ' || out_msg;
  zms.log_msg('ORDERRELEASE', oh.fromfacility, oh.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin
  out_msg := 'OKAY';
  out_errorno := 0;

  open curOrderhdr;
  fetch curOrderhdr into oh;
  if curOrderhdr%notfound then
    close curOrderhdr;
    out_msg := ' Order not found';
    out_errorno := -1;
    order_msg('E');
    return;
  end if;
  close curOrderhdr;

  if oh.ordertype in ('R','Q','P','A','C','I') then
    out_msg := 'Invalid order type: ' || oh.ordertype;
    order_msg('W');
    out_errorno := -2;
    return;
  end if;

  if oh.orderstatus > '2' then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    order_msg('W');
    out_errorno := -3;
    return;
  end if;

  if oh.manual_picks_yn = 'Y' and
     in_picktype != 'Line' then
    zgl.gen_order_picks(in_orderid,in_shipid,in_picktype,in_userid,
                        out_errorno,out_msg);
    if out_errorno <> 0 then
      return;
    end if;
  end if;

  update orderhdr
     set orderstatus = '4',
         commitstatus = '3',
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

  update waves
     set wavestatus = '3',
         actualrelease = sysdate,
         schedrelease = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave;

  update tasks
     set priority = '3',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave
     and orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  update subtasks
     set priority = '3',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave
     and orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  update batchtasks
     set priority = '3',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave
     and orderid = in_orderid
     and shipid = in_shipid
     and priority = '9';

  delete from direct_release_warnings
   where orderid = in_orderid
     and shipid = in_shipid;

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end complete_direct_release;

end zdirectrelease;
/
show error package body zdirectrelease;
exit;
