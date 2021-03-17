drop table bbb_route_rpt;

create table bbb_route_rpt
(sessionid           number,
 ld_loadno           number(7),
 ld_stopno           number(7),
 ld_shiptype         char(1),
 ld_shiptype_abbrev  varchar2(12),
 ld_trailer          varchar2(12),
 ld_billoflading     varchar2(40),
 ld_carrier          varchar2(4),
 ld_wave             number(9),
 ls_shipto           varchar2(10),
 oh_custid           varchar2(10),
 oh_fromfacility     varchar2(3),
 bbb_control_value   varchar2(255),
 order_count         number(9),
 carton_count        number(9),
 qtyorder            number(9),
 cubeorder           number(10,4),
 weightorder         number(17,4),
 wave_type           varchar2(7), -- 'P and C' or 'Vendor'
 lastupdate          date
);

create index bbb_route_rpt_sessionid_idx
 on bbb_route_rpt(sessionid);

create index bbb_route_rpt_lastupdate_idx
 on bbb_route_rpt(lastupdate);

create or replace package bbb_route_rpt_pkg
as type bbb_route_rpt_type is ref cursor return bbb_route_rpt%rowtype;

end bbb_route_rpt_pkg;
/

create or replace procedure bbb_route_rpt_proc
(bbb_route_rpt_cursor IN OUT bbb_route_rpt_pkg.bbb_route_rpt_type
,in_master_wave IN number)
as

l_sessionid number := 0;
l_count pls_integer := 0;
BRR bbb_route_rpt%rowtype := null;
l_order_count pls_integer;
l_carton_count pls_integer;
l_bbb_carton_uom custitem.baseuom%type;
l_custid customer.custid%type;
l_bbb_small_package_carrier carrier.carrier%type;
l_qtyorder orderhdr.qtyorder%type;
l_cubeorder orderhdr.cubeorder%type;
l_weightorder orderhdr.weightorder%type;
l_shipto orderhdr.shipto%type;
l_shipto_master orderhdr.shipto_master%type;
l_bbb_custid_template waves.bbb_custid_template%type;
l_bbb_routing_yn customer_aux.bbb_routing_yn%type;
l_wave_type bbb_route_rpt.wave_type%type;

begin

select sys_context('USERENV','SESSIONID')
 into l_sessionid
 from dual;

delete from bbb_route_rpt
 where sessionid = l_sessionid;
commit;

delete from bbb_route_rpt
 where lastupdate < trunc(sysdate);
commit;

select count(1)
  into l_count
  from bbb_route_rpt
 where lastupdate < sysdate;

if l_count = 0 then
  begin
    EXECUTE IMMEDIATE 'truncate table bbb_route_rpt';
  exception when others then
    null;
  end;
end if;

begin
  select bbb_custid_template
    into l_bbb_custid_template
    from waves
   where wave = in_master_wave;
exception when others then
  l_bbb_custid_template := '????';
end;

begin
  select bbb_small_package_carrier, bbb_routing_yn
    into l_bbb_small_package_carrier, l_bbb_routing_yn
    from customer_aux
   where custid = l_bbb_custid_template;
exception when others then
  l_bbb_small_package_carrier := '????';
  l_bbb_routing_yn := '?';
  l_wave_type := '??????';
end;

if l_bbb_routing_yn = 'V' then
  l_wave_type := 'Vendor';
elsif l_bbb_routing_yn = 'P' then
  l_wave_type := 'P and C';
end if;

for wv in (select wave
             from waves
            where master_wave = in_master_wave)
