create or replace package body alps.zimportproc947ia as
--
-- $Id$
--
debug_on boolean := False;

cursor c_adj(in_importfileid varchar2) is
  select d.*
   from import_invadj_947_hdr h,
        import_invadj_947_dtl d
  where h.importfileid = d.importfileid
    and h.importfileid = in_importfileid;

cursor c_plate(in_item varchar2, in_custid varchar2, in_facility varchar2) is
  select lpid, item, facility, custid, invstatus, creationdate, UNITOFMEASURE, type,
         quantity, sum(quantity) over( ) sum_quantity,
         inventoryclass, lotnumber, serialnumber, useritem1, useritem2, 
         useritem3, location, expirationdate, manufacturedate, anvdate
  from plate
  where facility = in_facility 
    and custid = in_custid 
    and item = in_item 
  order by creationdate;

IMP_USERID constant varchar2(10) := 'IMPINV';
IMP_MSG constant varchar2(8) := '4PL 947';

PROCEDURE debug_msg(in_text varchar2)
IS

cntChar integer;

BEGIN

    if not debug_on then
      return;
    end if;

    cntChar := 1;
    while (cntChar * 60) < (Length(in_text)+60)
    loop
        zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
        cntChar := cntChar + 1;
    end loop;

EXCEPTION WHEN OTHERS THEN
    null;
END debug_msg;

procedure write_msg
(in_msg varchar2, in_msgtype varchar2)
is
  strmsg appmsgs.msgtext%type;
  out_msg varchar2(2000);
begin
  out_msg := IMP_MSG||' - '||in_msg;
  dbms_output.put_line(out_msg);
  zms.log_msg(IMP_USERID,null,null,out_msg,nvl(in_msgtype,'E'),IMP_USERID,strmsg);
end write_msg;

procedure import_invadj_947_header
(in_importfileid  in varchar2
,in_facility      in varchar2
,in_custid        in varchar2
,in_transdate     in varchar2
,in_transtime     in varchar2
,in_facility_name in varchar2
,in_adjno         in varchar2
,out_errorno      in out number
,out_msg          in out varchar2
)
is
errmsg varchar2(100);

l_importfileid varchar2(255);
l_facility varchar2(3);
l_custid varchar2(10);
l_transdate date;
l_transtime varchar(10);
l_facility_name varchar2(40);
l_adjno varchar2(14);

begin
  out_errorno := 0;
  out_msg := 'OKAY';

  l_importfileid := rtrim(in_importfileid);
  if l_importfileid is null then 
    write_msg('Missing import file ID', 'E');
  end if;
  
  l_facility := rtrim(in_facility);
  if l_facility is null then 
    write_msg('Missing import facility', 'E');
  end if;
  
  l_custid := rtrim(upper(in_custid));
  if l_custid is null then 
    write_msg('Missing import customer id', 'E');
  end if;
  
  l_adjno := rtrim(in_adjno);
  if l_adjno is null then 
    write_msg('Missing import adjustment number', 'E');
  end if;
  
  l_facility_name := rtrim(in_facility_name);
  
  select decode(trim(in_transdate),
                null, trunc(sysdate),
                to_date(trim(in_transdate),'MM/DD/YYYY'))
   into l_transdate
   from dual;

  select decode(trim(in_transtime),
                null, to_char(sysdate,'HH24:MI:SS'),
                trim(in_transtime))
   into l_transtime
   from dual;
  
  insert into import_invadj_947_hdr values
  ( l_importfileid
   ,l_facility
   ,l_custid
   ,l_transdate
   ,l_transtime
   ,l_facility_name
   ,l_adjno);
  
   debug_msg('insert into import_invadj_947_hdr '||
    l_importfileid||', ' ||
    l_facility||', ' ||
    l_custid||', ' ||
    l_transdate||', ' ||
    l_transtime||', ' ||
    l_facility_name||', ' ||
    l_adjno||')');

exception when others then
  out_msg := IMP_MSG||' - '||sqlerrm;
  out_errorno := sqlcode;
  write_msg(out_msg,'E');
end import_invadj_947_header; 

procedure import_invadj_947_details
(in_importfileid    in varchar2
,in_item            in varchar2
,in_adjreason       in varchar2
,in_quantity        in number
,in_uom             in varchar2
,in_facility        in varchar2
,in_custid          in varchar2
,in_adjno           in varchar2
,in_invstatus       in varchar2
,out_errorno        in out number
,out_msg            in out varchar2
)
is
l_importfileid varchar2(255);
l_item varchar2(50);
l_adjreason varchar2(12);
l_quantity number;
l_uom varchar2(4);
l_facility varchar2(3);
l_custid varchar2(10);
l_transdate date;
l_facility_name varchar2(40);
l_adjno varchar2(14);
l_invstatus varchar2(2);

