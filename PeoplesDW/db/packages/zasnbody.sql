create or replace package body alps.zasncapture as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
-- Constants are defined in zbillspec.sql
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
--
----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
 select *
   from plate
  where lpid = in_lpid;
----------------------------------------------------------------------
CURSOR C_PLTITEMS(in_lpid varchar2, in_ignore_anvdate varchar2)
IS
 select P.custid, P.item, P.unitofmeasure UOM, P.invstatus, P.inventoryclass,
        P.lotnumber, P.status, P.manufacturedate, P.expirationdate,
        P.countryof,
        decode(CI.serialrequired,'Y',P.serialnumber,null) serialnumber,
        decode(CI.user1required,'Y',P.useritem1,null) useritem1,
        decode(CI.user2required,'Y',P.useritem2,null) useritem2,
        decode(CI.user3required,'Y',P.useritem3,null) useritem3,
        sum(P.quantity) qty, sum(P.qtyrcvd) qtyrcvd, min(P.lastcountdate) lcd,
        sum(P.qtyentered) qtyentered, sum(P.weight) weight,
        decode(in_ignore_anvdate, 'Y', null, P.anvdate) anvdate
   from custitemview CI, plate P
  where P.parentlpid = in_lpid
    and nvl(P.custid,'(none)') = CI.custid(+)
    and nvl(P.item,'(none)') = CI.item(+)
  group by P.custid, P.item, P.unitofmeasure, P.invstatus, P.inventoryclass,
           P.lotnumber, P.status, P.manufacturedate, P.expirationdate,
           P.countryof,
           decode(CI.serialrequired,'Y',P.serialnumber,null),
           decode(CI.user1required,'Y',P.useritem1,null),
           decode(CI.user2required,'Y',P.useritem2,null),
           decode(CI.user3required,'Y',P.useritem3,null),
           decode(in_ignore_anvdate, 'Y', null, P.anvdate);

----------------------------------------------------------------------
CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
RETURN custitemview%rowtype
IS
 select *
   from custitemview I
  where I.custid = in_custid
    and I.item = in_item;
----------------------------------------------------------------------


----------------------------------------------------------------------
--
-- check_plate
--
----------------------------------------------------------------------
PROCEDURE check_plate
(
    in_lpid           IN      varchar2,
    in_print          IN      varchar2,
    in_ignore_anvdate IN      varchar2,
    out_errno         OUT     number,
    out_errmsg        OUT     varchar2
)
IS

PLT plate%rowtype;

NP C_PLTITEMS%rowtype;


ix integer;

is_ok char;
has_item char;

ITM custitemview%rowtype;
l_user1_count number;
l_user2_count number;
l_user3_count number;
l_serial_count number;

procedure prt(in_text in varchar2 := null)
is

datestr varchar2(17);

begin

  if in_print != 'Y' then
     return;
  end if;
  select to_char(sysdate, 'mm/dd/yy hh24:mi:ss')
    into datestr
    from dual;
--  dbms_output.put_line(datestr || ' ' || in_text);
  dbms_output.put_line('> '||in_text);

