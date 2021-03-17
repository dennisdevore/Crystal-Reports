#!/bin/sh

IAM=`basename $0`

case $# in
5) ;;
*) echo "\nusage: $IAM <min_retention_years> <max_rows_to_purge>"
   echo "              <max_elapsed_hours> <fetch_limit> <update_yn>\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF

set serveroutput on;
set timing on;

declare

type asof_facility_tbl_type is table of asofinventory.facility%type;
asof_facility_tbl asof_facility_tbl_type;
type asof_custid_tbl_type is table of asofinventory.custid%type;
asof_custid_tbl asof_custid_tbl_type;
type asof_item_tbl_type is table of asofinventory.item%type;
asof_item_tbl asof_item_tbl_type;
type asof_lotnumber_tbl_type is table of asofinventory.lotnumber%type;
asof_lotnumber_tbl asof_lotnumber_tbl_type;
type asof_uom_tbl_type is table of asofinventory.uom%type;
asof_uom_tbl asof_uom_tbl_type;
type asof_effdate_tbl_type is table of asofinventory.effdate%type;
asof_effdate_tbl asof_effdate_tbl_type;
type asof_invstatus_tbl_type is table of asofinventory.invstatus%type;
asof_invstatus_tbl asof_invstatus_tbl_type;
type asof_inventoryclass_tbl_type is table of asofinventory.inventoryclass%type;
asof_inventoryclass_tbl asof_inventoryclass_tbl_type;

minRetentionYears integer := ${1};
maxRowCount integer := ${2};
maxElapsedHours integer := ${3};
maxFetchLimit integer := ${4};
update_Flag char(1) := upper(nvl(substr('${5}',1,1),'N'));
maxElapsedDays number;
curRetentionYears integer := 10;
dteCutOff date;
dteBeginTime date;
cntRows integer := 0;
cntasofinventory integer := 0;
cntasofinventorydtl integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
cntPrevRowCount integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select facility,custid,item,lotnumber,uom,effdate,inventoryclass,invstatus
  from asofinventory
 where effdate < in_cutoff;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin asofinventory-related row purge...');
zut.prt('min retention years is ' || minRetentionYears);
zut.prt('Purge limit is ' || maxRowCount);
zut.prt('Max wall hours ' || maxElapsedHours);
zut.prt('bulk collect fetch limit is ' || maxFetchLimit);
zut.prt('Update flag is ' || update_flag);

while (curRetentionYears >= minRetentionYears)
loop

  dteCutOff := trunc(sysdate) - (curRetentionYears * 365);

  zut.prt('Cut Off Date is ' || dteCutOff);

  open curPurgable(dteCutOff);
  loop


    fetch curPurgable bulk collect into asof_facility_tbl,
                                        asof_custid_tbl,
                                        asof_item_tbl,
                                        asof_lotnumber_tbl,
                                        asof_uom_tbl,
                                        asof_effdate_tbl,
                                        asof_inventoryclass_tbl,
                                        asof_invstatus_tbl
                                        limit maxFetchLimit;

    if asof_facility_tbl.count = 0 then
      exit;
    end if;

    forall i in asof_facility_tbl.first .. asof_facility_tbl.last
      delete asofinventorydtl
       where facility = asof_facility_tbl(i)
         and custid = asof_custid_tbl(i)
         and item = asof_item_tbl(i)
         and nvl(lotnumber,'x') = nvl(asof_lotnumber_tbl(i),'x')
         and nvl(uom,'x') = nvl(asof_uom_tbl(i),'x')
         and nvl(effdate,'01-JAN-01') = nvl(asof_effdate_tbl(i),'01-JAN-01')
         and nvl(inventoryclass,'x') = nvl(asof_inventoryclass_tbl(i),'x')
         and nvl(invstatus,'x') = nvl(asof_invstatus_tbl(i),'x');
    cntRows := sql%rowcount;
    cntasofinventorydtl := cntasofinventorydtl + cntRows;

    forall i in asof_facility_tbl.first .. asof_facility_tbl.last
      delete asofinventory
       where facility = asof_facility_tbl(i)
         and custid = asof_custid_tbl(i)
         and item = asof_item_tbl(i)
         and nvl(lotnumber,'x') = nvl(asof_lotnumber_tbl(i),'x')
         and nvl(uom,'x') = nvl(asof_uom_tbl(i),'x')
         and nvl(effdate,'01-JAN-01') = nvl(asof_effdate_tbl(i),'01-JAN-01')
         and nvl(inventoryclass,'x') = nvl(asof_inventoryclass_tbl(i),'x')
         and nvl(invstatus,'x') = nvl(asof_invstatus_tbl(i),'x');

    cntRows := sql%rowcount;
    cntasofinventory := cntasofinventory + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin interim commit');
      commit;
      zut.prt('end interim commit');
      commit;
      zms.log_autonomous_msg('PURGE', null, null,
          'asofinventory purged: ' || cntasofinventory, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin interim rollback');
      rollback;
      zut.prt('end interim rollback');
    end if;

    zut.prt('asofinventory count is ' || cntasofinventory);

    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntasofinventory >= maxRowcount then
      zut.prt('Max purge count reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    exit when curPurgable%notfound;

  end loop;

  if curPurgable%isopen then
    close curPurgable;
  end if;

  curRetentionYears := curRetentionYears - 1;

end loop;

<< print_totals >>

if curPurgable%isopen then
  close curPurgable;
end if;

if update_flag = 'Y' then
  zut.prt('begin final commit');
  commit;
  zut.prt('end final commit');
  zms.log_autonomous_msg('PURGE', null, null,
      'asofinventory purged: ' || cntasofinventory, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin final rollback');
  rollback;
  zut.prt('end final rollback');
end if;

zut.prt('asofinventorydtl count ' || cntasofinventorydtl);
zut.prt('asofinventory count ' || cntasofinventory);
cntTotRowsPurged := cntasofinventorydtl
                  + cntasofinventory;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end asofinventory-related row purge...');
rollback;

exception when others then
  rollback;
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql

