create or replace package body alps.zphinv as
--
-- $Id$
--
----------------------------------------------------------------------
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
RETURN custitemview%rowtype
IS
    SELECT *
      FROM custitemview
     WHERE custid = in_custid
       AND item = in_item;

----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
CURSOR C_DPLATE(in_lpid varchar2)
RETURN deletedplate%rowtype
IS
    SELECT *
      FROM deletedplate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
CURSOR C_LOCATION(in_facility varchar2, in_location varchar2)
RETURN location%rowtype
IS
    SELECT *
      FROM location
     WHERE facility = in_facility
       AND locid = in_location;

----------------------------------------------------------------------
CURSOR C_TASK(in_taskid number)
RETURN tasks%rowtype
IS
    SELECT *
      FROM tasks
     WHERE taskid = in_taskid;

----------------------------------------------------------------------
CURSOR C_SUBTASK(in_taskid number)
RETURN subtasks%rowtype
IS
    SELECT *
      FROM subtasks
     WHERE taskid = in_taskid;

----------------------------------------------------------------------
CURSOR C_PIH(in_id number)
RETURN physicalinventoryhdr%rowtype
IS
    SELECT *
      FROM physicalinventoryhdr
     WHERE id = in_id;

----------------------------------------------------------------------
CURSOR C_PID_TASK(in_taskid number)
RETURN physicalinventorydtl%rowtype
IS
    SELECT *
      FROM physicalinventorydtl
     WHERE taskid = in_taskid;

----------------------------------------------------------------------
CURSOR C_ZONE(in_facility varchar2, in_zoneid varchar2)
RETURN zone%rowtype
IS
    SELECT *
      FROM zone
     WHERE facility = in_facility
       AND zoneid = in_zoneid;

----------------------------------------------------------------------
CURSOR C_FACILITY(in_facility varchar2)
RETURN facility%rowtype
IS
    SELECT *
      FROM facility
     WHERE facility = in_facility;

----------------------------------------------------------------------


PROCEDURE start_physical_inventory
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_paper        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
)
IS
  CUST customer%rowtype;
  id number;

cntRows integer;
BEGIN
    out_errmsg := 'OKAY';
    out_id := null;

    if rtrim(in_custid) is not null then
      begin
        select *
          into CUST
          from customer
         where custid = in_custid;
      exception when others then
        out_errmsg := 'Invalid Customer Id: ' || in_custid;
        return;
      end;
      cntRows := 0;
      select count(1)
        into cntRows
        from physicalinventoryhdr
       where facility = in_facility
         and status = PI_READY
         and ( (custid = in_custid) or
               (custid is null) );
      if cntRows != 0 then
        out_errmsg := 'There is already an active physical inventory in process for this customer';
        return;
      end if;
    end if;

    cntRows := 0;
    select count(1)
      into cntRows
      from physicalinventoryhdr
     where facility = in_facility
       and status = PI_READY
       and custid is null;
    if cntRows != 0 then
      out_errmsg := 'There is already an active physical inventory in process for this facility';
      return;
    end if;

    select physicalinventoryseq.nextval
      into id
      from dual;

    INSERT INTO physicalinventoryhdr (
           id,
           facility,
           paper,
           status,
           zone,
           fromloc,
           toloc,
           requester,
           requested,
           lastuser,
           lastupdate,
           custid
    )
    VALUES (
           id,
           in_facility,
           in_paper,
           PI_READY,
           in_zone,
           in_fromloc,
           in_toloc,
           in_user,
           sysdate,
           in_user,
           sysdate,
           rtrim(in_custid)
    );

    out_id := id;
exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END start_physical_inventory;


PROCEDURE start_phinv
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
)IS
BEGIN
    start_physical_inventory(
        in_facility,
        in_zone,
        in_fromloc,
        in_toloc,
        'N',
        in_custid,
        in_user,
        out_id,
        out_errmsg
    );
exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END start_phinv;


PROCEDURE start_phinv_paper
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
)IS
BEGIN
    start_physical_inventory(
        in_facility,
        in_zone,
        in_fromloc,
        in_toloc,
        'Y',
        in_custid,
        in_user,
        out_id,
        out_errmsg
    );
exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END start_phinv_paper;


