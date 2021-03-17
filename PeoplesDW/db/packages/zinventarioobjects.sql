drop table inventariorpt;

create table inventariorpt
(sessionid         number
,orderid           number(9)
,shipid            number(2)
,po                varchar2(20)
,arrivaldate       date
,hdrpassthruchar02 varchar2(255)
,hdrpassthruchar08 varchar2(255)
,hdrpassthruchar14 varchar2(255)
,hdrpassthrunum01  number(16,4)
,hdrpassthrudate01 date
,inpallets         number(7)
,item              varchar2(50)
,qtyrcvd           number(10)
,qtyrcvdgood       number(10)
,qtyrcvddmgd       number(10)
,ob_orderid        number(9)
,ob_shipid         number(2)
,qtyship           number(10)
,trailer           varchar2(12)
,loadno            number(7)
,ldpassthruchar37  varchar2(255)
,dateshipped       date
,location          varchar2(10)
,outpallets        number(7)
,outpallets_noheat number(7)
,linenumber        number(2)
,lastupdate      date
);

create index inventariorpt_lastupdate_idx
 on inventariorpt(lastupdate);

create or replace package inventariorptpkg
as type ir_type is ref cursor return inventariorpt%rowtype;
	function ib_field
		(in_orderid IN number
		,in_shipid IN number
		,in_item IN varchar2
		,in_fieldname IN varchar2)
  return varchar2;
end inventariorptpkg;
/

--
-- $Id$
--

create or replace procedure inventariorptPROC
(ir_cursor IN OUT inventariorptpkg.ir_type
,in_custid IN varchar2
,in_item IN varchar2
,in_loadno IN varchar2
,in_orderid IN varchar2
,in_shipid IN varchar2
,in_startdate IN date
,in_enddate IN date
,in_datetype IN varchar2)
as

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curCustItem is
  select item
    from custitem
   where custid = in_custid
     and item = nvl(in_item,item)
     and rownum = 1;
cit curCustItem%rowtype;

cursor curOrders is
  select oh.orderid,
         oh.shipid
    from orderhdr oh, orderdtl od, orderdtlrcpt odr, loads ld
   where oh.custid = in_custid
     and oh.ordertype = 'R'
     and oh.orderstatus = 'R'
     and oh.loadno = nvl(to_number(in_loadno), oh.loadno)
     and oh.orderid = nvl(to_number(in_orderid), oh.orderid)
     and oh.shipid = nvl(to_number(in_shipid), oh.shipid)
     and ld.loadno = oh.loadno
     and trunc(ld.rcvddate) between trunc(in_startdate) and trunc(in_enddate)
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = nvl(in_item, od.item)
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
   union
  select pl.orderid,
         pl.shipid
    from plate pl
   where pl.lpid in(
    select sp.fromlpid
      from orderhdr oh, shippingplate sp
     where oh.custid = in_custid
       and oh.ordertype = 'O'
       and oh.orderstatus = '9'
       and oh.loadno = nvl(to_number(in_loadno), oh.loadno)
       and oh.orderid = nvl(to_number(in_orderid), oh.orderid)
       and oh.shipid = nvl(to_number(in_shipid), oh.shipid)
       and trunc(oh.dateshipped) between trunc(in_startdate) and trunc(in_enddate)
       and nvl(in_datetype,'A') <> 'R'
       and sp.orderid = oh.orderid
       and sp.shipid = oh.shipid
       and sp.status = 'SH'
       and sp.item = nvl(in_item, sp.item))
     and pl.orderid is not null
     and pl.shipid is not null
     and pl.loadno is not null
   union
  select pl.orderid,
         pl.shipid
    from deletedplate pl
   where pl.lpid in(
    select sp.fromlpid
      from orderhdr oh, shippingplate sp
     where oh.custid = in_custid
       and oh.ordertype = 'O'
       and oh.orderstatus = '9'
       and oh.loadno = nvl(to_number(in_loadno), oh.loadno)
       and oh.orderid = nvl(to_number(in_orderid), oh.orderid)
       and oh.shipid = nvl(to_number(in_shipid), oh.shipid)
       and trunc(oh.dateshipped) between trunc(in_startdate) and trunc(in_enddate)
       and nvl(in_datetype,'A') <> 'R'
       and sp.orderid = oh.orderid
       and sp.shipid = oh.shipid
       and sp.status = 'SH'
       and sp.item = nvl(in_item, sp.item))
     and pl.orderid is not null
     and pl.shipid is not null
     and pl.loadno is not null;
