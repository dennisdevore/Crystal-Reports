create or replace trigger loads_bi
--
-- $Id$
--
before insert
on loads
for each row
begin
    :new.recent_loadno := :new.loadno;
    :new.drop_type := nvl(:new.drop_type,zcustitem.default_value('DROPTYPEDEFAULT'));
end;
/
create or replace trigger loads_ai
--
-- $Id$
--
after insert
on loads
for each row
declare
chgdate date;
v_use_yard facility.use_yard%type;
v_count pls_integer;
l_msg varchar2(255);
begin
   chgdate := sysdate;
   insert into loadhistory
     (loadno, chgdate, userid, action, msg)
   values
     (:new.loadno, chgdate, :new.lastuser,
            'ADD', 'Add Load');

   if :new.trailer is not null then
      begin
        select nvl(use_yard, 'N') into v_use_yard
        from facility
        where facility = :new.facility;
      exception
        when others then
          v_use_yard := 'N';
      end;
      if v_use_yard = 'Y' then
         select count(1) into v_count
         from location
         where facility = nvl(:new.facility,'XXX')
           and locid = nvl(:new.doorloc,'(none)')
           and loctype = 'DOR';

         update trailer
         set loadno = :new.loadno,
             activity_type = decode(substr(:new.loadtype,1,1),'I','ATI','ATO'),
             location = case when v_count > 0 and :new.loadstatus > '2' then :new.doorloc else location end,
             disposition = case when v_count > 0 and :new.loadstatus > '2' then 'DC' else disposition end,
             lastuser = :new.lastuser,
             lastupdate = sysdate
         where carrier = :new.carrier and trailer_number = :new.trailer
           and (activity_type not in ('ATI','ATO') or loadno <> :new.loadno);
         zlh.add_loadhistory_autonomous(:new.loadno, 'Trailer To Load', 'Trailer Assigned '|| :new.trailer,
                                        :new.lastuser, l_msg);

      end if;
   end if;
end loads_ai;
/
create or replace trigger loads_bu
--
-- $Id$
--
before update
on loads
for each row
declare
  CURSOR C_SD(in_id varchar2)
  IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;
  csd C_SD%rowtype;

  cursor curCustUCC128 is
     select nvl(cu.manufacturerucc,'0000000') as manufacturerucc
       from orderhdr oh, customer cu
      where oh.loadno = :new.loadno
        and cu.custid = oh.custid;
  cucc curCustUCC128%rowtype;
begin
  if :old.loadstatus != :new.loadstatus then
    :new.statususer := :new.lastuser;
    :new.statusupdate := sysdate;
  end if;

  if nvl(:old.ldpassthruchar02,'x') != nvl(:new.ldpassthruchar02,'x') and
     :old.ldpassthruchar02 is null and :new.ldpassthruchar40 is null then
    csd := null;
    open C_SD('VICSBOLNUMBERAUTOGEN');
    fetch C_SD into csd;
    close C_SD;

    if ((nvl(csd.defaultvalue,'N') = 'Y') or (nvl(csd.defaultvalue,'N') = 'L')) then
      cucc := null;
      open curCustUCC128;
      fetch curCustUCC128 into cucc;
      close curCustUCC128;

      :new.ldpassthruchar40 := zld.calccheckdigit(cucc.manufacturerucc||trim(to_char(:new.loadno,'000000000')));
    end if;
  end if;
end;
/
create or replace trigger loads_au
--
-- $Id$
--
after update
on loads
for each row
declare
cursor c_oh(in_loadno number)
is
select orderid, shipid, custid
  from orderhdr
 where loadno = in_loadno
   and nvl(tms_carrier_optimized_yn, 'N') = 'Y';