end prt;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    PLT := null;
    OPEN C_PLATE(in_lpid);
    FETCH C_PLATE into PLT;
    CLOSE C_PLATE;

    if PLT.lpid is null then
       out_errno := 1;
       out_errmsg := 'Plate does not exist.';
       return;
    end if;

    if nvl(PLT.type,'XX') != 'MP' then
       out_errno := 2;
       out_errmsg := 'Plate is not a multi-plate.';
       return;
    end if;

    if PLT.parentlpid is not null then
       out_errno := 3;
       out_errmsg := 'Plate has a parent.('||PLT.parentlpid||')';
       return;
    end if;

    if nvl(PLT.qtytasked,0) != 0 then
       out_errno := 4;
       out_errmsg := 'Plate has quantity tasked for it.';
       return;
    end if;


    ix := 0;
    NP := null;
    is_ok := 'Y';
    has_item := 'N';
    for crec in C_PLTITEMS(in_lpid, in_ignore_anvdate) loop
        ix := ix + 1;

           if NP.item is not null then
              if NP.item != crec.item then
                 prt('   Items mixed:'||NP.item
                         ||'/'||crec.item);
              end if;
           end if;

           has_item := 'Y';
           if NP.item is not null then
              if NP.item != crec.item then
                 prt('   Items mixed:'||NP.item
                         ||'/'||crec.item);
              end if;
              if NP.lotnumber != crec.lotnumber then
                 prt('   Lotnumbers mixed:'||NP.lotnumber
                         ||'/'||crec.lotnumber);
              end if;
              if NP.invstatus != crec.invstatus then
                 prt('   Invstatus mixed:'||NP.invstatus
                         ||'/'||crec.invstatus);
              end if;
              if NP.inventoryclass != crec.inventoryclass then
                 prt('   Inventoryclass mixed:'||NP.inventoryclass
                         ||'/'||crec.inventoryclass);
              end if;
              if nvl(NP.manufacturedate,to_date('20010101','YYYYMMDD'))
                   != nvl(crec.manufacturedate,to_date('20010101','YYYYMMDD'))
              then
                 prt('   Manufacture dates mixed:'||NP.manufacturedate
                         ||'/'||crec.manufacturedate);
              end if;
              if nvl(NP.expirationdate,to_date('20010101','YYYYMMDD'))
                   != nvl(crec.expirationdate,to_date('20010101','YYYYMMDD'))
              then
                 prt('   Expiration dates mixed:'||NP.expirationdate
                         ||'/'||crec.expirationdate);
              end if;
              if nvl(NP.anvdate,to_date('20010101','YYYYMMDD'))
                   != nvl(crec.anvdate,to_date('20010101','YYYYMMDD'))
              then
                 prt('   Anniversary dates mixed:'||NP.anvdate
                         ||'/'||crec.anvdate);
              end if;
/*
              if nvl(NP.expiryaction,'xx')
                   != nvl(crec.expiryaction,'xx')
              then
                 prt('   Expiration actions mixed:'||NP.expiryaction
                         ||'/'||crec.expiryaction);
              end if;
*/
              if nvl(NP.countryof,'xx')
                   != nvl(crec.countryof,'xx')
              then
                 prt('   Country of origin mixed:'||NP.countryof
                         ||'/'||crec.countryof);
              end if;
              if nvl(NP.useritem1,'xx')
                   != nvl(crec.useritem1,'xx')
              then
                 prt('   User item 1 mixed:'||NP.useritem1
                         ||'/'||crec.useritem1);
              end if;
              if nvl(NP.useritem2,'xx')
                   != nvl(crec.useritem2,'xx')
              then
                 prt('   User item 2 mixed:'||NP.useritem2
                         ||'/'||crec.useritem2);
              end if;
              if nvl(NP.useritem3,'xx')
                   != nvl(crec.useritem3,'xx')
              then
                 prt('   User item 3 mixed:'||NP.useritem3
                         ||'/'||crec.useritem3);
              end if;
        end if;
        NP := crec;
    end loop;
    if ix > 1 then
       is_ok := 'N';
    end if;
    -- prt(' OKAY to convert?'||is_ok||' Qty:'||NP.qty||' UOM:'||NP.uom
    --      || ' QR:'||NP.qtyrcvd||' LCD:'||NP.lcd);

    if is_ok = 'N' then
       out_errno := 9;
       out_errmsg := 'Did not pass consolidation verification test.';
    end if;

EXCEPTION when others then
    out_errno  := sqlcode;
    out_errmsg := sqlerrm;
END check_plate;

----------------------------------------------------------------------
--
-- consolidate_plate
--
----------------------------------------------------------------------
PROCEDURE consolidate_plate
(
    in_lpid         IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
)
IS


PLT plate%rowtype;
NP plate%rowtype;

SP C_PLTITEMS%rowtype;
l_orderstatus orderhdr.orderstatus%type;
cntArrived integer;

CURSOR C_CHILDREN(in_lpid varchar2)
IS
  select lpid
    from plate
   where parentlpid = in_lpid;

ix integer;

is_ok char;

