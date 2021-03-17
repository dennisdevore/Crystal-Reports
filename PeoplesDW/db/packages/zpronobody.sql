create or replace PACKAGE BODY alps.zpronumber
IS
--
-- $Id$
--

FUNCTION unused_prono_count
(in_carrier IN varchar2
,in_zone IN varchar2
) return number

is

cntUnused number(12);

begin

cntUnused := 0;
select count(1)
  into cntUnused
  from carrierprono
 where carrier = in_carrier
   and zone = in_zone
   and assign_status = 'U';

return cntUnused;

exception when others then
  return 0;
end unused_prono_count;

FUNCTION max_prono_seq
(in_carrier IN varchar2
,in_zone IN varchar2
) return number

is

maxSeq number(12);

begin

maxSeq := 0;
select nvl(max(seq),0)
  into maxSeq
  from carrierprono
 where carrier = in_carrier
   and zone = in_zone;

return maxSeq;

exception when others then
  return 0;
end max_prono_seq;

PROCEDURE cancel_prono
(in_carrier  IN varchar2
,in_zone     IN varchar2
,in_seq      IN number
,in_prono    IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)
is

cursor curProNo is
  select carrier,zone, seq,prono,assign_status
    from carrierprono
   where carrier = in_carrier
     and zone = in_zone
     and seq = in_seq;
pn curProNo%rowtype;

begin

out_errorno := 0;
out_msg := '';

pn := null;
open curProNo;
fetch curProNo into pn;
close curProNo;

if pn.carrier is null then
  out_errorno := -1;
  out_msg := 'Cannot cancel--ProNo not found: ' || in_prono;
  return;
end if;

if in_zone != pn.zone then
  out_errorno := -5;
  out_msg := 'Cannot cancel -- Zone mismatch: ' || in_zone || ' / ' || pn.zone;
  return;
end if;

if in_prono != pn.prono then
  out_errorno := -2;
  out_msg := 'Cannot cancel--ProNo mistmatch: ' || in_prono || '/' || pn.prono;
  return;
end if;

if pn.assign_status != 'U' then
  out_errorno := -3;
  out_msg := 'Cannot cancel ' || in_prono || '--status must be ''U''nused';
  return;
end if;

update carrierprono
   set assign_status = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
 where carrier = in_carrier
   and zone = in_zone
   and seq = in_seq;

if sql%rowcount = 1 then
  out_errorno := 1;
  out_msg := 'ProNo ' || in_prono || ' was successfully cancelled';
else
  out_errorno := -4;
  out_msg := 'Unable to cancel ' || in_prono;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end cancel_prono;

PROCEDURE undo_cancel_prono
(in_carrier  IN varchar2
,in_zone     IN varchar2
,in_seq      IN number
,in_prono    IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)
is

cursor curProNo is
  select carrier,zone,seq,prono,assign_status
    from carrierprono
   where carrier = in_carrier
     and zone = in_zone
     and seq = in_seq;
pn curProNo%rowtype;

begin

out_errorno := 0;
out_msg := '';

pn := null;
open curProNo;
fetch curProNo into pn;
close curProNo;

if pn.carrier is null then
  out_errorno := -1;
  out_msg := 'Cannot undo cancellation--ProNo not found: ' || in_prono;
  return;
end if;

if in_prono != pn.prono then
  out_errorno := -2;
  out_msg := 'Cannot undo cancellation--ProNo mistmatch: ' || in_prono || '/' || pn.prono;
  return;
end if;

if pn.assign_status != 'X' then
  out_errorno := -3;
  out_msg := 'Cannot undo cancellation ' || in_prono || '--status must be ''X''-Cancelled';
  return;
end if;

update carrierprono
   set assign_status = 'U',
       lastuser = in_userid,
       lastupdate = sysdate
 where carrier = in_carrier
   and zone = in_zone
   and seq = in_seq;

if sql%rowcount = 1 then
  out_errorno := 1;
  out_msg := 'ProNo ' || in_prono || ' was successfully set back to unused';
else
  out_errorno := -4;
  return;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end undo_cancel_prono;

PROCEDURE check_for_prono_assignment
(in_orderid  IN number
,in_shipid   IN number
,in_event    IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)

is

cursor curOrderHdr is
  select orderid,shipid,custid,
         decode(nvl(oh.loadno,0),0,oh.carrier,nvl(ld.carrier,oh.carrier)) as carrier,
         oh.prono as prono,
         ordertype,
         nvl(oh.loadno,0) as loadno,
         wave,
         fromfacility
    from loads ld, orderhdr oh
   where orderid = in_orderid
     and shipid = in_shipid
     and oh.loadno = ld.loadno(+);
oh curOrderHdr%rowtype;

