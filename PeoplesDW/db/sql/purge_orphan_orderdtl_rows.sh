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

type orderid_table_type is table of orderhdr.orderid%type;
type shipid_table_type is table of orderhdr.shipid%type;

orderid_tbl orderid_table_type;
shipid_tbl shipid_table_type;

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
cntOrderHdrBolComments integer := 0;
cntOrderHistory integer := 0;
cntOrderHdrPassThrus integer := 0;
cntOrderDtl integer := 0;
cntOrderDtlBolComments integer := 0;
cntOrderDtlLine integer := 0;
cntOrderDtlPassThrus integer := 0;
cntOrderDtlRcpt integer := 0;
cntShippingPlate integer := 0;
cntorderlabor integer := 0;
cntmultishiphdr integer := 0;
cntmultishipdtl integer := 0;
cntasncartondtl integer := 0;
cntshippingaudit integer := 0;
cntElapsedDays number := 0;
cntTotRowsPurged integer := 0;
strMsg varchar2(255);
strOutMsg varchar2(255);

cursor curPurgable(in_cutoff date) is
select orderid,shipid
from
  (select distinct orderid,shipid
    from orderdtl
   where lastupdate < in_cutoff
     and not exists
  (select 1 from orderhdr
  where orderdtl.orderid = orderhdr.orderid
    and orderdtl.shipid = orderhdr.shipid)
    and lastupdate < in_cutoff)
where rownum <= maxRowCount;

begin

if minRetentionYears < 1 then
  zut.prt('Retention years value must be greater than or equal to 1');
  return;
end if;

maxElapsedDays := maxElapsedHours / 24;

dteBeginTime := sysdate;

zut.prt('begin orphan orderdtl row purge...');
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

    fetch curPurgable bulk collect into orderid_tbl, shipid_tbl limit maxFetchLimit;

    if orderid_tbl.count = 0 then
      exit;
    end if;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderdtlbolcomments
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderdtlbolcomments := cntorderdtlbolcomments + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderdtlline
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderdtlline := cntorderdtlline + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderdtlrcpt
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderdtlrcpt := cntorderdtlrcpt + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderdtlpassthrus
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderdtlpassthrus := cntorderdtlpassthrus + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderdtl
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderdtl := cntorderdtl + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete multishipdtl
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntmultishipdtl := cntmultishipdtl + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete multishiphdr
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntmultishiphdr := cntmultishiphdr + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderlabor
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderlabor := cntorderlabor + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete shippingaudit
       where lpid in (select fromlpid from shippingplate where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i));
    cntRows := sql%rowcount;
    cntshippingaudit := cntshippingaudit + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete shippingaudit
       where lpid in (select lpid from shippingplate where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i));
    cntRows := sql%rowcount;
    cntshippingaudit := cntshippingaudit + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete shippingplate
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntshippingplate := cntshippingplate + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete asncartondtl
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntasncartondtl := cntasncartondtl + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderhdrbolcomments
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntOrderHdrBolComments := cntOrderHdrBolComments + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderhistory
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderhistory := cntorderhistory + cntRows;

    forall i in orderid_tbl.first .. orderid_tbl.last
      delete orderhdrpassthrus
       where orderid = orderid_tbl(i)
         and shipid = shipid_tbl(i);
    cntRows := sql%rowcount;
    cntorderhdrpassthrus := cntorderhdrpassthrus + cntRows;

    if update_flag = 'Y' then
      zut.prt('begin commit');
      commit;
      zut.prt('end commit');
      zms.log_autonomous_msg('PURGE', null, null,
          'OrderDtl purged: ' || cntOrderDtl, 'I', 'PURGE', strOutMsg);
    else
      zut.prt('begin rollback');
      rollback;
      zut.prt('end rollback');
    end if;

    zut.prt('OrderDtl count is ' || cntOrderDtl);
    cntElapsedDays := sysdate - dteBeginTime;
    if cntElapsedDays >= maxElapsedDays then
      zut.prt('max elapsed wall time reached/exceeded-->terminating...');
      goto print_totals;
    end if;

    if cntOrderDtl >= maxRowcount then
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
      'OrderDtl purged: ' || cntOrderDtl, 'I', 'PURGE', strOutMsg);
else
  zut.prt('begin rollback');
  rollback;
  zut.prt('end rollback');
end if;

zut.prt('orderdtlbolcomments count ' || cntOrderDtlBolComments);
zut.prt('orderdtlline count ' || cntOrderDtlLine);
zut.prt('orderdtlrcpt count ' || cntOrderDtlRcpt);
zut.prt('orderDtlpassthrus count ' || cntOrderDtlPassThrus);
zut.prt('orderdtl count ' || cntOrderDtl);
zut.prt('multishipdtl count ' || cntmultishipdtl);
zut.prt('multishiphdr count ' || cntmultishiphdr);
zut.prt('orderlabor count ' || cntorderlabor);
zut.prt('shippingaudit count ' || cntshippingaudit);
zut.prt('shippingplate count ' || cntshippingplate);
zut.prt('asncartondtl count ' || cntasncartondtl);
zut.prt('orderhdrbolcomments count ' || cntOrderHdrBolComments);
zut.prt('orderhistory count ' || cntOrderHistory);
zut.prt('orderhdrpassthrus count ' || cntOrderHdrPassThrus);
cntTotRowsPurged := cntOrderHdrBolComments
                  + cntOrderHistory
                  + cntOrderHdrPassThrus
                  + cntOrderDtl
                  + cntOrderDtlBolComments
                  + cntOrderDtlLine
                  + cntOrderDtlPassThrus
                  + cntOrderDtlRcpt
                  + cntShippingPlate
                  + cntOrderLabor
                  + cntMultiShipHdr
                  + cntMultiShipDtl
                  + cntAsnCartonDtl
                  + cntShippingAudit;
zut.prt('total rows purged ' || cntTotRowsPurged);

zut.prt('end orphan orderdtl row purge...');
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