strMsg varchar2(200);
l_cnt pls_integer;
l_ignore_anvdate char := 'N';
ITM custitemview%rowtype;
l_user1_count number;
l_user2_count number;
l_user3_count number;
l_serial_count number;
BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    select count(1) into l_cnt
      from plate PL, orderhdr OH
      where PL.parentlpid = in_lpid
        and OH.orderid (+) = PL.orderid
        and OH.shipid (+) = PL.shipid
        and nvl(OH.ordertype,'X') != 'Q';
    if l_cnt = 0 then
       select count(1) into l_cnt
         from plate PL, customer_aux CX
         where PL.parentlpid = in_lpid
           and CX.custid = PL.custid
           and nvl(CX.ignore_anvdate_for_ret_cons,'N') = 'N';
      if l_cnt = 0 then
         l_ignore_anvdate := 'Y';
      end if;
    else
       select count(1) into l_cnt
         from plate PL, customer_aux CX
         where PL.parentlpid = in_lpid
           and CX.custid = PL.custid
           and nvl(CX.suppressanniversarydate, nvl(zci.default_value('SUPPRESSANNIVERSARYDATE'), 'N')) = 'N';
      if l_cnt = 0 then
         l_ignore_anvdate := 'Y';
      end if;
    end if;

 -- verify this is a valid plate for consoldation
    check_plate(in_lpid, 'N', l_ignore_anvdate, out_errno, out_errmsg);

    if out_errno != 0 then
       return;
    end if;

    PLT := null;
    OPEN C_PLATE(in_lpid);
    FETCH C_PLATE into PLT;
    CLOSE C_PLATE;

 -- Collect to common data and reverify the information
    ix := 0;
    SP := null;
    is_ok := 'Y';
    for crec in C_PLTITEMS(in_lpid, l_ignore_anvdate) loop
        ix := ix + 1;

        ITM := null;
        OPEN C_ITEM(crec.custid, crec.item);
        FETCH C_ITEM into ITM;
        CLOSE C_ITEM;
       
        select count(distinct nvl(useritem1,'XXX')), count(distinct nvl(useritem2,'XXX')), 
        	count(distinct nvl(useritem3,'XXX')), count(distinct nvl(serialnumber,'XXX'))
        into l_user1_count, l_user2_count, l_user3_count, l_serial_count
        from plate
        where parentlpid = in_lpid;
        
        if (ITM.user1required = 'Y' and l_user1_count > 1) then
          out_errno := 8;
          out_errmsg := 'User Item 1 not unique';
          return;
        end if;
        
        if (ITM.user2required = 'Y' and l_user2_count > 1) then
          out_errno := 8;
          out_errmsg := 'User Item 2 not unique';
          return;
        end if;
        
        if (ITM.user3required = 'Y' and l_user3_count > 1) then
          out_errno := 8;
          out_errmsg := 'User Item 3 not unique';
          return;
        end if;

        if (ITM.serialrequired = 'Y' and l_serial_count > 1) then
          out_errno := 8;
          out_errmsg := 'Serial not unique';
          return;
        end if;
        SP := crec;
    end loop;
    if ix > 1 then
       out_errno := 8;
       out_errmsg := 'After checking does not match????';
       return;
    end if;

 -- empty the new plate information to start
    NP := null;

 -- If po unique for the children use it for the consolidated plate
    begin
      select distinct po
        into NP.po
        from plate
       where parentlpid = in_lpid;
    exception when others then
        NP.po := null;
    end;

 -- If recmethod unique for the children use it for the consolidated plate
    begin
      select distinct recmethod
        into NP.recmethod
        from plate
       where parentlpid = in_lpid;
    exception when others then
        NP.recmethod := null;
    end;

 -- If load info unique for the children use it for the consolidated plate
    begin
      select distinct loadno, stopno, shipno
        into NP.loadno, NP.stopno, NP.shipno
        from plate
       where parentlpid = in_lpid;
    exception when others then
        NP.loadno := null;
        NP.stopno := null;
        NP.shipno := null;
    end;

 -- If order info unique for the children use it for the consolidated plate
    begin
      select distinct orderid, shipid
        into NP.orderid, NP.shipid
        from plate
       where parentlpid = in_lpid;
    exception when others then
        NP.orderid := null;
        NP.shipid := null;
    end;