oh c_oh%rowtype;
  currcount integer;
  nulldate date;
  chgdate date;
  ld_msg varchar2(2000);

  l_msg varchar2(255);
  eventCode varchar2(2);
  cursor c_cust(in_loadno number)
  is
     select distinct C.custid, C.outackbatchmap
       from customer C, customer_aux CA
        where C.custid in (select custid from orderhdr where loadno = in_loadno)
          and C.custid = CA.custid(+)
          and C.outackbatchmap is not null
          and nvl(CA.shipping_acknowledgment_status, 'x') in ('L', 'B');
  CU c_cust%rowtype;
  intErrorno integer;
  out_msg varchar2(255);
  l_facility facility.facility%type;
  v_use_yard facility.use_yard%type;
  v_count number;
  arrived_count integer;
  procedure add_msg(in_msg IN OUT varchar2, in_fn IN varchar2,
            in_old IN varchar2, in_new IN varchar2)
  is
    cont varchar2(2);
  begin
      if in_msg is null then
         cont := ' ';
         in_msg := 'Change load fields:';
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
  ld_msg := null;
  chgdate := sysdate;
  nulldate := to_date('01012000','mmddyyyy');

  if nvl(:old.facility,'x') <> nvl(:new.facility,'x')then
    update loadstop
       set facility = :new.facility
     where loadno = :new.loadno;
  end if;
  if nvl(:old.carrier,'x') != nvl(:new.carrier,'x') then
    update orderhdr
       set carrier = :new.carrier,
           lastuser = :new.lastuser
     where loadno = :new.loadno
       and nvl(carrier,'x') != nvl(:new.carrier,'x');

     select count(1)
      into currcount
      from pimevents
     where loadno = :new.loadno;

    if currcount != 0 then
      update pimevents
         set carrier = :new.carrier
       where loadno = :new.loadno;
    end if;
  end if;

  if nvl(:old.loadstatus,'x') <> nvl(:new.loadstatus,'x') and
     nvl(:new.loadstatus,'x') = '8' then
     open c_cust(:new.loadno);
     loop
        fetch c_cust into CU;
        exit when c_cust%notfound;
        ziem.impexp_request(
          'E', -- reqtype
          null, -- facility
          CU.custid, -- custid
          CU.OutAckBatchMap, -- formatid
          null, -- importfilepath
          'NOW', -- when
          :new.loadno, -- loadno
          0, -- orderid
          0, -- shipid
          'LOADED', --userid
          null, -- tablename
          null,  --columnname
          null, --filtercolumnname
          null, -- company
          null, -- warehouse
          null, -- begindatestr
          null, -- enddatestr
          intErrorno,out_msg);
        if intErrorno != 0 then
          zms.log_msg('LDLOADED', '', '', 'Request Export: ' || :new.loadno || ' ' || out_msg,
               'E', 'LDLOADED', out_msg);
        end if;
     end loop;
     close c_cust;
  end if;

  if nvl(:old.trailer,'x') != nvl(:new.trailer,'x') then
    begin
      select use_yard into v_use_yard
      from facility
      where facility = :new.facility;
    exception
      when others then
        v_use_yard := 'N';
    end;

    if nvl(v_use_yard,'N') = 'Y' then
      if :old.trailer is not null then
        update trailer
        set loadno = null,
          activity_type = 'DFL',
          lastuser = :new.lastuser,
          lastupdate = sysdate
        where carrier = :old.carrier and trailer_number = :old.trailer and loadno = :new.loadno
          and (activity_type <> 'DFL' or loadno is not null);
        zlh.add_loadhistory_autonomous(:new.loadno, 'Trailer Deassigned ', 'Trailer deassigned from load '|| :old.trailer,
                                       :new.lastuser, l_msg);
      end if;

      if :new.trailer is not null then
      /*
        select count(1) into v_count
        from location
        where facility = nvl(:new.facility,'XXX')
          and locid = nvl(:new.doorloc,'(none)')
          and loctype = 'DOR';

        select count(1) into arrived_count
          from door
         where facility = :new.facility
           and loadno = :new.loadno;
      */
        update trailer
        set loadno = :new.loadno,
            activity_type = decode(substr(:new.loadtype,1,1),'I','ATI','ATO'),
      --      location = case when v_count > 0 and :new.loadstatus > '2' and arrived_count > 0 then :new.doorloc else location end,
            disposition = case when v_count > 0 and :new.loadstatus > '2' then 'DC' else disposition end,
            lastuser = :new.lastuser,
            lastupdate = sysdate
        where carrier = :new.carrier and trailer_number = :new.trailer
          and (activity_type not in ('ATI','ATO') or loadno <> :new.loadno);
        zlh.add_loadhistory_autonomous(:new.loadno, 'Trailer To Load', 'Trailer Assigned '|| :new.trailer,
                                       :new.lastuser, l_msg);
      end if;
    end if;
  end if;

  if (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
     (:new.lastuser <> 'TMSIMPORT') and
     (nvl(:old.apptdate, trunc(sysdate)) != nvl(:new.apptdate, trunc(sysdate))) then
      eventCode := 'AB';
      for oh in c_oh(:new.loadno)
      loop
          ziem.impexp_request(
              'E', -- reqtype
              null, -- facility
              oh.custid, -- custid
              zim8.get_systemdefault('TMS_214_EXPORT_FORMAT'), -- formatid
              null, -- importfilepath
              'NOW', -- when
              null, -- loadno
              oh.orderid, -- orderid
              oh.shipid, -- shipid
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
              zms.log_msg('TMSEXPORT', :new.facility, '', 'Request TMS 214 Export: ' || out_msg,
                  'E', 'TMSEXPORT', l_msg);
          end if;
      end loop;
  elsif (:new.carrier = zim8.get_systemdefault('TMS_CARRIER')) and
     (nvl(:old.loadstatus, 'x') != nvl(:new.loadstatus, 'x')) and
     (nvl(:new.loadstatus, 'x') = 'E') then
      eventCode := 'D1';
      for oh in c_oh(:new.loadno)
      loop
          ziem.impexp_request(
              'E', -- reqtype
              null, -- facility
              oh.custid, -- custid
              zim8.get_systemdefault('TMS_214_EXPORT_FORMAT'), -- formatid
              null, -- importfilepath
              'NOW', -- when
              null, -- loadno
              oh.orderid, -- orderid
              oh.shipid, -- shipid
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
              zms.log_msg('TMSEXPORT', :new.facility, '', 'Request TMS 214 Export: ' || out_msg,
                  'E', 'TMSEXPORT', l_msg);
          end if;
      end loop;
  end if;
  if (nvl(:old.entrydate,nulldate) <> nvl(:new.entrydate,nulldate)) then
     add_msg(ld_msg,'entrydate',
        to_char(:old.entrydate, 'MM-DD-YY HH:MI:SSAM'),
        to_char(:new.entrydate, 'MM-DD-YY HH:MI:SSAM'));
  end if;
  if (nvl(:old.rcvddate,nulldate) <> nvl(:new.rcvddate,nulldate)) then
     add_msg(ld_msg,'rcvddate',
        to_char(:old.rcvddate, 'MM-DD-YY HH:MI:SSAM'),
        to_char(:new.rcvddate, 'MM-DD-YY HH:MI:SSAM'));
  end if;
  if (nvl(:old.billdate,nulldate) <> nvl(:new.billdate,nulldate)) then
     add_msg(ld_msg,'billdate',
        to_char(:old.billdate, 'MM-DD-YY HH:MI:SSAM'),
        to_char(:new.billdate, 'MM-DD-YY HH:MI:SSAM'));
  end if;

  if (nvl(:old.loadstatus,'x') <> nvl(:new.loadstatus,'x'))
  then
      add_msg(ld_msg,'LoadStatus',
                 :old.loadstatus,
                 :new.loadstatus);
  end if;
  if (nvl(:old.trailer,'x') <> nvl(:new.trailer,'x'))
  then
      add_msg(ld_msg,'Trailer',
                 :old.trailer,
                 :new.trailer);
  end if;
  if (nvl(:old.seal,'x') <> nvl(:new.seal,'x'))
  then
      add_msg(ld_msg,'Seal',
                 :old.seal,
                 :new.seal);
  end if;
  if (nvl(:old.seal,'x') <> nvl(:new.seal,'x'))
  then
      add_msg(ld_msg,'Seal',
                 :old.seal,
                 :new.seal);
  end if;
  if (nvl(:old.doorloc,'x') <> nvl(:new.doorloc,'x'))
  then
      add_msg(ld_msg,'DoorLoc',
                 :old.doorloc,
                 :new.doorloc);
  end if;
  if (nvl(:old.stageloc,'x') <> nvl(:new.stageloc,'x'))
  then
      add_msg(ld_msg,'StageLoc',
                 :old.stageloc,
                 :new.stageloc);
  end if;
  if (nvl(:old.carrier,'x') <> nvl(:new.carrier,'x'))
  then
      add_msg(ld_msg,'Carrier',
                 :old.carrier,
                 :new.carrier);
  end if;
  if (nvl(:old.billoflading,'x') <> nvl(:new.billoflading,'x'))
  then
      add_msg(ld_msg,'BillOfLading',
                 :old.billoflading,
                 :new.billoflading);
  end if;
  if (nvl(:old.loadtype,'x') <> nvl(:new.loadtype,'x'))
  then
      add_msg(ld_msg,'Loadtype',
                 :old.loadtype,
                 :new.loadtype);
  end if;
  if (nvl(:old.prono,'x') <> nvl(:new.prono,'x'))
  then
      add_msg(ld_msg,'Prono',
                 :old.prono,
                 :new.prono);
  end if;
  if (nvl(:old.apptdate,nulldate) <> nvl(:new.apptdate,nulldate)) then
     add_msg(ld_msg,'ApptDate',
        to_char(:old.apptdate, 'MM-DD-YY HH:MI:SSAM'),
        to_char(:new.apptdate, 'MM-DD-YY HH:MI:SSAM'));
  end if;
  if (nvl(:old.shiptype,'x') <> nvl(:new.shiptype,'x'))
  then
     add_msg(ld_msg,'ShipType',
                :old.shiptype,
                :new.shiptype);
  end if;
  if (nvl(:old.shipterms,'x') <> nvl(:new.shipterms,'x'))
  then
     add_msg(ld_msg,'ShipTerms',
                :old.shipterms,
                :new.shipterms);
  end if;
  if (nvl(:old.appointmentid,0) <> nvl(:new.appointmentid,0))
  then
     add_msg(ld_msg,'AppointmentID',
                :old.appointmentid,
                :new.appointmentid);
  end if;
  if (nvl(:old.lateshipreason,'x') <> nvl(:new.lateshipreason,'x'))
  then
     add_msg(ld_msg,'LateShipReason',
                :old.lateshipreason,
                :new.lateshipreason);
  end if;
  if (nvl(:old.ldpassthruchar01,'x') <> nvl(:new.ldpassthruchar01,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar01',
                :old.ldpassthruchar01,
                :new.ldpassthruchar01);
  end if;
  if (nvl(:old.ldpassthruchar02,'x') <> nvl(:new.ldpassthruchar02,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar02',
                :old.ldpassthruchar02,
                :new.ldpassthruchar02);
  end if;
  if (nvl(:old.ldpassthruchar03,'x') <> nvl(:new.ldpassthruchar03,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar03',
                :old.ldpassthruchar03,
                :new.ldpassthruchar03);
  end if;
  if (nvl(:old.ldpassthruchar04,'x') <> nvl(:new.ldpassthruchar04,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar04',
                :old.ldpassthruchar04,
                :new.ldpassthruchar04);
  end if;
  if (nvl(:old.ldpassthruchar05,'x') <> nvl(:new.ldpassthruchar05,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar05',
                :old.ldpassthruchar05,
                :new.ldpassthruchar05);
  end if;
  if (nvl(:old.ldpassthruchar06,'x') <> nvl(:new.ldpassthruchar06,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar06',
                :old.ldpassthruchar06,
                :new.ldpassthruchar06);
  end if;
  if (nvl(:old.ldpassthruchar07,'x') <> nvl(:new.ldpassthruchar07,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar07',
                :old.ldpassthruchar07,
                :new.ldpassthruchar07);
  end if;
  if (nvl(:old.ldpassthruchar08,'x') <> nvl(:new.ldpassthruchar08,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar08',
                :old.ldpassthruchar08,
                :new.ldpassthruchar08);
  end if;
  if (nvl(:old.ldpassthruchar09,'x') <> nvl(:new.ldpassthruchar09,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar09',
                :old.ldpassthruchar09,
                :new.ldpassthruchar09);
  end if;
  if (nvl(:old.ldpassthruchar10,'x') <> nvl(:new.ldpassthruchar10,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar10',
                :old.ldpassthruchar10,
                :new.ldpassthruchar10);
  end if;
  if (nvl(:old.ldpassthruchar11,'x') <> nvl(:new.ldpassthruchar11,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar11',
                :old.ldpassthruchar11,
                :new.ldpassthruchar11);
  end if;
  if (nvl(:old.ldpassthruchar12,'x') <> nvl(:new.ldpassthruchar12,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar12',
                :old.ldpassthruchar12,
                :new.ldpassthruchar12);
  end if;
  if (nvl(:old.ldpassthruchar13,'x') <> nvl(:new.ldpassthruchar13,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar13',
                :old.ldpassthruchar13,
                :new.ldpassthruchar13);
  end if;
  if (nvl(:old.ldpassthruchar14,'x') <> nvl(:new.ldpassthruchar14,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar14',
                :old.ldpassthruchar14,
                :new.ldpassthruchar14);
  end if;
  if (nvl(:old.ldpassthruchar15,'x') <> nvl(:new.ldpassthruchar15,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar15',
                :old.ldpassthruchar15,
                :new.ldpassthruchar15);
  end if;
  if (nvl(:old.ldpassthruchar16,'x') <> nvl(:new.ldpassthruchar16,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar16',
                :old.ldpassthruchar16,
                :new.ldpassthruchar16);
  end if;
  if (nvl(:old.ldpassthruchar17,'x') <> nvl(:new.ldpassthruchar17,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar17',
                :old.ldpassthruchar17,
                :new.ldpassthruchar17);
  end if;
  if (nvl(:old.ldpassthruchar18,'x') <> nvl(:new.ldpassthruchar18,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar18',
                :old.ldpassthruchar18,
                :new.ldpassthruchar18);
  end if;
  if (nvl(:old.ldpassthruchar19,'x') <> nvl(:new.ldpassthruchar19,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar19',
                :old.ldpassthruchar19,
                :new.ldpassthruchar19);
  end if;
  if (nvl(:old.ldpassthruchar20,'x') <> nvl(:new.ldpassthruchar20,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar20',
                :old.ldpassthruchar20,
                :new.ldpassthruchar20);
  end if;
  if (nvl(:old.ldpassthruchar21,'x') <> nvl(:new.ldpassthruchar21,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar21',
                :old.ldpassthruchar21,
                :new.ldpassthruchar21);
  end if;
  if (nvl(:old.ldpassthruchar22,'x') <> nvl(:new.ldpassthruchar22,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar22',
                :old.ldpassthruchar22,
                :new.ldpassthruchar22);
  end if;
  if (nvl(:old.ldpassthruchar23,'x') <> nvl(:new.ldpassthruchar23,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar23',
                :old.ldpassthruchar23,
                :new.ldpassthruchar23);
  end if;
  if (nvl(:old.ldpassthruchar24,'x') <> nvl(:new.ldpassthruchar24,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar24',
                :old.ldpassthruchar24,
                :new.ldpassthruchar24);
  end if;
  if (nvl(:old.ldpassthruchar25,'x') <> nvl(:new.ldpassthruchar25,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar25',
                :old.ldpassthruchar25,
                :new.ldpassthruchar25);
  end if;
  if (nvl(:old.ldpassthruchar26,'x') <> nvl(:new.ldpassthruchar26,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar26',
                :old.ldpassthruchar26,
                :new.ldpassthruchar26);
  end if;
  if (nvl(:old.ldpassthruchar27,'x') <> nvl(:new.ldpassthruchar27,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar27',
                :old.ldpassthruchar27,
                :new.ldpassthruchar27);
  end if;
  if (nvl(:old.ldpassthruchar28,'x') <> nvl(:new.ldpassthruchar28,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar28',
                :old.ldpassthruchar28,
                :new.ldpassthruchar28);
  end if;
  if (nvl(:old.ldpassthruchar29,'x') <> nvl(:new.ldpassthruchar29,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar29',
                :old.ldpassthruchar29,
                :new.ldpassthruchar29);
  end if;
  if (nvl(:old.ldpassthruchar30,'x') <> nvl(:new.ldpassthruchar30,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar30',
                :old.ldpassthruchar30,
                :new.ldpassthruchar30);
  end if;
  if (nvl(:old.ldpassthruchar31,'x') <> nvl(:new.ldpassthruchar31,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar31',
                :old.ldpassthruchar31,
                :new.ldpassthruchar31);
  end if;
  if (nvl(:old.ldpassthruchar32,'x') <> nvl(:new.ldpassthruchar32,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar32',
                :old.ldpassthruchar32,
                :new.ldpassthruchar32);
  end if;
  if (nvl(:old.ldpassthruchar33,'x') <> nvl(:new.ldpassthruchar33,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar33',
                :old.ldpassthruchar33,
                :new.ldpassthruchar33);
  end if;
  if (nvl(:old.ldpassthruchar34,'x') <> nvl(:new.ldpassthruchar34,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar34',
                :old.ldpassthruchar34,
                :new.ldpassthruchar34);
  end if;
  if (nvl(:old.ldpassthruchar35,'x') <> nvl(:new.ldpassthruchar35,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar35',
                :old.ldpassthruchar35,
                :new.ldpassthruchar35);
  end if;
  if (nvl(:old.ldpassthruchar36,'x') <> nvl(:new.ldpassthruchar36,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar36',
                :old.ldpassthruchar36,
                :new.ldpassthruchar36);
  end if;
  if (nvl(:old.ldpassthruchar37,'x') <> nvl(:new.ldpassthruchar37,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar37',
                :old.ldpassthruchar37,
                :new.ldpassthruchar37);
  end if;
  if (nvl(:old.ldpassthruchar38,'x') <> nvl(:new.ldpassthruchar38,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar38',
                :old.ldpassthruchar38,
                :new.ldpassthruchar38);
  end if;
  if (nvl(:old.ldpassthruchar39,'x') <> nvl(:new.ldpassthruchar39,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar39',
                :old.ldpassthruchar39,
                :new.ldpassthruchar39);
  end if;
  if (nvl(:old.ldpassthruchar40,'x') <> nvl(:new.ldpassthruchar40,'x'))
  then
     add_msg(ld_msg,'ldpassthruchar40',
                :old.ldpassthruchar40,
                :new.ldpassthruchar40);
  end if;
  if (nvl(:old.ldpassthrunum01,0) <> nvl(:new.ldpassthrunum01,0))
  then
     add_msg(ld_msg,'ldpassthrunum01',
                :old.ldpassthrunum01,
                :new.ldpassthrunum01);
  end if;
  if (nvl(:old.ldpassthrunum02,0) <> nvl(:new.ldpassthrunum02,0))
  then
     add_msg(ld_msg,'ldpassthrunum02',
                :old.ldpassthrunum02,
                :new.ldpassthrunum02);
  end if;
  if (nvl(:old.ldpassthrunum03,0) <> nvl(:new.ldpassthrunum03,0))
  then
     add_msg(ld_msg,'ldpassthrunum03',
                :old.ldpassthrunum03,
                :new.ldpassthrunum03);
  end if;
  if (nvl(:old.ldpassthrunum04,0) <> nvl(:new.ldpassthrunum04,0))
  then
     add_msg(ld_msg,'ldpassthrunum04',
                :old.ldpassthrunum04,
                :new.ldpassthrunum04);
  end if;
  if (nvl(:old.ldpassthrunum05,0) <> nvl(:new.ldpassthrunum05,0))
  then
     add_msg(ld_msg,'ldpassthrunum05',
                :old.ldpassthrunum05,
                :new.ldpassthrunum05);
  end if;
  if (nvl(:old.ldpassthrunum06,0) <> nvl(:new.ldpassthrunum06,0))
  then
     add_msg(ld_msg,'ldpassthrunum06',
                :old.ldpassthrunum06,
                :new.ldpassthrunum06);
  end if;
  if (nvl(:old.ldpassthrunum07,0) <> nvl(:new.ldpassthrunum07,0))
  then
     add_msg(ld_msg,'ldpassthrunum07',
                :old.ldpassthrunum07,
                :new.ldpassthrunum07);
  end if;
  if (nvl(:old.ldpassthrunum08,0) <> nvl(:new.ldpassthrunum08,0))
  then
     add_msg(ld_msg,'ldpassthrunum08',
                :old.ldpassthrunum08,
                :new.ldpassthrunum08);
  end if;
  if (nvl(:old.ldpassthrunum09,0) <> nvl(:new.ldpassthrunum09,0))
  then
     add_msg(ld_msg,'ldpassthrunum09',
                :old.ldpassthrunum09,
                :new.ldpassthrunum09);
  end if;
  if (nvl(:old.ldpassthrunum10,0) <> nvl(:new.ldpassthrunum10,0))
  then
     add_msg(ld_msg,'ldpassthrunum10',
                :old.ldpassthrunum10,
                :new.ldpassthrunum10);
  end if;
  if (nvl(:old.ldpassthrudate01,nulldate) <> nvl(:new.ldpassthrudate01,nulldate))
  then
     add_msg(ld_msg,'ldpassthrudate01',
                :old.ldpassthrudate01,
                :new.ldpassthrudate01);
  end if;
  if (nvl(:old.ldpassthrudate02,nulldate) <> nvl(:new.ldpassthrudate02,nulldate))
  then
     add_msg(ld_msg,'ldpassthrudate02',
                :old.ldpassthrudate02,
                :new.ldpassthrudate02);
  end if;
  if (nvl(:old.ldpassthrudate03,nulldate) <> nvl(:new.ldpassthrudate03,nulldate))
  then
     add_msg(ld_msg,'ldpassthrudate03',
                :old.ldpassthrudate03,
                :new.ldpassthrudate03);
  end if;
  if (nvl(:old.ldpassthrudate04,nulldate) <> nvl(:new.ldpassthrudate04,nulldate))
  then
     add_msg(ld_msg,'ldpassthrudate04',
                :old.ldpassthrudate04,
                :new.ldpassthrudate04);
  end if;
  if (nvl(:old.putonwater,nulldate) <> nvl(:new.putonwater,nulldate))
  then
     add_msg(ld_msg,'putonwater',
                :old.putonwater,
                :new.putonwater);
  end if;
  if (nvl(:old.etatoport,nulldate) <> nvl(:new.etatoport,nulldate))
  then
     add_msg(ld_msg,'etatoport',
                :old.etatoport,
                :new.etatoport);
  end if;
  if (nvl(:old.arrivedatport,nulldate) <> nvl(:new.arrivedatport,nulldate))
  then
     add_msg(ld_msg,'arrivedatport',
                :old.arrivedatport,
                :new.arrivedatport);
  end if;
  if (nvl(:old.lastfreedate,nulldate) <> nvl(:new.lastfreedate,nulldate))
  then
     add_msg(ld_msg,'lastfreedate',
                :old.lastfreedate,
                :new.lastfreedate);
  end if;
  if (nvl(:old.carriercontactdate,nulldate) <> nvl(:new.carriercontactdate,nulldate))
  then
     add_msg(ld_msg,'carriercontactdate',
                :old.carriercontactdate,
                :new.carriercontactdate);
  end if;
  if (nvl(:old.arrivedinyard,nulldate) <> nvl(:new.arrivedinyard,nulldate))
  then
     add_msg(ld_msg,'arrivedinyard',
                :old.arrivedinyard,
                :new.arrivedinyard);
  end if;
  if (nvl(:old.appointmentdate,nulldate) <> nvl(:new.appointmentdate,nulldate))
  then
     add_msg(ld_msg,'appointmentdate',
                :old.appointmentdate,
                :new.appointmentdate);
  end if;
  if (nvl(:old.dueback,nulldate) <> nvl(:new.dueback,nulldate))
  then
     add_msg(ld_msg,'dueback',
                :old.dueback,
                :new.dueback);
  end if;
  if (nvl(:old.returnedtoport,nulldate) <> nvl(:new.returnedtoport,nulldate))
  then
     add_msg(ld_msg,'returnedtoport',
                :old.returnedtoport,
                :new.returnedtoport);
  end if;
  if (nvl(:old.etatofacility,nulldate) <> nvl(:new.etatofacility,nulldate))
  then
     add_msg(ld_msg,'etatofacility',
                :old.etatofacility,
                :new.etatofacility);
  end if;
  if (nvl(:old.liveunload,'x') <> nvl(:new.liveunload,'x'))
  then
     add_msg(ld_msg,'liveunload',
                :old.liveunload,
                :new.liveunload);
  end if;
  if (nvl(:old.trackforcustomer,'x') <> nvl(:new.trackforcustomer,'x'))
  then
     add_msg(ld_msg,'trackforcustomer',
                :old.trackforcustomer,
                :new.trackforcustomer);
  end if;

  if ld_msg is not null then
     insert into loadhistory
       (loadno, chgdate, userid, action, msg)
     values
       (:new.loadno, chgdate, :new.lastuser,'CHANGE', ld_msg);
  end if;

 if nvl(:old.comment1,'x') != nvl(:new.comment1,'x') then
     insert into loadhistory
       (loadno, chgdate, userid, action, msg)
     values
       (:new.loadno, chgdate, :new.lastuser,
            'CHANGE','Comment1 was: '||chr(13) || chr(10) ||
             nvl(substr(:old.comment1,1,1000),'(null)'));
 end if;

 if nvl(:old.trackingnotes,'x') != nvl(:new.trackingnotes,'x') then
     insert into loadhistory
       (loadno, chgdate, userid, action, msg)
     values
       (:new.loadno, chgdate, :new.lastuser,
            'CHANGE','Trackingnotes was: '||chr(13) || chr(10) ||
             nvl(substr(:old.trackingnotes,1,1000),'(null)'));
 end if;

end;
/
show error trigger loads_bi;
show error trigger loads_bu;
show error trigger loads_au;
exit;