loop

  for ld in (select distinct nvl(loadno,0) as loadno,
                             nvl(stopno,0) as stopno,
                             fromfacility,
                             custid,
                             nvl(shipto_master,shipto) as shipto_master
               from orderhdr
              where wave = wv.wave)
  loop

    BRR.ld_shiptype := '?';
    BRR.ld_trailer := '';
    BRR.ld_billoflading := '';
    BRR.ld_carrier := '????';
    BRR.oh_custid := ld.custid;
    BRR.oh_fromfacility := ld.fromfacility;
    BRR.ls_shipto := ld.shipto_master;
    
    if ld.loadno = 0 then
      BRR.ld_shiptype := 'S';
      BRR.ld_carrier := l_bbb_small_package_carrier;
    else    
      begin
        select shiptype, trailer, billoflading, carrier
          into BRR.ld_shiptype, BRR.ld_trailer, BRR.ld_billoflading, BRR.ld_carrier
          from loads
         where loadno = ld.loadno;
      exception when others then
        null;
      end;
    end if;
    
    begin
      select abbrev
        into BRR.ld_shiptype_abbrev
        from shipmenttypes
       where code = BRR.ld_shiptype;
    exception when others then
      BRR.ld_shiptype_abbrev := BRR.ld_shiptype;
    end;
    
    if BRR.bbb_control_value is null then
      for oh in (select orderid,shipid,custid,fromfacility,shipto_master
                   from orderhdr
                  where wave = wv.wave
                    and nvl(shipto_master,shipto) = ld.shipto_master)
      loop
        BRR.bbb_control_value := zbbb.routing_control_value(oh.custid,oh.orderid,oh.shipid);
        exit;
      end loop;
    end if;

    if ld.loadno = 0 then
      l_order_count := 0;
      l_qtyorder := 0;
      l_cubeorder := 0;
      l_weightorder := 0;
      BRR.carton_count := 0;
      for oh in (select orderid,shipid,qtyorder,cubeorder,weightorder
                   from orderhdr
                  where wave = wv.wave
                    and nvl(shipto_master,shipto) = ld.shipto_master)
      loop
        l_order_count := l_order_count + 1;
        l_qtyorder := l_qtyorder + oh.qtyorder;
        l_cubeorder := l_cubeorder + oh.cubeorder;
        l_weightorder := l_weightorder + oh.weightorder;
        zbbb.compute_carton_count(oh.orderid,oh.shipid,null,'BBBROUTE',
                                  l_bbb_carton_uom,l_carton_count);
        BRR.carton_count := BRR.carton_count + l_carton_count;
      end loop;
      select count(1)
        into l_count
        from bbb_route_rpt
       where sessionid = l_sessionid
         and ld_loadno = 0
         and ld_stopno = 1
         and ld_shiptype = 'S'
         and ls_shipto = ld.shipto_master;
      if l_count = 0 then
        insert into bbb_route_rpt
         (sessionid,ld_loadno,ld_stopno,ld_shiptype,ld_shiptype_abbrev,ld_trailer,
          ld_billoflading,ld_carrier,ld_wave,ls_shipto,oh_custid,oh_fromfacility,
          bbb_control_value,order_count,carton_count,qtyorder,
          cubeorder,weightorder,lastupdate,wave_type)
         values
         (l_sessionid,ld.loadno,1,brr.ld_shiptype,brr.ld_shiptype_abbrev,
          brr.ld_trailer,brr.ld_billoflading,brr.ld_carrier,wv.wave,ld.shipto_master,
          brr.oh_custid,brr.oh_fromfacility,
          brr.bbb_control_value,l_order_count,
          brr.carton_count,l_qtyorder,l_cubeorder,l_weightorder,sysdate,l_wave_type);
      else
        update bbb_route_rpt
           set carton_count = carton_count + BRR.carton_count,
               order_count = order_count + l_order_count,
               qtyorder = qtyorder + l_qtyorder,
               cubeorder = cubeorder + l_cubeorder,
               weightorder = weightorder + l_weightorder
         where sessionid = l_sessionid
           and ld_loadno = 0
           and ld_stopno = 1
           and ld_shiptype = 'S'
           and ls_shipto = ld.shipto_master;
      end if;
    else
      for ls in (select stopno, shipto
                   from loadstop
                  where loadno = ld.loadno
                    and stopno = ld.stopno)
      loop

        l_order_count := 0;
        l_qtyorder := 0;
        l_cubeorder := 0;
        l_weightorder := 0;
        BRR.carton_count := 0;
        for oh in (select orderid,shipid,qtyorder,cubeorder,weightorder
                     from orderhdr
                    where loadno = ld.loadno
                      and stopno = ls.stopno
                      and wave = wv.wave
                      and nvl(shipto_master,shipto) = ld.shipto_master)
        loop
          l_order_count := l_order_count + 1;
          l_qtyorder := l_qtyorder + oh.qtyorder;
          l_cubeorder := l_cubeorder + oh.cubeorder;
          l_weightorder := l_weightorder + oh.weightorder;
          zbbb.compute_carton_count(oh.orderid,oh.shipid,null,'BBBROUTE',
                                    l_bbb_carton_uom,l_carton_count);
          BRR.carton_count := BRR.carton_count + l_carton_count;
          BRR.ls_shipto := ld.shipto_master;
        end loop;
        
        insert into bbb_route_rpt
         (sessionid,ld_loadno,ld_stopno,ld_shiptype,ld_shiptype_abbrev,ld_trailer,
          ld_billoflading,ld_carrier,ld_wave,ls_shipto,oh_custid,oh_fromfacility,
          bbb_control_value,order_count,carton_count,qtyorder,
          cubeorder,weightorder,lastupdate,wave_type)
         values
         (l_sessionid,ld.loadno,ls.stopno,brr.ld_shiptype,brr.ld_shiptype_abbrev,
          brr.ld_trailer,brr.ld_billoflading,brr.ld_carrier,wv.wave,
          ld.shipto_master,brr.oh_custid,brr.oh_fromfacility,
          brr.bbb_control_value,l_order_count,
          brr.carton_count,l_qtyorder,l_cubeorder,l_weightorder,sysdate,l_wave_type);
      
      end loop;
      
    end if;
    
  end loop;

end loop;

open bbb_route_rpt_cursor for
 select *
   from bbb_route_rpt
  where sessionid = l_sessionid
  order by ld_carrier, ld_loadno, ld_stopno desc, ls_shipto;
  
end bbb_route_rpt_proc;
/
show error procedure bbb_route_rpt_proc;

CREATE OR REPLACE PACKAGE Body bbb_route_rpt_pkg AS

end bbb_route_rpt_pkg;
/
show error package bbb_route_rpt_pkg;
show error package body bbb_route_rpt_pkg;
exit;