----------------------------------------------------------------------
--
-- generate_phinv_task
--
----------------------------------------------------------------------
PROCEDURE generate_phinv_task
(
    in_id           IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_paper        IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS


  cursor curNonPickFront
    (
      in_facility   varchar2,
      in_location   varchar2,
      in_custid     varchar2
    )
  IS
   SELECT custid,
          item,
          lotnumber,
          unitofmeasure as uom,
          lpid as lpid,
          quantity as qty
     FROM plate
    WHERE facility = in_facility
      AND location = in_location
      and type = 'PA'
      and invstatus != 'SU'
      and status = 'A'
      and custid = nvl(rtrim(in_custid),custid)
      and quantity != 0;


  cursor curPickFront
    (
      in_facility   varchar2,
      in_location   varchar2,
      in_custid     varchar2
    )
  IS
   SELECT custid,
          item,
          lotnumber,
          unitofmeasure as uom,
          sum(quantity) as qty
     FROM plate
    WHERE facility = in_facility
      AND location = in_location
      and type = 'PA'
      and status = 'A'
      and invstatus != 'SU'
      and custid = nvl(rtrim(in_custid),custid)
    group by custid,item,lotnumber,unitofmeasure
    having sum(quantity) > 0;

  taskid tasks.taskid%type;
  ITEM custitem%rowtype;
  PID physicalinventorydtl%rowtype;
  PIH physicalinventoryhdr%rowtype;
  ZN zone%rowtype;

  cursor curLocation(in_facility varchar2,in_location varchar2) is
    select section,
           equipprof,
           loctype,
           pickingzone,
           pickingseq
      from location
     where facility = in_facility
       and locid = in_location;
    fromloc curLocation%rowtype;

  dtlcnt integer;
  errmsg varchar2(200);
  priority varchar2(1);

BEGIN

    out_errmsg := 'OKAY';

    PIH := null;
    OPEN C_PIH(in_id);
    FETCH C_PIH into PIH;
    CLOSE C_PIH;
    if PIH.id is null then
     out_errmsg := 'Phys inventory header does not exist: ' || in_id;
     return;
    end if;
    if PIH.status != PI_READY then
      out_errmsg := 'This physical inventory request is not active: ' ||
         PIH.status;
      return;
    end if;

     fromloc := null;
     open curLocation(in_facility,in_location);
     fetch curLocation into fromloc;
     close curLocation;
     if fromloc.loctype is null then
       out_errmsg := 'Invalid location: ' || in_location;
       return;
     end if;

     if fromloc.loctype not in ('STG','PF','STO') then
       out_errmsg := 'Invalid location type: ' || fromloc.loctype;
       return;
     end if;

     ztsk.get_next_taskid(taskid,errmsg);

     if nvl(in_paper,'N') = 'Y' then
        priority := '0';
     else
        priority := '3';
     end if;

    INSERT INTO tasks(
        taskid,
        tasktype,
        facility,
        fromsection,
        fromloc,
        fromprofile,
        custid,
        item,
        lpid,
        uom,
        qty,
        locseq,
        orderlot,
        priority,
        prevpriority,
        curruserid,
        lastuser,
        lastupdate
   )
   VALUES(
        taskid,
        'PI',
        in_facility,
        fromloc.section,
        in_location,
        fromloc.equipprof,
        PIH.custid,
        null,
        null,
        '',
        null,
        fromloc.pickingseq,
        null,
        priority,
        priority,
        decode(in_paper,'Y','PAPER',null),
        in_user,
        sysdate);

   INSERT INTO subtasks(
        taskid,
        tasktype,
        facility,
        fromsection,
        fromloc,
        fromprofile,
        custid,
        item,
        lpid,
        uom,
        qty,
        locseq,
        orderlot,
        priority,
        prevpriority,
        curruserid,
        lastuser,
        lastupdate)
   VALUES(
        taskid,
        'PI',
        in_facility,
        fromloc.section,
        in_location,
        fromloc.equipprof,
        PIH.custid,
        null,
        null,
        '',
        null,
        fromloc.pickingseq,
        null,
        priority,
        priority,
        decode(in_paper,'Y','PAPER',null),
        in_user,
        sysdate);

    dtlcnt := 0;

    ZN := null;
    OPEN C_ZONE(in_facility, fromloc.pickingzone);
    FETCH C_ZONE into ZN;
    CLOSE C_ZONE;

    if fromloc.loctype != 'PF' or nvl(ZN.pickconfirmcontainer, 'N') = 'Y' then
      for crec in curNonPickFront(in_facility, in_location, PIH.custid)
      loop
         dtlcnt := dtlcnt + 1;
         INSERT INTO physicalinventorydtl (
               id,
               facility,
               custid,
               taskid,
               lpid,
               status,
               location,
               item,
               lotnumber,
               uom,
               systemcount,
               usercount,
               countby,
               countdate,
               countcount,
               countlocation,
               countitem,
               countlot,
               lastuser,
               lastupdate
         )
         VALUES (
             in_id,
             in_facility,
             crec.custid,
             taskid,
             crec.lpid,
             PI_READY,
             in_location,
             crec.item,
             crec.lotnumber,
             crec.uom,
             crec.qty,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             in_user,
             sysdate
         );
      end loop;
    else
      for crec in curPickFront(in_facility, in_location, PIH.custid)
      loop
         dtlcnt := dtlcnt + 1;
         INSERT INTO physicalinventorydtl (
               id,
               facility,
               custid,
               taskid,
               lpid,
               status,
               location,
               item,
               lotnumber,
               uom,
               systemcount,
               usercount,
               countby,
               countdate,
               countcount,
               countlocation,
               countitem,
               countlot,
               lastuser,
               lastupdate
         )
         VALUES (
             in_id,
             in_facility,
             crec.custid,
             taskid,
             null,
             PI_READY,
             in_location,
             crec.item,
             crec.lotnumber,
             crec.uom,
             crec.qty,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             in_user,
             sysdate
         );
      end loop;
    end if;

  -- If we didn't create an detail create an entry to indicate there is
  --    nothing we expect to count
    if dtlcnt = 0 then
       INSERT INTO physicalinventorydtl (
             id,
             facility,
             custid,
             taskid,
             lpid,
             status,
             location,
             item,
             lotnumber,
             uom,
             systemcount,
             usercount,
             countby,
             countdate,
             countcount,
             countlocation,
             countitem,
             countlot,
             lastuser,
             lastupdate
       )
       VALUES (
           in_id,
           in_facility,
           PIH.custid,
           taskid,
           NULL,
           PI_READY,
           in_location,
           null,
           null,
           null,
           0,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           in_user,
           sysdate
       );
    end if;

  out_errmsg := 'OKAY Task ID ' || taskid || ' was created.';

exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END generate_phinv_task;


----------------------------------------------------------------------
--
-- count_phinv_task
--
----------------------------------------------------------------------
PROCEDURE count_phinv_task
(
    in_taskid       IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_checkdigit   IN      varchar2,
    in_custid       IN      varchar2,
    in_lpid         IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber    IN      varchar2,
    in_qty          IN      number,
    in_override     IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
)
IS
  CURSOR C_PID(in_id number, in_facility varchar2,
    in_location varchar2, in_custid varchar2,
    in_item varchar2,
    in_lotnumber varchar2,
    in_lpid varchar2)
  IS
      SELECT rowid,physicalinventorydtl.*
        FROM physicalinventorydtl
       WHERE id = in_id
         and facility = in_facility
         and location = in_location
         and nvl(custid,'x') = nvl(rtrim(in_custid),'x')
         and nvl(item,'x') = nvl(rtrim(in_item),'x')
         and nvl(lotnumber,'x') = nvl(rtrim(in_lotnumber),'x')
         and nvl(lpid,'x') = nvl(rtrim(in_lpid),'x');

  CURSOR C_PID_TASK(in_taskid number)
  IS
      SELECT rowid,physicalinventorydtl.*
        FROM physicalinventorydtl
       WHERE taskid = in_taskid;

  cursor curItemPickFront is
    select pickuom
      from itempickfronts
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and pickfront = in_location;
  ipf curItemPickFront%rowtype;

  PIH physicalinventoryhdr%rowtype;
  PID c_pid%rowtype;
  TASK tasks%rowtype;
  ST subtasks%rowtype;
  PLT plate%rowtype;
  LOC location%rowtype;
  CUST customer%rowtype;
  ITEM custitemview%rowtype;
  ZN zone%rowtype;
  FA facility%rowtype;
  strlpid plate.lpid%type;
  lotreq varchar2(1);
  errmsg varchar2(200);
  cntRows integer;

BEGIN

  out_errno := 0;
  out_errmsg := 'OKAY';

  TASK := null;
  OPEN C_TASK(in_taskid);
  FETCH C_TASK into TASK;
  CLOSE C_TASK;

  if TASK.taskid is null then
     out_errno := 1;
     out_errmsg := 'Invalid taskid. Does not exist.';
     return;
  end if;

  if TASK.tasktype != 'PI' then
     out_errno := 2;
     out_errmsg := 'Invalid taskid. Only valid for physical inventory.';
     return;
  end if;

  if TASK.facility != in_facility OR
     TASK.fromloc != in_location then
     out_errno := 3;
     out_errmsg := 'Invalid location for this task.';
     return;
  end if;

  ST := null;
  OPEN C_SUBTASK(in_taskid);
  FETCH C_SUBTASK into ST;
  CLOSE C_SUBTASK;

  if ST.taskid is null then
     out_errno := 4;
     out_errmsg := 'Invalid sub-task. Does not exist.';
     return;
  end if;

  LOC := null;
  OPEN C_LOCATION(TASK.facility, in_location);
  FETCH C_LOCATION into LOC;
  CLOSE C_LOCATION;

  if LOC.locid is null then
    out_errno := 5;
    out_errmsg := 'Invalid location. Does not exist.';
    return;
  end if;

  if rtrim(in_checkdigit) != LOC.checkdigit then
    FA := null;
    OPEN C_FACILITY(TASK.facility);
    FETCH C_FACILITY into FA;
    CLOSE C_FACILITY;
    if (nvl(FA.use_location_checkdigit, 'Y')) = 'Y' then
      out_errno := 6;
      out_errmsg := 'Invalid check digit. Please verify!';
      return;
    end if;
  end if;

-- read and verify customer
  if rtrim(in_custid) is not null then
    CUST := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;
    if CUST.custid is null then
      out_errno := 7;
      out_errmsg := 'Customer '||in_custid||' does not exist';
      return;
    end if;
  else
    if nvl(in_qty,0) <> 0 then
      out_errno := 26;
      out_errmsg := 'A Customer entry is required';
    end if;
  end if;

  if nvl(in_qty,0) < 0 then
    out_errno := 22;
    out_errmsg := 'Quantity cannot be less than zero';
    return;
  end if;

-- read and verify custitem
  ITEM := null;
  if rtrim(in_custid) is not null then
    OPEN C_ITEM(CUST.custid, in_item);
    FETCH C_ITEM into ITEM;
    CLOSE C_ITEM;
    if ITEM.custid is null then
      out_errno := 9;
      out_errmsg := 'Item does not exist';
      return;
    end if;
    if ITEM.lotrequired = 'C' then
       lotreq := CUST.lotrequired;
    else
       lotreq := ITEM.lotrequired;
    end if;

    if nvl(lotreq, 'N') in ('Y','O','S') then
       if rtrim(in_lotnumber) is null then
          out_errno := 10;
          out_errmsg := 'Lot required';
          return;
       end if;
    else
       if rtrim(in_lotnumber) is not null then
         out_errno := 21;
         out_errmsg := 'Lot Number entry not allowed for this item';
         return;
       end if;
    end if;
  end if;

  PID := null;
  OPEN C_PID_TASK(in_taskid);
  FETCH C_PID_TASK into PID;
  CLOSE C_PID_TASK;

  if PID.id is null then
    out_errno := 11;
    out_errmsg := 'Phys inventory detail does not exist';
    return;
  end if;

  PIH := null;
  OPEN C_PIH(PID.id);
  FETCH C_PIH into PIH;
  CLOSE C_PIH;
  if PIH.id is null then
   out_errno := 12;
   out_errmsg := 'Phys inventory header does not exist';
   return;
  end if;
  if PIH.status != PI_READY then
    out_errno := 13;
    out_errmsg := 'This physical inventory request is not active.';
    return;
  end if;

  if (rtrim(in_custid) is not null) and
     (PIH.custid is not null) then
    if PIH.custid != rtrim(in_custid) then
      out_errno := 62;
      out_errmsg := 'Only counts for Customer ' || PIH.Custid ||
        ' can be entered.';
    end if;
  end if;

  if (LOC.Loctype = 'PF') and
     (rtrim(in_item) is not null) then
    ipf := null;
    open curItemPickFront;
    fetch curItemPickFront into ipf;
    close curItemPickFront;
    if ipf.pickuom is null then
     out_errno := 40;
     out_errmsg := 'Location is not a pick front for this item';
     return;
    end if;
  end if;

  ZN := null;
  OPEN C_ZONE(TASK.facility, LOC.pickingzone);
  FETCH C_ZONE into ZN;
  CLOSE C_ZONE;

  if LOC.LocType = 'PF' and nvl(ZN.pickconfirmcontainer, 'N') != 'Y' and
     rtrim(in_lpid) is not null then
    out_errno := 45;
    out_errmsg := 'LiP entry not allowed for pick front';
    return;
  end if;

  PLT := null;
  if rtrim(in_lpid) is not null then
    strlpid := lpad(in_lpid, 15,'0');
    OPEN C_PLATE(strlpid);
    FETCH C_PLATE into PLT;
    CLOSE C_PLATE;
    if PLT.lpid is null then
      out_errno := 46;
      out_errmsg := 'License Plate not found';
      return;
    end if;
    if (PLT.Type != 'PA') then
      out_errno := 25;
      out_errmsg := 'Invalid license plate type';
      return;
    end if;
    if (PLT.status != 'A') then
      out_errno := 50;
      out_errmsg := 'Invalid license plate status';
      return;
    end if;
    if (PLT.facility != in_facility) then
       out_errno := 24;
       out_errmsg := 'Invalid plate. Not at your facility.';
       return;
    end if;
  else
    PLT.facility := in_facility;
    PLT.location := in_location;
    PLT.custid := in_custid;
    PLT.item := in_item;
    PLT.lotnumber := in_lotnumber;
    strlpid := null;
  end if;

  -- Now try to find the specific entry for this count
  PID := null;
  OPEN C_PID(PIH.id, PLT.facility, PLT.location, PLT.custid,
    PLT.item, PLT.lotnumber, strlpid);
  FETCH C_PID into PID;
  CLOSE C_PID;
  if PID.id is not null then
    if PID.status not in (PI_READY,PI_NOTCOUNTED) then
      out_errno := 14;
      out_errmsg := 'This Item/Lot/LiP has already been counted';
      return;
    end if;
  end if;

  if rtrim(in_custid) is null then
    if rtrim(in_item) is not null or
       rtrim(in_lotnumber) is not null or
       rtrim(in_lpid) is not null or
       nvl(in_qty,0) <> 0 then
      out_errno := 99;
      out_errmsg := 'Required entries are missing';
      return;
    end if;
  end if;

-- null cust only allowed for empty location
  if PID.id is null and
     rtrim(in_custid) is null then
    cntRows := 0;
    select count(1)
      into cntRows
      from physicalinventorydtlview
     where facility = in_facility
       and location = in_location
       and status in ('CT','NC')
       and difference not like '%Location%'
       and physicalinventorydtlview.id = PIH.id;
    if cntRows <> 0 then
      out_errno := 15;
      out_errmsg := 'Location already counted';
      return;
    end if;
    begin
      INSERT INTO physicalinventorydtl (
             id,
             facility,
             custid,
             taskid,
             status,
             location,
             usercount,
             countby,
             countdate,
             countcount,
             countlocation,
             lastuser,
             lastupdate,
             countcustid
      )
      VALUES (
           PIH.id,
           in_facility,
           PIH.custid,
           in_taskid,
           PI_COUNTED,
           in_location,
           0,
           in_user,
           sysdate,
           1,
           in_location,
           in_user,
           sysdate,
           PIH.custid
      );
    exception when dup_val_on_index then
      null;
    end;
    return;
  end if;

  if PID.id is not null then
    UPDATE physicalinventorydtl
       SET status = PI_COUNTED,
           usercount = in_qty,
           countby = in_user,
           countdate = sysdate,
           countcount = nvl(countcount,0) + 1,
           countlocation = in_location,
           countitem = in_item,
           countlot = in_lotnumber,
           countcustid = in_custid,
           prev1countby = PID.countby,
           prev1countdate = PID.countdate,
           prev1usercount = PID.usercount,
           prev1countlocation = PID.countlocation,
           prev1countitem = PID.countitem,
           prev1countcustid = PID.countcustid,
           prev1countlot = PID.countlot,
           prev2countby = PID.prev1countby,
           prev2countdate = PID.prev1countdate,
           prev2usercount = PID.prev1usercount,
           prev2countlocation = PID.prev1countlocation,
           prev2countitem = PID.prev1countitem,
           prev2countcustid = PID.prev1countcustid,
           prev2countlot = PID.prev1countlot,
           lastuser = in_user,
           lastupdate = sysdate
     WHERE rowid = PID.rowid;
    return;
  else
      UPDATE physicalinventorydtl
         SET status = PI_CANCELLED,
             usercount = null,
             countlocation = in_location,
             countby = in_user,
             countdate = sysdate,
             countcount = nvl(countcount,0) + 1,
             prev1countby = PID.countby,
             prev1countdate = PID.countdate,
             prev1usercount = PID.usercount,
             prev1countlocation = PID.countlocation,
             prev1countitem = PID.countitem,
             prev1countcustid = PID.countcustid,
             prev1countlot = PID.countlot,
             prev2countby = PID.prev1countby,
             prev2countdate = PID.prev1countdate,
             prev2usercount = PID.prev1usercount,
             prev2countlocation = PID.prev1countlocation,
             prev2countitem = PID.prev1countitem,
             prev2countcustid = PID.prev1countcustid,
             prev2countlot = PID.prev1countlot,
             lastuser = in_user,
             lastupdate = sysdate
       WHERE lpid = strLpid
         and status in (PI_READY,PI_NOTCOUNTED)
         and physicalinventorydtl.id = PIH.id;
       INSERT INTO physicalinventorydtl (
             id,
             facility,
             custid,
             taskid,
             lpid,
             status,
             location,
             item,
             lotnumber,
             uom,
             usercount,
             countby,
             countdate,
             countcount,
             countlocation,
             countitem,
             countlot,
             lastuser,
             lastupdate,
             countcustid
       )
       VALUES (
           PIH.id,
           in_facility,
           in_custid,
           in_taskid,
           strlpid,
           PI_COUNTED,
           PLT.location,
           PLT.item,
           PLT.lotnumber,
           ITEM.baseuom,
           in_qty,
           in_user,
           sysdate,
           1,
           in_location,
           in_item,
           in_lotnumber,
           in_user,
           sysdate,
           in_custid
       );
  end if;

EXCEPTION WHEN OTHERS THEN
  out_errno := SQLCODE;
  out_errmsg := SUBSTR(SQLERRM, 1, 80);
END count_phinv_task;


----------------------------------------------------------------------
--
-- complete_phinv_task
--
----------------------------------------------------------------------
PROCEDURE complete_phinv_task
(
    in_taskid       IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_checkdigit   IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
)
IS
  PIH physicalinventoryhdr%rowtype;
  PID physicalinventorydtl%rowtype;

  TASK tasks%rowtype;
  ST subtasks%rowtype;

  LOC location%rowtype;
  CUST customer%rowtype;
  ITEM custitem%rowtype;
  FA facility%rowtype;

  lpid plate.lpid%type;

  CURSOR curReadyDtl(in_taskid number)
  IS
    SELECT rowid,physicalinventorydtl.*
      FROM physicalinventorydtl
     WHERE taskid = in_taskid
       AND status = PI_READY;

  CURSOR curCountReadyDtl(in_location varchar2)
  IS
    SELECT rowid,physicalinventorydtl.*
      FROM physicalinventorydtl
     WHERE id = PIH.id
       and countlocation = in_location
       and location != countlocation
       AND status = PI_READY;

BEGIN

    out_errno := 0;
    out_errmsg := 'OKAY';

-- Get Task and ZIH
-- Read task and subtask for taskid
    TASK := null;
    OPEN C_TASK(in_taskid);
    FETCH C_TASK into TASK;
    CLOSE C_TASK;

    if TASK.taskid is null then
       out_errno := 1;
       out_errmsg := 'Invalid taskid. Does not exist.';
       return;
    end if;

    if TASK.tasktype != 'PI' then
       out_errno := 2;
       out_errmsg := 'Invalid taskid. Only valid for physical inventory.';
       return;
    end if;

    if TASK.facility != in_facility OR
       TASK.fromloc != in_location then
       out_errno := 3;
       out_errmsg := 'Invalid location for this task.';
       return;
    end if;

-- Read sub-task
    ST := null;
    OPEN C_SUBTASK(in_taskid);
    FETCH C_SUBTASK into ST;
    CLOSE C_SUBTASK;

    if ST.taskid is null then
       out_errno := 4;
       out_errmsg := 'Invalid sub-task. Does not exist.';
       return;
    end if;

-- read and verify location
   LOC := null;
   OPEN C_LOCATION(TASK.facility, in_location);
   FETCH C_LOCATION into LOC;
   CLOSE C_LOCATION;

   if LOC.locid is null then
      out_errno := 5;
      out_errmsg := 'Invalid location. Does not exist.';
      return;
   end if;

   if in_checkdigit != LOC.checkdigit then
      FA := null;
      OPEN C_FACILITY(TASK.facility);
      FETCH C_FACILITY into FA;
      CLOSE C_FACILITY;
      if (nvl(FA.use_location_checkdigit, 'Y')) = 'Y' then
         out_errno := 6;
         out_errmsg := 'Invalid check digit. Please verify!';
         return;
      end if;
   end if;


-- locate a PI.dtl for this entry (If one exists)
   PID := null;
   OPEN C_PID_TASK(in_taskid);
   FETCH C_PID_TASK into PID;
   CLOSE C_PID_TASK;

   if PID.id is null then
        out_errno := 7;
        out_errmsg := 'Phys inventory detail does not exist';
        return;
   end if;

-- Locate PIH just for fun
   PIH := null;
   OPEN C_PIH(PID.id);
   FETCH C_PIH into PIH;
   CLOSE C_PIH;

   if PIH.id is null then
        out_errno := 8;
        out_errmsg := 'Phys inventory header does not exist';
        return;
   end if;

   if PIH.status != PI_READY then
        out_errno := 9;
        out_errmsg := 'This physical inventory request has been closed.';
        return;
   end if;

-- Process any unprocessed system counts
   for rdy in curReadyDtl(in_taskid) loop
     UPDATE physicalinventorydtl
        SET status = PI_NOTCOUNTED,
            usercount = null,
            countby = in_user,
            countdate = sysdate,
            countcount = nvl(countcount,0) + 1,
            countlocation = in_location,
            prev1countby = rdy.countby,
            prev1countdate = rdy.countdate,
            prev1usercount = rdy.usercount,
            prev1countlocation = rdy.countlocation,
            prev1countitem = rdy.countitem,
            prev1countcustid = rdy.countcustid,
            prev1countlot = rdy.countlot,
            prev2countby = rdy.prev1countby,
            prev2countdate = rdy.prev1countdate,
            prev2usercount = rdy.prev1usercount,
            prev2countlocation = rdy.prev1countlocation,
            prev2countitem = rdy.prev1countitem,
            prev2countcustid = rdy.prev1countcustid,
            prev2countlot = rdy.prev1countlot,
            lastuser = in_user,
            lastupdate = sysdate
      WHERE rowid = rdy.rowid;
   end loop;

   for rdy in curCountReadyDtl(in_location) loop
     UPDATE physicalinventorydtl
        SET status = PI_NOTCOUNTED,
            usercount = null,
            countby = in_user,
            countdate = sysdate,
            countcount = nvl(countcount,0) + 1,
            countlocation = in_location,
            prev1countby = rdy.countby,
            prev1countdate = rdy.countdate,
            prev1usercount = rdy.usercount,
            prev1countlocation = rdy.countlocation,
            prev1countitem = rdy.countitem,
            prev1countcustid = rdy.countcustid,
            prev1countlot = rdy.countlot,
            prev2countby = rdy.prev1countby,
            prev2countdate = rdy.prev1countdate,
            prev2usercount = rdy.prev1usercount,
            prev2countlocation = rdy.prev1countlocation,
            prev2countitem = rdy.prev1countitem,
            prev2countcustid = rdy.prev1countcustid,
            prev2countlot = rdy.prev1countlot,
            lastuser = in_user,
            lastupdate = sysdate
      WHERE rowid = rdy.rowid;
   end loop;

   DELETE FROM tasks
    WHERE taskid = in_taskid;
   DELETE FROM subtasks
    WHERE taskid = in_taskid;

EXCEPTION WHEN OTHERS THEN
  out_errno := SQLCODE;
  out_errmsg := SUBSTR(SQLERRM, 1, 80);
END complete_phinv_task;

PROCEDURE add_lpid
(
    IN_PID  IN  physicalinventorydtl%rowtype,
    IN_USER IN  varchar2
)
IS
BEGIN
-- Add a brand new plate
   INSERT INTO plate
   (
     lpid,
     item,
     custid,
     facility,
     location,
     status,
     unitofmeasure,
     quantity,
     type,
     lotnumber,
     creationdate,
     lastoperator,
     lastuser,
     lastupdate,
     invstatus,
     qtyentered,
     itementered,
     uomentered,
     inventoryclass,
     weight,
     lastcountdate,
     lasttask,
     orderid,
     shipid
   )
   VALUES
   (
     in_pid.lpid,
     in_pid.countitem,
     in_pid.countcustid,
     in_pid.facility,
     in_pid.countlocation,
     'A',
     in_pid.uom,
     0,
     'PA',
     in_pid.countlot,
     sysdate,
     in_user,
     in_user,
     sysdate,
     'AV',
     in_pid.usercount,
     in_pid.countitem,
     in_pid.uom,
     'RG',
     in_pid.usercount * zci.item_weight(in_pid.custid,in_pid.item, in_pid.uom),
     sysdate,
     'PI',
     0,
     0
   );

END add_lpid;


----------------------------------------------------------------------
--
-- complete_phinv_request
--
----------------------------------------------------------------------
PROCEDURE complete_phinv_request
(
    in_id           IN      number,
    in_type         IN      varchar2,
    in_user         IN      varchar2,
    in_validate_only IN     varchar2,
    out_errmsg      OUT     varchar2
)
IS
  PIH physicalinventoryhdr%rowtype;
  PID physicalinventorydtl%rowtype;
  PLT plate%rowtype;
  DPLT deletedplate%rowtype;
  LOC location%rowtype;
  qtyRemain plate.quantity%type;
  qtyOldLip plate.quantity%type;
  qtyNewLip plate.quantity%type;
  adjMsg varchar2(255);
  logMsg varchar2(255);
  errno integer;
  v_pf_qty plate.quantity%type;
  v_pf_lpcount integer;

  CURSOR C_PIDS(in_id number)
  RETURN physicalinventorydtl%rowtype
  IS
    SELECT *
      FROM physicalinventorydtl
     WHERE id = in_id
       and status in (PI_COUNTED, PI_NOTCOUNTED)
     ORDER BY lpid, status desc;

  CURSOR C_PIDS_TASKID(in_id number)
  IS
    SELECT DISTINCT taskid
      FROM physicalinventorydtl
     WHERE id = in_id;

  cursor curPickFrontLips (in_id integer, in_facility varchar2, in_location varchar2,
    in_custid varchar2, in_item varchar2, in_lotnumber varchar2) is
    select *
      from plate a
     where facility = in_facility
       and location = in_location
       and custid = in_custid
       and item = in_item
       and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
       and type = 'PA'
       and status = 'A'
       and invstatus != 'SU'
       and not exists (select *
                       from physicalinventorydtl
                       where id = in_id and lpid = a.lpid and status = PI_COUNTED and countlocation <> in_location)
     order by creationdate;
  cnt integer;

  cursor curMovedFromPickFront (in_id number,
     in_facility varchar2, in_location varchar2,
     in_custid varchar2, in_item varchar2, in_lotnumber varchar2) is
    select sum(usercount) as usercount
      from physicalinventorydtl
     where id = in_id
       and facility = in_facility
       and location = in_location
       and custid = in_custid
       and item = in_item
       and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
       and nvl(systemcount,0) = 0
       and location <> countlocation
       and lpid is not null
       and status = PI_COUNTED;
mpf curMovedFromPickFront%rowtype;

strRowId1 varchar2(20);
strRowId2 varchar2(20);

   type iaa_rectype is record (
      lpid     plate.lpid%type,
      custid   customer.custid%type,
      rid1     varchar2(20),
      rid2     varchar2(20));
   type iaa_tbltype is table of iaa_rectype index by binary_integer;
   iaa_tbl iaa_tbltype;
   i binary_integer;
   iaa_fac physicalinventoryhdr.facility%type;
  ZN zone%rowtype;

procedure save_iaa_rowids
   (in_lpid    in varchar2,
    in_custid  in varchar2)
is
begin
   if (strRowId1 is not null) or (strRowId2 is not null) then
      i := iaa_tbl.count+1;
      iaa_tbl(i).lpid := in_lpid;
      iaa_tbl(i).custid := in_custid;
      iaa_tbl(i).rid1 := strRowId1;
      iaa_tbl(i).rid2 := strRowId2;
   end if;
exception
   when others then
      null;
end;

function new_weight
   (in_custid     in varchar2,
    in_item       in varchar2,
    in_old_qty    in number,
    in_new_qty    in number,
    in_old_weight in number)
return number
is
   cursor c_itv(p_custid varchar2, p_item varchar2) is
      select baseuom, nvl(use_catch_weights, 'N') as use_catch_weights
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itv%rowtype;
   l_found boolean;
   l_weight number := in_old_weight;
begin
   open c_itv(in_custid, in_item);
   fetch c_itv into itv;
   l_found := c_itv%found;
   close c_itv;

   if (l_found) and (itv.use_catch_weights = 'Y') then
      if in_new_qty = 0 then
         l_weight := 0;
      elsif in_old_qty = 0 then
		   l_weight := zci.item_weight(in_custid, in_item, itv.baseuom);
      else
			l_weight := in_new_qty * (in_old_weight / in_old_qty);
      end if;
   end if;

   return l_weight;

exception
   when OTHERS then
      return in_old_weight;
end new_weight;

BEGIN

   out_errmsg := 'OKAY';

-- Verify this is a request that has not been closed yet
   PIH := null;
   OPEN C_PIH(in_id);
   FETCH C_PIH into PIH;
   CLOSE C_PIH;

   if PIH.id is null then
     out_errmsg := 'Phys inventory header does not exist';
     return;
   end if;

   if PIH.status != PI_READY then
     out_errmsg := 'This physical inventory request is not active.';
     return;
   end if;

   if in_validate_only = 'Y' and
      in_type = 'CANCEL' then
     return;
   end if;
   
-- For cancel just change the status and delete remaining tasks.
-- Leave the info out there for examining

   if in_type = 'CANCEL' then
      UPDATE physicalinventoryhdr
         SET status = PI_CANCELLED,
             lastuser = in_user,
             lastupdate = sysdate
       WHERE id = in_id;
      for crec in C_PIDS_TASKID(in_id) loop
         DELETE FROM tasks
          WHERE taskid = crec.taskid;
         DELETE FROM subtasks
          WHERE taskid = crec.taskid;
      end loop;
      return;
   end if;

-- If we are trying to complete the task make sure everything has been
-- counted.

   cnt := 0;
   SELECT count(1)
     INTO cnt
     FROM physicalinventorydtl
    WHERE id = PIH.id
     AND status = PI_READY;

   if cnt > 0 then
      out_errmsg := 'Not all locations have been counted';
      return;
   end if;
   
   if in_validate_only = 'Y' then
     return;
   end if;
   
--
-- Main processing loop. Process all detail information entries
--
   iaa_tbl.delete;
   for crec in C_PIDS(in_id) loop
     PID := crec;
     
     if PID.status = PI_NOTCOUNTED then
        PID.countcustid := PID.custid;
        PID.countitem := PID.item;
        PID.countlot := PID.lotnumber;
        PID.countlocation := PID.location;
        PID.usercount := 0;
     end if;
     
     update location
        set lastcounted = sysdate,
            lastuser = in_user,
            lastupdate = sysdate
      where facility = PID.facility
        and locid = PID.countlocation;
        
     LOC := null;
     OPEN C_LOCATION(PID.facility, PID.countlocation);
     FETCH C_LOCATION into LOC;
     CLOSE C_LOCATION;
     
     ZN := null;
     OPEN C_ZONE(PID.facility, LOC.pickingzone);
     FETCH C_ZONE into ZN;
     CLOSE C_ZONE;

--   no plate updates for empty location confirmations
     if (nvl(PID.systemcount,0) = 0) and (nvl(PID.usercount,0) = 0) then
       goto lp_continue;
     end if;

     -- adjust the system count if a plate the system thought was in the pick front was found in another location
     if (PID.lpid is null) and (LOC.loctype = 'PF') and (nvl(ZN.pickconfirmcontainer, 'N') != 'Y') then
       mpf := null;
       open curMovedFromPickFront(PID.id, PID.facility,PID.location,PID.custid,PID.item,PID.lotnumber);
       fetch curMovedFromPickFront into mpf;
       close curMovedFromPickFront;
       
       if nvl(mpf.usercount,0) != 0 then
         zms.log_msg('PhyInv', PID.facility, PID.custid,
             'Pick Front ' || PID.location || ' Count Adjusted for item/lot ' ||
             PID.countitem || '/' ||
             nvl(PID.countlot,'(none)') || ' orig quantity ' || PID.systemcount ||
             ' moved quantity ' || mpf.usercount,
             'I', in_user, logMsg);
             
         PID.systemcount := PID.systemcount - nvl(mpf.usercount,0);
         if PID.systemcount < 0 then
           PID.systemcount := 0;
       end if;
     end if;
     end if;

---  everything matches, set last count date and continue
     if nvl(PID.systemcount,0) = nvl(PID.usercount,0) and
        nvl(PID.location,'x') = nvl(PID.countlocation,'x') and
        nvl(PID.item, 'x') = nvl(PID.countitem,'x') and
        nvl(PID.lotnumber,'x') = nvl(PID.countlot,'x') and
        nvl(PID.custid,'x') = nvl(PID.countcustid,'x') then
       update plate
          set lastcountdate = sysdate,
              lasttask = 'PI',
              lastuser = in_user,
              lastupdate = sysdate
        where lpid = PID.lpid;
       goto lp_continue;
     end if;
     
     if loc.loctype != 'PF' or nvl(ZN.pickconfirmcontainer, 'N') = 'Y' then
       -- non-pickfront scenario (by lpid)
       PLT := null;
       if PID.lpid is not null then
         OPEN C_PLATE(PID.lpid);
         FETCH C_PLATE into PLT;
         CLOSE C_PLATE;
           end if;
       
       if PLT.lpid is null then
           zrf.get_next_lpid(PID.lpid, adjMsg);
           if adjMsg is not null then
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               'Unable to generate LiP at ' || PID.countlocation || ' for item/lot ' ||
               PID.countitem || '/' ||
               nvl(PID.countlot,'(none)') || ' quantity ' || qtyNewLip,
               'E', in_user, logMsg);
             goto lp_continue;
           end if;
           add_lpid(PID,in_user);
           open c_plate(PID.lpid);
           fetch c_plate into PLT;
           close c_plate;
       end if;
       
           zia.inventory_adjustment(
                PID.lpid,
                PID.countcustid,
                PID.countitem,
                PLT.inventoryclass,
                PLT.invstatus,
                PID.countlot,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PID.countlocation,
                PLT.expirationdate,
          nvl(PID.usercount,0),
                PLT.custid,
                PLT.item,
                PLT.inventoryclass,
                PLT.invstatus,
                PLT.lotnumber,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PLT.location,
                PLT.expirationdate,
                nvl(PLT.quantity,0),
                PLT.facility,
                'PI',
                in_user,
                'PI',
          new_weight(PID.countcustid, PID.countitem, nvl(PLT.quantity,0), nvl(PID.usercount,0), PLT.weight),
                PLT.weight,
                PLT.manufacturedate,
                PLT.manufacturedate,
                PLT.anvdate,
                PLT.anvdate,
                strRowid1,
                strRowid2,
                errno,
                adjMsg
             );
       
           if substr(adjMsg,1,4) <> 'OKAY' then
             zms.log_msg('PhyInv', PID.facility, PID.custid,
           'Unable to adjust ' || PID.Lpid || ' to item/lot ' ||
               PID.countitem || '/' ||
               nvl(PID.countlot,'(none)') || ' quantity ' || PID.usercount,
               'E', in_user, logMsg);
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               adjMsg,'E', in_user, logMsg);
           else
         save_iaa_rowids(PID.lpid, PID.custid);
           end if;
       
     elsif (PID.lpid is null) then
       -- pickfront scenario (not by lpid)
       select nvl(sum(quantity),0), nvl(count(1),0)
       into v_pf_qty, v_pf_lpcount
       from plate a
       where facility = PID.facility
         and location = PID.location
         and custid = PID.custid
         and item = PID.item
         and nvl(lotnumber,'x') = nvl(PID.lotnumber,'x')
         and type = 'PA'
         and status = 'A'
         and invstatus != 'SU'
         and not exists (select *
                         from physicalinventorydtl
                         where id = PID.id and lpid = a.lpid and status = PI_COUNTED and countlocation <> PID.location);
                         
       if (v_pf_qty = nvl(PID.usercount, 0)) then
         -- nothing to do, the counts match up
         goto lp_continue;
       elsif (v_pf_qty > nvl(PID.usercount,0)) then
         -- the system thinks it has more than it has, need to adjust plates downwards
         qtyRemain := v_pf_qty - nvl(PID.usercount,0);
         for lp in curPickFrontLips(PID.id,PID.facility,PID.location,PID.custid,PID.item,PID.lotnumber)
         loop
           PLT := lp;
           qtyOldLip := nvl(PLT.quantity,0) - qtyRemain;
           if (qtyOldLip < 0) then
             qtyOldLip := 0;
           end if;
           qtyRemain := qtyRemain - nvl(PLT.quantity, 0);
           
           zia.inventory_adjustment(
                PLT.lpid,
                PID.countcustid,
                PID.countitem,
                PLT.inventoryclass,
                PLT.invstatus,
                PID.countlot,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PID.countlocation,
                PLT.expirationdate,
              qtyOldLip,
                PLT.custid,
                PLT.item,
                PLT.inventoryclass,
                PLT.invstatus,
                PLT.lotnumber,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PLT.location,
                PLT.expirationdate,
                nvl(PLT.quantity,0),
                PLT.facility,
                'PI',
                in_user,
                'PI',
              new_weight(PID.countcustid, PID.countitem, nvl(PLT.quantity,0), qtyOldLip, PLT.weight),
                PLT.weight,
                PLT.manufacturedate,
                PLT.manufacturedate,
                PLT.anvdate,
                PLT.anvdate,
                strRowid1,
                strRowid2,
                errno,
                adjMsg
             );
           
           if substr(adjMsg,1,4) <> 'OKAY' then
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               'Unable to adjust ' || PLT.Lpid || ' to item/lot ' ||
               PID.countitem || '/' ||
               nvl(PID.countlot,'(none)') || ' quantity ' || PID.usercount,
               'E', in_user, logMsg);
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               adjMsg,'E', in_user, logMsg);
           else
             save_iaa_rowids(PLT.lpid, PID.custid);
           end if;
           
           exit when qtyRemain <= 0;
         end loop;
       else
         -- the usercount came out higher, so need to adjust one of the plates in the pickfront to account for the volume
         
         if (v_pf_lpcount > 0) then
           -- grab the first plate in order of creation date
           OPEN curPickFrontLips(PID.id,PID.facility,PID.location,PID.custid,PID.item,PID.lotnumber);
           FETCH curPickFrontLips into PLT;
           CLOSE curPickFrontLips;
         else
           -- there are no plates at the pickfront location, so need to create one
           zrf.get_next_lpid(PID.lpid, adjMsg);
           if adjMsg is not null then
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               'Unable to generate LiP at ' || PID.countlocation || ' for item/lot ' ||
               PID.countitem || '/' ||
               nvl(PID.countlot,'(none)') || ' quantity ' || qtyNewLip,
               'E', in_user, logMsg);
             goto lp_continue;
           end if;
           add_lpid(PID,in_user);
           open c_plate(PID.lpid);
           fetch c_plate into PLT;
           close c_plate;
           end if;
         
           zia.inventory_adjustment(
                PLT.lpid,
                PID.countcustid,
                PID.countitem,
                PLT.inventoryclass,
                PLT.invstatus,
                PID.countlot,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PID.countlocation,
                PLT.expirationdate,
              nvl(PLT.quantity,0) + (PID.usercount - v_pf_qty),
                PLT.custid,
                PLT.item,
                PLT.inventoryclass,
                PLT.invstatus,
                PLT.lotnumber,
                PLT.serialnumber,
                PLT.useritem1,
                PLT.useritem2,
                PLT.useritem3,
                PLT.location,
                PLT.expirationdate,
                nvl(PLT.quantity,0),
                PLT.facility,
                'PI',
                in_user,
                'PI',
              new_weight(PID.countcustid, PID.countitem, nvl(PLT.quantity,0), nvl(PLT.quantity,0) + (PID.usercount - v_pf_qty), PLT.weight),
                PLT.weight,
                PLT.manufacturedate,
                PLT.manufacturedate,
                PLT.anvdate,
                PLT.anvdate,
                strRowid1,
                strRowid2,
                errno,
                adjMsg
             );
           
           if substr(adjMsg,1,4) <> 'OKAY' then
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               'Unable to adjust ' || PLT.Lpid || ' to item/lot ' ||
               PID.countitem || '/' ||
               nvl(PID.countlot,'(none)') || ' quantity ' || PID.usercount,
               'E', in_user, logMsg);
             zms.log_msg('PhyInv', PID.facility, PID.custid,
               adjMsg,'E', in_user, logMsg);
           else
             save_iaa_rowids(PLT.lpid, PID.custid);
           end if;
           end if;
       
     else
      -- this shouldn't happen, as this means that a detail was found where lpid was populated for a pick front
      -- only scenario should be if this was counted in another location, and then it would be handled in the non-pickfront scenario
           zms.log_msg('PhyInv', PID.facility, PID.custid,
             'Unexpected PhyInv detail found with lpid in pickfront for ' || PID.location || ' item/lot ' || PID.item || '/' ||
             nvl(PID.lotnumber,'(none)') || ' quantity ' || qtyRemain,
             'E', in_user, logMsg);
         end if;