begin
  out_errorno := 0;
  out_msg := 'OKAY';
 
  l_importfileid := rtrim(in_importfileid);
  if l_importfileid is null then 
    write_msg('Missing file id', 'E');
  end if;
  
  l_item := rtrim(in_item);
  if l_item is null then 
    write_msg('Missing item', 'E');
  end if;

  l_adjreason := rtrim(in_adjreason);
  if l_adjreason is null then 
    write_msg('Missing item', 'E');
  end if;

  l_quantity := nvl(in_quantity,0);
  if l_quantity is null then 
    write_msg('Missing quantity', 'E');
  end if;
  
  l_uom := rtrim(in_uom);
  if l_uom is null then 
    write_msg('Missing Unit of measure', 'E');
  end if;
  
  l_facility := rtrim(in_facility);
  if l_facility is null then 
    write_msg('Missing facility', 'E');
  end if;

  l_custid := rtrim(upper(in_custid));
  if l_custid is null then 
    write_msg('Missing customer id', 'E');
  end if;

  l_adjno := rtrim(in_adjno);
  if l_adjno is null then 
    write_msg('Missing adjustment number', 'E');
  end if;

  l_invstatus := rtrim(in_invstatus);
  
  insert into import_invadj_947_dtl values
  ( l_importfileid
   ,l_item
   ,l_adjreason
   ,l_quantity
   ,l_uom
   ,l_facility
   ,l_custid
   ,l_adjno
   ,l_invstatus);

  debug_msg('insert into import_invadj_947_dtl: ('||
      l_importfileid||', '||
      l_item||', '||
      l_adjreason||', '||
      l_quantity||', '||
      l_uom||', '||
      l_facility||', '||
      l_custid||', '||
      l_adjno||', '||
      l_invstatus||')');

exception when others then
  out_msg := IMP_MSG||' - '||sqlerrm;
  out_errorno := sqlcode;
  write_msg(out_msg,'E');
end import_invadj_947_details;

procedure end_of_import_invadj_947
(in_importfileid    in varchar2
,out_errorno        in out number
,out_msg            in out varchar2
)
is
  adj c_adj%rowtype;
  plate c_plate%rowtype;
  paperbased_yn char(1);
  baseuom custitem.baseuom%type;
  adj_cnt number;
  plate_cnt number;
  l_cur_qty number;
  l_new_qty number;
  newlpid plate.lpid%type;
  out_adjrowid1 rowid;
  out_adjrowid2 rowid;
  out_controlnumber varchar2(10);
