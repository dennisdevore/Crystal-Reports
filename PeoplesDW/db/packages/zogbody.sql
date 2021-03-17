create or replace PACKAGE BODY alps.order_grouping
IS
--
-- $Id: zogbody.sql 4994 2010-04-27 12:54:46Z ed $
--
procedure group_orders
(in_orderid number
,in_shipid number
,in_validate_only_yn varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is

cursor curOrderhdr is
  select orderid,
         fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority,
         ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select custid, order_grouping_procedure
    from customer_aux
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curUserProcedure(in_procedure_name varchar2) is
  select procedure_name
    from user_procedures
   where object_name || '.' || procedure_name = in_procedure_name;
up curUserProcedure%rowtype;
 
l_cnt pls_integer;
l_cmd varchar2(4000);
   
begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -2;
  out_msg := 'Customer ' || oh.custid || ' not found for Order ' || in_orderid || '-' || in_shipid;
  return;
end if;

up := null;
open curUserProcedure(cu.order_grouping_procedure);
fetch curUserProcedure into up;
close curUserProcedure;
if up.procedure_name is null then
  out_errorno := -3;
  out_msg := 'Customer ' || oh.custid || ' procedure ' || cu.order_grouping_procedure ||
             ' not found for Order ' || in_orderid || '-' || in_shipid;
  return;
end if;

l_cmd := 'begin ' || cu.order_grouping_procedure || '(:in_orderid, :in_shipid, :in_validate_only_yn, ' ||
         ':in_userid, :out_errorno, :out_msg); end;';
execute immediate l_cmd
  using in_orderid, in_shipid, in_validate_only_yn, in_userid, IN OUT out_errorno, IN OUT out_msg;
  
exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end group_orders;

procedure group_by_item_and_qty
(in_orderid number
,in_shipid number
,in_validate_only_yn varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is

cursor curOrderhdr is
  select orderid,
         fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority,
         ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select custid, order_grouping_procedure
    from customer_aux
   where custid = in_custid;
cu curCustomer%rowtype;

l_length pls_integer;
l_item_data orderhdr.hdrpassthruchar01%type;
l_hdrpassthruchar orderhdr.hdrpassthruchar01%type;
   
begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

if nvl(in_validate_only_yn,'N') != 'N' then
  return;
end if;

l_hdrpassthruchar := '';
for od in (select item,qtyorder
             from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and linestatus != 'X'
            order by item)
loop

  l_item_data := rtrim(od.item) || to_char(od.qtyorder,'FM009');
  if l_hdrpassthruchar is not null then
    l_length := length(rtrim(l_hdrpassthruchar));
  else
    l_length := 0;
  end if;
  l_length := l_length + length(rtrim(l_item_data));
  if l_length <= 255 then
    l_hdrpassthruchar := l_hdrpassthruchar || l_item_data;
  end if;
  
end loop;

update orderhdr
   set hdrpassthruchar60 = l_hdrpassthruchar,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;
   
exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end group_by_item_and_qty;

end order_grouping;
/
show error package body order_grouping;
exit;