<<lp_continue>>
     null;
   end loop;

   UPDATE physicalinventoryhdr
      SET status = PI_PROCESSED,
          lastuser = in_user,
          lastupdate = sysdate
    WHERE id = in_id
    RETURNING facility into iaa_fac;

   commit;

   for i in 1..iaa_tbl.count loop
      if iaa_tbl(i).rid1 is not null then
         zim6.check_for_adj_interface(iaa_tbl(i).rid1, errno, adjmsg);
         if errno < 0 then
            zms.log_msg('PhyInv', iaa_fac, iaa_tbl(i).custid,
                  'LP ' || iaa_tbl(i).lpid || ' failed adjustment interface: ' || adjmsg,
                  'E', in_user, logMsg);
         end if;
      end if;
      if iaa_tbl(i).rid2 is not null then
         zim6.check_for_adj_interface(iaa_tbl(i).rid2, errno, adjmsg);
         if errno < 0 then
            zms.log_msg('PhyInv', iaa_fac, iaa_tbl(i).custid,
                  'LP ' || iaa_tbl(i).lpid || ' failed adjustment interface: ' || adjmsg,
                  'E', in_user, logMsg);
         end if;
      end if;
   end loop;

exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END complete_phinv_request;

PROCEDURE recount_request
(
    in_id       IN      number,
    in_location     IN      varchar2,
    in_custid       IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber        IN      varchar2,
    in_lpid         IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
) is

