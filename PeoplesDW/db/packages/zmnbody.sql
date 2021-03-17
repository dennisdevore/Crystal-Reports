create or replace package body alps.zmanifest as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--
type packlisttype is record (
     orderid      orderhdr.orderid%type,
     shipid       orderhdr.shipid%type,
     custid       orderhdr.custid%type,
     fromfacility orderhdr.fromfacility%type,
     loadno       orderhdr.loadno%type,
     report       varchar2(255),
     printer      varchar2(255),
     reqtype      char(1),
     email_rpt_format customer_aux.packlist_email_rpt_format%type,
     email_addresses customer_aux.packlist_email_addresses%type
);

type packlisttbltype is table of packlisttype
     index by binary_integer;

packlist_tbl packlisttbltype;


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_ORDHDR_WAVE(in_wave number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE wave = in_wave;

----------------------------------------------------------------------
CURSOR C_CONSIGNEE(in_consignee varchar2)
RETURN consignee%rowtype
IS
    SELECT *
      FROM consignee
     WHERE consignee = in_consignee;

----------------------------------------------------------------------
CURSOR C_MSHDR(in_orderid number, in_shipid number)
RETURN multishiphdr%rowtype
IS
    SELECT *
      FROM multishiphdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_MSDTL(in_orderid number, in_shipid number)
RETURN multishipdtl%rowtype
IS
    SELECT *
      FROM multishipdtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_MSTRM(in_facility varchar2, in_termid varchar2)
RETURN multishipterminal%rowtype
IS
    SELECT *
      FROM multishipterminal
     WHERE facility = in_facility
       AND termid = in_termid;

----------------------------------------------------------------------
CURSOR C_SP(in_orderid number, in_shipid number)
RETURN shippingplate%rowtype
IS
    SELECT *
      FROM shippingplate
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND type in ('F','M','C')
       AND parentlpid is null
       AND status <> 'U';

----------------------------------------------------------------------
CURSOR C_CARRIER(in_carrier varchar2)
RETURN carrier%rowtype
IS
    SELECT *
      FROM carrier
     WHERE carrier = in_carrier;

----------------------------------------------------------------------
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_CA(in_custid varchar2)
RETURN customer_aux%rowtype
IS
    SELECT *
      FROM customer_aux
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_SHIPPLATE(in_shiplpid varchar2)
RETURN shippingplate%rowtype
IS
    SELECT *
      FROM shippingplate
     WHERE lpid = in_shiplpid;

----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
cursor curMultiShipCode(in_carrier in varchar2, in_servicecode in varchar2) is
  select multishipcode
    from carrierservicecodes
   where carrier = in_carrier
     and servicecode = in_servicecode;

cursor curSpecialService(in_carrier in varchar2, in_servicecode in varchar2,
  in_specialservice varchar2) is
    select multishipcode
      from carrierspecialservice
     where carrier = in_carrier
       and servicecode = in_servicecode
       and specialservice = in_specialservice;

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

function correct_fromlpid
   (in_lpid in varchar2)
return varchar2
is
   cursor c_lp(p_lpid varchar2) is
      select type
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   cursor c_xp(p_lpid varchar2) is
      select PL.lpid
         from shippingplate SP, plate PL
         where SP.fromlpid = p_lpid
           and PL.parentlpid = SP.lpid
           and PL.type = 'XP';
   xp c_xp%rowtype;
   l_lpid plate.lpid%type := in_lpid;
begin
   open c_lp(in_lpid);
   fetch c_lp into lp;
   if c_lp%found and (lp.type = 'MP') then
      open c_xp(in_lpid);
      fetch c_xp into xp;
      if c_xp%found then
         l_lpid := xp.lpid;
      end if;
      close c_xp;
   end if;
   close c_lp;
   return l_lpid;

exception
   when OTHERS then
      return in_lpid;
end correct_fromlpid;
function find_sscc
   (in_lpid in varchar2)
return varchar2
is
cursor c_cl(in_lpid varchar2)
is
    select barcode
      from caselabels
     where lpid = in_lpid
       and labeltype = 'CS';

   l_sscc multishipdtl.sscc%type;
begin
    l_sscc := null;

    OPEN c_cl(in_lpid);
    FETCH c_cl into l_sscc;
    CLOSE c_cl;

    return l_sscc;

exception
   when OTHERS then
      return l_sscc;
end find_sscc;

FUNCTION ignore_smallpkg_station_weight
(in_custid in varchar2
) return varchar2

is

l_ignore customer_aux.ignore_smallpkg_station_weight%type;

begin

l_ignore := 'N';

select nvl(ignore_smallpkg_station_weight,'N')
  into l_ignore
  from customer_aux
 where custid = in_custid;

return l_ignore;

exception when others then
  return 'N';
end;

FUNCTION order_is_shipped
(in_orderid in number
,in_shipid in number
) return varchar2
is

cursor curOrderHdr is
  select orderid, shipid, custid, fromfacility,
         qtyorder, nvl(qtycommit,0) qtycommit, nvl(qtypick,0) qtypick, nvl(qtyship,0) qtyship
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select shortshipsmallpkgyn,
         decode(nvl(reduceorderqtybycancel,'D'),'D',nvl(zci.default_value('REDUCEORDERQTYBYCANCEL'),'N'),'Y','Y','N') reduceorderqtybycancel
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and ca.custid = cu.custid;
cu curCustomer%rowtype;

qtyCancel orderhdr.qtyorder%type;

begin

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

if oh.qtyorder is null then
  return 'N';
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;

if oh.qtycommit <= 0 then
  if ((oh.qtypick = oh.qtyship) or (oh.qtyorder = oh.qtyship)) and
     (oh.qtyship != 0) then
    if oh.qtyship = oh.qtyorder then
      return 'Y';
    else
      qtyCancel := 0;
        if cu.reduceorderqtybycancel <> 'Y' then
        begin
          select sum(qtyorder)
            into qtyCancel
            from orderdtl
           where orderid = in_orderid
             and shipid = in_shipid
             and linestatus = 'X';
        exception when others then
          null;
        end;
      end if;
      if oh.qtyship = (oh.qtyorder - qtyCancel) then
        return 'Y';
      end if;
      if nvl(cu.shortshipsmallpkgyn,'N') = 'Y' then
        return 'Y';
      elsif nvl(cu.shortshipsmallpkgyn,'N') = 'B' then
        return 'Y';
      end if;
    end if;
  end if;
end if;

return 'N';

exception when others then
  return 'N';
end order_is_shipped;

PROCEDURE shipped_order_updates
(in_orderid in number
,in_shipid in number
,in_userid in varchar2
,out_errorno OUT number
,out_errmsg OUT varchar2
)
is

cursor curOrderHdr is
  select orderstatus,wave,loadno,stopno,shipno,fromfacility,custid,xdockorderid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curPlatesToDelete is
  select lpid, parentlpid, quantity, weight
    from plate
   where exists (select 1 /*+ index(SP1 SHIPPINGPLATE_ORDER) */
                   from shippingplate SP1
                  where SP1.orderid = in_orderid
                    and SP1.shipid = in_shipid
                    and SP1.fromlpid = plate.lpid
                    and SP1.type = 'F')
     and status = 'P'
     and type <> 'TO'
  union
  select lpid, parentlpid, quantity, weight
    from (
  select lpid, parentlpid, quantity, weight
    from plate
   where exists (select 1 /*+ index(SP1 SHIPPINGPLATE_ORDER) */
                   from shippingplate SP1
                  where SP1.orderid = in_orderid
                    and SP1.shipid = in_shipid
                    and SP1.fromlpid = plate.lpid
                    and SP1.type = 'P'
                    and SP1.quantity = plate.quantity)
     and status = 'P'
     and type <> 'TO') P1
   where not exists (select 1 /*+ index(SP2 SHIPPINGPLATE_FROMLPID) */
                   from shippingplate SP2
                  where SP2.fromlpid = P1.lpid
                    and SP2.status <> 'SH');

cursor curChildrenToDelete(in_parentlpid varchar2) is
  select lpid
    from plate
   where parentlpid = in_parentlpid
     and status = 'P';

cursor curUnitsBackOrderLines is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and nvl(qtyorder,0) > nvl(qtyship,0)
     and nvl(qtyentered,0) != 0;

cursor curWeightsBackOrderLines is
  select item,
         lotnumber,
         nvl(weight_entered_lbs,0) as weight_entered_lbs,
         nvl(weight_entered_kgs,0) as weight_entered_kgs,
         nvl(weightpick,0) as weightpick,
         decode(nvl(variancepct_use_default,'Y'),'N',
                nvl(variancepct,0),zci.variancepct(custid,item)) as variancepct,
         qtytype,
         weightship,
         decode(nvl(weight_entered_lbs,0),0,zwt.from_kgs_to_lbs(custid,nvl(weight_entered_kgs,0)),
                weight_entered_lbs) as weightorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and ( nvl(weight_entered_lbs,0) != 0 or nvl(weight_entered_kgs,0) != 0 );

minstatus orderhdr.orderstatus%type;
rc integer;
strMsg varchar2(255);
datestamp date;
l_var_wt_lower number;
l_cnt pls_integer;
l_msg varchar2(255);

begin

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

if oh.orderstatus is null then
  out_errorno := -1;
  out_errmsg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

select count(1) into l_cnt
   from tasks
   where orderid = in_orderid
     and shipid = in_shipid
     and priority = '0';
if l_cnt != 0 then
  out_errmsg := 'Order has active tasks and cannot be shipped';
  return;
end if;

if (oh.orderstatus != 'X') and
   (oh.xdockorderid is null) and
   (not zld.is_split_facility_order(in_orderid, in_shipid)) then
  for bo in curUnitsBackOrderLines
  loop
    zbo.create_back_order_item(in_orderid,in_shipid,bo.item,
      bo.lotnumber,in_userid,out_errorno,out_errmsg);
    if out_errorno != 0 then
      zms.log_msg('ShipOrder', oh.fromfacility, oh.custid,
        'Back Order: ' || in_orderid || '-' || in_shipid || ' ' ||
        bo.item || ' ' || bo.lotnumber || ' ' ||
        out_errmsg, 'E', in_userid, strMsg);
    end if;
  end loop;
  for bo in curWeightsBackOrderLines
  loop
    if bo.weightship >= bo.weightorder then
      goto continue_weight_loop;
    end if;
    l_var_wt_lower := (bo.variancepct/100) * bo.weightorder;
    if bo.weightship >= l_var_wt_lower then
      goto continue_weight_loop;
    end if;
    zbo.create_back_order_item(in_orderid,in_shipid,bo.item,
      bo.lotnumber,in_userid,out_errorno,out_errmsg);
    if out_errorno != 0 then
      zms.log_msg('ShipOrder', oh.fromfacility, oh.custid,
        'Back Order: ' || in_orderid || '-' || in_shipid || ' ' ||
        bo.item || ' ' || bo.lotnumber || ' ' ||
        out_errmsg, 'E', in_userid, strMsg);
    end if;
  << continue_weight_loop >>
    null;
  end loop;
end if;

delete from commitments
 where orderid = in_orderid
   and shipid = in_shipid;

delete from orderlabor
 where orderid = in_orderid
   and shipid = in_shipid;

if oh.orderstatus != '9' then
  datestamp := sysdate;
  update orderhdr
     set orderstatus = '9',
         dateshipped = datestamp,
         lastuser = in_userid,
         lastupdate = datestamp
   where orderid = in_orderid
     and shipid = in_shipid;
  update multishiphdr
     set shipdate = datestamp
   where orderid = in_orderid
     and shipid = in_shipid;
end if;

for tk in (select taskid from tasks
            where orderid = in_orderid and shipid = in_shipid) loop
   for st in (select rowid, facility, custid, lpid from subtasks
               where taskid = tk.taskid) loop
      ztk.subtask_no_pick(st.rowid, st.facility, st.custid, tk.taskid,
            st.lpid, in_userid, 'N', l_msg);
   end loop;
end loop;

for x in curPlatesToDelete
loop
  zlp.plate_to_deletedplate(x.lpid,in_userid,'MN',out_errmsg);
  if (x.parentlpid is not null) then
    zplp.decrease_parent(x.parentlpid, x.quantity, x.weight, in_userid, 'MN', out_errmsg);
  end if;
  for y in curChildrenToDelete(x.lpid)
  loop
    zlp.plate_to_deletedplate(y.lpid,in_userid,'MN',out_errmsg);
  end loop;
end loop;

rc := zba.calc_outbound_order(null, null, in_orderid, in_shipid,'RS', out_errmsg);
if rc != zbill.GOOD then
  zms.log_msg('ShipOrder', oh.fromfacility, oh.custid,
    in_orderid || '-' || in_shipid  || ' ' || out_errmsg,
    'E', in_userid, strMsg);
end if;

select min(orderstatus)
  into minstatus
  from orderhdr
 where wave = oh.wave
   and ordertype not in ('W','K');
if minstatus >= '9' then
  update waves
     set wavestatus = '4',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave
     and wavestatus < '4';
end if;

if nvl(oh.loadno,0) != 0 then
  select min(orderstatus)
    into minstatus
    from orderhdr
   where loadno = oh.loadno
     and stopno = oh.stopno;
  if minstatus > zrf.LOD_PICKED then
     update loadstop
        set loadstopstatus = minstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = oh.loadno
        and stopno = oh.stopno
        and loadstopstatus < minstatus;
     if sql%rowcount > 0 then
         select min(loadstopstatus)
           into minstatus
           from loadstop
          where loadno = oh.loadno;
         update loads
            set loadstatus = minstatus,
                lastuser = in_userid,
                lastupdate = sysdate
          where loadno = oh.loadno
            and loadstatus < minstatus;
     end if;
  end if;
end if;

for cwt in (select SP.facility, SP.custid, SP.item, SP.lotnumber, SP.weight
               from shippingplate SP, custitemview CI
               where SP.orderid = in_orderid
                 and SP.shipid = in_shipid
                 and SP.type in ('P','F')
                 and CI.custid = SP.custid
                 and CI.item = SP.item
                 and CI.use_catch_weights = 'Y') loop
   zcwt.add_item_lot_catch_weight(cwt.facility, cwt.custid, cwt.item, cwt.lotnumber,
         -cwt.weight, out_errmsg);
end loop;

update shippingplate
   set totelpid = null
 where orderid = in_orderid
   and shipid = in_shipid;

zcus.ship_order(in_orderid, in_shipid);

out_errorno := 0;
out_errmsg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_errmsg := substr(sqlerrm,1,255);
end shipped_order_updates;


PROCEDURE add_multishiphdr
(
    ORD          IN      orderhdr%rowtype,
    in_requestor IN      varchar2,
    out_errmsg   OUT     varchar2
)
IS
   MSHDR multishiphdr%rowtype;
   CON   consignee%rowtype;
   CA customer_aux%rowtype;

mc curMultiShipCode%rowtype;
ss curSpecialService%rowtype;
errmsg varchar2(200);

CURSOR C_WV(in_wave number)
IS
    SELECT mass_manifest
      FROM waves
     WHERE wave = in_wave;
WV C_WV%rowtype;


BEGIN
   out_errmsg := 'OKAY';

-- verify this entry does not exist already
   MSHDR := null;
   OPEN C_MSHDR(ORD.orderid, ORD.shipid);
   FETCH C_MSHDR into MSHDR;
   CLOSE C_MSHDR;

   if (MSHDR.orderid is not null) and (nvl(in_requestor,'x') <> 'restage') then
      -- out_errmsg := 'Order already in manifest system';
      return;
   end if;

-- Get Customer Aux
    CA := null;
    OPEN C_CA(ORD.custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

-- Get Wave information
    WV := null;
    OPEN C_WV(ORD.wave);
    FETCH C_WV into WV;
    CLOSE C_WV;

-- Start filling in MSHDR data
   MSHDR.orderid := ORD.orderid;
   MSHDR.shipid := ORD.shipid;
   MSHDR.custid := ORD.custid;
   MSHDR.carrier := ORD.carrier;
   mc := null;
   open curMultiShipCode(ORD.carrier,ORD.deliveryservice);
   fetch curMultiShipCode into mc;
   close curMultiShipCode;
   MSHDR.carriercode := mc.MultiShipCode;
   if nvl(ORD.saturdaydelivery,'N') = 'Y' then
      MSHDR.satdelivery := 'Y';
   else
      MSHDR.satdelivery := 'N';
   end if;
   MSHDR.terms := ORD.shipterms;
   MSHDR.orderstatus := ORD.orderstatus;
   MSHDR.orderpriority := ORD.priority;
   MSHDR.ordercomments := substr(ORD.comment1,1,80);
   MSHDR.reference := ORD.reference;
   MSHDR.cod := ORD.cod;
   MSHDR.amtcod := ORD.amtcod;
   MSHDR.po := ORD.po;
   if ORD.specialservice1 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice1);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice1 := ss.multishipcode;
   end if;
   if ORD.specialservice2 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice2);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice2 := ss.multishipcode;
   end if;
   if ORD.specialservice3 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice3);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice3 := ss.multishipcode;
   end if;
   if ORD.specialservice4 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice4);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice4 := ss.multishipcode;
   end if;
   if ORD.shipto is not null then
      CON := null;
      OPEN C_CONSIGNEE(ORD.shipto);
      FETCH C_CONSIGNEE into CON;
      CLOSE C_CONSIGNEE;

      if CON.consignee is null then
        out_errmsg := 'Invalid consignee entry';
        return;
      end if;
      MSHDR.shiptoname := CON.name;
      MSHDR.shiptocontact := CON.contact;
      MSHDR.shiptoaddr1 := CON.addr1;
      MSHDR.shiptoaddr2 := CON.addr2;
      MSHDR.shiptocity := CON.city;
      MSHDR.shiptostate := CON.state;
      MSHDR.shiptopostalcode := CON.postalcode;
      MSHDR.shiptocountrycode := CON.countrycode;
      MSHDR.shiptophone := CON.phone;
   else
      MSHDR.shiptoname := ORD.shiptoname;
      MSHDR.shiptocontact := ORD.shiptocontact;
      MSHDR.shiptoaddr1 := ORD.shiptoaddr1;
      MSHDR.shiptoaddr2 := ORD.shiptoaddr2;
      MSHDR.shiptocity := ORD.shiptocity;
      MSHDR.shiptostate := ORD.shiptostate;
      MSHDR.shiptopostalcode := ORD.shiptopostalcode;
      MSHDR.shiptocountrycode := ORD.shiptocountrycode;
      MSHDR.shiptophone := ORD.shiptophone;
   end if;
   MSHDR.hdrpassthruchar01 := ORD.hdrpassthruchar01;
   MSHDR.hdrpassthruchar02 := ORD.hdrpassthruchar02;
   MSHDR.hdrpassthruchar03 := ORD.hdrpassthruchar03;
   MSHDR.hdrpassthruchar04 := ORD.hdrpassthruchar04;
   MSHDR.hdrpassthruchar05 := ORD.hdrpassthruchar05;
   MSHDR.hdrpassthruchar06 := ORD.hdrpassthruchar06;
   MSHDR.hdrpassthruchar07 := ORD.hdrpassthruchar07;
   MSHDR.hdrpassthruchar08 := ORD.hdrpassthruchar08;
   MSHDR.hdrpassthruchar09 := ORD.hdrpassthruchar09;
   MSHDR.hdrpassthruchar10 := ORD.hdrpassthruchar10;
   MSHDR.hdrpassthruchar11 := ORD.hdrpassthruchar11;
   MSHDR.hdrpassthruchar12 := ORD.hdrpassthruchar12;
   MSHDR.hdrpassthruchar13 := ORD.hdrpassthruchar13;
   MSHDR.hdrpassthruchar14 := ORD.hdrpassthruchar14;
   MSHDR.hdrpassthruchar15 := ORD.hdrpassthruchar15;
   MSHDR.hdrpassthruchar16 := ORD.hdrpassthruchar16;
   MSHDR.hdrpassthruchar17 := ORD.hdrpassthruchar17;
   MSHDR.hdrpassthruchar18 := ORD.hdrpassthruchar18;
   MSHDR.hdrpassthruchar19 := ORD.hdrpassthruchar19;
   MSHDR.hdrpassthruchar20 := nvl(ORD.hdrpassthruchar20,'N/A');
   MSHDR.hdrpassthrunum01 := ORD.hdrpassthrunum01;
   MSHDR.hdrpassthrunum02 := ORD.hdrpassthrunum02;
   MSHDR.hdrpassthrunum03 := ORD.hdrpassthrunum03;
   MSHDR.hdrpassthrunum04 := ORD.hdrpassthrunum04;
   MSHDR.hdrpassthrunum05 := ORD.hdrpassthrunum05;
   MSHDR.hdrpassthrunum06 := ORD.hdrpassthrunum06;
   MSHDR.hdrpassthrunum07 := ORD.hdrpassthrunum07;
   MSHDR.hdrpassthrunum08 := ORD.hdrpassthrunum08;
   MSHDR.hdrpassthrunum09 := ORD.hdrpassthrunum09;
   MSHDR.hdrpassthrunum10 := ORD.hdrpassthrunum10;
   MSHDR.hdrpassthrudate01 := ORD.hdrpassthrudate01;
   MSHDR.hdrpassthrudate02 := ORD.hdrpassthrudate02;
   MSHDR.hdrpassthrudate03 := ORD.hdrpassthrudate03;
   MSHDR.hdrpassthrudate04 := ORD.hdrpassthrudate04;
   MSHDR.hdrpassthrudoll01 := ORD.hdrpassthrudoll01;
   MSHDR.hdrpassthrudoll02 := ORD.hdrpassthrudoll02;
   MSHDR.hdrpassthruchar21 := ORD.hdrpassthruchar21;
   MSHDR.hdrpassthruchar22 := ORD.hdrpassthruchar22;
   MSHDR.hdrpassthruchar23 := ORD.hdrpassthruchar23;
   MSHDR.hdrpassthruchar24 := ORD.hdrpassthruchar24;
   MSHDR.hdrpassthruchar25 := ORD.hdrpassthruchar25;
   MSHDR.hdrpassthruchar26 := ORD.hdrpassthruchar26;
   MSHDR.hdrpassthruchar27 := ORD.hdrpassthruchar27;
   MSHDR.hdrpassthruchar28 := ORD.hdrpassthruchar28;
   MSHDR.hdrpassthruchar29 := ORD.hdrpassthruchar29;
   MSHDR.hdrpassthruchar30 := ORD.hdrpassthruchar30;
   MSHDR.hdrpassthruchar31 := ORD.hdrpassthruchar31;
   MSHDR.hdrpassthruchar32 := ORD.hdrpassthruchar32;
   MSHDR.hdrpassthruchar33 := ORD.hdrpassthruchar33;
   MSHDR.hdrpassthruchar34 := ORD.hdrpassthruchar34;
   MSHDR.hdrpassthruchar35 := ORD.hdrpassthruchar35;
   MSHDR.hdrpassthruchar36 := ORD.hdrpassthruchar36;
   MSHDR.hdrpassthruchar37 := ORD.hdrpassthruchar37;
   MSHDR.hdrpassthruchar38 := ORD.hdrpassthruchar38;
   MSHDR.hdrpassthruchar39 := ORD.hdrpassthruchar39;
   MSHDR.hdrpassthruchar40 := ORD.hdrpassthruchar40;
   MSHDR.shipping_insurance := nvl(CA.shipping_insurance,'N');
   MSHDR.massman := nvl(WV.mass_manifest,'N');

   begin
      INSERT INTO multishiphdr (
             orderid,
             shipid,
             custid,
             shiptoname,
             shiptocontact,
             shiptoaddr1,
             shiptoaddr2,
             shiptocity,
             shiptostate,
             shiptopostalcode,
             shiptocountrycode,
             shiptophone,
             carrier,
             carriercode,
             terms,
             satdelivery,
             orderstatus,
             orderpriority,
             ordercomments,
             reference,
             specialservice1,
             specialservice2,
             specialservice3,
             specialservice4,
             cod,
             amtcod,
             hdrpassthruchar20,
             hdrpassthruchar19,
             po,
             hdrpassthruchar01,
             hdrpassthruchar02,
             hdrpassthruchar03,
             hdrpassthruchar04,
             hdrpassthruchar05,
             hdrpassthruchar06,
             hdrpassthruchar07,
             hdrpassthruchar08,
             hdrpassthruchar09,
             hdrpassthruchar10,
             hdrpassthruchar11,
             hdrpassthruchar12,
             hdrpassthruchar13,
             hdrpassthruchar14,
             hdrpassthruchar15,
             hdrpassthruchar16,
             hdrpassthruchar17,
             hdrpassthruchar18,
             hdrpassthrunum01,
             hdrpassthrunum02,
             hdrpassthrunum03,
             hdrpassthrunum04,
             hdrpassthrunum05,
             hdrpassthrunum06,
             hdrpassthrunum07,
             hdrpassthrunum08,
             hdrpassthrunum09,
             hdrpassthrunum10,
             hdrpassthrudate01,
             hdrpassthrudate02,
             hdrpassthrudate03,
             hdrpassthrudate04,
             hdrpassthrudoll01,
             hdrpassthrudoll02,
             hdrpassthruchar21,
             hdrpassthruchar22,
             hdrpassthruchar23,
             hdrpassthruchar24,
             hdrpassthruchar25,
             hdrpassthruchar26,
             hdrpassthruchar27,
             hdrpassthruchar28,
             hdrpassthruchar29,
             hdrpassthruchar30,
             hdrpassthruchar31,
             hdrpassthruchar32,
             hdrpassthruchar33,
             hdrpassthruchar34,
             hdrpassthruchar35,
             hdrpassthruchar36,
             hdrpassthruchar37,
             hdrpassthruchar38,
             hdrpassthruchar39,
             hdrpassthruchar40,
             shipping_insurance,
             massman
      )
      values (
             MSHDR.orderid,
             MSHDR.shipid,
             MSHDR.custid,
             MSHDR.shiptoname,
             MSHDR.shiptocontact,
             MSHDR.shiptoaddr1,
             MSHDR.shiptoaddr2,
             MSHDR.shiptocity,
             MSHDR.shiptostate,
             MSHDR.shiptopostalcode,
             MSHDR.shiptocountrycode,
             MSHDR.shiptophone,
             MSHDR.carrier,
             MSHDR.carriercode,
             MSHDR.terms,
             MSHDR.satdelivery,
             MSHDR.orderstatus,
             MSHDR.orderpriority,
             MSHDR.ordercomments,
             MSHDR.reference,
             MSHDR.specialservice1,
             MSHDR.specialservice2,
             MSHDR.specialservice3,
             MSHDR.specialservice4,
             MSHDR.cod,
             MSHDR.amtcod,
             MSHDR.hdrpassthruchar20,
             MSHDR.hdrpassthruchar19,
             MSHDR.po,
             MSHDR.hdrpassthruchar01,
             MSHDR.hdrpassthruchar02,
             MSHDR.hdrpassthruchar03,
             MSHDR.hdrpassthruchar04,
             MSHDR.hdrpassthruchar05,
             MSHDR.hdrpassthruchar06,
             MSHDR.hdrpassthruchar07,
             MSHDR.hdrpassthruchar08,
             MSHDR.hdrpassthruchar09,
             MSHDR.hdrpassthruchar10,
             MSHDR.hdrpassthruchar11,
             MSHDR.hdrpassthruchar12,
             MSHDR.hdrpassthruchar13,
             MSHDR.hdrpassthruchar14,
             MSHDR.hdrpassthruchar15,
             MSHDR.hdrpassthruchar16,
             MSHDR.hdrpassthruchar17,
             MSHDR.hdrpassthruchar18,
             MSHDR.hdrpassthrunum01,
             MSHDR.hdrpassthrunum02,
             MSHDR.hdrpassthrunum03,
             MSHDR.hdrpassthrunum04,
             MSHDR.hdrpassthrunum05,
             MSHDR.hdrpassthrunum06,
             MSHDR.hdrpassthrunum07,
             MSHDR.hdrpassthrunum08,
             MSHDR.hdrpassthrunum09,
             MSHDR.hdrpassthrunum10,
             MSHDR.hdrpassthrudate01,
             MSHDR.hdrpassthrudate02,
             MSHDR.hdrpassthrudate03,
             MSHDR.hdrpassthrudate04,
             MSHDR.hdrpassthrudoll01,
             MSHDR.hdrpassthrudoll02,
             MSHDR.hdrpassthruchar21,
             MSHDR.hdrpassthruchar22,
             MSHDR.hdrpassthruchar23,
             MSHDR.hdrpassthruchar24,
             MSHDR.hdrpassthruchar25,
             MSHDR.hdrpassthruchar26,
             MSHDR.hdrpassthruchar27,
             MSHDR.hdrpassthruchar28,
             MSHDR.hdrpassthruchar29,
             MSHDR.hdrpassthruchar30,
             MSHDR.hdrpassthruchar31,
             MSHDR.hdrpassthruchar32,
             MSHDR.hdrpassthruchar33,
             MSHDR.hdrpassthruchar34,
             MSHDR.hdrpassthruchar35,
             MSHDR.hdrpassthruchar36,
             MSHDR.hdrpassthruchar37,
             MSHDR.hdrpassthruchar38,
             MSHDR.hdrpassthruchar39,
             MSHDR.hdrpassthruchar40,
             MSHDR.shipping_insurance,
             MSHDR.massman
      );
   exception when DUP_VAL_ON_INDEX then
     update multishiphdr
        set custid = MSHDR.custid,
            shiptoname = MSHDR.shiptoname,
            shiptocontact = MSHDR.shiptocontact,
            shiptoaddr1 = MSHDR.shiptoaddr1,
            shiptoaddr2 = MSHDR.shiptoaddr2,
            shiptocity = MSHDR.shiptocity,
            shiptostate = MSHDR.shiptostate,
            shiptopostalcode = MSHDR.shiptopostalcode,
            shiptocountrycode = MSHDR.shiptocountrycode,
            shiptophone = MSHDR.shiptophone,
            carrier = MSHDR.carrier,
            carriercode = MSHDR.carriercode,
            terms = MSHDR.terms,
            satdelivery = MSHDR.satdelivery,
            orderstatus = MSHDR.orderstatus,
            orderpriority = MSHDR.orderpriority,
            ordercomments = MSHDR.ordercomments,
            reference = MSHDR.reference,
            specialservice1 = MSHDR.specialservice1,
            specialservice2 = MSHDR.specialservice2,
            specialservice3 = MSHDR.specialservice3,
            specialservice4 = MSHDR.specialservice4,
            cod = MSHDR.cod,
            amtcod = MSHDR.amtcod,
            hdrpassthruchar20 = MSHDR.hdrpassthruchar20,
            hdrpassthruchar19 = MSHDR.hdrpassthruchar19,
            po = MSHDR.po,
            hdrpassthruchar01 = MSHDR.hdrpassthruchar01,
            hdrpassthruchar02 = MSHDR.hdrpassthruchar02,
            hdrpassthruchar03 = MSHDR.hdrpassthruchar03,
            hdrpassthruchar04 = MSHDR.hdrpassthruchar04,
            hdrpassthruchar05 = MSHDR.hdrpassthruchar05,
            hdrpassthruchar06 = MSHDR.hdrpassthruchar06,
            hdrpassthruchar07 = MSHDR.hdrpassthruchar07,
            hdrpassthruchar08 = MSHDR.hdrpassthruchar08,
            hdrpassthruchar09 = MSHDR.hdrpassthruchar09,
            hdrpassthruchar10 = MSHDR.hdrpassthruchar10,
            hdrpassthruchar11 = MSHDR.hdrpassthruchar11,
            hdrpassthruchar12 = MSHDR.hdrpassthruchar12,
            hdrpassthruchar13 = MSHDR.hdrpassthruchar13,
            hdrpassthruchar14 = MSHDR.hdrpassthruchar14,
            hdrpassthruchar15 = MSHDR.hdrpassthruchar15,
            hdrpassthruchar16 = MSHDR.hdrpassthruchar16,
            hdrpassthruchar17 = MSHDR.hdrpassthruchar17,
            hdrpassthruchar18 = MSHDR.hdrpassthruchar18,
            hdrpassthrunum01 = MSHDR.hdrpassthrunum01,
            hdrpassthrunum02 = MSHDR.hdrpassthrunum02,
            hdrpassthrunum03 = MSHDR.hdrpassthrunum03,
            hdrpassthrunum04 = MSHDR.hdrpassthrunum04,
            hdrpassthrunum05 = MSHDR.hdrpassthrunum05,
            hdrpassthrunum06 = MSHDR.hdrpassthrunum06,
            hdrpassthrunum07 = MSHDR.hdrpassthrunum07,
            hdrpassthrunum08 = MSHDR.hdrpassthrunum08,
            hdrpassthrunum09 = MSHDR.hdrpassthrunum09,
            hdrpassthrunum10 = MSHDR.hdrpassthrunum10,
            hdrpassthrudate01 = MSHDR.hdrpassthrudate01,
            hdrpassthrudate02 = MSHDR.hdrpassthrudate02,
            hdrpassthrudate03 = MSHDR.hdrpassthrudate03,
            hdrpassthrudate04 = MSHDR.hdrpassthrudate04,
            hdrpassthrudoll01 = MSHDR.hdrpassthrudoll01,
            hdrpassthrudoll02 = MSHDR.hdrpassthrudoll02,
            hdrpassthruchar21 = MSHDR.hdrpassthruchar21,
            hdrpassthruchar22 = MSHDR.hdrpassthruchar22,
            hdrpassthruchar23 = MSHDR.hdrpassthruchar23,
            hdrpassthruchar24 = MSHDR.hdrpassthruchar24,
            hdrpassthruchar25 = MSHDR.hdrpassthruchar25,
            hdrpassthruchar26 = MSHDR.hdrpassthruchar26,
            hdrpassthruchar27 = MSHDR.hdrpassthruchar27,
            hdrpassthruchar28 = MSHDR.hdrpassthruchar28,
            hdrpassthruchar29 = MSHDR.hdrpassthruchar29,
            hdrpassthruchar30 = MSHDR.hdrpassthruchar30,
            hdrpassthruchar31 = MSHDR.hdrpassthruchar31,
            hdrpassthruchar32 = MSHDR.hdrpassthruchar32,
            hdrpassthruchar33 = MSHDR.hdrpassthruchar33,
            hdrpassthruchar34 = MSHDR.hdrpassthruchar34,
            hdrpassthruchar35 = MSHDR.hdrpassthruchar35,
            hdrpassthruchar36 = MSHDR.hdrpassthruchar36,
            hdrpassthruchar37 = MSHDR.hdrpassthruchar37,
            hdrpassthruchar38 = MSHDR.hdrpassthruchar38,
            hdrpassthruchar39 = MSHDR.hdrpassthruchar39,
            hdrpassthruchar40 = MSHDR.hdrpassthruchar40,
            shipping_insurance = MSHDR.shipping_insurance,
            massman = MSHDR.massman
      where orderid = MSHDR.orderid
        and shipid = MSHDR.shipid;
   when others then
     out_errmsg := sqlerrm;
     zms.log_msg('Add_MultishipHdr', null, MSHDR.custid,
       'MultishipHdr Insert: ' || out_errmsg,
       'E', 'MULTISHIP', errMsg);
     return;
   end;

