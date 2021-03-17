create or replace trigger orderhdr_bu_all
before update
on orderhdr
begin

    delete from kitwave_temp;
end;
/
create or replace trigger orderhdr_au_all
after update
on orderhdr
declare
errmsg varchar2(255);
begin

    for crec in (select distinct * from kitwave_temp)
    loop

        zkit.complete_kit_wave(crec.wave, crec.userid, errmsg);

    end loop;


    delete from kitwave_temp;

end;
/
create or replace trigger orderhdr_bi
--
-- $Id$
--
before insert
on orderhdr
for each row
declare
chrToFacility char(3);

CURSOR C_CUST(in_custid varchar2)
IS
SELECT tms_orders_to_plan_format, xdockprocessing
 FROM customer
WHERE custid = in_custid;
CUS C_CUST%rowtype;

begin

  if :new.tms_status is null or :new.xdockprocessing is null then
    CUS := null;
    OPEN C_CUST(:new.custid);
    FETCH C_CUST into CUS;
    CLOSE C_CUST;

    if :new.tms_status is null then
      if (CUS.tms_orders_to_plan_format is null) and
         ((nvl(zci.default_value('TMS_CARRIER'),'x') != :new.carrier) or
          (:new.orderstatus < '0') or (:new.orderstatus > '6')) then
          :new.tms_status := 'X';
      else
        if (nvl(zci.default_value('TMS_CARRIER'),'x') = :new.carrier) and
           (:new.orderstatus >= '0') and (:new.orderstatus <= '6') then
          :new.tms_carrier_optimized_yn := 'N';
        end if;
          :new.tms_status := '1';
      end if;
      :new.tms_status_update := sysdate;
    end if;

    if :new.xdockprocessing is null then
      if CUS.xdockprocessing is null then
          :new.xdockprocessing := 'S';
      else
          :new.xdockprocessing := CUS.xdockprocessing;
      end if;
    end if;
  end if;

  if :new.ordertype = 'Q' then
    chrToFacility := nvl(:new.tofacility,'   ');
    :new.is_returns_order := 'Y' || chrToFacility ||
      ltrim(to_char(:new.orderid,'09999999999')) || '-' || ltrim(to_char(:new.shipid,'09'));
    if :new.returns_exception_yn is null then
      :new.returns_exception_yn := 'N';
    end if;
    if :new.returns_partial_yn is null then
      :new.returns_partial_yn := 'N';
    end if;
  end if;

  :new.recent_order_id := 'Y' || :new.orderid || '-' || :new.shipid;

  if nvl(:new.has_consumables,'N') != 'Y' then
    :new.has_consumables := 
      substr(zoe.consumable_entry_required(:new.custid,:new.ordertype),1,1);
  end if;
end orderhdr_bi;
/

create or replace trigger orderhdr_ai
--
-- $Id$
--
after insert
on orderhdr
for each row
declare
chgdate date;
l_msg varchar2(255);
intErrorno integer;
out_msg varchar2(255);

begin
  chgdate := sysdate;

  insert into orderhistory
    (chgdate, orderid, shipid, userid, action, msg)
  values
    (chgdate, :new.orderid, :new.shipid, :new.lastuser,
           'ADD', 'Add Order Header source:'||:new.source);

 if (nvl(:new.ordertype,'x') = 'R') and
    (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
    (nvl(:new.tms_status,'X') = '1') then
     ziem.impexp_request(
         'E', -- reqtype
         null, -- facility
         null, -- custid
         zim8.get_systemdefault('TMS_INBOUND_EXPORT_FORMAT'), -- formatid
         null, -- importfilepath
         'NOW', -- when
         null, -- loadno
         :new.orderid, -- orderid
         :new.shipid, -- shipid
         null, --userid
         null, -- tablename
         null,  --columnname
         null, --filtercolumnname
         null, -- company
         null, -- warehouse
         null, -- begindatestr
         null, -- enddatestr
         intErrorno,out_msg);
     if intErrorno != 0 then
         zms.log_msg('TMSEXPORT', :new.fromfacility, '', 'Request TMS Inbound Export: ' || out_msg,
             'E', 'TMSEXPORT', l_msg);
     end if;
 end if;
end orderhdr_ai;
/


create or replace trigger orderhdr_ad
--
-- $Id$
--
after delete
on orderhdr
for each row
declare
chgdate date;

begin
  chgdate := sysdate;

  insert into orderhistory
    (chgdate, orderid, shipid, userid, action, msg)
  values
    (chgdate, :old.orderid, :old.shipid, :old.lastuser,
           'DELETE', 'Delete Order Header');

end;
/
create or replace trigger orderhdr_au
--
-- $Id$
--
after update
on orderhdr
for each row
declare
chgdate date;
nulldate date;
oldhazardous char(1);
newhazardous char(1);
qtyHazardous integer;
qtyHot integer;
oh_msg varchar2(2000);
stat integer;
l_msg varchar2(255);
OutAckWaveMap varchar2(255);
OutTenderMapName varchar2(35);
eventCode varchar2(2);
intErrorno integer;
out_msg varchar2(255);
pos integer;
oh870value varchar2(255);
cmdSql varchar2(200);
SubmitLoadTender char(1);
cursor curCustomer(in_custid varchar2)
IS
SELECT tms_status_changes_format,
       nvl(out870_generate,'N') out870_generate,
       nvl(out870_map, '(NONE)') as out870_map,
       nvl(out870_passthrufield, 'hdrpassthruchar01') as out870_passthrufield,
       nvl(out870_passthruvalue, '(none)') as out870_passthruvalue,
       out870_status
 FROM customer c, customer_aux ca
WHERE c.custid = in_custid
  AND c.custid = ca.custid(+);
cu curCustomer%rowtype;

cursor c_fac(p_facility varchar2, p_orderid number, p_shipid number) is
   select F.order_completion_prtid, L.rowid
      from facility F, labelprofileline L
      where F.facility = p_facility
        and L.profid = F.order_completion_profid
        and L.businessevent = 'OCMP'
        and L.uom is null
        and zlbl.is_order_satisfied(p_orderid, p_shipid, L.passthrufield, L.passthruvalue) = 'Y';
fac c_fac%rowtype;

procedure add_msg(in_msg IN OUT varchar2, in_fn IN varchar2,
          in_old IN varchar2, in_new IN varchar2)
is
  cont varchar2(2);
begin
    if in_msg is null then
       cont := ' ';
       in_msg := 'Change order fields:';
    else
        cont := ', ';
    end if;

    if nvl(length(in_msg),0) + nvl(length(in_old),0) + nvl(length(in_new),0) + 50 > 2000 then
       if substr(in_msg, -3) != '...' then
          in_msg := in_msg || ' ...';
       end if;
       return;
    end if;
    in_msg := in_msg||cont||in_fn
           ||'=['||
           nvl(in_old,'(null)')||
           ']->['||
           nvl(in_new,'(null)')||']';
end;

begin

  oh_msg :=  null;

  chgdate := sysdate;
  nulldate := to_date('01012000','mmddyyyy');
  oldhazardous := substr(zci.hazardous_item_on_order(:old.orderid,:old.shipid),1,1);
  newhazardous := substr(zci.hazardous_item_on_order(:new.orderid,:new.shipid),1,1);

  if (nvl(:old.fromfacility,'x') <> nvl(:new.fromfacility,'x')) or
     (nvl(:old.custid,'x') <> nvl(:new.custid,'x')) or
     (nvl(:old.priority,'x') <> nvl(:new.priority,'x')) then
    update orderdtl
       set custid = :new.custid,
           fromfacility = :new.fromfacility,
           priority = :new.priority
     where orderid = :new.orderid
       and shipid = :new.shipid;
  end if;
  if nvl(:new.wave,0) != 0 then
    if nvl(:old.wave,0) != 0 then
      if :new.wave != :old.wave then
        if oldhazardous = 'Y' then
          qtyHazardous := 1;
        else
          qtyHazardous := 0;
        end if;
        if :old.priority = '0' then
          qtyHot := 1;
        else
          qtyHot := 0;
        end if;
        update waves
           set cntorder = nvl(cntorder,0) - 1,
               qtyorder = nvl(qtyorder,0) - nvl(:old.qtyorder,0),
               weightorder = nvl(weightorder,0) - nvl(:old.weightorder,0),
               cubeorder = nvl(cubeorder,0) - nvl(:old.cubeorder,0),
               qtycommit = nvl(qtycommit,0) - nvl(:old.qtycommit,0),
               weightcommit = nvl(weightcommit,0) - nvl(:old.weightcommit,0),
               cubecommit = nvl(cubecommit,0) - nvl(:old.cubecommit,0),
               staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0),
               qtyHazardousOrders = nvl(qtyHazardousOrders,0) - qtyHazardous,
               qtyHotOrders = nvl(qtyHotOrders,0) - qtyHot
         where wave = :old.wave;
        if newhazardous = 'Y' then
          qtyHazardous := 1;
        else
          qtyHazardous := 0;
        end if;
        if :new.priority = '0' then
          qtyHot := 1;
        else
          qtyHot := 0;
        end if;
        update waves
           set cntorder = nvl(cntorder,0) + 1,
               qtyorder = nvl(qtyorder,0) + nvl(:new.qtyorder,0),
               weightorder = nvl(weightorder,0) + nvl(:new.weightorder,0),
               cubeorder = nvl(cubeorder,0) + nvl(:new.cubeorder,0),
               qtycommit = nvl(qtycommit,0) + nvl(:new.qtycommit,0),
               weightcommit = nvl(weightcommit,0) + nvl(:new.weightcommit,0),
               cubecommit = nvl(cubecommit,0) + nvl(:new.cubecommit,0),
               staffhrs = nvl(staffhrs,0) + nvl(:new.staffhrs,0),
               qtyHazardousOrders = nvl(qtyHazardousOrders,0) + qtyHazardous,
               qtyHotOrders = nvl(qtyHotOrders,0) + qtyHot
         where wave = :new.wave;
      else
        if nvl(:new.qtyorder,0) != nvl(:old.qtyorder,0) or
           nvl(:new.weightorder,0) != nvl(:old.weightorder,0) or
           nvl(:new.cubeorder,0) != nvl(:old.cubeorder,0) or
           nvl(:new.qtycommit,0) != nvl(:old.qtycommit,0) or
           nvl(:new.weightcommit,0) != nvl(:old.weightcommit,0) or
           nvl(:new.cubecommit,0) != nvl(:old.cubecommit,0) or
           nvl(:new.staffhrs,0) != nvl(:old.staffhrs,0) or
           nvl(:new.priority,'x') != nvl(:old.priority,'x') or
           newhazardous != oldhazardous then
          qtyHot := 0;
          qtyHazardous := 0;
          if :new.priority = '0' then
            if :old.priority != '0' then
              qtyHot := 1;
            end if;
          else
            if :old.priority = '0' then
              qtyHot := -1;
            end if;
          end if;
          if newhazardous = 'Y' then
            if oldhazardous != 'Y' then
              qtyHazardous := 1;
            end if;
          else
            if oldhazardous = 'Y' then
              qtyHazardous := -1;
            end if;
          end if;
          update waves
             set qtyorder = nvl(qtyorder,0) - nvl(:old.qtyorder,0) + nvl(:new.qtyorder,0),
                 weightorder = nvl(weightorder,0) - nvl(:old.weightorder,0) + nvl(:new.weightorder,0),
                 cubeorder = nvl(cubeorder,0) - nvl(:old.cubeorder,0) + nvl(:new.cubeorder,0),
                 qtycommit = nvl(qtycommit,0) - nvl(:old.qtycommit,0) + nvl(:new.qtycommit,0),
                 weightcommit = nvl(weightcommit,0) - nvl(:old.weightcommit,0) + nvl(:new.weightcommit,0),
                 cubecommit = nvl(cubecommit,0) - nvl(:old.cubecommit,0) + nvl(:new.cubecommit,0),
                 staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0) + nvl(:new.staffhrs,0),
                 qtyHazardousOrders = nvl(qtyHazardousOrders,0) + qtyHazardous,
                 qtyHotOrders = nvl(qtyHotOrders,0) + qtyHot
           where wave = :new.wave;
        end if;
      end if;
    else
      if newhazardous = 'Y' then
        qtyHazardous := 1;
      else
        qtyHazardous := 0;
      end if;
      if :new.priority = '0' then
        qtyHot := 1;
      else
        qtyHot := 0;
      end if;
      update waves
         set cntorder = nvl(cntorder,0) + 1,
             qtyorder = nvl(qtyorder,0) + nvl(:new.qtyorder,0),
             weightorder = nvl(weightorder,0) + nvl(:new.weightorder,0),
             cubeorder = nvl(cubeorder,0) + nvl(:new.cubeorder,0),
             qtycommit = nvl(qtycommit,0) + nvl(:new.qtycommit,0),
             weightcommit = nvl(weightcommit,0) + nvl(:new.weightcommit,0),
             cubecommit = nvl(cubecommit,0) + nvl(:new.cubecommit,0),
             staffhrs = nvl(staffhrs,0) + nvl(:new.staffhrs,0),
             qtyHazardousOrders = nvl(qtyHazardousOrders,0) + qtyHazardous,
             qtyHotOrders = nvl(qtyHotOrders,0) + qtyHot
       where wave = :new.wave;
    end if;
  else
    if nvl(:old.wave,0) != 0 then
      if oldhazardous = 'Y' then
        qtyHazardous := 1;
      else
        qtyHazardous := 0;
      end if;
      if :old.priority = '0' then
        qtyHot := 1;
      else
        qtyHot := 0;
      end if;
      update waves
         set cntorder = nvl(cntorder,0) - 1,
             qtyorder = nvl(qtyorder,0) - nvl(:old.qtyorder,0),
             weightorder = nvl(weightorder,0) - nvl(:old.weightorder,0),
             cubeorder = nvl(cubeorder,0) - nvl(:old.cubeorder,0),
             qtycommit = nvl(qtycommit,0) - nvl(:old.qtycommit,0),
             weightcommit = nvl(weightcommit,0) - nvl(:old.weightcommit,0),
             cubecommit = nvl(cubecommit,0) - nvl(:old.cubecommit,0),
             staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0),
             qtyHazardousOrders = nvl(qtyHazardousOrders,0) - qtyHazardous,
             qtyHotOrders = nvl(qtyHotOrders,0) - qtyHot
       where wave = :old.wave;
    end if;
  end if;