begin  
  out_errorno := 0;
  out_msg := 'OKAY';

  if rtrim(in_importfileid) is null then 
    write_msg('Missing import file id', 'E');
    return;
  end if;

  adj_cnt := 0;
  open c_adj(trim(in_importfileid));
  loop
      fetch c_adj into adj;
      exit when c_adj%notfound;
      adj_cnt := adj_cnt + 1;

      -- Allow only aggregate customers
      select nvl(paperbased, 'N')
        into paperbased_yn
        from customer
       where custid = adj.custid;
      if paperbased_yn = 'N' then
        write_msg('Customer: '||adj.custid||' is not an aggregate customer.', 'E');
        exit;
      end if;

      if (nvl(trim(adj.quantity), 0) = 0) then
        write_msg('Nothing to adjust for fac/custid/item/adjno: '||
          adj.facility||'/'||adj.custid||'/'||adj.item||'/'||adj.adjno, 'E');
        exit;
      end if;

      begin
          select baseuom
            into baseuom
            from custitem
           where item=adj.item
             and custid=adj.custid;
      exception when others then
          write_msg('Cannot determine baseuom for custid/item: '||adj.custid||'/'||adj.item, 'E');
          exit;
      end;

      -- Convert rcvd qty to baseuom qty
      l_cur_qty := zlbl.uom_qty_conv(adj.custid, adj.item, adj.quantity, adj.uom, baseuom);
      l_cur_qty := abs(l_cur_qty);
          
      -- Locate plates for current item
      plate_cnt := 0;
      newlpid := null;
      
      open c_plate(adj.item, adj.custid, adj.facility);
      loop
          fetch c_plate into plate;
          exit when c_plate%notfound;
          plate_cnt := plate_cnt + 1;
          
          -- Determine if there is enough quantity to adjust
          if zlbl.uom_qty_conv(adj.custid, adj.item, 
               plate.sum_quantity, plate.unitofmeasure, baseuom) - l_cur_qty < 0 then
            write_msg('Not enough quantity to adjust. '||
              'qty requested= '||l_cur_qty||' - qty on plates= '||plate.sum_quantity, 'E');
            exit;
          end if;

          ---------------------------------------------------------------------
          -- Create license plates as needed for inventory to be moved to.
          -- As with receipts, all license plates created by this process 
          -- are located at a location with a location ID equal 
          -- to the customer ID for whom the license plate was created.
          ---------------------------------------------------------------------
          if (rtrim(adj.invstatus) is not null and newlpid is null) then
              adjust_inventory_status(plate.lpid, l_cur_qty, adj.uom, adj.invstatus, 
                adj.adjreason, adj.custid, IMP_USERID, newlpid, out_adjrowid1, out_adjrowid2, 
                out_controlnumber, out_errorno, out_msg);
              debug_msg('newlpid= '||newlpid);

              if out_msg != 'OKAY' then 
                  write_msg('adjust inventory status failed. '||out_errorno||' - '||out_msg, 'E');
                  exit;
              end if;
          end if;

          ----------------------------------------------------------------------------------
          -- Adjust inventory quantity on plates for the facility/customer/item requested.
          -- Adjustments occurs in FIFO manner so that the oldest license plates
          -- are adjusted first. If necessary, entire license plates may be deleted.
          ----------------------------------------------------------------------------------
          if rtrim(out_msg) = 'OKAY' then
              l_cur_qty := zlbl.uom_qty_conv(adj.custid, adj.item, 
                  plate.quantity, plate.unitofmeasure, baseuom) - abs(l_cur_qty);
 
              debug_msg('l_cur_qty= '||l_cur_qty);

              if l_cur_qty > 0 then
                  adjust_inventory_quantity(plate.lpid, l_cur_qty, adj.uom, null, 
                    adj.adjreason, out_adjrowid1, out_adjrowid2, out_errorno, out_msg);
              else
                 adjust_inventory_quantity(plate.lpid, 0, adj.uom, null, 
                    adj.adjreason, out_adjrowid1, out_adjrowid2, out_errorno, out_msg);
              end if;

              if substr(out_msg,1,4) != 'OKAY' then 
                  write_msg('adjust inventory quantity failed. '||out_errorno||' - '||out_msg, 'E');
                  exit;
              end if;
          end if;

          -- Done with this item
          if l_cur_qty >= 0 then
              exit;
          end if;

      end loop;
      close c_plate;
      write_msg('Number of plates processed for item ('||adj.item||') = '||plate_cnt, 'W');
      
  end loop;
  close c_adj;
  write_msg('Number of adj records processed = '||adj_cnt, 'W');
  
exception when others then
  out_msg := IMP_MSG||' - '||sqlerrm;
  out_errorno := sqlcode;
  write_msg(out_msg,'E');
end end_of_import_invadj_947;

procedure adjust_inventory_quantity
(in_lpid          in varchar2
,in_quantity      in number
,in_uom           in varchar2
,in_invstatus     in varchar2
,in_adjreason     in varchar2
,out_adjrowid1    in out varchar2
,out_adjrowid2    in out varchar2
,out_errorno      in out number
,out_msg          in out varchar2)
is
cursor c_plate(in_lpid varchar2) is
  select *
  from plate
  where lpid = in_lpid;
  plate c_plate%rowtype;
