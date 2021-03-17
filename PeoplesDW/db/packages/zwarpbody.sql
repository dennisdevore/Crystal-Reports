create or replace package body alps.wavereplan
as
--
-- $Id$
--


-- Public procedures


PROCEDURE replan_order
   (in_orderid in number,
    in_shipid  in number,
    in_userid in varchar2,
    in_wave in number,
    out_errorno in out number,
    out_msg in out varchar2)
is
   cursor curOrderhdr is
     select fromfacility,
            orderstatus,
            commitstatus,
            custid,
            nvl(wave,0) as wave
       from orderhdr
      where orderid = in_orderid
        and shipid = in_shipid;
   oh curOrderhdr%rowtype;

   cursor curWaves is
     select wavestatus
       from waves
      where wave = in_wave;
   wv curWaves%rowtype;

   l_min_orderstatus orderhdr.orderstatus%type;
   
   cnt pls_integer;
   cntRows integer;

   procedure replan_msg(in_msgtype varchar2)
   is
      strMsg appmsgs.msgtext%type;
   begin
      out_msg := in_orderid || '-' || in_shipid || ': ' || out_msg;
      zms.log_msg('WaveReplan', oh.fromfacility, oh.custid,
            out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
   end;

begin
   out_msg := '';
   out_errorno := 0;

   open curOrderhdr;
   fetch curOrderhdr into oh;
   if curOrderhdr%notfound then
      close curOrderhdr;
      out_msg := ' Order not found';
      replan_msg('E');
      return;
   end if;
   close curOrderhdr;

   if oh.orderstatus != '2' then
      out_msg := 'Invalid order status: ' || oh.orderstatus;
      replan_msg('W');
      out_errorno := 1;
      return;
   end if;

   if oh.commitstatus != '1' then
      out_msg := ' Invalid commitment status: ' || oh.commitstatus;
      replan_msg('W');
        out_errorno := 2;
        return;
   end if;

   open curWaves;
   fetch curWaves into wv;
   if curWaves%notfound then
      close curWaves;
      out_msg := ' Wave not found: ' || in_wave;
      replan_msg('E');
      out_errorno := 3;
      return;
   end if;
   close curWaves;

   if wv.wavestatus not in ('1','2') then
      out_msg := ' Invalid wave status: ' || wv.wavestatus;
      replan_msg('W');
      out_errorno := 4;
      return;
   end if;

   update orderhdr
      set wave = in_wave,
          lastuser = in_userid,
          lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid;

   update orderlabor
      set wave = in_wave,
          lastuser = in_userid,
          lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid;

   if oh.wave != 0 then
     begin
       select min(orderstatus)
         into l_min_orderstatus
         from orderhdr
        where wave = oh.wave
          and ordertype not in ('W','K');
     exception when no_data_found then
       l_min_orderstatus := '9';
     end;

     select count(1)
       into cntRows
       from orderhdr
      where fromfacility = oh.fromfacility
        and wave = oh.wave;
     
     if (l_min_orderstatus > '8') or (cntRows = 0) then
       update waves
          set wavestatus = '4',
              lastuser = in_userid,
              lastupdate = sysdate
        where wave = oh.wave
          and wavestatus < '4';
     end if;
   end if;

   update waves
      set replanned = 'R',
          lastuser = in_userid,
          lastupdate = sysdate
      where wave = in_wave;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Replanned',
     'Order Replanned to wave '||in_wave,
     in_userid, out_msg);
   out_msg := 'OKAY';

exception when others then
   out_msg := 'zwarpro ' || sqlerrm;
   out_errorno := sqlcode;
end replan_order;

PROCEDURE replan_selected_orders
(in_wave IN number
,in_included_rowids IN clob
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
,out_error_count IN OUT number
)
is

type cur_type is ref cursor;
l_cur cur_type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_custid orderhdr.custid%type;
l_sql varchar2(4000);
l_errorno pls_integer;
l_msg varchar2(255);
l_log_msg varchar2(255);
l_userid userheader.nameid%type;
l_wave waves.wave%type;
l_count pls_integer;
l_rowids clob;
l_rowid varchar2(50);
i pls_integer;

begin

l_userid := in_userid;
l_wave := in_wave;
out_error_count := 0;

l_rowids := in_included_rowids || ',';
l_count := length(in_included_rowids) - length(replace(l_rowids, ',', ''));
for i in 1 .. l_count loop 
  
  select regexp_substr(l_rowids,'[^,]+', 1, i)
    into l_rowid
    from dual;      

  if l_rowid is null then
    exit;
  end if;

  l_sql := 'select orderid, shipid, custid ' ||
           'from orderhdr ' ||
           'where rowid = ''' || l_rowid || '''';

  open l_cur for l_sql;
  fetch l_cur into l_orderid, l_shipid, l_custid;
  if l_cur%notfound then
    goto continue_oh_loop;
  end if;
  
  zwarp.replan_order(l_orderid, l_shipid, l_userid, l_wave, l_errorno, l_msg);
  if substr(l_msg, 1,4) != 'OKAY' then
    rollback;
		zms.log_autonomous_msg('WAVEREPLAN',null,l_custid,
                       l_msg,'E',in_userid,l_log_msg);
    out_error_count := out_error_count + 1;
  else
    commit;
  end if;  

<< continue_oh_loop >>
  close l_cur;
end loop;
         
out_msg := 'OKAY';
out_errorno := 0;

exception when others then
   out_msg := 'zwarprso ' || sqlerrm;
   out_errorno := sqlcode;
end replan_selected_orders;

end wavereplan;
/
show error package body wavereplan;
exit;