cursor curCustCarrierProno(in_custid varchar2, in_carrier varchar2,
  in_event varchar2) is
  select custid
    from custcarrierprono
   where custid = in_custid
     and carrier = in_carrier
     and event = in_event;
ccp curCustCarrierProno%rowtype;

cursor curCustomer(in_custid varchar2) is
  select prono_summary_column
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacilityCarrierPronoZone(in_facility varchar2, in_carrier varchar2) is
  select zone
    from facilitycarrierpronozone
    where facility = in_facility
      and carrier = in_carrier;
cz curFacilityCarrierPronoZone%rowtype;

cursor curCarrierProNo(in_carrier varchar2, in_zone varchar2) is
  select prono,seq,rowid
    from carrierprono
   where carrier = in_carrier
     and zone = in_zone
     and assign_status = 'U'
   order by seq;
cpn curCarrierProNo%rowtype;

cmdSql varchar2(4000);
curSql integer;
cntRows integer;
strValue varchar2(255);
strMsg varchar2(255);
strDebugYN char(1);
l_event custcarrierprono.event%type;

procedure debugmsg(in_text varchar2) is

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

if in_event = 'Wave Unrelease' then
  if rtrim(oh.prono) is null then
    out_errorno := -2;
    out_msg := 'Pro Number already deassigned: ' || in_orderid || '-' || in_shipid ||
      ' (' || oh.prono || ')';
    return;
  end if;
else
  if rtrim(oh.prono) is not null then
    out_errorno := -3;
    out_msg := 'Pro Number already assigned: ' || in_orderid || '-' || in_shipid ||
      ' (' || oh.prono || ')';
    return;
  end if;
end if;

if oh.ordertype not in ('O','V','T','U') then
  out_errorno := -4;
  out_msg := 'Not an outbound order: ' || in_orderid || '-' || in_shipid ||
              ' (' || oh.ordertype || ')';
  return;
end if;

ccp := null;
if in_event = 'LoadCloseCheck' then
  l_event := 'Load Close';
else
  l_event := in_event;
end if;
open curCustCarrierProNo(oh.custid,oh.carrier,l_event);
fetch curCustCarrierProNo into ccp;
close curCustCarrierProNo;
if ccp.custid is null then
  out_errorno := -5;
  out_msg := 'Auto Pro Number Assignment not configured: ' || in_orderid || '-' || in_shipid ||
   ' (Customer: ' || oh.custid || ' Carrier: ' || oh.carrier ||
   ' Event: ' || in_event || ')';
  return;
end if;

if in_event = 'Wave Unrelease' then
  update orderhdr
     set prono = null
   where orderid = in_orderid
     and shipid = in_shipid;
  return;
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;

if in_event = 'Wave Release' then
  if oh.wave = 0 then
    out_errorno := 4;
    out_msg := 'Order not assigned to wave: ' || in_orderid || '-' || in_shipid;
    return;
  end if;
end if;

if cu.prono_summary_column is not null then
  execute immediate
    'select to_char(nvl(' || cu.prono_summary_column || ',''0'')) from orderhdr where orderid = ' ||
      oh.orderid || ' and shipid = ' || oh.shipid
      into strValue;
  debugmsg('Summary column value is ' || strValue);
  cmdSql := cmdSql || ' and to_char(nvl(' || cu.prono_summary_column ||
    ',''0'')) = ''' || strValue || '''';
end if;

cz := null;
open curFacilityCarrierPronoZone(oh.fromfacility,oh.carrier);
fetch curFacilityCarrierPronoZone into cz;
close curFacilityCarrierPronoZone;
if cz.zone is null then
  out_errorno := -6;
  out_msg := 'Carrier ' || oh.carrier || ': No Zone available for Facility '|| oh.fromfacility;
  return;
end if;

cpn := null;
open curCarrierProNo(oh.carrier,cz.zone);
fetch curCarrierProNo into cpn;
close curCarrierProNo;
if cpn.prono is null then
  out_errorno := -7;
  out_msg := 'Carrier ' || oh.carrier || ': No Pro Number available for Order ' ||
    oh.orderid || '-' || oh.shipid;
  zms.log_msg('PRONO', oh.fromfacility, oh.custid,
    out_msg, 'E', 'PRONO', strMsg);
  return;
end if;

if in_event = 'LoadCloseCheck' then
  return;
end if;

update carrierprono
   set assign_status = 'A',
       assign_time = sysdate,
       assign_orderid = oh.orderid,
       assign_shipid = oh.shipid
 where rowid = cpn.rowid;
cntRows := sql%rowcount;
debugmsg('carrierprono update count is ' || cntRows);
oh.prono := cpn.prono;

cmdSql := 'update orderhdr set prono = ''' || oh.prono || ''' where ';
if in_event = 'Wave Release' then
  cmdSql := cmdSql || 'wave = ' || oh.wave;
else
  if oh.loadno = 0 then
    cmdSql := cmdSql || 'orderid = ' || oh.orderid ||
     ' and shipid = ' || oh.shipid;
  else
    cmdSql := cmdSql || 'loadno = ' || oh.loadno;
  end if;
end if;

if cu.prono_summary_column is not null then
  cmdSql := cmdSql || ' and to_char(nvl(' || cu.prono_summary_column ||
   ',''0'')) = ''' || strValue || '''';
end if;

cmdSql := cmdSql || ' and rtrim(prono) is null';

debugmsg(cmdSql);
zms.log_msg('PRONO', oh.fromfacility, oh.custid, cmdSql, 'E', 'PRONO', strMsg);
execute immediate cmdSql;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
  zms.log_msg('PRONO', oh.fromfacility, oh.custid, out_errorno||' - '||out_msg, 'E', 'PRONO', strMsg);
end check_for_prono_assignment;

PROCEDURE assign_pallet_defaults
(in_loadno   IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)
is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor curCustomers is
  select distinct OH.custid,
         nvl(CU.defpalletqty, 0) as defpalletqty,
         nvl(CU.defpallettype,'?') as defpallettype
    from customer CU, orderhdr OH
    where OH.loadno = in_loadno
      and OH.custid = CU.custid
      and CU.defpalletqty > 0;

cursor curMinOrderByWave(in_custid varchar2) is
  select wave,
         min(orderid) as orderid
    from orderhdr
   where loadno = in_loadno
     and custid = in_custid
   group by wave
   order by wave;

cursor curOrderHdr(in_orderid number) is
  select shipid,
         ordertype,
         carrier,
         fromfacility,
         tofacility,
         orderid,
         custid
    from orderhdr
    where orderid = in_orderid
      and loadno = in_loadno
    order by shipid;
oh curOrderHdr%rowtype;

ohcount integer;
incount integer;
outcount integer;
usefacility orderhdr.fromfacility%type;
usecarrier orderhdr.carrier%type;
adjrsn pallethistory.adjreason%type;
l_date date;
l_cnt pls_integer;

begin

out_msg := '';
out_errorno := 0;
adjrsn := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  out_errorno := -1;
  return;
end if;
close Cloads;

select count(1)
  into ohcount
  from orderhdr
 where loadno = in_loadno
   and orderstatus != 'X';

if ohcount = 0 then
  out_msg := 'No open orders are assigned to this load';
  out_errorno := -3;
  return;
end if;

if (substr(ld.loadtype,1,1) = 'I') then
  adjrsn := 'Inbound';
else
  adjrsn := 'Outbound';
end if;

for cu in curCustomers
loop

  for min_oh in curMinOrderByWave(cu.custid)
  loop

    oh := null;
    open curOrderHdr(min_oh.orderid);
    fetch curOrderHdr into oh;
    close curOrderHdr;

    usefacility := '';
    if (oh.ordertype in ('R','Q','C','I')) then
      usefacility := oh.tofacility;
    else
      usefacility := oh.fromfacility;
    end if;

    usecarrier := nvl(ld.carrier,oh.carrier);

    incount := 0;
    outcount := 0;
    if (adjrsn = 'Inbound') then
      incount := cu.defpalletqty;
    else
      outcount := cu.defpalletqty;
    end if;

    begin
      insert into pallethistory
        (custid,facility,pallettype,
         adjreason,loadno,lastuser,
         lastupdate,carrier,orderid,shipid,
         inpallets,outpallets)
      values
        (oh.custid,usefacility,cu.defpallettype,
         adjrsn,in_loadno,in_userid,
         sysdate,usecarrier,oh.orderid,oh.shipid,
         incount, outcount);
    exception when dup_val_on_index then
      l_cnt := 0;
      while (1=1) loop
        select max(lastupdate) into l_date
          from pallethistory
          where custid = oh.custid
            and facility = usefacility
            and pallettype = cu.defpallettype
            and carrier = usecarrier;
        begin
          insert into pallethistory
            (custid,facility,pallettype,
             adjreason,loadno,lastuser,
             lastupdate,carrier,orderid,shipid,
             inpallets,outpallets)
          values
            (oh.custid,usefacility,cu.defpallettype,
             adjrsn,in_loadno,in_userid,
             l_date+(1/86400),usecarrier,oh.orderid,oh.shipid,
             incount, outcount);
          exit;
        exception when dup_val_on_index then
          l_cnt := l_cnt + 1;
          if l_cnt >= 10 then
            out_errorno := sqlcode;
            out_msg := substr(sqlerrm,1,80);
            return;
          end if;
        end;
      end loop;
    end;
  end loop;

end loop;

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end assign_pallet_defaults;

end zpronumber;
/
show error package body zpronumber;
exit;
