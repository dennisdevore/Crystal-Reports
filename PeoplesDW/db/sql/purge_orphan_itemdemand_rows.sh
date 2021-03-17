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

type rowid_table_type is table of rowid;

rowid_tbl rowid_table_type;

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
cntitemdemand integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select rowid
from
  (select rowid
    from itemdemand
   where (demandtype = 'O' and not exists
          (select 1 from orderhdr
          where itemdemand.orderid = orderhdr.orderid
            and itemdemand.shipid = orderhdr.shipid))
      or lastupdate < in_cutoff
  )
where rownum <= maxRowCount;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin orphan itemdemand row purge...');
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

    fetch curPurgable bulk collect into rowid_tbl limit maxFetchLimit;

    if rowid_tbl.count = 0 then
      exit;
    end if;

    forall i in rowid_tbl.first .. rowid_tbl.last
      delete itemdemand
       where rowid = rowid_tbl(i);
    cntRows := sql%rowcount;
    cntitemdemand := cntitemdemand + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      zms.log_autonomous_msg('PURGE', null, null,
          'itemdemand purged: ' || cntitemdemand, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('itemdemand count is ' || cntitemdemand);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntitemdemand >= maxRowcount then
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
      'itemdemand purged: ' || cntitemdemand, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('itemdemand count ' || cntitemdemand);
cntTotRowsPurged := cntitemdemand;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end orphan itemdemand row purge...');
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