begin
    debug_msg('adjust inventory quantity for lpid/qty/invstatus/adjreason : '||
        in_lpid||'/'||in_quantity||'/'||in_invstatus||'/'||in_adjreason);
        
    out_adjrowid1 := null;
    out_adjrowid2 := null;
    out_errorno := 0;
    out_msg := null;

    if in_quantity is null then
      out_msg := 'Missing qty';
      return;
    end if;

    open c_plate(in_lpid);
    fetch c_plate into plate;
    close c_plate;

    if plate.lpid is null then
      out_msg := 'Plate not found';
      return;
    end if;
      
    zia.inventory_adjustment(
       in_lpid                    => plate.lpid
      ,in_custid                  => plate.custid
      ,in_item                    => plate.item
      ,in_inventoryclass          => plate.inventoryclass
      ,in_invstatus               => in_invstatus
      ,in_lotnumber               => plate.lotnumber
      ,in_serialnumber            => plate.serialnumber
      ,in_useritem1               => plate.useritem1
      ,in_useritem2               => plate.useritem2
      ,in_useritem3               => plate.useritem3
      ,in_location                => plate.location
      ,in_expirationdate          => plate.expirationdate        
      ,in_qty                     => in_quantity
      ,in_orig_custid             => plate.custid
      ,in_orig_item               => plate.item
      ,in_orig_inventoryclass     => plate.inventoryclass
      ,in_orig_invstatus          => plate.invstatus
      ,in_orig_lotnumber          => plate.lotnumber
      ,in_orig_serialnumber       => plate.serialnumber
      ,in_orig_useritem1          => plate.useritem1
      ,in_orig_useritem2          => plate.useritem2
      ,in_orig_useritem3          => plate.useritem3
      ,in_orig_location           => plate.location
      ,in_orig_expirationdate     => plate.expirationdate
      ,in_orig_qty                => plate.quantity
      ,in_facility                => plate.facility
      ,in_adjreason               => in_adjreason
      ,in_userid                  => IMP_USERID
      ,in_tasktype                => null
      ,in_weight                  => null
      ,in_orig_weight             => null
      ,in_mfgdate                 => plate.manufacturedate
      ,in_orig_mfgdate            => plate.manufacturedate
      ,in_anvdate                 => plate.anvdate
      ,in_orig_anvdate            => plate.anvdate
      ,out_adjrowid1              => out_adjrowid1
      ,out_adjrowid2              => out_adjrowid2
      ,out_errorno                => out_errorno
      ,out_msg                    => out_msg
      ,in_custreference           => null
      ,in_tasks_ok                => null);
    
exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end adjust_inventory_quantity;

procedure adjust_inventory_status
(in_lpid            in varchar2
,in_quantity        in number
,in_uom             in varchar2
,in_invstatus       in varchar2
,in_adjreason       in varchar2
,in_newlocid        in varchar2
,in_user            in varchar2
,out_newlpid        in out varchar2
,out_adjrowid1      in out varchar2
,out_adjrowid2      in out varchar2
,out_controlnumber  in out varchar2
,out_errorno        in out number
,out_msg            in out varchar2)
is
cursor c_plate(in_lpid varchar2) is
  select *
  from plate
  where lpid = in_lpid;
  
  plate c_plate%rowtype;
  newplate c_plate%rowtype;
  newlpid plate.lpid%type;
  newlocid location.locid%type;
begin
    debug_msg('adjust inventory status for lpid/qty/invstatus/adjreason : '||
        in_lpid||'/'||in_quantity||'/'||in_invstatus||'/'||in_adjreason);
    
    out_newlpid := null;
    out_adjrowid1 := null;
    out_adjrowid2 := null;
    out_controlnumber := null;
    out_errorno := 0;
    out_msg := null;
    
    if in_quantity is null then
      out_msg := 'Missing qty';
      return;
    end if;

    if trim(in_invstatus) is null then
      out_msg := 'inv status is null';
      return;
    end if;
    
    open c_plate(in_lpid);
    fetch c_plate into plate;
    close c_plate;

    if plate.lpid is null then
      out_msg := 'plate not found';
      return;
    end if;

    -- get location id
    if trim(in_newlocid) is null then
      select locid
        into newlocid
        from location 
       where locid = plate.custid;
      if trim(in_newlocid) is null then 
        write_msg('Location: '||plate.custid||' does not exist', 'E');
        return;
      end if;
    else
      newlocid := in_newlocid;
    end if;
    
    -- get next lpid
    zrf.get_next_lpid(newlpid, out_msg);
    if (out_msg is not null or trim(newlpid) is null) then
      write_msg('Cannot get next lpid - '||out_msg, 'E');
       return;
    end if;

    -- Create a new plate
    rfbp.dupe_lp(plate.lpid, newlpid, newlocid, plate.status, in_quantity,
      in_user, plate.disposition, null, null, out_msg);
    if out_msg is not null then
      return;
    end if;

    open c_plate(newlpid);
    fetch c_plate into newplate;
    close c_plate;

    -- Update the new plate with the new inventory status
    zia.change_invstatus(newplate.lpid ,in_invstatus ,in_adjreason ,null ,in_user,
        out_adjrowid1, out_adjrowid2, out_controlnumber, out_errorno, out_msg, null);

    if out_msg = 'OKAY' then
        out_newlpid := newlpid;
    end if;
    
exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end adjust_inventory_status;

END zimportproc947ia;
/
show errors package body zimportproc947ia;
exit;
