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

type pi_tbl_type is table of physicalinventoryhdr.id%type;

pi_tbl pi_tbl_type;

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
cntphysicalinventoryhdr integer := 0;
cntphysicalinventorydtl integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select id
  from physicalinventoryhdr
 where status in ('CA','PR')
   and lastupdate < in_cutoff;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin pi-related row purge...');
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

    fetch curPurgable bulk collect into pi_tbl limit maxFetchLimit;

    if pi_tbl.count = 0 then
      exit;
    end if;

    forall i in pi_tbl.first .. pi_tbl.last
      delete physicalinventorydtl
       where id = pi_tbl(i);
    cntRows := sql%rowcount;
    cntphysicalinventorydtl := cntphysicalinventorydtl + cntRows;

    forall i in pi_tbl.first .. pi_tbl.last
      delete physicalinventoryhdr
       where id = pi_tbl(i);
    cntRows := sql%rowcount;
    cntphysicalinventoryhdr := cntphysicalinventoryhdr + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      commit;
      zms.log_autonomous_msg('PURGE', null, null,
          'physicalinventoryhdr purged: ' || cntphysicalinventoryhdr, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('PhysicalInventoryHdr count is ' || cntphysicalinventoryhdr);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntphysicalinventoryhdr >= maxRowcount then
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
      'physicalinventoryhdr purged: ' || cntphysicalinventoryhdr, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('physicalinventorydtl count ' || cntphysicalinventorydtl);
zut.prt('physicalinventoryhdr count ' || cntphysicalinventoryhdr);
cntTotRowsPurged := cntphysicalinventorydtl
                  + cntphysicalinventoryhdr;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end pi-related row purge...');
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