co curOrders%rowtype;

cursor curRcptInfo(in_orderid IN number, in_shipid IN number) is
  select oh.loadno,
         oh.po,
         oh.hdrpassthruchar02,
         oh.hdrpassthruchar08,
         oh.hdrpassthruchar14,
         trunc(oh.hdrpassthrudate01) hdrpassthrudate01,
         oh.hdrpassthrunum01,
         trunc(ld.rcvddate) rcvddate,
         ld.ldpassthruchar37,
         odr.item,
         sum(odr.qtyrcvd) qtyrcvd,
         sum(odr.qtyrcvdgood) qtyrcvdgood,
         sum(odr.qtyrcvddmgd) qtyrcvddmgd
    from orderhdr oh, orderdtlrcpt odr, loads ld
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and ld.loadno = oh.loadno
     and odr.orderid = oh.orderid
     and odr.shipid = oh.shipid
     and odr.item = nvl(in_item, odr.item)
   group by oh.loadno,
         oh.po,
         oh.hdrpassthruchar02,
         oh.hdrpassthruchar08,
         oh.hdrpassthruchar14,
         trunc(oh.hdrpassthrudate01),
         oh.hdrpassthrunum01,
         trunc(ld.rcvddate),
         ld.ldpassthruchar37,
         odr.item;
cri curRcptInfo%rowtype;

cursor curPalletsIn(in_orderid IN number, in_shipid IN number) is
  select sum(inpallets) inpallets
    from pallethistory
   where orderid = in_orderid
     and shipid = in_shipid;
cpi curPalletsIn%rowtype;

cursor curShipInfo(in_orderid IN number, in_shipid IN number, in_item IN varchar2) is
  select oh.orderid,
         oh.shipid,
         oh.hdrpassthrunum01,
         oh.hdrpassthrudate01,
         oh.loadno,
         ld.ldpassthruchar37,
         ld.trailer,
         oh.dateshipped,
         sum(nvl(quantity,0)) quantity
    from orderhdr oh, shippingplate sp, loads ld
   where sp.fromlpid in
   (select lpid
      from plate
     where orderid = in_orderid
       and shipid = in_shipid
     union
    select lpid
      from deletedplate
     where orderid = in_orderid
       and shipid = in_shipid)
     and oh.orderstatus = '9'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
     and sp.status = 'SH'
     and sp.item = nvl(in_item, sp.item)
     and oh.loadno = ld.loadno(+)
   group by oh.orderid,
         oh.shipid,
         oh.hdrpassthrunum01,
         oh.hdrpassthrudate01,
         oh.loadno,
         ld.ldpassthruchar37,
         ld.trailer,
         oh.dateshipped;
csi curShipInfo%rowtype;
       
cursor curLocation(in_orderid IN number, in_shipid IN number, in_item IN varchar2) is
  select pickedfromloc
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and status = 'SH'
     and nvl(pickedfromloc,'(none)') != '(none)';
cl curLocation%rowtype;
       
cursor curPalletsOut(in_orderid IN number, in_shipid IN number) is
  select sum(outpallets) outpallets,
         sum(decode(pallettype,'NOHEAT',outpallets,0)) outpallets_noheat
    from pallethistory
   where (orderid,shipid) in
   (select oh.orderid,oh.shipid
      from orderhdr oh, shippingplate sp
     where sp.fromlpid in
     (select lpid
        from plate
       where orderid = in_orderid
         and shipid = in_shipid
       union
      select lpid
        from deletedplate
       where orderid = in_orderid
         and shipid = in_shipid)
       and oh.orderstatus = '9'
       and sp.orderid = oh.orderid
       and sp.shipid = oh.shipid
       and sp.status = 'SH'
       and sp.item = nvl(in_item, sp.item));
cpo curPalletsOut%rowtype;

numSessionId number;
dtlCount number;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from inventariorpt
where sessionid = numSessionId;
commit;

delete from inventariorpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from inventariorpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table inventariorpt';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

if nvl(cu.custid,'(none)') = '(none)' then
  goto end_proc;
end if;

cit := null;
open curCustItem;
fetch curCustItem into cit;
close curCustItem;

if nvl(cit.item,'(none)') = '(none)' then
  goto end_proc;
end if;