cursor curLocation(in_facility varchar2,in_location varchar2) is
  select section,
         equipprof,
         loctype
    from location
   where facility = in_facility
     and locid = in_location;
fromloc curLocation%rowtype;

cursor curPID is
  select rowid,physicalinventorydtlview.*
    from physicalinventorydtlview
   where id = in_id
     and location = in_location
     and countlocation = in_location
     and status in ('CT','NC');
PID curPID%rowtype;

cursor curCountPID is
  select rowid,physicalinventorydtlview.*
    from physicalinventorydtlview
   where id = in_id
     and countlocation = in_location
     and location != countlocation
     and status in ('CT','NC');

PIH physicalinventoryhdr%rowtype;
newtaskid tasks.taskid%type;
priority varchar2(1);
errmsg varchar2(255);
cntRows integer;
cntDtl integer;
prevtask tasks.taskid%type;
v_has_rows integer;

begin

out_errno := -1;
out_errmsg := '';

PIH := null;
OPEN C_PIH(in_id);
FETCH C_PIH into PIH;
CLOSE C_PIH;
if PIH.id is null then
 out_errno := -1;
 out_errmsg := 'Phys inventory header does not exist';
 return;
end if;
if PIH.status != PI_READY then
  out_errno := -2;
  out_errmsg := 'This physical inventory request has been closed.';
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from physicalinventorydtl
 where id = in_id
   and location = in_location
   and location = nvl(countlocation, location)
   and status in ('RD');
if cntRows <> 0 then
  out_errno := -15;
  out_errmsg := 'There are uncounted items for this location: '
   || in_location;
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from physicalinventorydtl
 where id = in_id
   and countlocation = in_location
   and status in ('RD');
if cntRows <> 0 then
  out_errno := -15;
  out_errmsg := 'There are uncounted items for this location: '
   || in_location;
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from tasks
 where facility = PIH.facility
   and fromloc = in_location
   and tasktype = 'PI';
if cntRows <> 0 then
  out_errno := -16;
  out_errmsg := 'There is already a task associated with this location: '
   || in_location;
  return;
end if;

ztsk.get_next_taskid(newtaskid,errmsg);

open curLocation(PIH.facility,in_location);
fetch curLocation into fromloc;
close curLocation;

if nvl(PIH.paper,'N') = 'Y' then
  priority := '0';
else
  priority := '3';
end if;

INSERT INTO tasks(
      taskid,
      tasktype,
      facility,
      fromsection,
      fromloc,
      fromprofile,
      custid,
      item,
      lpid,
      uom,
      qty,
      locseq,
      orderlot,
      priority,
      prevpriority,
      curruserid,
      lastuser,
      lastupdate
)
VALUES(
      newtaskid,
      'PI',
      PIH.facility,
      fromloc.section,
      in_location,
      fromloc.equipprof,
      PIH.custid,
      null,
      null,
      '',
      null,
      1,
      null,
      priority,
      priority,
      decode(PIH.paper,'Y','PAPER',null),
      in_user,
      sysdate);

INSERT INTO subtasks(
      taskid,
      tasktype,
      facility,
      fromsection,
      fromloc,
      fromprofile,
      custid,
      item,
      lpid,
      uom,
      qty,
      locseq,
      orderlot,
      priority,
      prevpriority,
      curruserid,
      lastuser,
      lastupdate)
VALUES(
      newtaskid,
      'PI',
      PIH.facility,
      fromloc.section,
      in_location,
      fromloc.equipprof,
      PIH.custid,
      null,
      null,
      '',
      null,
      1,
      null,
      priority,
      priority,
      decode(PIH.paper,'Y','PAPER',null),
      in_user,
      sysdate);

cntDtl := 0;
for dtl in curPid
loop
  PID := dtl;
  cntDtl := cntDtl + 1;
  update physicalinventorydtl
     set status = PI_READY,
         taskid = newtaskid,
         lastuser = in_user,
         lastupdate = sysdate
   where rowid = PID.rowid;
end loop;

for dtl in curCountPid
loop
  PID := dtl;
  cntDtl := cntDtl + 1;
  
  update physicalinventorydtl
     set status = PI_READY,
         taskid = newtaskid,
         lastuser = in_user,
         lastupdate = sysdate
   where rowid = PID.rowid;
   
  select nvl(max(taskid),0)
  into prevtask
  from subtasks
  where facility = PIH.facility and fromloc = PID.location and nvl(custid,'x') = nvl(PID.custid,'x');
  
  if (prevtask > 0) then
    select count(1)
    into v_has_rows
    from physicalinventorydtl
    where id = PIH.id and taskid = prevtask;
    
    if (v_has_rows = 0)
    then
      INSERT INTO physicalinventorydtl (
       id,
       facility,
       custid,
       taskid,
       lpid,
       status,
       location,
       item,
       lotnumber,
       uom,
       systemcount,
       usercount,
       countby,
       countdate,
       countcount,
       countlocation,
       countitem,
       countlot,
       lastuser,
       lastupdate
      )
      VALUES (
       PIH.id,
       PIH.facility,
       PIH.custid,
       prevtask,
       NULL,
       PI_READY,
       PID.location,
       null,
       null,
       null,
       0,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       in_user,
       sysdate
      );
    end if;
  end if;
end loop;

if cntDtl <> 0 then
  out_errmsg := 'OKAY';
  if nvl(PIH.paper,'N') = 'Y' then
    out_errno := newtaskid;
  else
    out_errno := 0;
  end if;
else
  out_errmsg := 'No eligible physical inventory found';
  out_errno := -22;
end if;

exception when others then
  out_errno := sqlcode;
  out_errmsg := substr(sqlerrm,1,80);
end recount_request;

procedure count_ai_phinv_task
(
    in_taskid       in      number,
    in_facility     in      varchar2,
    in_location     in      varchar2,
    in_checkdigit   in      varchar2,
    in_custid       in      varchar2,
    in_item         in      varchar2,
    in_lotnumber    in      varchar2,
    in_qty          in      number,
    in_override     in      varchar2,
    in_user         in      varchar2,
    out_errno       out     number,
    out_errmsg      out     varchar2)
is
   cursor c_cus(p_custid varchar2) is
      select paperbased
         from customer
         where custid = p_custid;
   cus c_cus%rowtype := null;
   cursor c_loc(p_facility varchar2, p_location varchar2) is
      select loctype
         from location
         where facility = p_facility
           and locid = p_location;
   loc c_loc%rowtype := null;
   cursor c_lp(p_facility varchar2, p_location varchar2, p_custid varchar2, p_item varchar2,
               p_lotnumber varchar2) is
      select lpid, quantity
         from plate
         where facility = p_facility
           and location = p_location
           and custid = p_custid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)')
           and type = 'PA'
         order by creationdate desc;
   lp c_lp%rowtype;
   prevlp c_lp%rowtype := null;
   l_remaining number := in_qty;
   l_qty number;