-- Enhanced Order History Stuff

  if (nvl(:old.ordertype,'x') <> nvl(:new.ordertype,'x'))
  then
        add_msg(oh_msg,'OrderType',
           :old.ordertype,
           :new.ordertype);
  end if;

  if (nvl(:old.orderstatus,'x') <> nvl(:new.orderstatus,'x'))
  then
        add_msg(oh_msg,'orderstatus',
           :old.orderstatus,
           :new.orderstatus);
  end if;

  if (nvl(:old.apptdate,nulldate) <> nvl(:new.apptdate,nulldate))
  then
        add_msg(oh_msg,'apptdate',
                to_char(:old.apptdate, 'MM-DD-YY HH:MI:SSAM'),
             to_char(:new.apptdate, 'MM-DD-YY HH:MI:SSAM'));
  end if;

  if (nvl(:old.shipdate,nulldate) <> nvl(:new.shipdate,nulldate))
  then
        add_msg(oh_msg,'shipdate',
                to_char(:old.shipdate, 'MM-DD-YY HH:MI:SSAM'),
                to_char(:new.shipdate, 'MM-DD-YY HH:MI:SSAM'));
  end if;

  if (nvl(:old.po,'x') <> nvl(:new.po,'x'))
  then
        add_msg(oh_msg,'po',
            :old.po,
            :new.po);
  end if;

  if (nvl(:old.rma,'x') <> nvl(:new.rma,'x'))
  then
        add_msg(oh_msg,'rma',
            :old.rma,
            :new.rma);
  end if;

  if (nvl(:old.commitstatus,'x') <> nvl(:new.commitstatus,'x'))
  then
        add_msg(oh_msg,'commitstatus',
            :old.commitstatus,
            :new.commitstatus);
  end if;

  if (nvl(:old.wave,0) <> nvl(:new.wave,0))
  then
        add_msg(oh_msg,'wave',
            :old.wave,
            :new.wave);
  end if;

  if (nvl(:old.loadno,0) <> nvl(:new.loadno,0))
  then
        add_msg(oh_msg,'loadno',
            :old.loadno,
            :new.loadno);
  end if;

  if (nvl(:old.stopno,0) <> nvl(:new.stopno,0))
  then
        add_msg(oh_msg,'stopno',
            :old.stopno,
            :new.stopno);
  end if;

  if (nvl(:old.shipno,0) <> nvl(:new.shipno,0))
  then
        add_msg(oh_msg,'shipno',
            :old.shipno,
            :new.shipno);
  end if;

  if (nvl(:old.shipto,'x') <> nvl(:new.shipto,'x'))
  then
        add_msg(oh_msg,'shipto',
            :old.shipto,
            :new.shipto);
  end if;

  if (nvl(:old.priority,'x') <> nvl(:new.priority,'x'))
  then
        add_msg(oh_msg,'priority',
            :old.priority,
            :new.priority);
  end if;

  if (nvl(:old.arrivaldate,nulldate) <> nvl(:new.arrivaldate,nulldate))
  then
        add_msg(oh_msg,'arrivaldate',
              to_char(:old.arrivaldate,'MM-DD-YY HH:MI:SSAM'),
              to_char(:new.arrivaldate,'MM-DD-YY HH:MI:SSAM'));
  end if;
  if (nvl(:old.consignee,'x') <> nvl(:new.consignee,'x'))
  then
        add_msg(oh_msg,'consignee',
            :old.consignee,
            :new.consignee);
  end if;

  if (nvl(:old.shiptype,'x') <> nvl(:new.shiptype,'x'))
  then
        add_msg(oh_msg,'shiptype',
            :old.shiptype,
            :new.shiptype);
  end if;

  if (nvl(:old.carrier,'x') <> nvl(:new.carrier,'x'))
  then
        add_msg(oh_msg,'carrier',
            :old.carrier,
            :new.carrier);
  end if;

  if (nvl(:old.reference,'x') <> nvl(:new.reference,'x'))
  then
        add_msg(oh_msg,'reference',
            :old.reference,
            :new.reference);
  end if;

  if (nvl(:old.shipterms,'x') <> nvl(:new.shipterms,'x'))
  then
        add_msg(oh_msg,'shipterms',
            :old.shipterms,
            :new.shipterms);
  end if;

  if (nvl(:old.dateshipped,nulldate) <> nvl(:new.dateshipped,nulldate))
  then
        add_msg(oh_msg,'dateshipped',
                to_char(:old.dateshipped, 'MM-DD-YY HH:MI:SSAM'),
                to_char(:new.dateshipped, 'MM-DD-YY HH:MI:SSAM'));
  end if;

  if (nvl(:old.deliveryservice,'x') <> nvl(:new.deliveryservice,'x'))
  then
        add_msg(oh_msg,'deliveryservice',
            :old.deliveryservice,
            :new.deliveryservice);
  end if;

  if (nvl(:old.saturdaydelivery,'x') <> nvl(:new.saturdaydelivery,'x'))
  then
        add_msg(oh_msg,'saturdaydelivery',
            :old.saturdaydelivery,
            :new.saturdaydelivery);
  end if;

  if (nvl(:old.specialservice1,'x') <> nvl(:new.specialservice1,'x'))
  then
        add_msg(oh_msg,'specialservice1',
            :old.specialservice1,
            :new.specialservice1);
  end if;

  if (nvl(:old.specialservice2,'x') <> nvl(:new.specialservice2,'x'))
  then
        add_msg(oh_msg,'specialservice2',
            :old.specialservice2,
            :new.specialservice2);
  end if;

  if (nvl(:old.specialservice3,'x') <> nvl(:new.specialservice3,'x'))
  then
        add_msg(oh_msg,'specialservice3',
            :old.specialservice3,
            :new.specialservice3);
  end if;

  if (nvl(:old.specialservice4,'x') <> nvl(:new.specialservice4,'x'))
  then
        add_msg(oh_msg,'specialservice4',
            :old.specialservice4,
            :new.specialservice4);
  end if;

  if (nvl(:old.cod,'x') <> nvl(:new.cod,'x'))
  then
        add_msg(oh_msg,'cod',
            :old.cod,
            :new.cod);
  end if;

  if (nvl(:old.amtcod,0) <> nvl(:new.amtcod,0))
  then
        add_msg(oh_msg,'amtcod',
            :old.amtcod,
            :new.amtcod);
  end if;

  if (nvl(:old.prono,0) <> nvl(:new.prono,0))
  then
        add_msg(oh_msg,'prono',
            :old.prono,
            :new.prono);
  end if;

  if (nvl(:old.cancelreason,'x') <> nvl(:new.cancelreason,'x'))
  then
        add_msg(oh_msg,'cancelreason',
            :old.cancelreason,
            :new.cancelreason);
  end if;

  if (nvl(:old.transapptdate,nulldate) <> nvl(:new.transapptdate,nulldate))
  then
        add_msg(oh_msg,'transapptdate',
              to_char(:old.transapptdate, 'MM-DD-YY HH:MI:SSAM'),
                to_char(:new.transapptdate, 'MM-DD-YY HH:MI:SSAM'));
  end if;

  if (nvl(:old.deliveryaptconfname,'x') <> nvl(:new.deliveryaptconfname,'x'))
  then
        add_msg(oh_msg,'deliveryaptconfname',
            :old.deliveryaptconfname,
            :new.deliveryaptconfname);
  end if;

  if (nvl(:old.interlinecarrier,'x') <> nvl(:new.interlinecarrier,'x'))
  then
        add_msg(oh_msg,'interlinecarrier',
            :old.interlinecarrier,
            :new.interlinecarrier);
  end if;

  if (nvl(:old.ftz216authorization,'x') <> nvl(:new.ftz216authorization,'x'))
  then
        add_msg(oh_msg,'ftz216authorization',
            :old.ftz216authorization,
            :new.ftz216authorization);
  end if;

  if (nvl(:old.stageloc,'x') <> nvl(:new.stageloc,'x'))
  then
        add_msg(oh_msg,'StageLoc',
           :old.stageloc,
           :new.stageloc);
  end if;



  if (nvl(:old.hdrpassthruchar01,'x') <> nvl(:new.hdrpassthruchar01,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar01',
            :old.hdrpassthruchar01,
            :new.hdrpassthruchar01);
  end if;

  if (nvl(:old.hdrpassthruchar02,'x') <> nvl(:new.hdrpassthruchar02,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar02',
            :old.hdrpassthruchar02,
            :new.hdrpassthruchar02);
  end if;

  if (nvl(:old.hdrpassthruchar03,'x') <> nvl(:new.hdrpassthruchar03,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar03',
            :old.hdrpassthruchar03,
            :new.hdrpassthruchar03);
  end if;

  if (nvl(:old.hdrpassthruchar04,'x') <> nvl(:new.hdrpassthruchar04,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar04',
            :old.hdrpassthruchar04,
            :new.hdrpassthruchar04);
  end if;

  if (nvl(:old.hdrpassthruchar05,'x') <> nvl(:new.hdrpassthruchar05,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar05',
            :old.hdrpassthruchar05,
            :new.hdrpassthruchar05);
  end if;

  if (nvl(:old.hdrpassthruchar06,'x') <> nvl(:new.hdrpassthruchar06,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar06',
            :old.hdrpassthruchar06,
            :new.hdrpassthruchar06);
  end if;

  if (nvl(:old.hdrpassthruchar07,'x') <> nvl(:new.hdrpassthruchar07,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar07',
            :old.hdrpassthruchar07,
            :new.hdrpassthruchar07);
  end if;

  if (nvl(:old.hdrpassthruchar08,'x') <> nvl(:new.hdrpassthruchar08,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar08',
            :old.hdrpassthruchar08,
            :new.hdrpassthruchar08);
  end if;

  if (nvl(:old.hdrpassthruchar09,'x') <> nvl(:new.hdrpassthruchar09,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar09',
            :old.hdrpassthruchar09,
            :new.hdrpassthruchar09);
  end if;

  if (nvl(:old.hdrpassthruchar10,'x') <> nvl(:new.hdrpassthruchar10,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar10',
            :old.hdrpassthruchar10,
            :new.hdrpassthruchar10);
  end if;

  if (nvl(:old.hdrpassthruchar11,'x') <> nvl(:new.hdrpassthruchar11,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar11',
            :old.hdrpassthruchar11,
            :new.hdrpassthruchar11);
  end if;

  if (nvl(:old.hdrpassthruchar12,'x') <> nvl(:new.hdrpassthruchar12,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar12',
            :old.hdrpassthruchar12,
            :new.hdrpassthruchar12);
  end if;

  if (nvl(:old.hdrpassthruchar13,'x') <> nvl(:new.hdrpassthruchar13,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar13',
            :old.hdrpassthruchar13,
            :new.hdrpassthruchar13);
  end if;

  if (nvl(:old.hdrpassthruchar14,'x') <> nvl(:new.hdrpassthruchar14,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar14',
            :old.hdrpassthruchar14,
            :new.hdrpassthruchar14);
  end if;

  if (nvl(:old.hdrpassthruchar15,'x') <> nvl(:new.hdrpassthruchar15,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar15',
            :old.hdrpassthruchar15,
            :new.hdrpassthruchar15);
  end if;

  if (nvl(:old.hdrpassthruchar16,'x') <> nvl(:new.hdrpassthruchar16,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar16',
            :old.hdrpassthruchar16,
            :new.hdrpassthruchar16);
  end if;

  if (nvl(:old.hdrpassthruchar17,'x') <> nvl(:new.hdrpassthruchar17,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar17',
            :old.hdrpassthruchar17,
            :new.hdrpassthruchar17);
  end if;

  if (nvl(:old.hdrpassthruchar18,'x') <> nvl(:new.hdrpassthruchar18,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar18',
            :old.hdrpassthruchar18,
            :new.hdrpassthruchar18);
  end if;

  if (nvl(:old.hdrpassthruchar19,'x') <> nvl(:new.hdrpassthruchar19,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar19',
            :old.hdrpassthruchar19,
            :new.hdrpassthruchar19);
  end if;

  if (nvl(:old.hdrpassthruchar20,'x') <> nvl(:new.hdrpassthruchar20,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar20',
            :old.hdrpassthruchar20,
            :new.hdrpassthruchar20);
  end if;

  if (nvl(:old.hdrpassthruchar21,'x') <> nvl(:new.hdrpassthruchar21,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar21',
            :old.hdrpassthruchar21,
            :new.hdrpassthruchar21);
  end if;

  if (nvl(:old.hdrpassthruchar22,'x') <> nvl(:new.hdrpassthruchar22,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar22',
            :old.hdrpassthruchar22,
            :new.hdrpassthruchar22);
  end if;

  if (nvl(:old.hdrpassthruchar23,'x') <> nvl(:new.hdrpassthruchar23,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar23',
            :old.hdrpassthruchar23,
            :new.hdrpassthruchar23);
  end if;

  if (nvl(:old.hdrpassthruchar24,'x') <> nvl(:new.hdrpassthruchar24,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar24',
            :old.hdrpassthruchar24,
            :new.hdrpassthruchar24);
  end if;

  if (nvl(:old.hdrpassthruchar25,'x') <> nvl(:new.hdrpassthruchar25,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar25',
            :old.hdrpassthruchar25,
            :new.hdrpassthruchar25);
  end if;

  if (nvl(:old.hdrpassthruchar26,'x') <> nvl(:new.hdrpassthruchar26,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar26',
            :old.hdrpassthruchar26,
            :new.hdrpassthruchar26);
  end if;

  if (nvl(:old.hdrpassthruchar27,'x') <> nvl(:new.hdrpassthruchar27,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar27',
            :old.hdrpassthruchar27,
            :new.hdrpassthruchar27);
  end if;

  if (nvl(:old.hdrpassthruchar28,'x') <> nvl(:new.hdrpassthruchar28,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar28',
            :old.hdrpassthruchar28,
            :new.hdrpassthruchar28);
  end if;

  if (nvl(:old.hdrpassthruchar29,'x') <> nvl(:new.hdrpassthruchar29,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar29',
            :old.hdrpassthruchar29,
            :new.hdrpassthruchar29);
  end if;

  if (nvl(:old.hdrpassthruchar30,'x') <> nvl(:new.hdrpassthruchar30,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar30',
            :old.hdrpassthruchar30,
            :new.hdrpassthruchar30);
  end if;

  if (nvl(:old.hdrpassthruchar31,'x') <> nvl(:new.hdrpassthruchar31,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar31',
            :old.hdrpassthruchar31,
            :new.hdrpassthruchar31);
  end if;

  if (nvl(:old.hdrpassthruchar32,'x') <> nvl(:new.hdrpassthruchar32,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar32',
            :old.hdrpassthruchar32,
            :new.hdrpassthruchar32);
  end if;

  if (nvl(:old.hdrpassthruchar33,'x') <> nvl(:new.hdrpassthruchar33,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar33',
            :old.hdrpassthruchar33,
            :new.hdrpassthruchar33);
  end if;

  if (nvl(:old.hdrpassthruchar34,'x') <> nvl(:new.hdrpassthruchar34,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar34',
            :old.hdrpassthruchar34,
            :new.hdrpassthruchar34);
  end if;

  if (nvl(:old.hdrpassthruchar35,'x') <> nvl(:new.hdrpassthruchar35,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar35',
            :old.hdrpassthruchar35,
            :new.hdrpassthruchar35);
  end if;

  if (nvl(:old.hdrpassthruchar36,'x') <> nvl(:new.hdrpassthruchar36,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar36',
            :old.hdrpassthruchar36,
            :new.hdrpassthruchar36);
  end if;

  if (nvl(:old.hdrpassthruchar37,'x') <> nvl(:new.hdrpassthruchar37,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar37',
            :old.hdrpassthruchar37,
            :new.hdrpassthruchar37);
  end if;

  if (nvl(:old.hdrpassthruchar38,'x') <> nvl(:new.hdrpassthruchar38,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar38',
            :old.hdrpassthruchar38,
            :new.hdrpassthruchar38);
  end if;

  if (nvl(:old.hdrpassthruchar39,'x') <> nvl(:new.hdrpassthruchar39,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar39',
            :old.hdrpassthruchar39,
            :new.hdrpassthruchar39);
  end if;

  if (nvl(:old.hdrpassthruchar40,'x') <> nvl(:new.hdrpassthruchar40,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar40',
            :old.hdrpassthruchar40,
            :new.hdrpassthruchar40);
  end if;

  if (nvl(:old.hdrpassthruchar41,'x') <> nvl(:new.hdrpassthruchar41,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar41',
            :old.hdrpassthruchar41,
            :new.hdrpassthruchar41);
  end if;

  if (nvl(:old.hdrpassthruchar42,'x') <> nvl(:new.hdrpassthruchar42,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar42',
            :old.hdrpassthruchar42,
            :new.hdrpassthruchar42);
  end if;

  if (nvl(:old.hdrpassthruchar43,'x') <> nvl(:new.hdrpassthruchar43,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar43',
            :old.hdrpassthruchar43,
            :new.hdrpassthruchar43);
  end if;

  if (nvl(:old.hdrpassthruchar44,'x') <> nvl(:new.hdrpassthruchar44,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar44',
            :old.hdrpassthruchar44,
            :new.hdrpassthruchar44);
  end if;

  if (nvl(:old.hdrpassthruchar45,'x') <> nvl(:new.hdrpassthruchar45,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar45',
            :old.hdrpassthruchar45,
            :new.hdrpassthruchar45);
  end if;

  if (nvl(:old.hdrpassthruchar46,'x') <> nvl(:new.hdrpassthruchar46,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar46',
            :old.hdrpassthruchar46,
            :new.hdrpassthruchar46);
  end if;

  if (nvl(:old.hdrpassthruchar47,'x') <> nvl(:new.hdrpassthruchar47,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar47',
            :old.hdrpassthruchar47,
            :new.hdrpassthruchar47);
  end if;

  if (nvl(:old.hdrpassthruchar48,'x') <> nvl(:new.hdrpassthruchar48,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar48',
            :old.hdrpassthruchar48,
            :new.hdrpassthruchar48);
  end if;

  if (nvl(:old.hdrpassthruchar49,'x') <> nvl(:new.hdrpassthruchar49,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar49',
            :old.hdrpassthruchar49,
            :new.hdrpassthruchar49);
  end if;

  if (nvl(:old.hdrpassthruchar50,'x') <> nvl(:new.hdrpassthruchar50,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar50',
            :old.hdrpassthruchar50,
            :new.hdrpassthruchar50);
  end if;

  if (nvl(:old.hdrpassthruchar51,'x') <> nvl(:new.hdrpassthruchar51,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar51',
            :old.hdrpassthruchar51,
            :new.hdrpassthruchar51);
  end if;

  if (nvl(:old.hdrpassthruchar52,'x') <> nvl(:new.hdrpassthruchar52,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar52',
            :old.hdrpassthruchar52,
            :new.hdrpassthruchar52);
  end if;

  if (nvl(:old.hdrpassthruchar53,'x') <> nvl(:new.hdrpassthruchar53,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar53',
            :old.hdrpassthruchar53,
            :new.hdrpassthruchar53);
  end if;

  if (nvl(:old.hdrpassthruchar54,'x') <> nvl(:new.hdrpassthruchar54,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar54',
            :old.hdrpassthruchar54,
            :new.hdrpassthruchar54);
  end if;

  if (nvl(:old.hdrpassthruchar55,'x') <> nvl(:new.hdrpassthruchar55,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar55',
            :old.hdrpassthruchar55,
            :new.hdrpassthruchar55);
  end if;

  if (nvl(:old.hdrpassthruchar56,'x') <> nvl(:new.hdrpassthruchar56,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar56',
            :old.hdrpassthruchar56,
            :new.hdrpassthruchar56);
  end if;

  if (nvl(:old.hdrpassthruchar57,'x') <> nvl(:new.hdrpassthruchar57,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar57',
            :old.hdrpassthruchar57,
            :new.hdrpassthruchar57);
  end if;

  if (nvl(:old.hdrpassthruchar58,'x') <> nvl(:new.hdrpassthruchar58,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar58',
            :old.hdrpassthruchar58,
            :new.hdrpassthruchar58);
  end if;

  if (nvl(:old.hdrpassthruchar59,'x') <> nvl(:new.hdrpassthruchar59,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar59',
            :old.hdrpassthruchar59,
            :new.hdrpassthruchar59);
  end if;

  if (nvl(:old.hdrpassthruchar60,'x') <> nvl(:new.hdrpassthruchar60,'x'))
  then
        add_msg(oh_msg,'hdrpassthruchar60',
            :old.hdrpassthruchar60,
            :new.hdrpassthruchar60);
  end if;


  if (nvl(:old.hdrpassthrunum01,0) <> nvl(:new.hdrpassthrunum01,0))
  then
        add_msg(oh_msg,'hdrpassthrunum01',
            :old.hdrpassthrunum01,
            :new.hdrpassthrunum01);
  end if;

  if (nvl(:old.hdrpassthrunum02,0) <> nvl(:new.hdrpassthrunum02,0))
  then
        add_msg(oh_msg,'hdrpassthrunum02',
            :old.hdrpassthrunum02,
            :new.hdrpassthrunum02);
  end if;

  if (nvl(:old.hdrpassthrunum03,0) <> nvl(:new.hdrpassthrunum03,0))
  then
        add_msg(oh_msg,'hdrpassthrunum03',
            :old.hdrpassthrunum03,
            :new.hdrpassthrunum03);
  end if;

  if (nvl(:old.hdrpassthrunum04,0) <> nvl(:new.hdrpassthrunum04,0))
  then
        add_msg(oh_msg,'hdrpassthrunum04',
            :old.hdrpassthrunum04,
            :new.hdrpassthrunum04);
  end if;

  if (nvl(:old.hdrpassthrunum05,0) <> nvl(:new.hdrpassthrunum05,0))
  then
        add_msg(oh_msg,'hdrpassthrunum05',
            :old.hdrpassthrunum05,
            :new.hdrpassthrunum05);
  end if;

  if (nvl(:old.hdrpassthrunum06,0) <> nvl(:new.hdrpassthrunum06,0))
  then
        add_msg(oh_msg,'hdrpassthrunum06',
            :old.hdrpassthrunum06,
            :new.hdrpassthrunum06);
  end if;

  if (nvl(:old.hdrpassthrunum07,0) <> nvl(:new.hdrpassthrunum07,0))
  then
        add_msg(oh_msg,'hdrpassthrunum07',
            :old.hdrpassthrunum07,
            :new.hdrpassthrunum07);
  end if;

  if (nvl(:old.hdrpassthrunum08,0) <> nvl(:new.hdrpassthrunum08,0))
  then
        add_msg(oh_msg,'hdrpassthrunum08',
            :old.hdrpassthrunum08,
            :new.hdrpassthrunum08);
  end if;

  if (nvl(:old.hdrpassthrunum09,0) <> nvl(:new.hdrpassthrunum09,0))
  then
        add_msg(oh_msg,'hdrpassthrunum09',
            :old.hdrpassthrunum09,
            :new.hdrpassthrunum09);
  end if;

  if (nvl(:old.hdrpassthrunum10,0) <> nvl(:new.hdrpassthrunum10,0))
  then
        add_msg(oh_msg,'hdrpassthrunum10',
            :old.hdrpassthrunum10,
            :new.hdrpassthrunum10);
  end if;

  if (nvl(:old.hdrpassthrudate01,nulldate) <> nvl(:new.hdrpassthrudate01,nulldate))
  then
        add_msg(oh_msg,'hdrpassthrudate01',
            :old.hdrpassthrudate01,
            :new.hdrpassthrudate01);
  end if;

  if (nvl(:old.hdrpassthrudate02,nulldate) <> nvl(:new.hdrpassthrudate02,nulldate))
  then
        add_msg(oh_msg,'hdrpassthrudate02',
            :old.hdrpassthrudate02,
            :new.hdrpassthrudate02);
  end if;

  if (nvl(:old.hdrpassthrudate03,nulldate) <> nvl(:new.hdrpassthrudate03,nulldate))
  then
        add_msg(oh_msg,'hdrpassthrudate03',
            :old.hdrpassthrudate03,
            :new.hdrpassthrudate03);
  end if;

  if (nvl(:old.hdrpassthrudate04,nulldate) <> nvl(:new.hdrpassthrudate04,nulldate))
  then
        add_msg(oh_msg,'hdrpassthrudate04',
            :old.hdrpassthrudate04,
            :new.hdrpassthrudate04);
  end if;

  if (nvl(:old.hdrpassthrudoll01,0) <> nvl(:new.hdrpassthrudoll01,0))
  then
        add_msg(oh_msg,'hdrpassthrudoll01',
            :old.hdrpassthrudoll01,
            :new.hdrpassthrudoll01);
  end if;

  if (nvl(:old.hdrpassthrudoll02,0) <> nvl(:new.hdrpassthrudoll02,0))
  then
        add_msg(oh_msg,'hdrpassthrudoll02',
            :old.hdrpassthrudoll02,
            :new.hdrpassthrudoll02);
  end if;

  if (nvl(:old.fromfacility,'x') <> nvl(:new.fromfacility,'x'))
  then
        add_msg(oh_msg,'fromfacility',
            :old.fromfacility,
            :new.fromfacility);
  end if;

  if (nvl(:old.tofacility,'x') <> nvl(:new.tofacility,'x'))
  then
        add_msg(oh_msg,'tofacility',
            :old.tofacility,
            :new.tofacility);
  end if;

  if (nvl(:old.tms_status,'x') <> nvl(:new.tms_status,'x'))
  then
        add_msg(oh_msg,'tms_status',
            :old.tms_status,
            :new.tms_status);
  end if;

  if (nvl(:old.tms_carrier_optimized_yn, 'x') <> nvl(:new.tms_carrier_optimized_yn, 'x'))
  then
        add_msg(oh_msg, 'tms_carrier_optimized_yn',
            :old.tms_carrier_optimized_yn,
            :new.tms_carrier_optimized_yn);
  end if;
  if (nvl(:old.tms_shipment_id,'x') <> nvl(:new.tms_shipment_id,'x'))
  then
        add_msg(oh_msg,'tms_shipment_id',
            :old.tms_shipment_id,
            :new.tms_shipment_id);
  end if;

  if (nvl(:old.tms_release_id,'x') <> nvl(:new.tms_release_id,'x'))
  then
        add_msg(oh_msg,'tms_release_id',
            :old.tms_release_id,
            :new.tms_release_id);
  end if;

  if (nvl(:old.seal_verification_attempts, 0) <>
    nvl(:new.seal_verification_attempts, 0)) then
        add_msg(oh_msg, 'seal_verification_attempts',
            :old.seal_verification_attempts,
              :new.seal_verification_attempts);
  end if;

  if (nvl(:old.seal_verified, 'x') <> nvl(:new.seal_verified, 'x')) then
        add_msg(oh_msg, 'seal_verified',
            :old.seal_verified,
              :new.seal_verified);
  end if;

  if (nvl(:old.trailernosetemp, 0) <> nvl(:new.trailernosetemp, 0)) then
        add_msg(oh_msg, 'trailernosetemp',
            :old.trailernosetemp,
              :new.trailernosetemp);
  end if;

  if (nvl(:old.trailermiddletemp, 0) <> nvl(:new.trailermiddletemp, 0)) then
        add_msg(oh_msg, 'trailermiddletemp',
            :old.trailermiddletemp,
              :new.trailermiddletemp);
  end if;

  if (nvl(:old.trailertailtemp, 0) <> nvl(:new.trailertailtemp, 0)) then
        add_msg(oh_msg, 'trailertailtemp',
            :old.trailertailtemp,
              :new.trailertailtemp);
  end if;

  if (nvl(:old.xfercustid, 'x') <> nvl(:new.xfercustid, 'x')) then
        add_msg(oh_msg, 'xfercustid',
            :old.xfercustid,
              :new.xfercustid);
  end if;

  if (nvl(:old.routingstatus, 'x') <> nvl(:new.routingstatus, 'x')) then
        add_msg(oh_msg, 'routingstatus',
            :old.routingstatus,
              :new.routingstatus);
  end if;

  if (nvl(:old.shipshort, 'x') <> nvl(:new.shipshort, 'x')) then
        add_msg(oh_msg, 'shipshort',
            :old.shipshort,
              :new.shipshort);
  end if;

  if oh_msg is not null then
    insert into orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    values
      (chgdate, :new.orderid, :new.shipid, :new.lastuser,
           'CHANGE', oh_msg);
 end if;

 oh_msg := null;

 if
    nvl(:old.shiptoname,'x') <> nvl(:new.shiptoname,'x')
 or
    nvl(:old.shiptocontact,'x') <> nvl(:new.shiptocontact,'x')
 or
    nvl(:old.shiptoaddr1,'x') <> nvl(:new.shiptoaddr1,'x')
 or
    nvl(:old.shiptoaddr2,'x') <> nvl(:new.shiptoaddr2,'x')
 or
    nvl(:old.shiptocity,'x') <> nvl(:new.shiptocity,'x')
 or
    nvl(:old.shiptostate,'x') <> nvl(:new.shiptostate,'x')
 or
    nvl(:old.shiptopostalcode,'x') <> nvl(:new.shiptopostalcode,'x')
 or
    nvl(:old.shiptocountrycode,'x') <> nvl(:new.shiptocountrycode,'x')
 or
    nvl(:old.shiptophone,'x') <> nvl(:new.shiptophone,'x')
 or
    nvl(:old.shiptofax,'x') <> nvl(:new.shiptofax,'x')
 or
    nvl(:old.shiptoemail,'x') <> nvl(:new.shiptoemail,'x')
 then

        add_msg(oh_msg,'one time shipto',
              :old.shiptoname||' / '||
                :old.shiptocontact||' / '||
                :old.shiptoaddr1||' / '||
                :old.shiptoaddr2||' / '||
                :old.shiptocity||' / '||
                :old.shiptostate||' / '||
                :old.shiptopostalcode||' / '||
                :old.shiptocountrycode||' / '||
                :old.shiptophone||' / '||
                :old.shiptofax||' / '||
                :old.shiptoemail,
              :new.shiptoname||' / '||
                :new.shiptocontact||' / '||
                :new.shiptoaddr1||' / '||
                :new.shiptoaddr2||' / '||
                :new.shiptocity||' / '||
                :new.shiptostate||' / '||
                :new.shiptopostalcode||' / '||
                :new.shiptocountrycode||' / '||
                :new.shiptophone||' / '||
                :new.shiptofax||' / '||
                :new.shiptoemail);


 end if;

 if oh_msg is not null then
    insert into orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    values
      (chgdate, :new.orderid, :new.shipid, :new.lastuser,
           'CHANGE', oh_msg);
 end if;

 oh_msg := null;

 if
    nvl(:old.billtoname,'x') <> nvl(:new.billtoname,'x')
 or
    nvl(:old.billtocontact,'x') <> nvl(:new.billtocontact,'x')
 or
    nvl(:old.billtoaddr1,'x') <> nvl(:new.billtoaddr1,'x')
 or
    nvl(:old.billtoaddr2,'x') <> nvl(:new.billtoaddr2,'x')
 or
    nvl(:old.billtocity,'x') <> nvl(:new.billtocity,'x')
 or
    nvl(:old.billtostate,'x') <> nvl(:new.billtostate,'x')
 or
    nvl(:old.billtopostalcode,'x') <> nvl(:new.billtopostalcode,'x')
 or
    nvl(:old.billtocountrycode,'x') <> nvl(:new.billtocountrycode,'x')
 or
    nvl(:old.billtophone,'x') <> nvl(:new.billtophone,'x')
 or
    nvl(:old.billtofax,'x') <> nvl(:new.billtofax,'x')
 or
    nvl(:old.billtoemail,'x') <> nvl(:new.billtoemail,'x')
 then
        add_msg(oh_msg,'one time billto',
              :old.billtoname||' / '||
                :old.billtocontact||' / '||
                :old.billtoaddr1||' / '||
                :old.billtoaddr2||' / '||
                :old.billtocity||' / '||
                :old.billtostate||' / '||
                :old.billtopostalcode||' / '||
                :old.billtocountrycode||' / '||
                :old.billtophone||' / '||
                :old.billtofax||' / '||
                :old.billtoemail,
              :new.billtoname||' / '||
                :new.billtocontact||' / '||
                :new.billtoaddr1||' / '||
                :new.billtoaddr2||' / '||
                :new.billtocity||' / '||
                :new.billtostate||' / '||
                :new.billtopostalcode||' / '||
                :new.billtocountrycode||' / '||
                :new.billtophone||' / '||
                :new.billtofax||' / '||
                :new.billtoemail);


 end if;

 if oh_msg is not null then
    insert into orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    values
      (chgdate, :new.orderid, :new.shipid, :new.lastuser,
           'CHANGE', oh_msg);
 end if;

if nvl(:old.comment1,'x') != nvl(:new.comment1,'x') then
    insert into orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    values
      (chgdate, :new.orderid, :new.shipid, :new.lastuser,
           'CHANGE','Comment1 was: '||chr(13) || chr(10) ||
            nvl(substr(:old.comment1,1,500),'(null)'));

end if;

-- Order Status Change detection for TMS
 if :old.orderstatus != :new.orderstatus then
   cu := null;
   open curCustomer(:new.custid);
   fetch curCustomer into cu;
   close curCustomer;
   if cu.tms_status_changes_format is not null then
      stat := zqm.send('tms','CHANGE',
            to_char(:new.orderid,'FM099999999')||to_char(:new.shipid,'FM09'),
            1, null);
      if :new.orderstatus = '9' then
        stat := zqm.send('tms','SHIP',
            to_char(:new.orderid,'FM099999999')||to_char(:new.shipid,'FM09'),
            1, null);
      end if;
    end if;
 end if;


 if nvl(:old.orderstatus,'x') <> nvl(:new.orderstatus,'x')
  and :new.orderstatus in ('6','X')
  and :new.ordertype in ('W','K')
  and :new.wave is not null
 then
      insert into kitwave_temp(wave,userid)
      values(:new.wave,:new.statususer);
 end if;

 if nvl(:old.orderstatus,'x') != nvl(:new.orderstatus,'x')
 and :new.orderstatus = '6' then
   fac := null;
   open c_fac(:new.fromfacility, :new.orderid, :new.shipid);
   fetch c_fac into fac;
   close c_fac;
   if fac.order_completion_prtid is not null
   and fac.rowid is not null then
     zlbl.print_order(:new.orderid, :new.shipid, fac.rowid, fac.order_completion_prtid,
         :new.fromfacility, :new.lastuser, l_msg);
   end if;
 end if;

 if nvl(:old.orderstatus,'x') != nvl(:new.orderstatus,'x') and
    nvl(:new.ordertype,'x') = 'O' then
    if cu.out870_generate = 'Y' then
       pos := instr(cu.out870_status,:new.orderstatus);
       if pos > 0 then
          if cu.out870_passthrufield = 'HDRPASSTHRUCHAR01' then
             oh870Value := :new.hdrpassthruchar01;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR02' then
              oh870value := :new.hdrpassthruchar02;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR03' then
              oh870value := :new.hdrpassthruchar03;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR04' then
              oh870value := :new.hdrpassthruchar04;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR05' then
              oh870value := :new.hdrpassthruchar05;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR06' then
              oh870value := :new.hdrpassthruchar06;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR07' then
              oh870value := :new.hdrpassthruchar07;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR08' then
              oh870value := :new.hdrpassthruchar08;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR09' then
              oh870value := :new.hdrpassthruchar09;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR10' then
              oh870value := :new.hdrpassthruchar10;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR11' then
              oh870value := :new.hdrpassthruchar11;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR12' then
              oh870value := :new.hdrpassthruchar12;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR13' then
              oh870value := :new.hdrpassthruchar13;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR14' then
              oh870value := :new.hdrpassthruchar14;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR15' then
              oh870value := :new.hdrpassthruchar15;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR16' then
              oh870value := :new.hdrpassthruchar16;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR17' then
              oh870value := :new.hdrpassthruchar17;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR18' then
              oh870value := :new.hdrpassthruchar18;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR19' then
              oh870value := :new.hdrpassthruchar19;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR20' then
              oh870value := :new.hdrpassthruchar20;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR21' then
              oh870value := :new.hdrpassthruchar21;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR22' then
              oh870value := :new.hdrpassthruchar22;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR23' then
              oh870value := :new.hdrpassthruchar23;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR24' then
              oh870value := :new.hdrpassthruchar24;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR25' then
              oh870value := :new.hdrpassthruchar25;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR26' then
              oh870value := :new.hdrpassthruchar26;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR27' then
              oh870value := :new.hdrpassthruchar27;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR28' then
              oh870value := :new.hdrpassthruchar28;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR29' then
              oh870value := :new.hdrpassthruchar29;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR30' then
              oh870value := :new.hdrpassthruchar30;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR31' then
              oh870value := :new.hdrpassthruchar31;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR32' then
              oh870value := :new.hdrpassthruchar32;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR33' then
              oh870value := :new.hdrpassthruchar33;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR34' then
              oh870value := :new.hdrpassthruchar34;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR35' then
              oh870value := :new.hdrpassthruchar35;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR36' then
              oh870value := :new.hdrpassthruchar36;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR37' then
              oh870value := :new.hdrpassthruchar37;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR38' then
              oh870value := :new.hdrpassthruchar38;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR39' then
              oh870value := :new.hdrpassthruchar39;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR40' then
              oh870value := :new.hdrpassthruchar40;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR41' then
              oh870value := :new.hdrpassthruchar41;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR42' then
              oh870value := :new.hdrpassthruchar42;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR43' then
              oh870value := :new.hdrpassthruchar43;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR44' then
              oh870value := :new.hdrpassthruchar44;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR45' then
              oh870value := :new.hdrpassthruchar45;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR46' then
              oh870value := :new.hdrpassthruchar46;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR47' then
              oh870value := :new.hdrpassthruchar47;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR48' then
              oh870value := :new.hdrpassthruchar48;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR49' then
              oh870value := :new.hdrpassthruchar49;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR50' then
              oh870value := :new.hdrpassthruchar50;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR51' then
              oh870value := :new.hdrpassthruchar51;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR52' then
              oh870value := :new.hdrpassthruchar52;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR53' then
              oh870value := :new.hdrpassthruchar53;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR54' then
              oh870value := :new.hdrpassthruchar54;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR55' then
              oh870value := :new.hdrpassthruchar55;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR56' then
              oh870value := :new.hdrpassthruchar56;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR57' then
              oh870value := :new.hdrpassthruchar57;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR58' then
              oh870value := :new.hdrpassthruchar58;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR59' then
              oh870value := :new.hdrpassthruchar59;
            elsif cu.out870_passthrufield = 'HDRPASSTHRUCHAR60' then
              oh870value := :new.hdrpassthruchar60;
          else
             oh870value := '(none(';
          end if;
          if oh870value = cu.out870_passthruvalue then
             ziem.impexp_request(
               'E', -- reqtype
               null, -- facility
               :new.custid, -- custid
               cu.out870_map, -- formatid
               null, -- importfilepath
               'NOW', -- when
               0, -- loadno
               :new.orderid, -- orderid
               :new.shipid, -- shipid
               'A870', --userid
               null, -- tablename
               null,  --columnname
               null, --filtercolumnname
               null, -- company
               null, -- warehouse
               null, -- begindatestr
               null, -- enddatestr
               intErrorno,out_msg);
               if intErrorno != 0 then
                 zms.log_msg('A870', :new.fromfacility, '', 'Request Export: ' || out_msg,
                      'E', 'A870', l_msg);
               end if;
          end if;
       end if;
    end if;
 end if;
 
 if (nvl(:old.loadno,0) = nvl(:new.loadno,0)) and
    (nvl(:new.loadno,0) != 0) then
   if (nvl(:old.qtyorder,0) != nvl(:new.qtyorder,0)) or
      (nvl(:old.weightorder,0) != nvl(:new.weightorder,0)) or
      (nvl(:old.cubeorder,0) != nvl(:new.cubeorder,0)) or
      (nvl(:old.amtorder,0) != nvl(:new.amtorder,0)) then
     update loads
        set qtyorder = nvl(qtyorder,0) + nvl(:new.qtyorder,0) - nvl(:old.qtyorder,0),
            weightorder = nvl(weightorder,0) + nvl(:new.weightorder,0) -  nvl(:old.weightorder,0),
            cubeorder = nvl(cubeorder,0) + nvl(:new.cubeorder,0) - nvl(:old.cubeorder,0),
            amtorder = nvl(amtorder,0) + nvl(:new.amtorder,0) - nvl(:old.amtorder,0),
            lastuser = :new.lastuser,
            lastupdate = :new.lastupdate
      where loadno = :new.loadno;
   end if;
 end if;

 if nvl(:old.orderstatus,'x') != nvl(:new.orderstatus,'x') and
    nvl(:new.orderstatus,'x') = '4' and
    nvl(:old.orderstatus,'x') < '4' then
   begin
      select nvl(outackwavemap,'(none)') into OutAckWaveMap
        from customer
        where custid = nvl(:new.custid,'(none)');
   exception when no_data_found then
      OutAckWaveMap := '(none)';
   end;
   if OutAckWaveMap != '(none)' then
     ziem.impexp_request(
       'E', -- reqtype
       null, -- facility
       :new.custid, -- custid
       OutAckWaveMap, -- formatid
       null, -- importfilepath
       'NOW', -- when
       0, -- loadno
       :new.orderid, -- orderid
       :new.shipid, -- shipid
       'RELEASE', --userid
       null, -- tablename
       null,  --columnname
       null, --filtercolumnname
       null, -- company
       null, -- warehouse
       null, -- begindatestr
       null, -- enddatestr
       intErrorno,out_msg);
     if intErrorno != 0 then
       zms.log_msg('ORDWAVE', :new.fromfacility, '', 'Request Export: ' || out_msg,
            'E', 'ORDWAVE', l_msg);
     end if;
   end if;
 end if;
 if nvl(:old.orderstatus,'x') != nvl(:new.orderstatus,'x') and
    nvl(:new.orderstatus,'x') < '4' and
    nvl(:old.orderstatus,'x') = '4' then
   begin
      select nvl(outackwavemap,'(none)') into OutAckWaveMap
        from customer
        where custid = nvl(:new.custid,'(none)');
   exception when no_data_found then
      OutAckWaveMap := '(none)';
   end;
   if OutAckWaveMap != '(none)' then
     ziem.impexp_request(
       'E', -- reqtype
       null, -- facility
       :new.custid, -- custid
       OutAckWaveMap, -- formatid
       null, -- importfilepath
       'NOW', -- when
       0, -- loadno
       :new.orderid, -- orderid
       :new.shipid, -- shipid
       'UNRELEASE', --userid
       null, -- tablename
       null,  --columnname
       null, --filtercolumnname
       null, -- company
       null, -- warehouse
       null, -- begindatestr
       null, -- enddatestr
       intErrorno,out_msg);
     if intErrorno != 0 then
       zms.log_msg('ORDWAVE', :new.fromfacility, '', 'Request Export: ' || out_msg,
            'E', 'ORDWAVE', l_msg);
     end if;
   end if;
 end if;

 if nvl(:old.orderstatus,'x') <> nvl(:new.orderstatus,'x') then
   if :new.orderstatus = 'R'
   and :new.ordertype in ('R','C','Q') then
      zoo.closereceipt(:new.tofacility, :new.custid, :new.qtyrcvd);
   elsif :new.orderstatus = '9'
   and :new.ordertype in ('O','V') then
      zoo.shiporder(:new.fromfacility, :new.custid, :new.qtyship);
   end if;
end if;
if nvl(:new.ordertype, 'x') = 'O' and
   ((nvl(:old.orderstatus, 'x') != 'X' and
     nvl(:new.orderstatus, 'x') = 'X') or
     (nvl(:old.orderstatus, 'x') < '4' and
      nvl(:new.orderstatus, 'x') = '4' and zim8.get_systemdefault('LOAD_TDR_204_SUBMITSTATUS') = '4') or
    (nvl(:old.orderstatus, 'x') = '0' and
      nvl(:new.orderstatus, 'x') = '1' and zim8.get_systemdefault('LOAD_TDR_204_SUBMITSTATUS') = '1') or 
     ((nvl(:old.carrier, 'x') != nvl(:new.carrier, 'x')) and zim8.get_systemdefault('LOAD_TDR_204_CARRIERCHANGE') = 'Y' and (nvl(:new.orderstatus, 'x') != '0'))) then
   SubmitLoadTender := 'Y';
 end if;

if nvl(SubmitLoadTender,'N') = 'Y' then
  begin
     select nvl(tendermapname ,'(none)') into OutTenderMapName
       from facilitycarriertender
       where facility = :new.fromfacility
         and carrier = :new.carrier;
  exception when no_data_found then
     OutTenderMapName := '(none)';
  end;

  if OutTenderMapName != '(none)' then
    if zim8.get_systemdefault('LOAD_TDR_204_PROCESSBYLOAD') = 'Y' then
      begin
      --zms.log_autonomous_msg('TENDER', :new.fromfacility, :new.custid, 'LOAD_TDR_204_PROCESSBYLOAD=Y - '||:new.loadno,'E', 'TENDER', l_msg);
      if zim8.check_orderstatus_for_load(:new.orderid, :new.shipid) = 0 then  -- check if all orders in load have been released
        --zms.log_autonomous_msg('TENDER', :new.fromfacility, :new.custid, 'checkorderstatus=0 - load='||:new.loadno,'E', 'TENDER', l_msg);
        ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        :new.custid, -- custid
        OutTenderMapName, -- formatid
        null, -- importfilepath
        'NOW', -- when
        :new.loadno, -- loadno
        0, -- orderid
        0, -- shipid
        'TENDER', --userid
        null, -- tablename
        null,  --columnname
        null, --filtercolumnname
        null, -- company
        null, -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        intErrorno,out_msg);
      end if;
      end;
    else
      --zms.log_autonomous_msg('TENDER', :new.fromfacility, :new.custid, 'ORDER='||:new.orderid || ' ' || :new.shipid,'E', 'TENDER', l_msg);
      ziem.impexp_request(
       'E', -- reqtype
       null, -- facility
       :new.custid, -- custid
       OutTenderMapName, -- formatid
       null, -- importfilepath
       'NOW', -- when
       0, -- loadno
       :new.orderid, -- orderid
       :new.shipid, -- shipid
       'TENDER', --userid
       null, -- tablename
       null,  --columnname
       null, --filtercolumnname
       null, -- company
       null, -- warehouse
       null, -- begindatestr
       null, -- enddatestr
       intErrorno,out_msg);
    end if;
    if intErrorno != 0 then
       zms.log_msg('ORDADD', :new.fromfacility, '', 'Request Tender Export: ' || out_msg,
            'E', 'ORDADD', l_msg);
    end if;
  end if;
end if;
if (nvl(:old.carrier,'x') != nvl(:new.carrier,'x')) and
   (nvl(:new.ordertype,'x') = 'R') and
   (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
   (nvl(:new.tms_status,'X') = '1') and
   (nvl(:new.tms_carrier_optimized_yn,'X') = 'N') then
    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        null, -- custid
        zim8.get_systemdefault('TMS_INBOUND_EXPORT_FORMAT'), -- formatid
        null, -- importfilepath
        'NOW', -- when
        null, -- loadno
        :new.orderid, -- orderid
        :new.shipid, -- shipid
        null, --userid
        null, -- tablename
        null,  --columnname
        null, --filtercolumnname
        null, -- company
        null, -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        intErrorno,out_msg);
    if intErrorno != 0 then
        zms.log_msg('TMSEXPORT', :new.fromfacility, '', 'Request TMS Inbound Export: ' || out_msg,
            'E', 'TMSEXPORT', l_msg);
    end if;
end if;
if (nvl(:new.tms_carrier_optimized_yn, 'N') = 'Y') and
   (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
   (((nvl(:old.orderstatus, 'x') != nvl(:new.orderstatus, 'x')) and
     (nvl(:new.orderstatus, 'x') in ('5','7','8','9'))) or
    ((:new.lastuser <> 'TMSIMPORT') and
     ((nvl(:old.shipdate, trunc(sysdate)) != nvl(:new.shipdate, trunc(sysdate))) or
      (nvl(:old.requested_ship, trunc(sysdate)) != nvl(:new.requested_ship, trunc(sysdate)))))) then
    eventCode := 'XX';
    if (nvl(:old.orderstatus, 'x') != nvl(:new.orderstatus, 'x')) then
        if (nvl(:new.orderstatus, 'x') = '5') then
            eventCode := 'ZZ';
        elsif (nvl(:new.orderstatus, 'x') = '7') then
            eventCode := 'L1';
        elsif (nvl(:new.orderstatus, 'x') = '8') then
            eventCode := 'CP';
        elsif (nvl(:new.orderstatus, 'x') = '9') then
            eventCode := 'AF';
        end if;
    elsif (nvl(:old.shipdate, trunc(sysdate)) != nvl(:new.shipdate, trunc(sysdate))) then
        eventCode := 'AA';
    elsif (nvl(:old.requested_ship, trunc(sysdate)) != nvl(:new.requested_ship, trunc(sysdate))) then
        eventCode := 'AC';
    end if;
    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        :new.custid, -- custid
        zim8.get_systemdefault('TMS_214_EXPORT_FORMAT'), -- formatid
        null, -- importfilepath
        'NOW', -- when
        null, -- loadno
        :new.orderid, -- orderid
        :new.shipid, -- shipid
        eventCode, --userid
        null, -- tablename
        null,  --columnname
        null, --filtercolumnname
        null, -- company
        null, -- warehouse
        to_char(sysdate,'YYYYMMDDHH24MISS'), -- begindatestr
        null, -- enddatestr
        intErrorno,out_msg);
    if intErrorno != 0 then
        zms.log_msg('TMSEXPORT', :new.fromfacility, '', 'Request TMS 214 Export: ' || out_msg,
            'E', 'TMSEXPORT', l_msg);
    end if;
elsif (nvl(:new.tms_carrier_optimized_yn, 'N') = 'Y') and
   (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
   (((nvl(:old.orderstatus, 'x') != nvl(:new.orderstatus, 'x')) and
     (nvl(:new.orderstatus, 'x') in ('A','R'))) or
    ((nvl(:old.orderstatus, 'x') != nvl(:new.orderstatus, 'x')) and
     (nvl(:old.orderstatus, 'x') = 'A') and
     (nvl(:new.orderstatus, 'x') in ('0','1','2','3')))) then
    eventCode := 'XX';
    if (nvl(:new.orderstatus, 'x') = 'A') then
        eventCode := 'X1';
    elsif (nvl(:new.orderstatus, 'x') = 'R') then
        eventCode := 'CD';
    elsif (nvl(:new.orderstatus, 'x') in ('0','1','2','3')) then
        eventCode := 'SD';
    end if;
    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        :new.custid, -- custid
        zim8.get_systemdefault('TMS_214_EXPORT_FORMAT'), -- formatid
        null, -- importfilepath
        'NOW', -- when
        null, -- loadno
        :new.orderid, -- orderid
        :new.shipid, -- shipid
        eventCode, --userid
        null, -- tablename
        null,  --columnname
        null, --filtercolumnname
        null, -- company
        null, -- warehouse
        to_char(sysdate,'YYYYMMDDHH24MISS'), -- begindatestr
        null, -- enddatestr
        intErrorno,out_msg);
    if intErrorno != 0 then
        zms.log_msg('TMSEXPORT', :new.fromfacility, '', 'Request TMS 214 Export: ' || out_msg,
            'E', 'TMSEXPORT', l_msg);
    end if;
end if;
end;
/
create or replace trigger orderhdr_bu
--
-- $Id$
--
before update
on orderhdr
for each row
declare
chrToFacility char(3);
def_date date := to_date('01012000','mmddyyyy');
CURSOR C_CUST(in_custid varchar2)
IS
SELECT tms_orders_to_plan_format
 FROM customer
WHERE custid = in_custid;
CUS C_CUST%rowtype;
begin
  if :old.orderstatus != :new.orderstatus then
    :new.statususer := :new.lastuser;
    :new.statusupdate := sysdate;
    if (nvl(zci.default_value('TMS_CARRIER'),'x') = :new.carrier) and
       (:new.orderstatus >= '0') and (:new.orderstatus <= '6') and
       (nvl(:new.tms_status,'X') = 'X')
    then
      :new.tms_status := '1';
      :new.tms_status_update := sysdate;
      :new.tms_carrier_optimized_yn := 'N';
    end if;
  elsif (nvl(:old.carrier,'x') <> nvl(:new.carrier,'x')) and
       (nvl(zci.default_value('TMS_CARRIER'),'x') = :new.carrier) and
       (:new.orderstatus >= '0') and (:new.orderstatus <= '6') and
       (nvl(:new.tms_status,'X') = 'X') then
    :new.tms_status := '1';
    :new.tms_status_update := sysdate;
    :new.tms_carrier_optimized_yn := 'N';
  elsif (nvl(:new.tms_carrier_optimized_yn,'X') = 'Y') and
        (:new.orderstatus >= '0') and (:new.orderstatus <= '6') and
        (nvl(:new.tms_status,'X') = '3') and
        ((nvl(:old.carrier,'x') <> nvl(:new.carrier,'x')) or
         (nvl(:old.fromfacility,'x') <> nvl(:new.fromfacility,'x')) or
         (nvl(:old.qtyorder,0) <> nvl(:new.qtyorder,0)) or
         (nvl(:old.weightorder,0) <> nvl(:new.weightorder,0)) or
         (nvl(:old.shipdate,def_date) <> nvl(:new.shipdate,def_date)) or
         (nvl(:old.delivery_requested,def_date) <> nvl(:new.delivery_requested,def_date)) or
         (nvl(:old.shipto,'x') <> nvl(:new.shipto,'x')) or
         (nvl(:old.shiptoname,'x') <> nvl(:new.shiptoname,'x')) or
         (nvl(:old.shiptocontact,'x') <> nvl(:new.shiptocontact,'x')) or
         (nvl(:old.shiptoaddr1,'x') <> nvl(:new.shiptoaddr1,'x')) or
         (nvl(:old.shiptoaddr2,'x') <> nvl(:new.shiptoaddr2,'x')) or
         (nvl(:old.shiptocity,'x') <> nvl(:new.shiptocity,'x')) or
         (nvl(:old.shiptostate,'x') <> nvl(:new.shiptostate,'x')) or
         (nvl(:old.shiptopostalcode,'x') <> nvl(:new.shiptopostalcode,'x')) or
         (nvl(:old.shiptocountrycode,'x') <> nvl(:new.shiptocountrycode,'x')) or
         (nvl(:old.shiptophone,'x') <> nvl(:new.shiptophone,'x')) or
         (nvl(:old.shiptofax,'x') <> nvl(:new.shiptofax,'x')) or
         (nvl(:old.shiptoemail,'x') <> nvl(:new.shiptoemail,'x')))
  then
    :new.tms_status := '1';
    :new.tms_status_update := sysdate;
    :new.tms_carrier_optimized_yn := 'N';
  end if;

  if (nvl(:old.ordertype,'x') != nvl(:new.ordertype,'x')) or
    (nvl(:old.tofacility,'x') != nvl(:new.tofacility,'x')) then
   if (nvl(:new.ordertype,'x') = 'Q') then
     chrToFacility := nvl(:new.tofacility,'   ');
     :new.is_returns_order := 'Y' || chrToFacility ||
       ltrim(to_char(:new.orderid,'09999999999')) || '-' || ltrim(to_char(:new.shipid,'09'));
   elsif (:new.is_returns_order is not null) then
     :new.is_returns_order := null;
   end if;
 end if;

 if (:old.custid != :new.custid) or
    (:old.shipto != :new.shipto) then
  update orderdtl
     set min_days_to_expiration =
         zoe.get_min_days_to_expiration(:new.orderid, :new.shipid, item)
   where orderid = :new.orderid
     and shipid = :new.shipid;
 end if;

 if nvl(:new.has_consumables,'N') != 'Y' or (:old.custid != :new.custid) then
   :new.has_consumables := 
     substr(zoe.consumable_entry_required(:new.custid,:new.ordertype),1,1);
 end if;
end;
/
show error trigger orderhdr_bi;
show error trigger orderhdr_ai;
show error trigger orderhdr_ad;
show error trigger orderhdr_au;
show error trigger orderhdr_bu;
show error trigger orderhdr_au_all;
show error trigger orderhdr_bu_all;
exit;