for co in curOrders
loop
	open curPalletsIn(co.orderid, co.shipid);
	fetch curPalletsIn into cpi;
	close curPalletsIn;
	
	open curPalletsOut(co.orderid, co.shipid);
	fetch curPalletsOut into cpo;
	close curPalletsOut;
	
  for cri in curRcptInfo(co.orderid, co.shipid)
  loop
    dtlCount := 1;
    for csi in curShipInfo(co.orderid, co.shipid, cri.item)
    loop
    	open curLocation(csi.orderid, csi.shipid, cri.item);
    	fetch curLocation into cl;
    	close curLocation;
    	
     	insert into inventariorpt
     	values (numSessionId,
              co.orderid,
              co.shipid,
              cri.po,
              cri.rcvddate,
              cri.hdrpassthruchar02,
              cri.hdrpassthruchar08,
              cri.hdrpassthruchar14,
              csi.hdrpassthrunum01,
              csi.hdrpassthrudate01,
              nvl(cpi.inpallets,0),
              cri.item,
              nvl(cri.qtyrcvd,0),
              nvl(cri.qtyrcvdgood,0),
              nvl(cri.qtyrcvddmgd,0),
              csi.orderid,
              csi.shipid,
              nvl(csi.quantity,0),
              csi.trailer,
              csi.loadno,
              csi.ldpassthruchar37,
              csi.dateshipped,
              cl.pickedfromloc,
              nvl(cpo.outpallets,0),
              nvl(cpo.outpallets_noheat,0),
              dtlCount,
              sysdate);
      dtlCount := dtlCount + 1;
    end loop;
  end loop;
  commit;
end loop;

commit;

<< end_proc >>

open ir_cursor for
select *
   from inventariorpt
  where sessionid = numSessionId;

end inventariorptPROC;
/


create or replace package body inventariorptpkg
as

function ib_field
		(in_orderid IN number
		,in_shipid IN number
		,in_item IN varchar2
		,in_fieldname IN varchar2)
  return varchar2 is

strTFField varchar2(255);

begin
strTFField := null;

if(upper(in_fieldname) in ('TRAILER',
                           'LOADNO',
                           'HDRPASSTHRUNUM01',
                           'HDRPASSTHRUDATE01',
                           'LDPASSTHRUCHAR37',
                           'DATESHIPPED')) then
  select substr (sys_connect_by_path (order_field, ','), 2) csv
    into strTFField
    from (select order_field,
                 row_number () over (order by order_field ) rn,
                 count (1) over () cnt
            from (select distinct decode(upper(in_fieldname),
                                         'TRAILER', ld.trailer,
                                         'LOADNO', to_char(decode(nvl(oh.loadno,0),0,null,oh.loadno)),
                                         'HDRPASSTHRUNUM01', to_char(decode(nvl(oh.hdrpassthrunum01,0),0,null,oh.hdrpassthrunum01)),
                                         'HDRPASSTHRUDATE01', to_char(oh.hdrpassthrudate01,'MM/DD/YYYY'),
                                         'LDPASSTHRUCHAR37', ld.ldpassthruchar37,
                                         'DATESHIPPED', to_char(oh.dateshipped,'MM/DD/YYYY'),
                                         null) order_field
                    from orderhdr oh, loads ld
                   where (oh.orderid, oh.shipid) in
                   (select sp.orderid, sp.shipid
                      from shippingplate sp
                     where sp.fromlpid in
                     (select pl.lpid
                        from plate pl
                       where pl.orderid = in_orderid
                         and pl.shipid = in_shipid
                         and pl.item = in_item
                       union
                      select pl.lpid
                        from deletedplate pl
                       where pl.orderid = in_orderid
                         and pl.shipid = in_shipid
                         and pl.item = in_item)
                       and sp.status = 'SH')
                     and oh.orderstatus = '9'
                     and oh.loadno = ld.loadno(+))
           order by 1)
   where rn = cnt
   start with rn = 1
  connect by rn = prior rn + 1;
elsif(upper(in_fieldname) = 'LOCATION') then
  select substr (sys_connect_by_path (order_field, ','), 2) csv
    into strTFField
    from (select order_field,
                 row_number () over (order by order_field ) rn,
                 count (1) over () cnt
            from (select distinct decode(upper(in_fieldname),
                                         'LOCATION',pl.location,
                                         null) order_field
                    from plate pl
                   where pl.orderid = in_orderid
                     and pl.shipid = in_shipid
                     and pl.item = in_item)
           order by 1)
   where rn = cnt
   start with rn = 1
  connect by rn = prior rn + 1;
end if;

return strTFField;
exception when others then
  return '';
end ib_field;

end inventariorptpkg;
/
show errors package inventariorptpkg;
exit;