-- Check Status of orders for open receipts
    l_orderstatus := 'R';
    if NP.orderid is null then
      cntArrived := 0;
      for ord in (select distinct orderid,shipid
                    from plate
                   where parentlpid = in_lpid
                     and type = 'PA')
      loop
        begin
          select orderstatus
            into l_orderstatus
            from orderhdr
           where orderid = ord.orderid
             and shipid = ord.shipid;
        exception when others then
          l_orderstatus := 'R';
        end;
        if l_orderstatus = 'A' then
          cntArrived := cntArrived + 1;
          exit;
        end if;
      end loop;
      if (cntArrived != 0) then
          out_errno := 10;
          out_errmsg := 'Multiple orders on pallet (including ''ARRIVED'' orders)';
          return;
      else
        l_orderstatus := 'R';
      end if;
    else
      begin
        select orderstatus
          into l_orderstatus
          from orderhdr
         where orderid = NP.orderid
           and shipid = NP.shipid;
      exception when others then
        l_orderstatus := 'R';
      end;
    end if;

 -- If entered info unique for the children use it for the consolidated plate
    begin
      select distinct itementered, uomentered
        into NP.item, NP.uomentered
        from plate
       where parentlpid = in_lpid;
    exception when others then
        NP.item := null;
        NP.uomentered := null;
    end;

 -- use the other data from the children
    NP.serialnumber := SP.serialnumber;
    NP.useritem1 := SP.useritem1;
    NP.useritem2 := SP.useritem2;
    NP.useritem3 := SP.useritem3;

    NP.item := SP.item;
    NP.custid := SP.custid;
    NP.status := SP.status;
    NP.unitofmeasure := SP.uom;
    NP.quantity := SP.qty;
    NP.type := 'PA';
    NP.lotnumber := SP.lotnumber;
    NP.creationdate := PLT.creationdate;
    NP.manufacturedate := SP.manufacturedate;
    NP.expirationdate := SP.expirationdate;
    NP.expiryaction := null;
    NP.lastcountdate := SP.lcd;
    -- NP.recmethod := SP.recmethod;
    NP.condition := PLT.condition;
    NP.lastoperator := in_user;
    NP.lasttask := 'CN';
    NP.fifodate := PLT.fifodate;
    NP.countryof := SP.countryof;
    NP.lastuser := in_user;
    NP.lastupdate := sysdate;
    NP.invstatus := SP.invstatus;
    NP.qtyentered := SP.qtyentered;
    NP.inventoryclass := SP.inventoryclass;
    NP.weight := SP.weight;
    NP.qtyrcvd := SP.qtyrcvd;
    NP.qtytasked := PLT.qtytasked;
    NP.parentfacility := PLT.facility;
    NP.parentitem := SP.item;
    NP.facility := PLT.facility;
    if l_ignore_anvdate = 'Y' then
      select min(anvdate) into NP.anvdate
         from plate
         where parentlpid = in_lpid;
    else
      NP.anvdate := SP.anvdate;
    end if;

 -- Move the children to the deleted plate table
    for crec in C_CHILDREN(in_lpid) loop
       zlp.plate_to_deletedplate(crec.lpid,in_user,'CN',strMsg);
       if l_orderstatus = 'A' then
         delete from orderdtlrcpt
          where lpid = crec.lpid;
       end if;
    end loop;

 -- now update the parent to make it a 'PA'
    update plate
       set
           item = NP.item,
           custid = NP.custid,
           status = NP.status,
           unitofmeasure = NP.unitofmeasure,
           quantity = NP.quantity,
           type = NP.type,
           serialnumber = NP.serialnumber,
           lotnumber = NP.lotnumber,
           creationdate = NP.creationdate,
           manufacturedate = NP.manufacturedate,
           expirationdate = NP.expirationdate,
           expiryaction = NP.expiryaction,
           lastcountdate = NP.lastcountdate,
           po = NP.po,
           recmethod = NP.recmethod,
           condition = NP.condition,
           lastoperator = NP.lastoperator,
           lasttask = NP.lasttask,
           fifodate = NP.fifodate,
           destlocation = NP.destlocation,
           destfacility = NP.destfacility,
           countryof = NP.countryof,
           parentlpid = NP.parentlpid,
           useritem1 = NP.useritem1,
           useritem2 = NP.useritem2,
           useritem3 = NP.useritem3,
           disposition = NP.disposition,
           lastuser = NP.lastuser,
           lastupdate = NP.lastupdate,
           invstatus = NP.invstatus,
           qtyentered = NP.qtyentered,
           itementered = NP.itementered,
           uomentered = NP.uomentered,
           inventoryclass = NP.inventoryclass,
           loadno = NP.loadno,
           stopno = NP.stopno,
           shipno = NP.shipno,
           orderid = NP.orderid,
           shipid = NP.shipid,
           weight = NP.weight,
           adjreason = NP.adjreason,
           qtyrcvd = NP.qtyrcvd,
           controlnumber = NP.controlnumber,
           qcdisposition = NP.qcdisposition,
           fromlpid = NP.fromlpid,
           taskid = NP.taskid,
           dropseq = NP.dropseq,
           fromshippinglpid = NP.fromshippinglpid,
           workorderseq = NP.workorderseq,
           workordersubseq = NP.workordersubseq,
           qtytasked = NP.qtytasked,
           childfacility = NP.childfacility,
           childitem = NP.childitem,
           parentfacility = NP.parentfacility,
           parentitem = NP.parentitem,
           prevlocation = NP.prevlocation,
           anvdate = NP.anvdate
    where lpid = in_lpid;

    if l_orderstatus = 'A' then
      insert into orderdtlrcpt
       (orderid,shipid,orderitem,orderlot,facility,custid,item,lotnumber,
        uom,inventoryclass,invstatus,lpid,qtyrcvd,qtyrcvdgood,
        qtyrcvddmgd,lastuser,lastupdate,
        serialnumber,useritem1,useritem2,useritem3, parentlpid)
      values
       (NP.orderid,NP.shipid,NP.item,NP.lotnumber,NP.facility,NP.custid,
        NP.item,NP.lotnumber,NP.unitofmeasure,
        NP.inventoryclass,NP.invstatus,
        in_lpid,NP.quantity,
        decode(NP.invstatus,'DM',null,NP.quantity),
        decode(NP.invstatus,'DM',NP.quantity,null),
        NP.lastuser,sysdate,
        NP.serialnumber,NP.useritem1,NP.useritem2,NP.useritem3,NP.parentlpid);
    end if;
    zloc.reset_location_status(PLT.facility, PLT.location, out_errno, out_errmsg);