END add_multishiphdr;


PROCEDURE process_shipped
IS
  CURSOR C_MSSHIP
  IS
    SELECT rowid,multishipdtl.*
      FROM multishipdtl
     WHERE status = 'SHIPPED';

  CURSOR C_SP_CONTENTS(in_parentlpid varchar2)
  IS
    select facility,custid,loadno,stopno,shipno,
           orderid,shipid,orderitem,orderlot,
           item,lotnumber,unitofmeasure,
           inventoryclass, invstatus, lpid,
           sum(quantity) as quantity,
           sum(weight) as weight
      from shippingplate
     where parentlpid = in_parentlpid
       and type in ('F','P')
     group by facility,custid,loadno,stopno,shipno,
           orderid,shipid,orderitem,orderlot,
           item,lotnumber,unitofmeasure,
           inventoryclass, invstatus, lpid;

  cursor curFindCarton(in_fromlpid varchar2,
    in_orderid number, in_shipid number) is
    select *
      from shippingplate
     where fromlpid = in_fromlpid
       and status in ('S','SH')
       and orderid = in_orderid
       and shipid = in_shipid
       and parentlpid is null;


  CURSOR C_CIV(in_custid varchar2, in_item varchar2)
    IS
  SELECT custid, item, lotrequired
    FROM custitemview
   WHERE custid = in_custid
     AND item = in_item;


  CIV C_CIV%rowtype;
  od_lotnumber orderdtl.lotnumber%type;

  cursor c_mp_container(p_lpid varchar2, p_orderid number, p_shipid number) is
    select *
      from shippingplate
      where (fromlpid in (select lpid from plate
                           start with lpid = p_lpid
                           connect by prior lpid = parentlpid)
            or parentlpid in (select lpid from shippingplate
                              where fromlpid = p_lpid))
        and orderid = p_orderid
        and shipid = p_shipid;

  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;
  lpid  plate%rowtype;
  ORD   orderhdr%rowtype;
  TERM  multishipterminal%rowtype;
  CUST  customer%rowtype;
  CARR  carrier%rowtype;
  MD    multishipdtl%rowtype;
  CNTS  c_sp_contents%rowtype;

  ordstatus orderhdr.orderstatus%type;
  errmsg varchar2(255);
  errno integer;
  strMsg varchar2(255);
  l_ignore_station_weight customer_aux.ignore_smallpkg_station_weight%type;

  ix integer;
  out_msg varchar2(255);
  hold_msg varchar2(255);
  hold_errcode integer;
  is_shipped varchar2(1);

  cord orderhdr.orderid%type;
  cnt integer;
  l_totcalcwt shippingplate.weight%type;
  l_parentweight shippingplate.weight%type;
  l_weight shippingplate.weight%type;
  l_dateshipped orderhdr.dateshipped%type;
  l_packlistshipdate orderhdr.packlistshipdate%type;
  l_cartonid multishipdtl.cartonid%type;
  l_rid rowid;