begin
   out_errno := 0;
   out_errmsg := 'OKAY';

   open c_cus(in_custid);
   fetch c_cus into cus;
   close c_cus;
   if nvl(cus.paperbased, 'N') = 'N' then
      out_errno := 98;
      out_errmsg := 'Not an aggregate inventory customer';
      return;
   end if;

-- no lpid for pickfront
   open c_loc(in_facility, in_location);
   fetch c_loc into loc;
   close c_loc;
   if loc.loctype is null then
      loc.loctype := 'STO';
   end if;

   open c_lp(in_facility, in_location, in_custid, in_item, in_lotnumber);
   loop
      fetch c_lp into lp;
      if c_lp%rowcount > 1 then
         if loc.loctype = 'PF' then
            prevlp.lpid := null;
         end if;
         if c_lp%found then
            l_qty := least(l_remaining, prevlp.quantity);
         else
            l_qty := l_remaining;
         end if;
         count_phinv_task(in_taskid, in_facility, in_location, in_checkdigit,
               in_custid, prevlp.lpid, in_item, in_lotnumber,
               l_qty, in_override,
               in_user, out_errno, out_errmsg);
         if c_lp%found then
            l_remaining := l_remaining - least(l_remaining, prevlp.quantity);
         else
            l_remaining := 0;
         end if;
      end if;
      exit when c_lp%notfound or (out_errno != 0);
      prevlp := lp;
   end loop;
   close c_lp;

   if (l_remaining > 0) and (out_errno = 0) then
--    this should only be necessary if the user reported a quantity
--    and we couldn't find any plates
      count_phinv_task(in_taskid, in_facility, in_location, in_checkdigit,
            in_custid, null, in_item, in_lotnumber, l_remaining, in_override,
            in_user, out_errno, out_errmsg);
   end if;

exception
   when OTHERS then
      out_errno := sqlcode;
      out_errmsg := substr(sqlerrm, 1, 80);
end count_ai_phinv_task;

----------------------------------------------------------------------
end zphinv;
/
show errors package body zphinv;

exit;
