#!/bin/sh

IAM=`basename $0`

case $# in
4) ;;
*) echo "\nusage: $IAM <min_retention_days> <max_rows_to_purge>"
   echo "              <fetch_limit> <update_yn>\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF

set serveroutput on;
set timing on;

declare

type wsdtlhistory_tbl_type is table of rowid;

wsdtlhistory_tbl wsdtlhistory_tbl_type;

minRetentionDays integer := ${1};
maxRowCount integer := ${2};
maxFetchLimit integer := ${3};
update_Flag char(1) := upper(nvl(substr('${4}',1,1),'N'));
dteCutOff date;
cntRows integer := 0;
cntTableHistory integer := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgableRecords(in_cutoff date) is
select rowid
  from worldshipdtlhistory
 where whenoccurred < in_cutoff;

begin

if minRetentionDays < 30 then
  zut.prt('Retention days value must be greater than or equal to 30');
  return;
end if;

zut.prt('begin WorldShipDtlHistory row purge...');
zut.prt('min retention days is ' || minRetentionDays);
zut.prt('Purge limit is ' || maxRowCount);
zut.prt('bulk collect fetch limit is ' || maxFetchLimit);
zut.prt('Update flag is ' || update_flag);

  dteCutOff := trunc(sysdate) - minRetentionDays;

  zut.prt('Cut Off Date is ' || dteCutOff);

  open curPurgableRecords(dteCutOff);
  loop
  
    fetch curPurgableRecords bulk collect into wsdtlhistory_tbl limit maxFetchLimit;

    if wsdtlhistory_tbl.count = 0 then
      exit;
    end if;

    forall i in wsdtlhistory_tbl.first .. wsdtlhistory_tbl.last
      delete worldshipdtlhistory
       where rowid = wsdtlhistory_tbl(i);
    cntRows := sql%rowcount;
    cntTableHistory := cntTableHistory + cntRows;

    if (cntRows) > 0 then
      if update_flag = 'Y' then
        zut.prt('begin commit');
        commit;
        zut.prt('end commit');
        zms.log_autonomous_msg('PURGE', null, null,
            'WorldShipDtlHistory purged: ' || cntTableHistory, 'I', 'PURGE', strOutMsg);
      else
        zut.prt('begin rollback');
        rollback;
        zut.prt('end rollback');
      end if;
    end if;

    zut.prt('WorldShipDtlHistory count is ' || cntTableHistory);

    if cntTableHistory >= maxRowcount then
      zut.prt('Max purge count reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    exit when curPurgableRecords%notfound;
  end loop;

  if curPurgableRecords%isopen then
    close curPurgableRecords;
  end if;

<< print_totals >>

if curPurgableRecords%isopen then
  close curPurgableRecords;
end if;

if update_flag = 'Y' then
  zut.prt('begin commit');
  commit;
  zut.prt('end commit');
  zms.log_autonomous_msg('PURGE', null, null,
      'WorldShipDtlHistory purged: ' || cntTableHistory, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('WorldShipDtlHistory count ' || cntTableHistory);
cntTotRowsPurged := cntTableHistory;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end WorldShipDtlHistory row purge...');
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