cursor curUnitsBackOrderLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and nvl(qtyorder,0) > nvl(qtyship,0)
     and nvl(qtyentered,0) != 0;

cursor curWeightsBackOrderLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         nvl(weight_entered_lbs,0) as weight_entered_lbs,
         nvl(weight_entered_kgs,0) as weight_entered_kgs,
         nvl(weightpick,0) as weightpick,
         decode(nvl(variancepct_use_default,'Y'),'N',
                nvl(variancepct,0),zci.variancepct(custid,item)) as variancepct,
         qtytype,
         weightship,
         decode(nvl(weight_entered_lbs,0),0,zwt.from_kgs_to_lbs(custid,nvl(weight_entered_kgs,0)),
                weight_entered_lbs) as weightorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and ( nvl(weight_entered_lbs,0) != 0 or nvl(weight_entered_kgs,0) != 0 );

l_var_wt_lower number;
intErrorno integer;
l_packlist_email_rpt_format customer_aux.packlist_email_rpt_format%type;
l_packlist_email_addresses customer_aux.packlist_email_addresses%type;

cursor curCustomer(in_custid varchar2) is
  select shortshipsmallpkgyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curCaseLabels(p_barcode varchar2) is
   select SP.fromlpid
      from caselabels UC, shippingplate SP
      where UC.barcode = p_barcode
        and SP.lpid = UC.lpid;
clbl curCaseLabels%rowtype;

procedure update_order_qtyship(od in c_sp_contents%rowtype,
                               in_weight in number) is
  cord orderhdr.orderid%type;
  l_datefmt varchar2(32);
  l_cnt pls_integer;
  l_dateshipped date;
  l_strdate varchar2(32);
  l_strtime varchar2(32);
begin

  cord := null;
  cord := zcord.cons_orderid(od.orderid, od.shipid);
  if cord = 0 then
    cord := null;
  end if;

update orderdtl
   set qtyship = nvl(qtyship,0) + od.quantity,
       weightship = nvl(weightship,0) + in_weight,
       cubeship = nvl(cubeship,0) + (od.quantity *
          zci.item_cube(od.custid,od.item,od.unitofmeasure)),
       amtship = nvl(amtship,0) + (od.quantity *
          zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber)), --prn 25133
       lastuser = 'MULTISHIP',
       lastupdate = sysdate
 where orderid = od.orderid
   and shipid = od.shipid
   and item = od.orderitem
   and nvl(lotnumber,'(none)') = nvl(od.orderlot,'(none)');

if nvl(od.loadno,0) = 0 then


   if (nvl(CIV.custid,'aaa') <> od.custid
    or nvl(CIV.item,'aaa') <> od.item) then
       OPEN C_CIV(od.custid, od.item);
       FETCH C_CIV into CIV;
       CLOSE C_CIV;
   end if;

   od_lotnumber := od.lotnumber;

   if CIV.lotrequired = 'P' then
      od_lotnumber := null;
   end if;

  -- remove asof inventory for the plate
  zbill.add_asof_inventory(
        od.facility,
        od.custid,
        od.item,
        od_lotnumber,
        od.unitofmeasure,
        trunc(sysdate),
        - od.quantity,
        - in_weight,
        'Shipped',
        'SH',
        od.inventoryclass,
        od.invstatus,
        od.orderid,
        od.shipid,
        od.lpid,
        'MS', -- in_userid,
        errmsg
     );
end if;

ORD := null;
OPEN C_ORDHDR(od.orderid, od.shipid);
FETCH C_ORDHDR into ORD;
CLOSE C_ORDHDR;

ordstatus := ORD.orderstatus;

is_shipped := zmn.order_is_shipped(od.orderid,od.shipid);

if is_shipped = 'Y' then
 if nvl(ORD.loadno,0) = 0 then
    ordstatus := '9';
 else
    ordstatus := zrf.ORD_LOADED;
 end if;
else
 if ordstatus < zrf.ORD_LOADING then
   ordstatus := zrf.ORD_LOADING;
 end if;
end if;

if ORD.orderstatus != ordstatus then
  if ordstatus = '9' then

    cu := null;
    open curCustomer(ORD.custid);
    fetch curCustomer into cu;
    close curCustomer;

    /* 
    -- backorders are created in zmn.shipped_order_updates
    if nvl(cu.shortshipsmallpkgyn,'N') = 'B' then
      for bo in curUnitsBackOrderLines(od.orderid,od.shipid)
      loop
        zbo.create_back_order_item(od.orderid,od.shipid,bo.item,
          bo.lotnumber,'MULTISHIP',intErrorno,out_msg);
        if intErrorno != 0 then
          zms.log_msg('WaveRelease', ORD.fromfacility, od.custid,
            'Back Order: ' || od.orderid || '-' || od.shipid || ' ' ||
            bo.item || ' ' || bo.lotnumber || ' ' ||
            out_msg, 'E', 'MULTISHIP', strMsg);
        end if;
      end loop;
      for bo in curWeightsBackOrderLines(od.orderid,od.shipid)
      loop
        if bo.weightship >= bo.weightorder then
          goto continue_weight_loop;
        end if;
        l_var_wt_lower := (bo.variancepct/100) * bo.weightorder;
        if bo.weightship >= l_var_wt_lower then
          goto continue_weight_loop;
        end if;
        zbo.create_back_order_item(od.orderid,od.shipid,bo.item,
          bo.lotnumber,'MULTISHIP',intErrorno,out_msg);
        if intErrorno != 0 then
          zms.log_msg('WaveRelease', ORD.fromfacility, od.custid,
            'Back Order: ' || od.orderid || '-' || od.shipid || ' ' ||
            bo.item || ' ' || bo.lotnumber || ' ' ||
            out_msg, 'E', 'MULTISHIP', strMsg);
        end if;
      << continue_weight_loop >>
        null;
      end loop;
    end if;
    */

    begin
      select max(shipdatetime), max(packlistshipdatetime), max(nvl(termid, 'STD'))
        into md.shipdatetime, md.packlistshipdatetime, md.termid
        from multishipdtl
       where orderid = nvl(cord,od.orderid)
         and shipid = decode(nvl(cord,0),0,od.shipid,0);
    exception when others then
      null;
    end;
    begin
       select count(1) into l_cnt
          from MultishipTermDate
          where code = md.termid;
    exception when others then
       l_cnt := 0;
    end;
    if l_cnt = 0 then
        l_datefmt := 'YYYYMMDDHH24MISS';
    else
       select descr into l_datefmt
          from MultishipTermDate
          where code = md.termid;
    end if;

    begin
      if instr(l_datefmt,'HH') > 0 then
         l_dateshipped := to_date(md.shipdatetime,l_datefmt);
      else
         l_strdate := to_char(to_date(md.shipdatetime,l_datefmt),'YYYYMMDD') ||
                      to_char(sysdate,'HH24MISS');
         l_dateshipped := to_date(l_strdate,'YYYYMMDDHH24MISS');
      end if;
    exception when others then
      l_dateshipped := sysdate;
    end;

    begin
      l_packlistshipdate := to_date(md.packlistshipdatetime,l_datefmt);
    exception when others then
      l_packlistshipdate := sysdate;
    end;

    update multishiphdr
       set shipdate = l_dateshipped
     where orderid = nvl(cord,od.orderid)
       and shipid = decode(nvl(cord,0),0,od.shipid,0);
  end if;
  UPDATE orderhdr
     SET orderstatus = ordstatus,
         dateshipped = l_dateshipped,
         packlistshipdate = l_packlistshipdate,
         lastuser = 'MULTISHIP',
         lastupdate = sysdate
   WHERE orderid = od.orderid
     AND shipid = od.shipid;
end if;

if nvl(od.loadno,0) <> 0 then
  update loadstopship
     set qtyship = nvl(qtyship, 0) + od.quantity,
         weightship = nvl(weightship, 0) + in_weight,
         weightship_kgs = nvl(weightship_kgs,0)
                        + nvl(zwt.from_lbs_to_kgs(ORD.custid,in_weight),0),
         cubeship = nvl(cubeship, 0) + (od.quantity *
                    zci.item_cube(od.custid,od.item,od.unitofmeasure)),
         amtship = nvl(amtship, 0) + (od.quantity *
                    zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber)), --prn 25133
         lastuser = 'MULTISHIP',
         lastupdate = sysdate
   where loadno = od.loadno
     and stopno = od.stopno
     and shipno = od.shipno;
end if;

if ordstatus = '9' then

  if ORD.orderstatus != '9' then
    zmn.shipped_order_updates(ORD.orderid,ORD.shipid,'MULTISHIP',errno,errmsg);
    zoh.add_orderhistory(ORD.orderid, ORD.shipid,
       'Order Shipped',
       'Order shipped multiship station:' || TERM.facility||'/'||TERM.termid,
       'MULTISHIP', out_msg);
    zsmtp.notify_order_shipped(ORD.orderid, ORD.shipid);

  end if;

  -- Check customer if printing pack list
  CUST := null;
  OPEN C_CUST(ORD.custid);
  FETCH C_CUST into CUST;
  CLOSE C_CUST;

  zcu.pack_list_format(ORD.orderid,ORD.shipid,CUST.packlist,CUST.packlistrptfile);
  zcu.small_pkg_email_pack_list_fmt(ORD.custid,l_packlist_email_rpt_format,l_packlist_email_addresses);

  -- Check if we need to create a packing list ???
  -- if CUST.packlistrptfile is not null then
     ix := packlist_tbl.count + 1;
     packlist_tbl(ix).orderid := ORD.orderid;
     packlist_tbl(ix).shipid := ORD.shipid;
     packlist_tbl(ix).custid := ORD.custid;
     packlist_tbl(ix).fromfacility := ORD.fromfacility;
     packlist_tbl(ix).loadno := nvl(ORD.loadno,0);
     packlist_tbl(ix).report := CUST.packlistrptfile;
     packlist_tbl(ix).printer := TERM.packprinter;
     packlist_tbl(ix).reqtype := CUST.packlist;
     packlist_tbl(ix).email_rpt_format := l_packlist_email_rpt_format;
     packlist_tbl(ix).email_addresses := l_packlist_email_addresses;
  -- end if;

  cord := zcord.cons_orderid(ORD.orderid, ORD.shipid);

  if nvl(cord,0) > 0 then
    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where wave = cord
       and orderstatus not in ('9','X');

    if nvl(cnt,0) = 0 then
        zcu.master_pack_list_format(ORD.orderid,ORD.shipid,
            CUST.masterpacklist,CUST.masterpacklistrptfile);

        if CUST.masterpacklist = 'Y' then
            ix := packlist_tbl.count + 1;
            packlist_tbl(ix).orderid := cord;
            packlist_tbl(ix).shipid := 0;
            packlist_tbl(ix).custid := ORD.custid;
            packlist_tbl(ix).fromfacility := ORD.fromfacility;
            packlist_tbl(ix).loadno := nvl(ORD.loadno,0);
            packlist_tbl(ix).report := CUST.packlistrptfile;
            packlist_tbl(ix).printer := TERM.packprinter;
            packlist_tbl(ix).reqtype := CUST.packlist;
        end if;

    end if;

  end if;

end if;

end;

BEGIN

   packlist_tbl.delete;

   l_ignore_station_weight := substr(zmn.ignore_smallpkg_station_weight(CRTN.custid),1,1);

   CIV := null;

   for D in C_MSSHIP loop
      -- if D.status = 'REJECT' then
      --    DELETE multishipdtl
      --     WHERE rowid = D.rowid;
      --    goto LOOP_END;
      -- end if;
      l_rid := null;

      l_cartonid := D.cartonid;
      if length(D.cartonid) != 15 then
         clbl := null;
         open curCaseLabels(D.cartonid);
         fetch curCaseLabels into clbl;
         close curCaseLabels;
         if clbl.fromlpid is not null then
            l_cartonid := clbl.fromlpid;
         end if;
      end if;

      update multishipdtl
         set status = 'INPROCESS'
         where rowid = D.rowid;
      commit;

      l_rid := D.rowid;

      zcus.multiship_process(l_cartonid);

      if D.trackid is null then
         update multishipdtl
            set status = 'VOID'
            where rowid = D.rowid;
         zms.log_msg('MultiShip', null, null,
               D.cartonid || ' ' || 'Tracking Number is missing',
               'E', 'MultiShip', out_msg);
         goto loop_end;
      end if;

      update multishipdtl
         set status = 'PROCESSED'
         where rowid = D.rowid;

      -- read the carton and the shippingplate
      CRTNX := null;
      OPEN C_PLATE(l_cartonid);
      FETCH C_PLATE into CRTNX;
      CLOSE C_PLATE;
      CRTN := null;
      if CRTNX.type = 'XP' then
         OPEN C_SHIPPLATE(CRTNX.parentlpid);
         FETCH C_SHIPPLATE into CRTN;
         CLOSE C_SHIPPLATE;
      end if;
      if CRTNX.type = 'MP' then
         CRTN.facility := CRTNX.facility;
      elsif CRTN.lpid is null then
         CRTN := null;
         open curFindCarton(l_cartonid,D.orderid,D.shipid);
         fetch curFindCarton into CRTN;
         close curFindCarton;
         CRTNX.parentlpid := CRTN.lpid;
      end if;

      -- Get terminal this was done on
      TERM := null;
      OPEN C_MSTRM(CRTN.facility, D.termid);
      FETCH C_MSTRM into TERM;
      CLOSE C_MSTRM;

      if (nvl(CRTNX.type,'X')) != 'MP' then
         update shippingplate
            set trackingno = D.trackid,
                rmatrackingno = D.rmatrackingno,
                weight = decode(l_ignore_station_weight,'Y',weight,D.actweight),
                shippingcost = D.cost,
                carriercodeused = D.carrierused,
                actualcarrier = D.actualcarrier,
                satdeliveryused = D.satdeliveryused,
                status = 'SH',
                lastuser = 'MULTISHIP',
                lastupdate = sysdate,
                height = D.height,
                width = D.width,
                length = D.length
            where lpid = CRTN.lpid;

         if CRTN.type in ('F','P') then
            if CRTN.status != 'SH' then
               cnts.facility := CRTN.facility;
               cnts.custid := CRTN.custid;
               cnts.loadno := CRTN.loadno;
               cnts.stopno := CRTN.stopno;
               cnts.shipno := CRTN.shipno;
               cnts.orderid := CRTN.orderid;
               cnts.shipid := CRTN.shipid;
               cnts.orderitem := CRTN.orderitem;
               cnts.orderlot := CRTN.orderlot;
               cnts.item := CRTN.item;
               cnts.lotnumber := CRTN.lotnumber;
               cnts.unitofmeasure := CRTN.unitofmeasure;
               cnts.quantity := CRTN.quantity;
               cnts.inventoryclass := CRTN.inventoryclass;
               cnts.invstatus := CRTN.invstatus;
               select decode(l_ignore_station_weight,'Y',CRTN.weight,D.actweight)
                 into cnts.weight
                 from dual;
               update_order_qtyship(cnts, cnts.weight);
            end if;
         else

--          determine total calculated weight
            l_totcalcwt := 0;
            for f_p in (select custid, item, sum(quantity) qty, unitofmeasure uom,
                               sum(weight) as weight
                           from shippingplate
                           where type in ('F','P')
                           start with lpid = CRTN.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure) loop
               if l_ignore_station_weight = 'Y' then
                 l_totcalcwt := l_totcalcwt + f_p.weight;
               else
                 l_totcalcwt := l_totcalcwt
                              + (zci.item_weight(f_p.custid, f_p.item, f_p.uom) * f_p.qty);
               end if;
            end loop;

            for pp in (select rowid, lpid, status, trackingno, weight, rmatrackingno
                        from shippingplate
                        where type in ('C','M')
                        start with lpid = CRTNX.parentlpid
                        connect by prior lpid = parentlpid) loop

               l_parentweight := 0;
               for sp in (select rowid, shippingplate.*
                           from shippingplate
                           where parentlpid = pp.lpid
                             and type in ('F','P')
                             and status != 'SH') loop

