create or replace package body alps.zabccycle as
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
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
--
-- calc_velocity
--
----------------------------------------------------------------------
PROCEDURE calc_velocity
(
    in_custid       IN      varchar2,
    in_start        IN      date,
    in_end          IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CUST customer%rowtype;

  CURSOR C_ITEMTOT(in_custid varchar2)
  IS
    SELECT count(*)
      FROM custitem
     WHERE custid = in_custid
       and status = 'ACTV';

  CURSOR C_ITEMS(in_custid varchar2, in_start date, in_end date)
  IS
    SELECT I.item, nvl(sum(P.qtypick),0) qty
      FROM itempickview P, custitem I
     WHERE I.custid = in_custid
       AND I.custid = P.custid(+)
       AND I.item = P.item(+)
       AND I.status = 'ACTV'
       AND P.pickdate(+) >= in_start
       AND P.pickdate(+) <= in_end
      GROUP BY I.item
       ORDER by 2 desc, I.item;

  itemtot integer;
  tot_a integer;
  tot_b integer;
  tot_c integer;

  vel varchar2(1);

BEGIN
    out_errmsg := 'OKAY';

-- Get the customer information
    CUST := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
       out_errmsg := 'Invalid customer ID';
       return;
    end if;

-- Determine number of items for this customer
    itemtot := 0;
    OPEN C_ITEMTOT(in_custid);
    FETCH C_ITEMTOT into itemtot;
    CLOSE C_ITEMTOT;

    -- zut.prt('Count of items = '||itemtot);

-- Determin count of items in each category
   tot_a := round(itemtot*CUST.cycleapercent/100);
   tot_b := round(itemtot*CUST.cyclebpercent/100);
   tot_c := itemtot - tot_a - tot_b;

   -- zut.prt(' Breakdown is A:'||tot_a||' B:'||tot_b||' C:'||tot_c);

   for crec in C_ITEMS(in_custid, in_start, in_end) loop
       if tot_a > 0 then
          vel := 'A';
          tot_a := tot_a - 1;
       elsif tot_b > 0 then
          vel := 'B';
          tot_b := tot_b - 1;
       else
          vel := 'C';
       end if;

       -- zut.prt('   Item:'||crec.item||' Qty:'||crec.qty|| ' VEL:'|| vel);
       update custitem
          set velocity = vel,
              lastupdate = sysdate,
              lastuser = in_user
        where custid = in_custid
          and item = crec.item;

   end loop;


    return;

exception when others then
  out_errmsg := sqlerrm;

END calc_velocity;


----------------------------------------------------------------------
--
-- calc_abc_tasks
--
----------------------------------------------------------------------
PROCEDURE calc_abc_tasks
(
    in_custid       IN      varchar2,
    out_A_items     OUT     number,
    out_B_items     OUT     number,
    out_C_items     OUT     number,
    out_A_tasks     OUT     number,
    out_B_tasks     OUT     number,
    out_C_tasks     OUT     number,
    out_errmsg      OUT     varchar2
)
IS
  CUST customer%rowtype;

  CURSOR C_CNT(in_custid varchar2)
  IS
    SELECT velocity, count(*) cnt
      FROM custitem
     WHERE custid = in_custid
       AND status = 'ACTV'
     GROUP BY velocity;

  A_count   integer;
  B_count   integer;
  C_count   integer;
  A_tasks   integer;
  B_tasks   integer;
  C_tasks   integer;
  A_created integer;
  B_created integer;
  C_created integer;
  A_days   integer;
  B_days   integer;
  C_days   integer;


  CURSOR C_ITEMS(in_custid varchar2, in_velocity varchar2, in_days number)
  IS
    SELECT item, trunc(sysdate - nvl(lastcount, sysdate - 60)) days
      FROM custitem
     WHERE custid = in_custid
       AND status = 'ACTV'
       AND velocity = in_velocity
       AND sysdate - nvl(lastcount,sysdate - 60) > in_days
    ORDER BY sysdate - nvl(lastcount,sysdate-60) desc ;

  errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- Get the customer information
    CUST := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
       out_errmsg := 'Invalid customer ID';
       return;
    end if;

-- count the number of A,B,C for this customer
    A_count := 0;
    B_count := 0;
    C_count := 0;

    for crec in C_CNT(in_custid) loop
        if crec.velocity = 'A' then
           A_count := crec.cnt;
        elsif crec.velocity = 'B' then
           B_count := crec.cnt;
        elsif crec.velocity = 'C' then
           C_count := crec.cnt;
        end if;
    end loop;

    -- zut.prt('CNTS A:'||A_count||' B:'||B_count||' C:'||C_count);

-- for each class determine number of tasks to create
--    C(A) = N(A)*Q(A)*12/250
    A_tasks := CEIL(CUST.cycleafrequency*A_count*12/250);
    B_tasks := CEIL(CUST.cyclebfrequency*B_count*12/250);
    C_tasks := CEIL(CUST.cyclecfrequency*C_count*12/250);
    -- zut.prt('TSKS A:'||A_tasks||' B:'||B_tasks||' C:'||C_tasks);

-- Calc days gap for creating tasks
--     n = ceil(365/(N(A)*12))
    A_days := FLOOR(365/(CUST.cycleafrequency*12));
    B_days := FLOOR(365/(CUST.cyclebfrequency*12));
    C_days := FLOOR(365/(CUST.cyclecfrequency*12));
    -- zut.prt('DAYS A:'||A_days||' B:'||B_days||' C:'||C_days);


    out_a_items := A_count;
    out_b_items := B_count;
    out_c_items := C_count;

    out_a_tasks := A_tasks;
    out_b_tasks := B_tasks;
    out_c_tasks := C_tasks;

    return;
exception when others then
  out_errmsg := sqlerrm;

END calc_abc_tasks;



----------------------------------------------------------------------
--
-- create_counts
--
----------------------------------------------------------------------
PROCEDURE create_counts
(
    in_custid       IN      varchar2,
    in_item         IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CURSOR C_LOC(in_custid varchar2, in_item varchar2)
  IS
    SELECT distinct facility, location
      FROM plate P
     WHERE custid = in_custid
       AND item = in_item
       AND type = 'PA'
       AND exists
       (SELECT *
          FROM location L
         WHERE L.facility = P.facility
           AND L.locid = P.location
           AND L.loctype in ('STO','PF'))
       AND not exists
       (SELECT *
          FROM tasks T
         WHERE T.facility = P.facility
           AND T.fromloc = P.location
           AND T.custid = in_custid
           AND T.item = in_item
           AND tasktype = 'CC');

CURSOR C_Location(in_facility varchar2,in_location varchar2) is
  select section,
         equipprof,
         loctype
    from location
   where facility = in_facility
     and locid = in_location;
fromloc C_Location%rowtype;



TSK tasks%rowtype;

BEGIN
    out_errmsg := 'OKAY';
    -- zut.prt('CREATE COUNTS FOR '||in_custid||'/'||in_item);

    for crec in C_LOC(in_custid, in_item) loop
        TSK := null;

        fromloc := NULL;

        open C_Location(crec.facility,crec.location);
        fetch C_Location into fromloc;
        close C_Location;

        if fromloc.loctype != 'USR' then
          ztsk.get_next_taskid(TSK.taskid,out_errmsg);
          insert into tasks
               (taskid, tasktype, facility, fromsection, fromloc,
                fromprofile,custid,item,
                locseq,priority,
                prevpriority,curruserid,lastuser,lastupdate)
          values
                (TSK.taskid, 'CC', crec.facility, fromloc.section,
                crec.location,
                fromloc.equipprof,in_custid,in_item,
                1,
                '3','3',null,in_user,sysdate);
          insert into subtasks
               (taskid, tasktype, facility, fromsection, fromloc,
               fromprofile,custid,item,
               locseq,
               priority,prevpriority,curruserid,lastuser,lastupdate)
          values
               (TSK.taskid, 'CC', crec.facility, fromloc.section,
               crec.location,
               fromloc.equipprof,in_custid,in_item,
               1,
               '3','3',null,in_user,sysdate);
       end if;

    end loop;

    update custitem
       set lastcount = sysdate
     where custid = in_custid
       and item = in_item;

    return;

exception when others then
  out_errmsg := sqlerrm;

END create_counts;


----------------------------------------------------------------------
--
-- create_tasks
--
----------------------------------------------------------------------
PROCEDURE create_tasks
(
    in_custid       IN      varchar2,
    in_days         IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CUST customer%rowtype;

  CURSOR C_LASTCOUNT(in_custid varchar2)
  IS
    SELECT item, min(nvl(lastcountdate, creationdate)) lastcount
      FROM plate P
     WHERE custid = in_custid
       AND type = 'PA'
       AND exists
       (SELECT *
          FROM location L
         WHERE L.facility = P.facility
           AND L.locid = P.location
           AND L.loctype in ('STO','PF'))
       AND not exists
       (SELECT *
          FROM tasks T
         WHERE T.facility = P.facility
           AND T.fromloc = P.location
           AND T.custid = in_custid
           AND T.item = P.item
           AND tasktype = 'CC')
      GROUP BY item;

  CURSOR C_CNT(in_custid varchar2)
  IS
    SELECT velocity, count(*) cnt
      FROM custitem
     WHERE custid = in_custid
       and status = 'ACTV'
     GROUP BY velocity;

  A_count   integer;
  B_count   integer;
  C_count   integer;
  A_tasks   integer;
  B_tasks   integer;
  C_tasks   integer;
  A_created integer;
  B_created integer;
  C_created integer;
  A_days   integer;
  B_days   integer;
  C_days   integer;


  CURSOR C_ITEMS(in_custid varchar2, in_velocity varchar2, in_days number)
  IS
    SELECT item, trunc(sysdate - nvl(lastcount, sysdate - 60)) days
      FROM custitem
     WHERE custid = in_custid
       AND status = 'ACTV'
       AND velocity = in_velocity
       AND sysdate - nvl(lastcount,sysdate - 60) > in_days
    ORDER BY sysdate - nvl(lastcount,sysdate-60) desc ;

  errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- Get the customer information
    CUST := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
       out_errmsg := 'Invalid customer ID';
       return;
    end if;

-- count the number of A,B,C for this customer
    A_count := 0;
    B_count := 0;
    C_count := 0;

    for crec in C_CNT(in_custid) loop
        if crec.velocity = 'A' then
           A_count := crec.cnt;
        elsif crec.velocity = 'B' then
           B_count := crec.cnt;
        elsif crec.velocity = 'C' then
           C_count := crec.cnt;
        end if;
    end loop;

    -- zut.prt('CNTS A:'||A_count||' B:'||B_count||' C:'||C_count);

-- for each class determine number of tasks to create
--    C(A) = N(A)*Q(A)*12/250
    A_tasks := CEIL(CUST.cycleafrequency*A_count*12/250) * in_days;
    B_tasks := CEIL(CUST.cyclebfrequency*B_count*12/250) * in_days;
    C_tasks := CEIL(CUST.cyclecfrequency*C_count*12/250) * in_days;
    -- zut.prt('TSKS A:'||A_tasks||' B:'||B_tasks||' C:'||C_tasks);

-- Calc days gap for creating tasks
--     n = ceil(365/(N(A)*12))
    A_days := FLOOR(365/(CUST.cycleafrequency*12));
    B_days := FLOOR(365/(CUST.cyclebfrequency*12));
    C_days := FLOOR(365/(CUST.cyclecfrequency*12));
    -- zut.prt('DAYS A:'||A_days||' B:'||B_days||' C:'||C_days);

-- For each item set the last countdate
   for crec in C_LASTCOUNT(in_custid) loop
       update custitem
         set lastcount = crec.lastcount
        where custid = in_custid
          and item = crec.item;
        --  and lastcount < crec.lastcount;
   end loop;

   if nvl(to_char(CUST.lastcyclerequest,'MM'),'XX')
          = to_char(sysdate,'MM') then
       A_created := CUST.CycleACounts;
       B_created := CUST.CycleBCounts;
       C_created := CUST.CycleCCounts;
   else
       A_created := 0;
       B_created := 0;
       C_created := 0;
   end if;

-- Do the A's
   for crec in C_ITEMS(in_custid, 'A', A_days) loop
       -- zut.prt(' A Item:' || crec.item||' days:'||crec.days);
       create_counts(in_custid, crec.item, in_user, errmsg);
       A_created := A_created + 1;
       A_tasks := A_tasks - 1;
       exit when A_tasks <= 0;
   end loop;

-- Do the B's
   for crec in C_ITEMS(in_custid, 'B', B_days) loop
       -- zut.prt(' B Item:' || crec.item||' days:'||crec.days);
       create_counts(in_custid, crec.item, in_user, errmsg);
       B_created := B_created + 1;
       B_tasks := B_tasks - 1;
       exit when B_tasks <= 0;
   end loop;


-- Do the C's
   for crec in C_ITEMS(in_custid, 'C', C_days) loop
       -- zut.prt(' C Item:' || crec.item||' days:'||crec.days);
       create_counts(in_custid, crec.item, in_user, errmsg);
       C_created := C_created + 1;
       C_tasks := C_tasks - 1;
       exit when C_tasks <= 0;
   end loop;


   Update customer
      set lastcyclerequest = sysdate,
          cycleAcounts = A_created,
          cycleBcounts = B_created,
          cycleCcounts = C_created,
          lastupdate = sysdate,
          lastuser = in_user
    where custid = in_custid;

    return;
exception when others then
  out_errmsg := sqlerrm;

END create_tasks;




end zabccycle;
/

exit;
