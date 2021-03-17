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

type plate_tbl_type is table of plate.lpid%type;

plate_tbl plate_tbl_type;

minRetentionYears integer := ${1};
maxRowCount integer := ${2};
maxElapsedHours integer := ${3};
maxFetchLimit integer := ${4};
update_flag char(1) := upper(nvl(substr('${5}',1,1),'N'));
maxElapsedDays number;
curRetentionYears integer := 10;
dteCutOff date;
dteBeginTime date;
cntRows integer := 0;
cntplatehistory integer := 0;
cntdeletedplate integer := 0;
cntinvadjactivity integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select lpid
  from deletedplate
 where lastupdate < in_cutoff;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

dteCutOff := trunc(sysdate) - (minRetentionYears * 365);
maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin deletedplate row purge...');
zut.prt('min retention years is ' || minRetentionYears);
zut.prt('Plate limit is ' || maxRowCount);
zut.prt('Max wall hours ' || maxElapsedHours);
zut.prt('bulk collect fetch limit is ' || maxFetchLimit);
zut.prt('Update flag is ' || update_flag);

while (curRetentionYears >= minRetentionYears)
loop

  dteCutOff := trunc(sysdate) - (curRetentionYears * 365);

  zut.prt('Cut Off Date is ' || dteCutOff);

  open curPurgable(dteCutOff);
  loop

    fetch curPurgable bulk collect into plate_tbl limit maxFetchLimit;

    if plate_tbl.count = 0 then
      exit;
    end if;

    forall i in plate_tbl.first .. plate_tbl.last
      delete platehistory
       where lpid = plate_tbl(i);
    cntRows := sql%rowcount;
    cntplatehistory := cntplatehistory + cntRows;

    forall i in plate_tbl.first .. plate_tbl.last
      delete invadjactivity
       where lpid = plate_tbl(i);
    cntRows := sql%rowcount;
    cntinvadjactivity := cntinvadjactivity + cntRows;

    forall i in plate_tbl.first .. plate_tbl.last
      delete deletedplate
       where lpid = plate_tbl(i);
    cntRows := sql%rowcount;
    cntdeletedplate := cntdeletedplate + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      commit;
      zms.log_autonomous_msg('PURGE', null, null,
          'DeletedPlates purged: ' || cntDeletedPlate, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('Deleted plate count is ' || cntDeletedPlate);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntDeletedPlate >= maxRowcount then
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
      'DeletedPlates purged: ' || cntDeletedPlate, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('platehistory count ' || cntplatehistory);
zut.prt('deletedplate count ' || cntdeletedplate);
zut.prt('invadjactivity count ' || cntinvadjactivity);
cntTotRowsPurged := cntplatehistory
                  + cntdeletedplate
                  + cntinvadjactivity;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end deletedplate row purge...');
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