--                actual weight for plate is proportionate to calculated weight
                  if l_ignore_station_weight = 'Y' then
                    l_weight := sp.weight;
                  else
                    if l_totcalcwt = 0  then
                      l_weight := D.actweight;
                    else
                      l_weight := ((zci.item_weight(sp.custid, sp.item, sp.unitofmeasure)*sp.quantity)
                                  /l_totcalcwt) * D.actweight;
                    end if;
                  end if;

                  update shippingplate
                     set trackingno = D.trackid,
                         rmatrackingno = D.rmatrackingno,
                         status = 'SH',
                         lastuser = 'MULTISHIP',
                         lastupdate = sysdate,
                         weight = l_weight
                     where rowid = sp.rowid;

                  cnts.facility := sp.facility;
                  cnts.custid := sp.custid;
                  cnts.loadno := sp.loadno;
                  cnts.stopno := sp.stopno;
                  cnts.shipno := sp.shipno;
                  cnts.orderid := sp.orderid;
                  cnts.shipid := sp.shipid;
                  cnts.orderitem := sp.orderitem;
                  cnts.orderlot := sp.orderlot;
                  cnts.item := sp.item;
                  cnts.lotnumber := sp.lotnumber;
                  cnts.unitofmeasure := sp.unitofmeasure;
                  cnts.quantity := sp.quantity;
                  cnts.inventoryclass := sp.inventoryclass;
                  cnts.invstatus := sp.invstatus;
                  update_order_qtyship(cnts, l_weight);
                  l_parentweight := l_parentweight + l_weight;
               end loop;

               for sp in (select rowid, shippingplate.*
                           from shippingplate
                           where parentlpid = pp.lpid
                             and type in ('F','P')
                             and status = 'SH'
                             and trackingno != D.trackid) loop

                  update shippingplate
                     set trackingno = D.trackid,
                         lastuser = 'MULTISHIP',
                         lastupdate = sysdate
                     where rowid = sp.rowid;
               end loop;

               for rp in (select rowid, shippingplate.*
                           from shippingplate
                           where parentlpid = pp.lpid
                             and type in ('F','P')
                             and status = 'SH'
                             and nvl(rmatrackingno, 'x') != nvl(D.rmatrackingno, 'x')) loop

                  update shippingplate
                     set rmatrackingno = D.rmatrackingno,
                         lastuser = 'MULTISHIP',
                         lastupdate = sysdate
                     where rowid = rp.rowid;
               end loop;

               if (pp.status != 'SH') or (nvl(pp.trackingno,'x') != nvl(D.trackid,'x')) then
                  update shippingplate
                     set trackingno = D.trackid,
                         status = 'SH',
                         lastuser = 'MULTISHIP',
                         lastupdate = sysdate,
                         weight = decode(l_ignore_station_weight,'Y',weight,l_parentweight)
                     where rowid = pp.rowid;
               end if;
               if (pp.status != 'SH') or (nvl(pp.rmatrackingno,'x') != nvl(D.rmatrackingno,'x')) then
                  update shippingplate
                     set rmatrackingno = D.rmatrackingno,
                         status = 'SH',
                         lastuser = 'MULTISHIP',
                         lastupdate = sysdate,
                         weight = decode(l_ignore_station_weight,'Y',weight,l_parentweight)
                     where rowid = pp.rowid;
               end if;

            end loop;

         end if;
      else
--       determine total calculated weight
         l_totcalcwt := 0;
         for lp in (select custid, item, sum(quantity) qty, unitofmeasure uom,
                           sum(weight) weight
                     from plate
                     where type = 'PA'
                     start with lpid = l_cartonid
                     connect by prior lpid = parentlpid
                     group by custid, item, unitofmeasure) loop
           if l_ignore_station_weight = 'Y' then
             l_totcalcwt := l_totcalcwt + lp.weight;
           else
             l_totcalcwt := l_totcalcwt
                  + (zci.item_weight(lp.custid, lp.item, lp.uom) * lp.qty);
           end if;
         end loop;

         for M in c_mp_container(l_cartonid, D.orderid, D.shipid) loop

--          actual weight for plate is proportionate to calculated weight
            if l_ignore_station_weight = 'Y' then
              l_weight := M.weight;
            else
              if l_totcalcwt = 0 then
                 l_weight := D.actweight;
              else
                 l_weight := ((zci.item_weight(M.custid, M.item, M.unitofmeasure)*M.quantity)
                       /l_totcalcwt) * D.actweight;
              end if;
            end if;

            update shippingplate
               set trackingno = D.trackid,
                   rmatrackingno = D.rmatrackingno,
                   weight = l_weight,
                   shippingcost = D.cost,
                   carriercodeused = D.carrierused,
                   actualcarrier = D.actualcarrier,
                   satdeliveryused = D.satdeliveryused,
                   status = 'SH',
                   lastuser = 'MULTISHIP',
                   lastupdate = sysdate,
                   height = D.height,
                   width = D.width,
                   length = D.length
               where lpid = M.lpid;

            if (M.status != 'SH') and (M.type in ('F','P')) then
               cnts.facility := M.facility;
               cnts.custid := M.custid;
               cnts.loadno := M.loadno;
               cnts.stopno := M.stopno;
               cnts.shipno := M.shipno;
               cnts.orderid := M.orderid;
               cnts.shipid := M.shipid;
               cnts.orderitem := M.orderitem;
               cnts.orderlot := M.orderlot;
               cnts.item := M.item;
               cnts.lotnumber := M.lotnumber;
               cnts.unitofmeasure := M.unitofmeasure;
               cnts.quantity := M.quantity;
               cnts.inventoryclass := M.inventoryclass;
               cnts.invstatus := M.invstatus;
               update_order_qtyship(cnts, l_weight);
            end if;
         end loop;
      end if;

      update orderhdr
       set final_order_closed_yn = decode(nvl(loadno,0), 0,'Y',final_order_closed_yn),
           lastupdate = sysdate,
           lastuser = 'MULTISHIP'
      where orderid = D.orderid
        and shipid = D.shipid;
<<LOOP_END>>
      commit;
      l_rid := null;

    for ix in 1..packlist_tbl.count loop
      if packlist_tbl(ix).report is not null then
        if packlist_tbl(ix).reqtype = 'S' then
          zvm.send_vics_bol_request('MULTI',
            0,
            packlist_tbl(ix).orderid,
            packlist_tbl(ix).shipid,
            'PACK',
            packlist_tbl(ix).printer,
            errno,
            errmsg);
        else
          zmnq.send_shipping_msg(packlist_tbl(ix).orderid,
                          packlist_tbl(ix).shipid,
                          packlist_tbl(ix).printer,
                          packlist_tbl(ix).report,
                          null,
						  null,
                          errmsg);
        end if;
      end if;
      if (packlist_tbl(ix).email_rpt_format is not null) and
         (packlist_tbl(ix).email_addresses is not null) then
          zmnq.send_shipping_msg(packlist_tbl(ix).orderid,
                          packlist_tbl(ix).shipid,
                          packlist_tbl(ix).printer,
                          packlist_tbl(ix).email_rpt_format,
                          null,
                          packlist_tbl(ix).email_addresses,
                          errmsg);
      end if;
      if packlist_tbl(ix).loadno = 0 then
        zld.check_for_interface(0,
                            packlist_tbl(ix).orderid,
                            packlist_tbl(ix).shipid,
                            packlist_tbl(ix).fromfacility,
                            'REGORDTYPES',
                            'REGI44SNFMT',
                            'RETORDTYPES',
                            'RETI9GIFMT',
                            'MULTISHIP',
                            errmsg);
      end if;
    end loop;

    packlist_tbl.delete;

  end loop;

exception when others then
  hold_errcode := sqlcode;
  hold_msg := substr(sqlerrm,1,255);
  rollback;
  
  -- if this was a deadlock, the rollback should have let the other transaction proceed, so try again
  if (hold_errcode = -60 and l_rid is not null) then
    update multishipdtl
    set status = 'SHIPPED'
    where rowid = l_rid;
    
    zms.log_msg('MultiShip', null, null,
      CRTN.lpid || ' - Deadlock detected, trying to process the multishipdtl again', 'W', 'MultiShip', out_msg);
  else
  zms.log_msg('MultiShip', null, null,
    CRTN.lpid || ' ' || hold_msg, 'E', 'MultiShip', out_msg);
  end if;
  commit;
END process_shipped;


PROCEDURE stage_carton
(
    in_carton    IN       varchar2,
    in_requestor IN       varchar2,
    out_errmsg   OUT      varchar2
)
IS

  cursor curChildren(in_parentlpid varchar2) is
    select lpid, weight, fromlpid, custid, item, pickuom,
           orderid, shipid, orderitem, orderlot
      from shippingplate
     where parentlpid = in_parentlpid;

  cursor curPlateChildren(in_parentlpid varchar2) is
    select lpid
      from plate
     where parentlpid = in_parentlpid;

  cursor curChildPlateSummary(in_parentlpid varchar2) is
    select count(1) as count,
           sum(quantity) as quantity
      from shippingplate
     where parentlpid = in_parentlpid;
  pcs curChildPlateSummary%rowtype;

  cursor curOrderDtl(in_orderid number, in_shipid number,
    in_orderitem varchar2, in_orderlot varchar2) is
    select *
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_orderitem
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
  ORL curOrderDtl%rowtype;

  cursor curanyshippingplate is
    select lpid
      from shippingplate
      where fromlpid in (select lpid from plate
                           start with lpid = in_carton
                           connect by prior lpid = parentlpid);

  cursor C_SHIP_ORDER(in_plpid varchar2)
  IS
    SELECT orderid, shipid
      FROM shippingplate
     WHERE parentlpid = in_plpid
     ORDER BY orderid, shipid;

  cursor curCustAux(in_custid in varchar2) is
    select allow_overpicking
      from customer_aux
     where custid = in_custid;
  caux curCustAux%rowtype;

  CRTNX plate%rowtype;
  INVLIP plate%rowtype;
  CRTN  shippingplate%rowtype;
  DIMCRTN curChildren%rowtype;

  ORD   orderhdr%rowtype;
  CUST  customer%rowtype;
  CARR  carrier%rowtype;
  msd multishipdtl%rowtype;

  errmsg varchar2(200);

  singleonly char(1);
  cnt integer;
  out_msg varchar2(255);

  l_orderid orderhdr.orderid%type;
  l_shipid orderhdr.shipid%type;
  l_type plate.type%type;
  l_uom labelprofileline.uom%type;
  l_profid labelprofileline.profid%type;
  l_msg varchar2(255);
  l_sscc multishipdtl.sscc%type;
  l_keepconfig systemdefaults.defaultvalue%type;

   function will_overship
      (in_orderid in number,
       in_shipid  in number,
       in_lpid    in varchar2)
   return boolean
   is
      cursor c_od(p_item varchar2, p_lotnumber varchar2) is
         select nvl(qtyorder,0) as qtyorder,
                nvl(qtyship,0) as qtyship
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = p_item
              and nvl(lotnumber,'(none)') = nvl(p_lotnumber,'(none)');
      od c_od%rowtype;
      l_ready shippingplate.quantity%type;
      l_overage boolean := false;
   begin
      for pl in (select item, lotnumber, sum(nvl(quantity,0)) as qtytostage
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and type in ('F','P')
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid
                  group by item, lotnumber) loop
         open c_od(pl.item, pl.lotnumber);
         fetch c_od into od;
         close c_od;
         select nvl(sum(nvl(SP.quantity,0)),0) into l_ready
            from shippingplate SP, plate LP, multishipdtl MD
            where MD.orderid = in_orderid
              and MD.shipid = in_shipid
              and MD.status in ('READY','HOLD')
              and LP.lpid = MD.cartonid
              and SP.lpid = LP.parentlpid
              and SP.item = pl.item
              and nvl(SP.lotnumber,'(none)') = nvl(pl.lotnumber,'(none)');
         if (pl.qtytostage + od.qtyship + l_ready) > od.qtyorder then
            l_overage := true;
            exit;
         end if;
      end loop;
      return l_overage;
   exception
      when OTHERS then
         return false;
   end will_overship;
BEGIN
   out_errmsg := 'OKAY';

-- read the carton and the shippingplate
   if substr(in_carton, -1) != 'S' then
     CRTNX := null;
     OPEN C_PLATE(in_carton);
     FETCH C_PLATE into CRTNX;
     CLOSE C_PLATE;
     if CRTNX.lpid is null then
         out_errmsg := 'Invalid carton. '|| in_carton;
         return;
     end if;

     if CRTNX.type = 'PA' then
        CRTNX.parentlpid := CRTNX.fromshippinglpid;
     elsif CRTNX.type = 'MP' then
        open curanyshippingplate;
        fetch curanyshippingplate into CRTNX.parentlpid;
        close curanyshippingplate;
     elsif CRTNX.type != 'XP' then
         out_errmsg := 'Specified lpid not for a carton reference.';
         return;
     end if;
   else
     CRTNX := null;
     CRTNX.parentlpid := in_carton;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if substr(in_carton, -1) = 'S' then
     CRTNX := null;
     OPEN C_PLATE(CRTN.fromlpid);
     FETCH C_PLATE into CRTNX;
     CLOSE C_PLATE;
     CRTNX.lpid := CRTN.fromlpid;
     CRTNX.parentlpid := in_carton;

   end if;

/*
   if CRTN.type not in ('C', 'M', 'F') then
       out_errmsg := 'Specified lpid not for a carton or master or full pick.';
       return;
   end if;
*/

   if CRTN.parentlpid is not null then
       out_errmsg := 'Specified lpid has a parent.';
       return;
   end if;

   if nvl(CRTN.orderid,0) = 0 and CRTN.type = 'M' and CRTNX.type = 'MP' then
      for cr in (select P.lpid lpid, S.lpid slpid
                    from plate P, shippingplate S
                    where P.parentlpid = CRTNX.lpid
                      and S.fromlpid = P.lpid)
      loop
        -- zut.prt('Found carton to do:'||cr.lpid||'/'||cr.slpid);
        -- Remove the carton from the mutliplate and recall stage_carton
        update shippingplate
           set parentlpid = null,
               lastuser = 'MULTISHIP',
               lastupdate = sysdate
         where lpid = cr.slpid;
        update plate
           set parentlpid = null,
               lastuser = 'MULTISHIP',
               lastupdate = sysdate
         where lpid = cr.lpid;
        stage_carton(cr.lpid, in_requestor, out_msg);
--        if out_msg != 'OKAY' then
--            zut.prt('...'||out_msg);
--        end if;
      end loop;
    -- Remove the parents properly
      delete from shippingplate
       where lpid = CRTN.lpid;
      if CRTNX.type != 'TO' then
        zlp.plate_to_deletedplate(CRTNX.lpid,'MULTISHIP','SG',out_msg);
        if (CRTNX.parentlpid is not null) then
          zplp.decrease_parent(CRTNX.parentlpid, CRTNX.quantity, CRTNX.weight, 'MULTISHIP',
              'SG', out_msg);
        end if;
      end if;
      return;
   end if;

