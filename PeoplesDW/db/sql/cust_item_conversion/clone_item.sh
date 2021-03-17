#!/bin/bash
date
while IFS="|" read "OLD_ITEM" "OLD_NAME" "NEW_ITEM" "NEW_NAME"
do
  NEW_NAME=`echo ${NEW_NAME} | tr -d '\r'`
  echo ${OLD_ITEM} ${NEW_ITEM} ${NEW_NAME}
cat >/tmp/clone_item.$$.sql <<EOF
set serveroutput on;
set heading off;
set pagesize 0;
set linesize 32000;
set trimspool on;
set feedback off;

declare
l_cnt pls_integer;
l_userid userheader.nameid%type := 'ITEMCLONE';
l_old_custid customer.custid%type;
l_old_item custitem.item%type;
l_new_custid customer.custid%type;
l_new_item custitem.item%type;
l_new_item_descr custitem.descr%type;

out_msg varchar2(255);

begin

l_old_custid := '1008';
l_old_item  := substr('${OLD_ITEM}',50);
l_new_custid := '511009';
l_new_item  := '${NEW_ITEM}';
if length(rtrim('${NEW_NAME}')) > 255 then
  dbms_output.put_line('Item ' || l_new_item || ' description "' || '${NEW_NAME}' || '" was truncated to 40 characters');
end if;
l_new_item_descr := substr('${NEW_NAME}',1,255);

zcl.clone_custitem(
l_old_custid,
l_old_item,
l_new_custid,
l_new_item,
null,
l_userid,
out_msg
);

if out_msg = 'OKAY' then
  update custitem
     set status = 'INAC'
   where custid = l_old_custid
     and item = l_old_item
     and status != 'INAC';
  update custitem
     set descr = l_new_item_descr
   where custid = l_new_custid
     and item = l_new_item
     and descr != l_new_item_descr;
  commit;
else
  rollback;
  dbms_output.put_line(l_old_item || ' ' || l_new_item || ' '  || out_msg);
end if;

exception when others then
  dbms_output.put_line(l_old_item || ' ' || l_new_item || ' ' || sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqls @/tmp/clone_item.$$.sql
rm /tmp/clone_item.$$.sql
done < old_new_item.csv
date
