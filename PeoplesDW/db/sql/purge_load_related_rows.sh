#!/bin/sh

IAM=`basename $0`

case $# in
5) ;;
*) echo "\nusage: $IAM <min_retention_year> <max_rows_to_purge>"
   echo "              <max_elapsed_hours> <fetch_limit> <update_yn>\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF

set serveroutput on;
set timing on;

declare

type loadno_tbl_type is table of loads.loadno%type;

loadno_tbl loadno_tbl_type;

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
cntPalletHistory integer := 0;
cntloadstopship integer := 0;
cntloads integer := 0;
cntloadstop integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select loadno
  from loads
 where loadstatus in ('9','R','X')
   and not exists
       (select 1
          from orderhdr
         where loads.loadno = orderhdr.loadno)
   and statusupdate < in_cutoff;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin load-related row purge...');
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

    fetch curPurgable bulk collect into loadno_tbl limit maxFetchLimit;

    if loadno_tbl.count = 0 then
      exit;
    end if;

    forall i in loadno_tbl.first .. loadno_tbl.last
      delete pallethistory
       where loadno = loadno_tbl(i);
    cntRows := sql%rowcount;
    cntPalletHistory := cntPalletHistory + cntRows;

    forall i in loadno_tbl.first .. loadno_tbl.last
      delete loadstopship
       where loadno = loadno_tbl(i);
    cntRows := sql%rowcount;
    cntloadstopship := cntloadstopship + cntRows;

    forall i in loadno_tbl.first .. loadno_tbl.last
      delete loadstop
       where loadno = loadno_tbl(i);
    cntRows := sql%rowcount;
    cntloadstop := cntloadstop + cntRows;

    forall i in loadno_tbl.first .. loadno_tbl.last
      delete loads
       where loadno = loadno_tbl(i);
    cntRows := sql%rowcount;
    cntloads := cntloads + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      commit;
      zms.log_autonomous_msg('PURGE', null, null,
          'Loads purged: ' || cntLoads, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('Loads count is ' || cntLoads);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntLoads >= maxRowcount then
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
      'Loads purged: ' || cntLoads, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('PalletHistory count ' || cntPalletHistory);
zut.prt('loadstopship count ' || cntloadstopship);
zut.prt('loadstop count ' || cntloadstop);
zut.prt('loads count ' || cntloads);
cntTotRowsPurged := cntpallethistory
                  + cntloadstopship
                  + cntloadstop
                  + cntloads;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end load-related row purge...');
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

