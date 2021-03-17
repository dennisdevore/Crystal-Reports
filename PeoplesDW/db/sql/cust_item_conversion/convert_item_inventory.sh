#!/bin/bash
date
while IFS="|" read "OLD_ITEM" "OLD_NAME" "NEW_ITEM" "NEW_NAME"
do
  NEW_NAME=`echo ${NEW_NAME} | tr -d '\r'`
  echo ${OLD_ITEM} ${NEW_ITEM} ${NEW_NAME}
cat >/tmp/convert_item_inventory.$$.sql <<EOF
set serveroutput on;
set heading off;
set pagesize 0;
set linesize 32000;
set trimspool on;
set feedback off;

declare

cursor curPlates(in_custid varchar2, in_item varchar2) is
  select lpid,
         custid,
         item,
         nvl(inventoryclass,'RG') as inventoryclass,
         invstatus,
         lotnumber,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         location,
         expirationdate,
         manufacturedate,
         anvdate,
         unitofmeasure,
         quantity as qty,
         facility,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         orderid,
         shipid,
         type,
         parentlpid,
         weight,
         controlnumber,
         adjreason
    from plate
   where custid = in_custid
     and item = in_item
     and type = 'PA';

l_cnt pls_integer;
l_userid userheader.nameid%type := 'INVADJ';
l_old_custid customer.custid%type;
l_old_item custitem.item%type;
l_new_custid customer.custid%type;
l_new_item custitem.item%type;
out_adjrowid1 varchar2(255);
out_adjrowid2 varchar2(255);
cntRows pls_integer;
cntTot pls_integer;
cntErr pls_integer;
cntOky pls_integer;
qtyTot pls_integer;
qtyErr pls_integer;
qtyOky pls_integer;
l_suppress_edi_yn char(1);
l_outmsg varchar2(255);
l_msg varchar2(255);
l_custreference invadjactivity.custreference%type;
out_msg varchar2(255);
out_errorno pls_integer;

begin

l_old_custid := '1008';
l_old_item  := '${OLD_ITEM}';
l_new_custid := '511009';
l_new_item  := '${NEW_ITEM}';
l_suppress_edi_yn := 'Y';
l_custreference := 'Item Code Change';

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

select count(1)
  into l_cnt
  from custitem
 where custid = l_new_custid
   and item = l_new_item;
if l_cnt = 0 then
  l_msg := 'Item change from ' || 
         l_old_item ||
         ' to ' ||
         l_new_item || 
         '--new item is invalid';
  zms.log_autonomous_msg('INVADJ', null, l_new_custid,
                       l_msg, 'E', l_userid, l_outmsg);
  return;
end if;

for pl in curPlates(l_old_custid, l_old_item)
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + pl.qty;

  zia.inventory_adjustment
  (pl.lpid
  ,l_new_custid
  ,l_new_item
  ,pl.inventoryclass
  ,pl.invstatus
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.custid
  ,pl.item
  ,pl.inventoryclass
  ,pl.invstatus
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.facility
  ,'SG'
  ,l_userid
  ,'IC'
  ,pl.weight
  ,pl.weight
  ,pl.manufacturedate
  ,pl.manufacturedate
  ,pl.anvdate
  ,pl.anvdate
  ,out_adjrowid1
  ,out_adjrowid2
  ,out_errorno
  ,out_msg
  ,l_custreference
  ,'Y' -- in_tasks_ok
  ,l_suppress_edi_yn);

  if out_errorno != 0 then
    rollback;
    cntErr := cntErr + 1;
    qtyErr := qtyErr + pl.qty;
    l_msg := substr('LiP: ' || pl.lpid || ' ' || out_msg,1,255);
    zms.log_autonomous_msg('INVADJ', pl.facility, pl.custid,
                           l_msg, 'E', l_userid, l_outmsg);
  else
    commit;
    cntOky := cntOky + 1;
    qtyOky := qtyOky + pl.qty;
    if l_suppress_edi_yn = 'N' then
      if out_adjrowid1 is not null then
         zim6.check_for_adj_interface(out_adjrowid1,out_errorno,out_msg);
      end if;
      if out_adjrowid2 is not null then
         zim6.check_for_adj_interface(out_adjrowid2,out_errorno,out_msg);
      end if;
    end if;
  end if;

end loop;

l_msg := 'Item change from ' || 
         l_old_item ||
         ' to ' ||
         l_new_item || 
         ' Qty Total: ' || qtyTot ||
         ' Qty Error: ' || qtyErr ||
         ' Qty Okay: ' || qtyOky;
         
zms.log_autonomous_msg('INVADJ', null, l_new_custid,
                       l_msg, 'I', l_userid, l_outmsg);
         
exception when others then
  zut.prt('ex others ' || sqlerrm);
  zut.prt('others...');
end;
/
exit;
EOF
sqls @/tmp/convert_item_inventory.$$.sql
rm /tmp/convert_item_inventory.$$.sql
done < old_new_item.csv
date