EXCEPTION when others then
    out_errno  := sqlcode;
    out_errmsg := sqlerrm;
END consolidate_plate;


----------------------------------------------------------------------
--
-- plate_has_asn_data
--
----------------------------------------------------------------------
FUNCTION plate_has_asn_data
(
    in_lpid   IN     varchar2
)
RETURN varchar2
IS

rtn varchar2(1);


CURSOR C_PLT(in_lpid varchar2)
IS
   select custid, item, serialnumber, useritem1, useritem2, useritem3, type
     from plate
    where lpid = in_lpid;

PLT C_PLT%rowtype;

CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
IS
   select nvl(serialrequired,'C') as serialrequired,
          nvl(user1required,'C') as user1required,
          nvl(user2required, 'C') as user2required,
          nvl(user3required, 'C') as user3required,
          nvl(serialasncapture, 'C') as serialasncapture,
          nvl(user1asncapture, 'C') as user1asncapture,
          nvl(user2asncapture, 'C') as user2asncapture,
          nvl(user3asncapture, 'C') as user3asncapture,
          productgroup
     from custitem
    where custid = in_custid
      and item = in_item;
ITM C_ITEM%rowtype;

CURSOR C_GRP(in_custid varchar2, in_productgroup varchar2)
IS
   select nvl(serialrequired,'C') as serialrequired,
          nvl(user1required,'C') as user1required,
          nvl(user2required, 'C') as user2required,
          nvl(user3required, 'C') as user3required,
          nvl(serialasncapture, 'C') as serialasncapture,
          nvl(user1asncapture, 'C') as user1asncapture,
          nvl(user2asncapture, 'C') as user2asncapture,
          nvl(user3asncapture, 'C') as user3asncapture
    from custproductgroup
   where custid = in_custid
     and productgroup = in_productgroup;
GRP C_GRP%rowtype;

CURSOR C_CUS(in_custid varchar2)
IS
   select nvl(serialrequired,'N') as serialrequired,
          nvl(user1required,'N') as user1required,
          nvl(user2required, 'N') as user2required,
          nvl(user3required, 'N') as user3required,
          nvl(serialasncapture, 'N') as serialasncapture,
          nvl(user1asncapture, 'N') as user1asncapture,
          nvl(user2asncapture, 'N') as user2asncapture,
          nvl(user3asncapture, 'N') as user3asncapture
    from customer
   where custid = in_custid;
CUS C_CUS%rowtype;

