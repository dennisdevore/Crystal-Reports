CREATE OR replace PACKAGE BODY zcyclecount
AS
--
-- $Id$
--

CC_ITEM_LIMIT constant integer := 2;

PROCEDURE generate_cycle_count
(in_location in varchar2
,in_facility in varchar2
,in_userid in varchar2
,in_custid in varchar2 default null
,in_item in varchar2 default null
,in_itemvelocity in varchar2 default null 
,out_msg  IN OUT varchar2
) is

cursor curLocation(in_facility varchar2,in_location varchar2) is
  select section,
         equipprof
    from location
   where facility = in_facility
     and locid = in_location;
fromloc curLocation%rowtype;

TYPE cur_type is REF CURSOR;
cc_cur cur_type;

tk tasks%rowtype;
l_custid plate.custid%type;
l_item plate.item%type;
qtyRemain number(16);
cc_cmd VARCHAR2(2000);

begin
  if rtrim(in_itemvelocity) is not null then 
     cc_cmd := 'select distinct custid, item from plate p where location = ''' || in_location || ''' and facility = ''' ||
               in_facility || ''' and type = ''PA''';
     cc_cmd := cc_cmd || ' and exists (select 1 from custitem i, plate p where p.facility = ''' || in_facility || 
	           ''' and p.location = ''' || in_location || 
	           ''' and p.custid = i.custid(+) and p.item = i.item(+) and i.velocity = ''' || in_itemvelocity || ''')';
     cc_cmd := cc_cmd || ' and not exists (select 1 from tasks t where t.facility = ''' || in_facility ||
	           ''' and t.fromloc = ''' || in_location ||
			   ''' and t.tasktype = ''CC'' and t.custid = p.custid and t.item = p.item)';
    if(in_custid is not null) then 
       cc_cmd := cc_cmd || ' and custid = ''' || in_custid || '''';
    end if;
    if(in_item is not null) then 
       cc_cmd := cc_cmd || ' and item = ''' || in_item || '''';
    end if;
  else 
    cc_cmd := 'select ''' || in_custid || ''', ''' || in_item || ''' from dual ';
  end if;
  
open cc_cur for cc_cmd;
loop
  fetch cc_cur into l_custid, l_item;
  exit when cc_cur%notfound;

  ztsk.get_next_taskid(tk.taskid,out_msg);
  open curLocation(in_facility,in_location);
  fetch curLocation into fromloc;
  close curLocation;

  insert into tasks
    (taskid, tasktype, facility, fromsection, fromloc,
    fromprofile, custid, item, lpid, uom, qty,
    locseq, orderlot, priority,
    prevpriority, curruserid, lastuser, lastupdate)
  values
    (tk.taskid, 'CC', in_facility, fromloc.section,in_location,
    fromloc.equipprof, l_custid, l_item, null, '', null,
    1, null, '3',
    '3', null, in_userid, sysdate);

  insert into subtasks
    (taskid, tasktype, facility, fromsection, fromloc,
    fromprofile, custid, item, lpid, uom, qty, locseq,
    orderlot, priority, prevpriority, curruserid, lastuser, lastupdate)
  values
    (tk.taskid, 'CC', in_facility, fromloc.section, in_location,
    fromloc.equipprof, l_custid, l_item, null, '', null, 1,
    null, '3', '3', null, in_userid, sysdate);
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ccgcc ' || sqlerrm;
end generate_cycle_count;

PROCEDURE generate_cc_load_order
(in_loadno   in number
,in_orderid  in number
,in_facility in varchar2
,in_userid in varchar2
,out_msg  IN OUT varchar2
)
IS

CURSOR C_LPID(in_facility varchar2, in_load number, in_order number)
IS
SELECT facility, location, lpid, custid, item, quantity, lotnumber
  FROM plate
 WHERE facility = in_facility
   AND loadno = in_loadno
   AND orderid = NVL(in_orderid, orderid)
   AND status = 'A'
   AND type = 'PA'
 ORDER BY facility, location;

cursor curLocation(in_facility varchar2,in_location varchar2) is
  select section,
         equipprof
    from location
   where facility = in_facility
     and locid = in_location;
fromloc curLocation%rowtype;

CURSOR C_CC(in_facility varchar2, in_load number, in_lpid varchar2)
IS
select count(1)
  FROM tasks
 WHERE tasktype = 'CC'
   AND facility = in_facility
   AND loadno = in_loadno
   AND lpid = in_lpid;

tk tasks%rowtype;
cnt integer;

errmsg varchar2(200);

BEGIN
  out_msg := 'OKAY';

  for cr in C_LPID(in_facility, in_loadno, in_orderid) loop
  -- check that there isn't a CC task for this guy
     cnt := 0;
     OPEN C_CC(in_facility, in_loadno, cr.lpid);
     FETCH C_CC into cnt;
     CLOSE C_CC;

     if cnt = 0 then
  -- get location information
        open curLocation(in_facility,cr.location);
        fetch curLocation into fromloc;
        close curLocation;

  -- create a CC task for this guy
        ztsk.get_next_taskid(tk.taskid,errmsg);
        insert into tasks
        (taskid, tasktype, facility, fromsection, fromloc,
        fromprofile,custid,item,lpid,uom,qty,
        locseq,orderlot,priority,
        prevpriority,curruserid,loadno, lastuser,lastupdate)
        values
        (tk.taskid, 'CC', in_facility, fromloc.section,cr.location,
        fromloc.equipprof,cr.custid,cr.item,cr.lpid,
        '',cr.quantity,1,cr.lotnumber,
        '3','3',null,in_loadno, in_userid,sysdate);

        insert into subtasks
        (taskid, tasktype, facility, fromsection, fromloc,
        fromprofile,custid,item,lpid,uom,qty,locseq,
        orderlot,priority,prevpriority,curruserid,loadno, lastuser,lastupdate)
        values
        (tk.taskid, 'CC', in_facility, fromloc.section,cr.location,
        fromloc.equipprof,cr.custid,cr.item,cr.lpid,
        '',cr.quantity,1,cr.lotnumber,
        '3','3',null,in_loadno, in_userid,sysdate);
     end if;
  end loop;
END generate_cc_load_order;

PROCEDURE execute_job
(in_descr IN varchar2,
in_facility in varchar2) IS

cursor JobReq is
  select facility,
  STR01,
  STR04,
  STR05,
  STR06,
  STR07,
  STR08,
  FLAG06,
  FLAG07
  from requests
  where reqtype = 'CycleCount'
  and descr = in_descr;
jr JobReq%rowtype;

jl integer;
cmdsql varchar2(255);
loc varchar2(25);
fac varchar2(3);
what_msg varchar2(255);
rowct integer;
begin
  open JobReq;
  fetch JobReq into jr;
  close JobReq;
  cmdsql := 'select distinct location ' ||
  'from cyclecountrequestview ccr ' ||
  'where facility = ''' || jr.facility || '''';

  if jr.str01 is not null then
    cmdsql := cmdsql || ' and (custid = ''' || jr.str01 || ''')';
  end if;
  if jr.str07 is not null then
    cmdsql := cmdsql || ' and (item = ''' || jr.str07 || ''')';
  end if;
  if jr.str04 is not null then
    cmdsql := cmdsql || ' and (Location >= ''' || jr.str04 || ''')';
  end if;
  if jr.str05 is not null then
    cmdsql := cmdsql || ' and (Location <= ''' || jr.str05 || ''')';
  end if;
  if jr.str06 is not null then
    cmdsql := cmdsql || ' and (PickingZone = ''' || jr.str06 || ''')';
  end if;
  if jr.str08 is not null then
    cmdsql := cmdsql || ' and (LocType = ''' || jr.str08 || ''')';
  end if;
  if jr.flag06 is not null then
    cmdsql := cmdsql || ' and exists (select 1 from custitem i, plate p where p.facility = ccr.facility ' ||
	  ' and p.location = ccr.location ' ||
	  ' and p.custid = i.custid(+) and p.item = i.item(+) and i.velocity = ''' || jr.flag06 || ''')';
  end if;
  if jr.flag07 is not null then
    cmdsql := cmdsql || ' and exists (select 1 from location lo where lo.facility = ccr.facility ' ||
	  ' and lo.locid = ccr.location and lo.velocity = ''' || jr.flag07 || ''')';
	  end if;
  cmdsql := cmdsql || ' ORDER BY LOCATION';

  begin
  jl := dbms_sql.open_cursor;
  dbms_sql.parse(jl, cmdSql, dbms_sql.native);
  dbms_sql.define_column(jl,1,loc,15);
  rowct := dbms_sql.execute(jl);
  while(1=1)
  loop
    rowct := dbms_sql.fetch_rows(jl);
    if rowct <= 0 then
      exit;
    end if;
    dbms_sql.column_value(jl,1,loc);
    generate_cycle_count(loc,jr.facility,'AUTO',null,null, jr.flag06, what_msg);
    if substr(what_msg,1,4) = 'OKAY' then
      commit;
    else
      rollback;
    end if;
  end loop;
  dbms_sql.close_cursor(jl);
  exception when no_data_found then
    dbms_sql.close_cursor(jl);
  end;
end execute_job;

PROCEDURE enqueue(
jobid OUT integer,
what IN varchar2,
startdate IN date,
interval IN varchar2
) is

begin
   DBMS_JOB.SUBMIT(jobid,what,startdate,interval);
end enqueue;

procedure setbroken(
  jobid in integer,
  broken in boolean,
  next_date in date
) is

begin
  DBMS_JOB.BROKEN(jobid,broken,next_date);
end setbroken;

end zcyclecount;
/
show errors package body zcyclecount;
exit;
