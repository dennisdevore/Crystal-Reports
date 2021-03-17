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

type asof_facility_tbl_type is table of asofvendor.facility%type;
asof_facility_tbl asof_facility_tbl_type;
type asof_custid_tbl_type is table of asofvendor.custid%type;
asof_custid_tbl asof_custid_tbl_type;
type asof_item_tbl_type is table of asofvendor.item%type;
asof_item_tbl asof_item_tbl_type;
type asof_lotnumber_tbl_type is table of asofvendor.lotnumber%type;
asof_lotnumber_tbl asof_lotnumber_tbl_type;
type asof_uom_tbl_type is table of asofvendor.uom%type;
asof_uom_tbl asof_uom_tbl_type;
type asof_invstatus_tbl_type is table of asofvendor.invstatus%type;
asof_invstatus_tbl asof_invstatus_tbl_type;
type asof_inventoryclass_tbl_type is table of asofvendor.inventoryclass%type;
asof_inventoryclass_tbl asof_inventoryclass_tbl_type;
type asof_useritem1_tbl_type is table of asofvendor.useritem1%type;
asof_useritem1_tbl asof_useritem1_tbl_type;
type asof_useritem2_tbl_type is table of asofvendor.useritem2%type;
asof_useritem2_tbl asof_useritem2_tbl_type;
type asof_useritem3_tbl_type is table of asofvendor.useritem3%type;
asof_useritem3_tbl asof_useritem3_tbl_type;
type asof_effdate_tbl_type is table of asofvendor.effdate%type;
asof_effdate_tbl asof_effdate_tbl_type;

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
cntasofvendor integer := 0;
cntasofvendordtl integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select facility,custid,item,lotnumber,uom,invstatus,inventoryclass,
       useritem1,useritem2,useritem3,effdate
  from asofvendor
 where effdate < in_cutoff;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin asofvendor-related row purge...');
zut.prt('min retention years is ' || minRetentionYears);
zut.prt('Purge limit is ' || maxRowCount);
zut.prt('Max wall hours ' || maxElapsedHours);
zut.prt('bulk collect fetch limit is ' || maxFetchLimit);
zut.prt('Update flag is ' || update_flag);

dteCutOff := trunc(sysdate) - (minRetentionYears * 365);

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
                                        asof_invstatus_tbl,
                                        asof_inventoryclass_tbl,
                                        asof_useritem1_tbl,
                                        asof_useritem2_tbl,
                                        asof_useritem3_tbl,
                                        asof_effdate_tbl
                                        limit maxFetchLimit;


    if asof_facility_tbl.count = 0 then
      exit;
    end if;

    forall i in asof_facility_tbl.first .. asof_facility_tbl.last
      delete asofvendordtl
       where facility = asof_facility_tbl(i)
         and custid = asof_custid_tbl(i)
         and item = asof_item_tbl(i)
         and nvl(lotnumber,'x') = nvl(asof_lotnumber_tbl(i),'x')
         and uom = asof_uom_tbl(i)
         and nvl(invstatus,'x') = nvl(asof_invstatus_tbl(i),'x')
         and nvl(inventoryclass,'x') = nvl(asof_inventoryclass_tbl(i),'x')
         and nvl(useritem1,'x') = nvl(asof_useritem1_tbl(i),'x')
         and nvl(useritem2,'x') = nvl(asof_useritem2_tbl(i),'x')
         and nvl(useritem3,'x') = nvl(asof_useritem3_tbl(i),'x')
         and nvl(effdate,'01-JAN-01') = nvl(asof_effdate_tbl(i),'01-JAN-01');
    cntRows := sql%rowcount;
    cntasofvendordtl := cntasofvendordtl + cntRows;

    forall i in asof_facility_tbl.first .. asof_facility_tbl.last
      delete asofvendor
       where facility = asof_facility_tbl(i)
         and custid = asof_custid_tbl(i)
         and item = asof_item_tbl(i)
         and nvl(lotnumber,'x') = nvl(asof_lotnumber_tbl(i),'x')
         and uom = asof_uom_tbl(i)
         and nvl(invstatus,'x') = nvl(asof_invstatus_tbl(i),'x')
         and nvl(inventoryclass,'x') = nvl(asof_inventoryclass_tbl(i),'x')
         and nvl(useritem1,'x') = nvl(asof_useritem1_tbl(i),'x')
         and nvl(useritem2,'x') = nvl(asof_useritem2_tbl(i),'x')
         and nvl(useritem3,'x') = nvl(asof_useritem3_tbl(i),'x')
         and nvl(effdate,'01-JAN-01') = nvl(asof_effdate_tbl(i),'01-JAN-01');

    cntRows := sql%rowcount;
    cntasofvendor := cntasofvendor + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      commit;
      zms.log_autonomous_msg('PURGE', null, null,
          'asofvendor purged: ' || cntasofvendor, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('asofvendor count is ' || cntasofvendor);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntasofvendor >= maxRowcount then
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
  zut.prt('begin commit');
  commit;
  zut.prt('end commit');
  zms.log_autonomous_msg('PURGE', null, null,
      'asofvendor purged: ' || cntasofvendor, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('asofvendordtl count ' || cntasofvendordtl);
zut.prt('asofvendor count ' || cntasofvendor);
cntTotRowsPurged := cntasofvendordtl
                  + cntasofvendor;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end asofvendor-related row purge...');
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