BEGIN
    rtn := 'N';

    PLT := null;
    OPEN C_PLT(in_lpid);
    FETCH C_PLT into PLT;
    CLOSE C_PLT;

    ITM := null;
    OPEN C_ITEM(PLT.custid, PLT.item);
    FETCH C_ITEM into ITM;
    CLOSE C_ITEM;

    if (ITM.serialrequired = 'C') or
       (ITM.user1required = 'C') or
       (ITM.user2required = 'C') or
       (ITM.user3required = 'C') or
       (ITM.serialasncapture = 'C') or
       (ITM.user1asncapture = 'C') or
       (ITM.user2asncapture = 'C') or
       (ITM.user3asncapture = 'C') then
      if (ITM.productgroup is not null) then
        GRP := null;
        open C_GRP(PLT.CustId, ITM.productgroup);
        fetch C_GRP into GRP;
        close C_GRP;
        if GRP.SerialRequired is not null then
          if ITM.SerialRequired = 'C' then
            ITM.SerialRequired := GRP.SerialRequired;
          end if;
          if ITM.User1Required = 'C' then
            ITM.User1Required := GRP.User1Required;
          end if;
          if ITM.User2Required = 'C' then
            ITM.User2Required := GRP.User2Required;
          end if;
          if ITM.User3Required = 'C' then
            ITM.User3Required := GRP.User3Required;
          end if;
          if ITM.SerialAsnCapture = 'C' then
            ITM.SerialAsnCapture := GRP.SerialAsnCapture;
          end if;
          if ITM.User1AsnCapture = 'C' then
            ITM.User1AsnCapture := GRP.User1AsnCapture;
          end if;
          if ITM.User2AsnCapture = 'C' then
            ITM.User2AsnCapture := GRP.User2AsnCapture;
          end if;
          if ITM.User3AsnCapture = 'C' then
            ITM.User3AsnCapture := GRP.User3AsnCapture;
          end if;
        end if;
      end if;
    if (ITM.serialrequired = 'C') or
       (ITM.user1required = 'C') or
       (ITM.user2required = 'C') or
       (ITM.user3required = 'C') or
       (ITM.serialasncapture = 'C') or
       (ITM.user1asncapture = 'C') or
       (ITM.user2asncapture = 'C') or
       (ITM.user3asncapture = 'C') then
        CUS := null;
        open C_CUS(PLT.CustId);
        fetch C_CUS into CUS;
        close C_CUS;
        if CUS.SerialRequired is not null then
          if ITM.SerialRequired = 'C' then
            ITM.SerialRequired := CUS.SerialRequired;
          end if;
          if ITM.User1Required = 'C' then
            ITM.User1Required := CUS.User1Required;
          end if;
          if ITM.User2Required = 'C' then
            ITM.User2Required := CUS.User2Required;
          end if;
          if ITM.User3Required = 'C' then
            ITM.User3Required := CUS.User3Required;
          end if;
          if ITM.SerialAsnCapture = 'C' then
            ITM.SerialAsnCapture := CUS.SerialAsnCapture;
          end if;
          if ITM.User1AsnCapture = 'C' then
            ITM.User1AsnCapture := CUS.User1AsnCapture;
          end if;
          if ITM.User2AsnCapture = 'C' then
            ITM.User2AsnCapture := CUS.User2AsnCapture;
          end if;
          if ITM.User3AsnCapture = 'C' then
            ITM.User3AsnCapture := CUS.User3AsnCapture;
          end if;
        end if;
      end if;
    end if;

    if PLT.type = 'MP' then
       if (ITM.serialrequired != 'Y' and ITM.serialasncapture = 'Y')
        or (ITM.user1required != 'Y' and ITM.user1asncapture = 'Y')
        or (ITM.user2required != 'Y' and ITM.user2asncapture = 'Y')
        or (ITM.user3required != 'Y' and ITM.user3asncapture = 'Y') then
           return 'Y';
       else
           return 'N';
       end if;
    end if;

    if PLT.serialnumber is not null
     and ITM.serialrequired != 'Y'
     and ITM.serialasncapture = 'Y' then
         return 'Y';
    end if;

    if PLT.useritem1 is not null
     and ITM.user1required != 'Y'
     and ITM.user1asncapture = 'Y' then
         return 'Y';
    end if;

    if PLT.useritem2 is not null
     and ITM.user2required != 'Y'
     and ITM.user2asncapture = 'Y' then
         return 'Y';
    end if;

    if PLT.useritem3 is not null
     and ITM.user3required != 'Y'
     and ITM.user3asncapture = 'Y' then
         return 'Y';
    end if;


    return rtn;
EXCEPTION when others then
    return 'N';
END plate_has_asn_data;

end zasncapture;
/

show errors package body zasncapture;
exit;