-- Get order information for this carton etc.
    ORD := null;
    if CRTN.shipid = 0 then
        OPEN C_SHIP_ORDER(CRTN.lpid);
        FETCH C_SHIP_ORDER into l_orderid, l_shipid;
        CLOSE C_SHIP_ORDER;
        OPEN C_ORDHDR(l_orderid, l_shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
        ORD.orderid := CRTN.orderid;
        ORD.shipid := CRTN.shipid;
    else
        OPEN C_ORDHDR(CRTN.orderid, CRTN.shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
    end if;

    if ORD.orderid is null then
       out_errmsg := 'No order found for this carton!!!';
       return;
    end if;

-- Get carrier information
   CARR := null;
   OPEN C_CARRIER(ORD.carrier);
   FETCH C_CARRIER into CARR;
   CLOSE C_CARRIER;

-- Check if going to a small package type
   if nvl(CARR.multiship,'N') != 'Y' then
      out_errmsg := 'Not a MultiShip Carrier';
      return;
   end if;

   if nvl(ORD.ignore_multiship,'N') = 'Y' then
      if in_requestor != 'restage' then
         return;
      end if;
      caux := null;
      open curCustAux(CRTN.custid);
      fetch curCustAux into caux;
      close curCustAux;
      if nvl(caux.allow_overpicking,'N') != 'Y' then
         if will_overship(ORD.orderid, ORD.shipid, CRTN.lpid) then
            out_errmsg := 'Plate would cause shipped qty to exceed ordered qty';
            return;
         end if;
      end if;
   end if;

-- Add to multiship table
   add_multishiphdr(ORD, in_requestor, errmsg);
   if errmsg != 'OKAY' then
      out_errmsg := errmsg;
      return;
   end if;

   singleonly := 'N';
   if CRTN.type in ('M') then
    begin
      select zwv.single_shipping_units_only(ORD.orderid, ORD.shipid)
        into singleonly
        from dual;
    exception when others then
      singleonly := 'N';
    end;
   end if;
   if singleonly = 'Y' then
     pcs := null;
     open curChildPlateSummary(CRTN.lpid);
     fetch curChildPlateSummary into pcs;
     close curChildPlateSummary;
     if (pcs.count = 1) and
        (nvl(pcs.quantity,0) = CRTN.quantity) then
       singleonly := 'N';
     else
       cnt := 0;
       begin
         select count(1)
           into cnt
           from shippingplate
          where parentlpid = CRTN.lpid
            and type = 'P';
       exception when others then
         cnt := 1;
       end;
       if cnt <> 0 then
         singleonly := 'N';
       end if;
     end if;
   end if;

   begin
    select upper(defaultvalue) into l_keepconfig
    from systemdefaults
    where defaultid = 'RESTAGEKEEPCONFIGURATION';

    if (l_keepconfig = 'Y') then
      singleonly := 'N';
    end if;
   exception
    when others then
      null;
   end;

   if singleonly = 'Y' then -- single shipping units only -- break apart multi pallet
     for ch in curChildren(CRTN.lpid)
     loop
       update shippingplate
          set parentlpid = null,
              lastuser = 'MULTISHIP',
              lastupdate = sysdate
        where lpid = ch.lpid;
       msd := null;
       begin
         select orderid, shipid, status
           into msd.orderid, msd.shipid, msd.status
           from multishipdtl
          where cartonid = CRTN.fromlpid;
       exception when others then
         null;
       end;
       if msd.orderid is not null and in_requestor != 'restage' then
         zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
           'Multiship duplicate: ' || CRTN.lpid || ' ' || msd.orderid || '-' || msd.shipid  || ' ' || msd.status,
           'E', 'MULTISHIP', errMsg);
       else
         ORL := null;
         open curOrderDtl(CH.orderid,CH.shipid,CH.orderitem,CH.orderlot);
         fetch curOrderDtl into ORL;
         close curOrderdtl;
         l_sscc := find_sscc(CH.lpid);
         if msd.orderid is null then
           begin
             insert into multishipdtl(
                 orderid,
                 shipid,
                 cartonid,
                 estweight,
                 status,
                 length,
                 width,
                 height,
                 dtlpassthruchar01,
                 dtlpassthruchar02,
                 dtlpassthruchar03,
                 dtlpassthruchar04,
                 dtlpassthruchar05,
                 dtlpassthruchar06,
                 dtlpassthruchar07,
                 dtlpassthruchar08,
                 dtlpassthruchar09,
                 dtlpassthruchar10,
                 dtlpassthruchar11,
                 dtlpassthruchar12,
                 dtlpassthruchar13,
                 dtlpassthruchar14,
                 dtlpassthruchar15,
                 dtlpassthruchar16,
                 dtlpassthruchar17,
                 dtlpassthruchar18,
                 dtlpassthruchar19,
                 dtlpassthruchar20,
                 dtlpassthrunum01,
                 dtlpassthrunum02,
                 dtlpassthrunum03,
                 dtlpassthrunum04,
                 dtlpassthrunum05,
                 dtlpassthrunum06,
                 dtlpassthrunum07,
                 dtlpassthrunum08,
                 dtlpassthrunum09,
                 dtlpassthrunum10,
                 dtlpassthrudate01,
                 dtlpassthrudate02,
                 dtlpassthrudate03,
                 dtlpassthrudate04,
                 dtlpassthrudoll01,
                 dtlpassthrudoll02,
                 sscc
             )
             values (
                 ORD.orderid,
                 ORD.shipid,
                 correct_fromlpid(CH.fromlpid),
                 round(CH.weight,4),
                 decode(zcu.credit_hold(ch.custid),'Y','HOLD','READY'),
                 zci.item_uom_length(ch.custid,ch.item,ch.pickuom),
                 zci.item_uom_width(ch.custid,ch.item,ch.pickuom),
                 zci.item_uom_height(ch.custid,ch.item,ch.pickuom),
                 ORL.dtlpassthruchar01,
                 ORL.dtlpassthruchar02,
                 ORL.dtlpassthruchar03,
                 ORL.dtlpassthruchar04,
                 ORL.dtlpassthruchar05,
                 ORL.dtlpassthruchar06,
                 ORL.dtlpassthruchar07,
                 ORL.dtlpassthruchar08,
                 ORL.dtlpassthruchar09,
                 ORL.dtlpassthruchar10,
                 ORL.dtlpassthruchar11,
                 ORL.dtlpassthruchar12,
                 ORL.dtlpassthruchar13,
                 ORL.dtlpassthruchar14,
                 ORL.dtlpassthruchar15,
                 ORL.dtlpassthruchar16,
                 ORL.dtlpassthruchar17,
                 ORL.dtlpassthruchar18,
                 ORL.dtlpassthruchar19,
                 ORL.dtlpassthruchar20,
                 ORL.dtlpassthrunum01,
                 ORL.dtlpassthrunum02,
                 ORL.dtlpassthrunum03,
                 ORL.dtlpassthrunum04,
                 ORL.dtlpassthrunum05,
                 ORL.dtlpassthrunum06,
                 ORL.dtlpassthrunum07,
                 ORL.dtlpassthrunum08,
                 ORL.dtlpassthrunum09,
                 ORL.dtlpassthrunum10,
                 ORL.dtlpassthrudate01,
                 ORL.dtlpassthrudate02,
                 ORL.dtlpassthrudate03,
                 ORL.dtlpassthrudate04,
                 ORL.dtlpassthrudoll01,
                 ORL.dtlpassthrudoll02,
                 l_sscc
             );
           exception when others then
             out_errmsg := sqlerrm;
             zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
               'MultishipDtl Insert: ' || out_errmsg,
               'E', 'MULTISHIP', errMsg);
             return;
           end;
           add_multishipitems(ORD.orderid, ORD.shipid,
               correct_fromlpid(CH.fromlpid), errmsg);
         else
           begin
             update multishipdtl
                set orderid = ORD.orderid,
                    shipid = ORD.shipid,
                    estweight = round(CH.weight,4),
                    status = decode(zcu.credit_hold(ch.custid),'Y','HOLD','READY'),
                    length = zci.item_uom_length(ch.custid,ch.item,ch.pickuom),
                    width = zci.item_uom_width(ch.custid,ch.item,ch.pickuom),
                    height = zci.item_uom_height(ch.custid,ch.item,ch.pickuom),
                    dtlpassthruchar01 = ORL.dtlpassthruchar01,
                    dtlpassthruchar02 = ORL.dtlpassthruchar02,
                    dtlpassthruchar03 = ORL.dtlpassthruchar03,
                    dtlpassthruchar04 = ORL.dtlpassthruchar04,
                    dtlpassthruchar05 = ORL.dtlpassthruchar05,
                    dtlpassthruchar06 = ORL.dtlpassthruchar06,
                    dtlpassthruchar07 = ORL.dtlpassthruchar07,
                    dtlpassthruchar08 = ORL.dtlpassthruchar08,
                    dtlpassthruchar09 = ORL.dtlpassthruchar09,
                    dtlpassthruchar10 = ORL.dtlpassthruchar10,
                    dtlpassthruchar11 = ORL.dtlpassthruchar11,
                    dtlpassthruchar12 = ORL.dtlpassthruchar12,
                    dtlpassthruchar13 = ORL.dtlpassthruchar13,
                    dtlpassthruchar14 = ORL.dtlpassthruchar14,
                    dtlpassthruchar15 = ORL.dtlpassthruchar15,
                    dtlpassthruchar16 = ORL.dtlpassthruchar16,
                    dtlpassthruchar17 = ORL.dtlpassthruchar17,
                    dtlpassthruchar18 = ORL.dtlpassthruchar18,
                    dtlpassthruchar19 = ORL.dtlpassthruchar19,
                    dtlpassthruchar20 = ORL.dtlpassthruchar20,
                    dtlpassthrunum01 = ORL.dtlpassthrunum01,
                    dtlpassthrunum02 = ORL.dtlpassthrunum02,
                    dtlpassthrunum03 = ORL.dtlpassthrunum03,
                    dtlpassthrunum04 = ORL.dtlpassthrunum04,
                    dtlpassthrunum05 = ORL.dtlpassthrunum05,
                    dtlpassthrunum06 = ORL.dtlpassthrunum06,
                    dtlpassthrunum07 = ORL.dtlpassthrunum07,
                    dtlpassthrunum08 = ORL.dtlpassthrunum08,
                    dtlpassthrunum09 = ORL.dtlpassthrunum09,
                    dtlpassthrunum10 = ORL.dtlpassthrunum10,
                    dtlpassthrudate01 = ORL.dtlpassthrudate01,
                    dtlpassthrudate02 = ORL.dtlpassthrudate02,
                    dtlpassthrudate03 = ORL.dtlpassthrudate03,
                    dtlpassthrudate04 = ORL.dtlpassthrudate04,
                    dtlpassthrudoll01 = ORL.dtlpassthrudoll01,
                    dtlpassthrudoll02 = ORL.dtlpassthrudoll02,
                    sscc = l_sscc
              where cartonid = CRTNX.fromlpid;
           exception when others then
             out_errmsg := sqlerrm;
             zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
               'MultishipDtl Update: ' || out_errmsg,
               'E', 'MULTISHIP', errMsg);
             return;
           end;
         end if;
       end if;
     end loop;
     delete from shippingplate
      where lpid = CRTN.lpid;
     for ch in curPlateChildren(CRTN.fromlpid)
     loop
       update plate
          set parentlpid = null,
              lastuser = 'MULTISHIP',
              lastupdate = sysdate
        where lpid = ch.lpid;
     end loop;

     begin
       select type into l_type
         from plate
         where lpid = CRTN.fromlpid;
     exception
       when others then
         l_type := 'PA';
     end;
     if l_type != 'TO' then
       zlp.plate_to_deletedplate(CRTN.fromlpid,'MULTISHIP','SG',out_msg);
       if (CRTN.parentlpid is not null) then
         zplp.decrease_parent(CRTN.parentlpid, CRTN.quantity, CRTN.weight, 'MULTISHIP',
             'SG', out_msg);
       end if;
     end if;
   else
     -- Add entry for this Carton
     msd := null;
     begin
       select orderid, shipid, status
         into msd.orderid, msd.shipid, msd.status
         from multishipdtl
        where cartonid = CRTNX.lpid;
     exception when others then
       null;
     end;
     if msd.orderid is not null and in_requestor != 'restage' then
       zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
         'Multiship duplicate: ' || CRTN.lpid || ' ' || msd.orderid || '-' || msd.shipid  || ' ' || msd.status,
         'E', 'MULTISHIP', errMsg);
     else
       if (CRTN.pickuom is null) then
         open curChildren(CRTN.lpid);
         fetch curChildren into DIMCRTN;
         if curChildren%notfound then
           DIMCRTN.item := CRTN.item;
           DIMCRTN.orderitem := CRTN.orderitem;
           DIMCRTN.pickuom := CRTN.pickuom;
           DIMCRTN.orderlot := CRTN.orderlot;
         end if;
         close curChildren;
       else
         DIMCRTN.item := CRTN.item;
         DIMCRTN.orderitem := CRTN.orderitem;
         DIMCRTN.pickuom := CRTN.pickuom;
         DIMCRTN.orderlot := CRTN.orderlot;
       end if;
       ORL := null;
       open curOrderDtl(DIMCRTN.orderid,DIMCRTN.shipid,
            DIMCRTN.orderitem,DIMCRTN.orderlot);
       fetch curOrderDtl into ORL;
       close curOrderdtl;
       l_sscc := find_sscc(CRTN.lpid);
       if msd.orderid is null then
         begin
           insert into multishipdtl(
               orderid,
               shipid,
               cartonid,
               estweight,
               status,
               length,
               width,
               height,
               dtlpassthruchar01,
               dtlpassthruchar02,
               dtlpassthruchar03,
               dtlpassthruchar04,
               dtlpassthruchar05,
               dtlpassthruchar06,
               dtlpassthruchar07,
               dtlpassthruchar08,
               dtlpassthruchar09,
               dtlpassthruchar10,
               dtlpassthruchar11,
               dtlpassthruchar12,
               dtlpassthruchar13,
               dtlpassthruchar14,
               dtlpassthruchar15,
               dtlpassthruchar16,
               dtlpassthruchar17,
               dtlpassthruchar18,
               dtlpassthruchar19,
               dtlpassthruchar20,
               dtlpassthrunum01,
               dtlpassthrunum02,
               dtlpassthrunum03,
               dtlpassthrunum04,
               dtlpassthrunum05,
               dtlpassthrunum06,
               dtlpassthrunum07,
               dtlpassthrunum08,
               dtlpassthrunum09,
               dtlpassthrunum10,
               dtlpassthrudate01,
               dtlpassthrudate02,
               dtlpassthrudate03,
               dtlpassthrudate04,
               dtlpassthrudoll01,
               dtlpassthrudoll02,
               sscc
           )
           values (
               ORD.orderid,
               ORD.shipid,
               correct_fromlpid(CRTNX.lpid),
               round(CRTN.weight,4),
               decode(zcu.credit_hold(CRTN.custid),'Y','HOLD','READY'),
               zci.item_uom_length(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
               zci.item_uom_width(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
               zci.item_uom_height(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
               ORL.dtlpassthruchar01,
               ORL.dtlpassthruchar02,
               ORL.dtlpassthruchar03,
               ORL.dtlpassthruchar04,
               ORL.dtlpassthruchar05,
               ORL.dtlpassthruchar06,
               ORL.dtlpassthruchar07,
               ORL.dtlpassthruchar08,
               ORL.dtlpassthruchar09,
               ORL.dtlpassthruchar10,
               ORL.dtlpassthruchar11,
               ORL.dtlpassthruchar12,
               ORL.dtlpassthruchar13,
               ORL.dtlpassthruchar14,
               ORL.dtlpassthruchar15,
               ORL.dtlpassthruchar16,
               ORL.dtlpassthruchar17,
               ORL.dtlpassthruchar18,
               ORL.dtlpassthruchar19,
               ORL.dtlpassthruchar20,
               ORL.dtlpassthrunum01,
               ORL.dtlpassthrunum02,
               ORL.dtlpassthrunum03,
               ORL.dtlpassthrunum04,
               ORL.dtlpassthrunum05,
               ORL.dtlpassthrunum06,
               ORL.dtlpassthrunum07,
               ORL.dtlpassthrunum08,
               ORL.dtlpassthrunum09,
               ORL.dtlpassthrunum10,
               ORL.dtlpassthrudate01,
               ORL.dtlpassthrudate02,
               ORL.dtlpassthrudate03,
               ORL.dtlpassthrudate04,
               ORL.dtlpassthrudoll01,
               ORL.dtlpassthrudoll02,
               l_sscc
           );
         exception when others then
           out_errmsg := sqlerrm;
           zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
             'MultishipDtl Insert: ' || out_errmsg,
             'E', 'MULTISHIP', errMsg);
           return;
         end;
         add_multishipitems(ORD.orderid, ORD.shipid,
             correct_fromlpid(CRTNX.fromlpid), errmsg);
       else
         begin
           update multishipdtl
              set orderid = ORD.orderid,
                  shipid = ORD.shipid,
                  estweight = round(CRTN.weight,4),
                  status = decode(zcu.credit_hold(CRTN.custid),'Y','HOLD','READY'),
                  length = zci.item_uom_length(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
                  width = zci.item_uom_width(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
                  height = zci.item_uom_height(CRTN.custid,DIMCRTN.item,DIMCRTN.pickuom),
                  dtlpassthruchar01 = ORL.dtlpassthruchar01,
                  dtlpassthruchar02 = ORL.dtlpassthruchar02,
                  dtlpassthruchar03 = ORL.dtlpassthruchar03,
                  dtlpassthruchar04 = ORL.dtlpassthruchar04,
                  dtlpassthruchar05 = ORL.dtlpassthruchar05,
                  dtlpassthruchar06 = ORL.dtlpassthruchar06,
                  dtlpassthruchar07 = ORL.dtlpassthruchar07,
                  dtlpassthruchar08 = ORL.dtlpassthruchar08,
                  dtlpassthruchar09 = ORL.dtlpassthruchar09,
                  dtlpassthruchar10 = ORL.dtlpassthruchar10,
                  dtlpassthruchar11 = ORL.dtlpassthruchar11,
                  dtlpassthruchar12 = ORL.dtlpassthruchar12,
                  dtlpassthruchar13 = ORL.dtlpassthruchar13,
                  dtlpassthruchar14 = ORL.dtlpassthruchar14,
                  dtlpassthruchar15 = ORL.dtlpassthruchar15,
                  dtlpassthruchar16 = ORL.dtlpassthruchar16,
                  dtlpassthruchar17 = ORL.dtlpassthruchar17,
                  dtlpassthruchar18 = ORL.dtlpassthruchar18,
                  dtlpassthruchar19 = ORL.dtlpassthruchar19,
                  dtlpassthruchar20 = ORL.dtlpassthruchar20,
                  dtlpassthrunum01 = ORL.dtlpassthrunum01,
                  dtlpassthrunum02 = ORL.dtlpassthrunum02,
                  dtlpassthrunum03 = ORL.dtlpassthrunum03,
                  dtlpassthrunum04 = ORL.dtlpassthrunum04,
                  dtlpassthrunum05 = ORL.dtlpassthrunum05,
                  dtlpassthrunum06 = ORL.dtlpassthrunum06,
                  dtlpassthrunum07 = ORL.dtlpassthrunum07,
                  dtlpassthrunum08 = ORL.dtlpassthrunum08,
                  dtlpassthrunum09 = ORL.dtlpassthrunum09,
                  dtlpassthrunum10 = ORL.dtlpassthrunum10,
                  dtlpassthrudate01 = ORL.dtlpassthrudate01,
                  dtlpassthrudate02 = ORL.dtlpassthrudate02,
                  dtlpassthrudate03 = ORL.dtlpassthrudate03,
                  dtlpassthrudate04 = ORL.dtlpassthrudate04,
                  dtlpassthrudoll01 = ORL.dtlpassthrudoll01,
                  dtlpassthrudoll02 = ORL.dtlpassthrudoll02,
                  sscc = l_sscc
            where cartonid = CRTN.fromlpid;
         exception when others then
           out_errmsg := sqlerrm;
           zms.log_msg('StgOrder', CRTN.facility, CRTN.custid,
             'MultishipDtl Update: ' || out_errmsg,
             'E', 'MULTISHIP', errMsg);
           return;
         end;
       end if;
     end if;
   end if;

-- if the customer is paperbased (AI) and labels would have printed for the
-- SOUL businessevent and there is a ucc128 value in the shippingplate, then
-- update the cartonid to the ucc128 value
   CUST := null;
   OPEN C_CUST(CRTN.custid);
   FETCH C_CUST into CUST;
   CLOSE C_CUST;
   if nvl(CUST.paperbased,'N') = 'Y' and CRTN.ucc128 is not null then
      zlbl.get_plate_profid_aux('SOUL', null, 'S', 'A', 'ORDER|'||CRTN.orderid||'|'||CRTN.shipid,
            l_uom, l_profid, l_msg);
      if l_profid is not null then
         update multishipdtl
            set cartonid = CRTN.ucc128
            where cartonid = CRTN.fromlpid;
      end if;
   end if;

exception when others then
  out_errmsg := sqlerrm;
END stage_carton;


----------------------------------------------------------------------
--
-- restage_cartons
--
----------------------------------------------------------------------
PROCEDURE restage_cartons
(
    in_orderid   IN       number,
    in_shipid    IN       number,
    out_errorno  OUT      number
)
IS

  CSP shippingplate%rowtype;
  l_qcount integer;
  strMsg varchar2(255);

BEGIN

  l_qcount := 0;
  out_errorno := 0;

-- Verify order exists
  CSP := null;
  for CSP in C_SP(in_orderid, in_shipid)
  loop
    stage_carton(CSP.lpid, 'restage', strMsg);
    if (strMsg != 'OKAY') then
      l_qcount := l_qcount + 1;
    end if;
  end loop;

  out_errorno := l_qcount;

exception when others then
  out_errorno := -1;
  zms.log_autonomous_msg('MULTISHIP', null, null,
    sqlerrm,
    'E', 'MULTISHIP', strMsg);
  rollback;
END restage_cartons;

----------------------------------------------------------------------
--
-- add_multishipitems
--
----------------------------------------------------------------------
PROCEDURE add_multishipitems
(
    in_orderid   IN         number,
    in_shipid    IN         number,
    in_carton    IN         varchar2,
    out_errmsg   IN OUT     varchar2
)
IS
  CRTNX     plate%rowtype;
  CRTN      shippingplate%rowtype;
  ORD       orderhdr%rowtype;
  DTL       orderdtl%rowtype;
  CA        customer_aux%rowtype;

  cursor C_DTL(in_orderid number, in_shipid number,
    in_orderitem varchar2, in_orderlot varchar2) is
    select *
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_orderitem
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');


  cursor curanyshippingplate is
    select lpid
      from shippingplate
      where fromlpid in (select lpid from plate
                           start with lpid = in_carton
                           connect by prior lpid = parentlpid);

  cursor C_ITEM(in_custid varchar2, in_item varchar2) IS
    select *
      from custitem
     where custid = in_custid
       and item = in_item;

ITM custitem%rowtype;

CURSOR C_DFLT(in_id varchar2)
IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;


DFLT C_DFLT%rowtype;


BEGIN
    out_errmsg := 'OKAY';

-- Check if need to write out
    DFLT := null;
    OPEN C_DFLT('MULTISHIPITEMS');
    FETCH C_DFLT into DFLT;
    CLOSE C_DFLT;

-- Get orderhdr
    ORD := null;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

-- Get Customer
    CA := null;
    OPEN C_CA(ORD.custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

    if nvl(CA.shipping_insurance,'N') != 'Y'
     and nvl(DFLT.defaultvalue,'N') != 'Y' then
        return;
    end if;


-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;

   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton. '|| in_carton;
       return;
   end if;

   if CRTNX.type = 'PA' then
      CRTNX.parentlpid := CRTNX.fromshippinglpid;
   elsif CRTNX.type = 'MP' then
      open curanyshippingplate;
      fetch curanyshippingplate into CRTNX.parentlpid;
      close curanyshippingplate;
   elsif CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;




    for crec in (select custid, item, lotnumber, orderitem, orderlot,
                    unitofmeasure,
                        sum(quantity) quantity
                   from shippingplate
                  where type in ('F','P')
                start with lpid = CRTN.lpid
                connect by prior lpid = parentlpid
                group by custid, item, lotnumber, orderitem, orderlot,
                    unitofmeasure)
    loop

    -- Read Orderdtl Line
        DTL := null;
        OPEN C_DTL(in_orderid, in_shipid, crec.orderitem, crec.orderlot);
        FETCH C_DTL into DTL;
        CLOSE C_DTL;


    -- Read item
        ITM := null;
        OPEN C_ITEM(crec.custid, zci.item_code(crec.custid,crec.item));
        FETCH C_ITEM into ITM;
        CLOSE C_ITEM;

        if nvl(DFLT.defaultvalue, 'N') = 'Y' then
          insert into multishipitems (
            orderid,
            shipid,
            cartonid,
            item,
            lotnumber,
            quantity,
            uom,
            useramt1,
            useramt2,
            itmpassthruchar01,
            itmpassthruchar02,
            itmpassthruchar03,
            itmpassthruchar04,
            itmpassthrunum01,
            itmpassthrunum02,
            itmpassthrunum03,
            itmpassthrunum04,
            dtlpassthruchar01,
            dtlpassthruchar02,
            dtlpassthruchar03,
            dtlpassthruchar04,
            dtlpassthruchar05,
            dtlpassthruchar06,
            dtlpassthruchar07,
            dtlpassthruchar08,
            dtlpassthruchar09,
            dtlpassthruchar10,
            dtlpassthruchar11,
            dtlpassthruchar12,
            dtlpassthruchar13,
            dtlpassthruchar14,
            dtlpassthruchar15,
            dtlpassthruchar16,
            dtlpassthruchar17,
            dtlpassthruchar18,
            dtlpassthruchar19,
            dtlpassthruchar20,
            dtlpassthrunum01,
            dtlpassthrunum02,
            dtlpassthrunum03,
            dtlpassthrunum04,
            dtlpassthrunum05,
            dtlpassthrunum06,
            dtlpassthrunum07,
            dtlpassthrunum08,
            dtlpassthrunum09,
            dtlpassthrunum10,
            dtlpassthrudate01,
            dtlpassthrudate02,
            dtlpassthrudate03,
            dtlpassthrudate04,
            dtlpassthrudoll01,
            dtlpassthrudoll02
          )
          values (
            in_orderid,
            in_shipid,
            in_carton,
            crec.item,
            crec.lotnumber,
            crec.quantity,
            crec.unitofmeasure,
            zci.item_amt(crec.custid,in_orderid,in_shipid,crec.item,crec.lotnumber),
            ITM.useramt2,
            ITM.itmpassthruchar01,
            ITM.itmpassthruchar02,
            ITM.itmpassthruchar03,
            ITM.itmpassthruchar04,
            ITM.itmpassthrunum01,
            ITM.itmpassthrunum02,
            ITM.itmpassthrunum03,
            ITM.itmpassthrunum04,
            DTL.dtlpassthruchar01,
            DTL.dtlpassthruchar02,
            DTL.dtlpassthruchar03,
            DTL.dtlpassthruchar04,
            DTL.dtlpassthruchar05,
            DTL.dtlpassthruchar06,
            DTL.dtlpassthruchar07,
            DTL.dtlpassthruchar08,
            DTL.dtlpassthruchar09,
            DTL.dtlpassthruchar10,
            DTL.dtlpassthruchar11,
            DTL.dtlpassthruchar12,
            DTL.dtlpassthruchar13,
            DTL.dtlpassthruchar14,
            DTL.dtlpassthruchar15,
            DTL.dtlpassthruchar16,
            DTL.dtlpassthruchar17,
            DTL.dtlpassthruchar18,
            DTL.dtlpassthruchar19,
            DTL.dtlpassthruchar20,
            DTL.dtlpassthrunum01,
            DTL.dtlpassthrunum02,
            DTL.dtlpassthrunum03,
            DTL.dtlpassthrunum04,
            DTL.dtlpassthrunum05,
            DTL.dtlpassthrunum06,
            DTL.dtlpassthrunum07,
            DTL.dtlpassthrunum08,
            DTL.dtlpassthrunum09,
            DTL.dtlpassthrunum10,
            DTL.dtlpassthrudate01,
            DTL.dtlpassthrudate02,
            DTL.dtlpassthrudate03,
            DTL.dtlpassthrudate04,
            DTL.dtlpassthrudoll01,
            DTL.dtlpassthrudoll02
         );
        end if;


        if nvl(CA.shipping_insurance,'N') = 'Y' then
            update multishipdtl
               set total_price = nvl(total_price,0)
                    + crec.quantity * nvl(zci.item_amt(crec.custid,in_orderid,in_shipid,crec.item,crec.lotnumber),0),
                   shipping_insurance = ceil( (nvl(total_price,0)
                    + crec.quantity * nvl(zci.item_amt(crec.custid,in_orderid,in_shipid,crec.item,crec.lotnumber),0))/100) * 100
             where orderid = in_orderid
               and shipid = in_shipid
               and cartonid = in_carton;
        end if;


    end loop;



exception when others then
  out_errmsg := sqlerrm;
END add_multishipitems;


----------------------------------------------------------------------
--
-- send_shipped_msg
--
----------------------------------------------------------------------
PROCEDURE send_shipped_msg
(
    in_cartonid  IN         varchar2,
    out_errmsg   IN OUT     varchar2
)
IS
  l_status integer;
  l_qcount integer;
  l_qmsg qmsg := qmsg('SHIPPED', in_cartonid);
  strMsg varchar2(255);

BEGIN

  out_errmsg := 'OKAY';

  begin
    select count(1)
      into l_qcount
      from qt_rp_multiship;
  exception when others then
    l_qcount := 0;
  end;
  if l_qcount < 2 then
    l_status := zqm.send(zmnq.MULTISHIP_DEFAULT_QUEUE,
                         l_qmsg.trans, l_qmsg.message, 1, null);
    if l_status != 1 then
      out_errmsg := 'Unable to send shipped carton ' || in_cartonid ||
       ' to multiship queue';
      zms.log_autonomous_msg('MULTISHIP', null, null,
        out_errmsg,
        'E', 'MULTISHIP', strMsg);
    end if;
  end if;

exception when others then
  zms.log_autonomous_msg('MULTISHIP', null, null,
    sqlerrm,
    'E', 'MULTISHIP', strMsg);
  rollback;
END send_shipped_msg;


----------------------------------------------------------------------
--
-- change_order
--
----------------------------------------------------------------------
PROCEDURE change_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    out_errmsg    OUT     varchar2
)
is
  ORD   orderhdr%rowtype;
  MSHDR multishiphdr%rowtype;
  CON   consignee%rowtype;
  mc curMultiShipCode%rowtype;
  CARR  carrier%rowtype;
  ss curSpecialService%rowtype;
begin

   out_errmsg := 'OKAY';

-- Verify order exists
   ORD := null;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR into ORD;
   CLOSE C_ORDHDR;

   if ORD.orderid is null then
      out_errmsg := 'Order does not exist';
      return;
   end if;

   CARR := null;
   OPEN C_CARRIER(ORD.carrier);
   FETCH C_CARRIER into CARR;
   CLOSE C_CARRIER;

   if nvl(CARR.multiship,'N') != 'Y' then
     out_errmsg := 'Order not associated with a MultiShip Carrier';
     return;
   end if;

   MSHDR.custid := ORD.custid;
   MSHDR.carrier := ORD.carrier;
   mc := null;
   open curMultiShipCode(ORD.carrier,ORD.deliveryservice);
   fetch curMultiShipCode into mc;
   close curMultiShipCode;
   MSHDR.carriercode := mc.MultiShipCode;
   if nvl(ORD.saturdaydelivery,'N') = 'Y' then
      MSHDR.satdelivery := 'Y';
   else
      MSHDR.satdelivery := 'N';
   end if;
   MSHDR.terms := ORD.shipterms;
   MSHDR.orderstatus := ORD.orderstatus;
   MSHDR.orderpriority := ORD.priority;
   MSHDR.ordercomments := substr(ORD.comment1,1,80);
   MSHDR.reference := ORD.reference;
   MSHDR.cod := ORD.cod;
   MSHDR.amtcod := ORD.amtcod;
   MSHDR.po := ORD.po;
   if ORD.specialservice1 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice1);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice1 := ss.multishipcode;
   end if;
   if ORD.specialservice2 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice2);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice2 := ss.multishipcode;
   end if;
   if ORD.specialservice3 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice3);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice3 := ss.multishipcode;
   end if;
   if ORD.specialservice4 is not null then
     ss := null;
     open curSpecialService(ord.carrier,ord.deliveryservice,ord.specialservice4);
     fetch curSpecialService into ss;
     close curSpecialService;
     MSHDR.specialservice4 := ss.multishipcode;
   end if;

   if ORD.shipto is not null then
      CON := null;
      OPEN C_CONSIGNEE(ORD.shipto);
      FETCH C_CONSIGNEE into CON;
      CLOSE C_CONSIGNEE;
      if CON.consignee is null then
        out_errmsg := 'Invalid consignee entry';
        return;
      end if;
      MSHDR.shiptoname := CON.name;
      MSHDR.shiptocontact := CON.contact;
      MSHDR.shiptoaddr1 := CON.addr1;
      MSHDR.shiptoaddr2 := CON.addr2;
      MSHDR.shiptocity := CON.city;
      MSHDR.shiptostate := CON.state;
      MSHDR.shiptostate := CON.state;
      MSHDR.shiptopostalcode := CON.postalcode;
      MSHDR.shiptocountrycode := CON.countrycode;
      MSHDR.shiptophone := CON.phone;
   else
      MSHDR.shiptoname := ORD.shiptoname;
      MSHDR.shiptocontact := ORD.shiptocontact;
      MSHDR.shiptoaddr1 := ORD.shiptoaddr1;
      MSHDR.shiptoaddr2 := ORD.shiptoaddr2;
      MSHDR.shiptocity := ORD.shiptocity;
      MSHDR.shiptostate := ORD.shiptostate;
      MSHDR.shiptopostalcode := ORD.shiptopostalcode;
      MSHDR.shiptocountrycode := ORD.shiptocountrycode;
      MSHDR.shiptophone := ORD.shiptophone;
   end if;

   update multishiphdr
      set custid = MSHDR.custid,
          carrier = MSHDR.carrier,
          carriercode = MSHDR.carriercode,
          satdelivery = MSHDR.satdelivery,
          terms = MSHDR.terms,
          orderstatus = MSHDR.orderstatus,
          orderpriority = MSHDR.orderpriority,
          ordercomments = MSHDR.ordercomments,
          reference = MSHDR.reference,
          shiptoname = MSHDR.shiptoname,
          shiptocontact = MSHDR.shiptocontact,
          shiptoaddr1 = MSHDR.shiptoaddr1,
          shiptoaddr2 = MSHDR.shiptoaddr2,
          shiptocity = MSHDR.shiptocity,
          shiptostate = MSHDR.shiptostate,
          shiptopostalcode = MSHDR.shiptopostalcode,
          shiptocountrycode = MSHDR.shiptocountrycode,
          shiptophone = MSHDR.shiptophone,
          cod = MSHDR.cod,
          amtcod = MSHDR.amtcod,
          specialservice1 = MSHDR.specialservice1,
          specialservice2 = MSHDR.specialservice2,
          specialservice3 = MSHDR.specialservice3,
          specialservice4 = MSHDR.specialservice4,
          po = MSHDR.po
    where orderid = in_orderid
      and shipid = in_shipid;

exception when others then
  out_errmsg := substr(sqlerrm,1,255);
end change_order;

function get_actualcarrier
(
   in_shippingplate_lpid IN varchar2
) return varchar2
is

cursor curShippingPlate is
  select actualcarrier,
         loadno,
         orderid,
         shipid
    from shippingplate
   where lpid = in_shippingplate_lpid;
sp curShippingPlate%rowtype;

cursor curLoad(in_loadno number) is
  select carrier
    from loads
   where loadno = in_loadno;
ld curLoad%rowtype;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select carrier
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

begin

sp := null;
open curShippingPlate;
fetch curShippingPlate into sp;
close curShippingPlate;

if sp.actualcarrier is not null then
  return sp.actualcarrier;
end if;

if nvl(sp.loadno,0) <> 0 then
  ld := null;
  open curLoad(sp.loadno);
  fetch curLoad into ld;
  close curLoad;
  if ld.carrier is not null then
    return ld.carrier;
  end if;
end if;

oh := null;
open curOrderHdr(sp.orderid,sp.shipid);
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.carrier is not null then
  return oh.carrier;
end if;

return null;

exception when others then
  return null;
end get_actualcarrier;

function get_tracker_url
(
  in_actualcarrier IN varchar2,
  in_trackingno    IN varchar2
)
return varchar2
is
theURL varchar2(255);
begin

   if in_trackingno is null then
     return null;
   end if;

   theURL := null;
   if in_actualcarrier is not null then
     select trackerurl into theURL from carrier where carrier = in_actualcarrier;
   end if;

   if theURL is not null then
     theURL := substr(theURL,1,instr(theURL,'{')-1)||in_trackingno||substr(theURL,instr(theURL,'}')+1);
   end if;

   return theURL;

exception when others then
  return null;
end get_tracker_url;

PROCEDURE send_staged_carton_trigger(
    in_facility     varchar2,
    in_custid       varchar2,
    in_termid       varchar2,
    in_lpid         varchar2,
    in_userid       varchar2,
    out_errmsg      out   varchar2
)
IS
CURSOR C_DFLT(in_id varchar2)
IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;

expmap varchar2(255);

errno integer;
errmsg varchar2(255);

fh utl_file.file_type;
  l_seq integer;


BEGIN
    out_errmsg := 'OKAY';

/*
    fh := utl_file.fopen('MAL_DIR',
        in_termid||to_char(sysdate,'YYYYMMDDHH24MISS'),'w');

    utl_file.put_line(fh, in_lpid||chr(9)||in_facility||chr(9)||in_termid);
    utl_file.fclose(fh);


    return;

*/

-- Check if we have a map to export
    expmap := null;
    OPEN C_DFLT('STAGEDCARTONTRIGGERMAP');
    FETCH C_DFLT into expmap;
    CLOSE C_DFLT;

    if expmap is null then
        return;
    end if;


-- If no termid no export
    if in_termid is null then
        out_errmsg := 'No Multiship Terminal Specified.';
        return;
    end if;

-- If no lpid no export
    if in_lpid is null then
        out_errmsg := 'No Carton ID Specified';
        return;
    end if;

    l_seq := 0;
    select malvernfileseq.nextval
      into l_seq
      from dual;


-- Create an IE request for the carton
    ziem.impexp_request('E',null, in_custid,
      expmap,
--      'TRM'||in_termid||'-'||in_facility||'-'||l_seq,
      'TRM'||in_termid||'-'||in_facility||'-'||in_lpid,
      'NOW',
      0,0,0,
      substr(rpad(in_lpid,15),1,15)||rpad(in_facility,3)||in_termid, --in_userid,
      null,null,null,null,null,
      null,null,errno,errmsg);



exception when others then
  out_errmsg := sqlerrm;
END send_staged_carton_trigger;

PROCEDURE check_and_send_carton_trigger(
    in_facility     varchar2,
    in_termid       varchar2,
    in_lpid         varchar2,
    in_item         varchar2,
    in_userid       varchar2,
    out_errmsg      out   varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;
  ORD orderhdr%rowtype;
  CARR carrier%rowtype;

BEGIN
    out_errmsg := 'OKAY';

-- Verify we have a termid
    if in_termid is null then
       out_errmsg := 'No terminal assigned.';
       return;
    end if;

-- read the carton and the shippingplate
    CRTNX := null;
    OPEN C_PLATE(in_lpid);
    FETCH C_PLATE into CRTNX;
    CLOSE C_PLATE;
    if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
    end if;

    if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
    end if;

    CRTN := null;
    OPEN C_SHIPPLATE(CRTNX.parentlpid);
    FETCH C_SHIPPLATE into CRTN;
    CLOSE C_SHIPPLATE;
    if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
    end if;

    if CRTN.type not in  ('F','P', 'M') then
       out_errmsg := 'Specified plate not for a full carton.';
       return;
    end if;

    if CRTN.status !=  'S' then
       out_errmsg := 'Specified plate not staged.';
       return;
    end if;

    if CRTN.facility != in_facility then
       out_errmsg := 'Plate not in current facility.';
       return;
    end if;


    if nvl(CRTN.item,'xyz') != nvl(in_item,'xx') then
        out_errmsg := 'Plate item does not match!';
        return;
    end if;

-- Get order information for this carton etc.
    ORD := null;
    if CRTN.shipid = 0 then
        OPEN C_ORDHDR_WAVE(CRTN.orderid);
        FETCH C_ORDHDR_WAVE into ORD;
        CLOSE C_ORDHDR_WAVE;
    else
        OPEN C_ORDHDR(CRTN.orderid, CRTN.shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
    end if;

    if ORD.orderid is null then
       out_errmsg := 'No order found for this carton!!!';
       return;
    end if;

    if ORD.shiptype != 'S' then
       out_errmsg := 'Order not a small package order.';
       return;
    end if;

-- Get carrier information
    CARR := null;
    OPEN C_CARRIER(ORD.carrier);
    FETCH C_CARRIER into CARR;
    CLOSE C_CARRIER;

    if CARR.carriertype != 'S' then
       out_errmsg := 'Order not for a small package carrier.';
       return;
    end if;



    send_staged_carton_trigger(in_facility, ORD.custid, in_termid, in_lpid,
        in_userid, out_errmsg);


exception when others then
  out_errmsg := sqlerrm;
END check_and_send_carton_trigger;

end zmanifest;
/
show error package body zmanifest;

exit;
