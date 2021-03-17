drop table bolrequest_comment;
drop table bolrequest_tmpcomment;

create table bolrequest_tmpcomment
(vicsessionid    number(7)
,vicsequence     number(7)
,comments        varchar2(4000)
,lastupdate      date
);

create table bolrequest_comment
(vicsessionid    number(7)
,vicsequence     number(7)
,vicsubsequence  number(7)
,comments        varchar2(132)
,numstops        number(7)
,lastupdate      date
);

create index bolrequest_com_sessionid_idx
 on bolrequest_comment(vicsessionid,vicsequence);

create index bolrequest_com_lastupdate_idx
 on bolrequest_comment(lastupdate);

create or replace package bolcommentpkg
as type bolrequest_comment_type is ref cursor return bolrequest_comment%rowtype;
end bolcommentpkg;
/
create or replace procedure bolcommentproc
(bolrequest_comment_cursor IN OUT bolcommentpkg.bolrequest_comment_type
,in_vicsessionid number
,in_vicsequence number
,in_bolreqtype varchar2
,in_comsuppmsg_yn varchar2
,in_loadno number
,in_stopno number
,in_shipno number
,in_orderid number
,in_shipid number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curLoads is
  select loadno,
         shiptype,
         carrier,
         facility
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curLoadComment is
  select bolcomment
    from loadsbolcomments
   where loadno = in_loadno;

cursor curLoadStopComment is
  select bolcomment
    from loadstopbolcomments
   where loadno = in_loadno
     and stopno = in_stopno;

cursor curLoadStopShipComment is
  select bolcomment
    from loadstopshipbolcomments
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno;

cursor curTmpComments is
  select comments
    from bolrequest_tmpcomment
   where vicsessionid = in_vicsessionid
     and vicsequence = in_vicsequence
   order by rowid;

cntRows integer;
cntComment integer;
cntHazard integer;
cntPallets integer;
bolstopno integer;
bolmaxstopno integer;
stopshipto orderhdr.shipto%type;
shipcarrier carrier.carrier%type;
shipcarrierphone carrier.phone%type;
stopfound boolean;
numStops integer;
wrkh bolrequest_header%rowtype;
wrk bolrequest_comment%rowtype;
strComment varchar2(4000);
lenComment integer;
cntLoop integer;
lenWrkComment integer;
posWrkComment integer;

procedure edit_comment(in_comment varchar2)
as

wrkComment varchar2(4000);

begin

wrkComment := rtrim(in_comment);
cntLoop := 0;

while (1=1)
loop
  cntLoop := cntLoop + 1;
  if (wrkComment is null) or
     (cntLoop > 200) then
    exit;
  end if;
  lenComment := length(wrkComment);
  wrk.comments := rtrim(substr(wrkComment,1,132));
  lenWrkComment := length(wrk.comments);
  posWrkComment := 1;
  while posWrkComment < lenWrkComment
  loop
    if substr(wrk.comments,posWrkComment,1) in (CHR(13),CHR(10)) then
      wrk.comments := rtrim(substr(wrk.comments,1,posWrkComment-1) || ' ' ||
                            substr(wrk.comments,posWrkComment+1,lenWrkComment));
    end if;
    posWrkComment := posWrkComment + 1;
  end loop;
  wrk.vicsubsequence := wrk.vicsubsequence + 1;
  insert into bolrequest_comment
  values
  (wrk.vicsessionid,wrk.vicsequence,wrk.vicsubsequence,
   wrk.comments,null,sysdate);
  if lenComment > 132 then
    wrkComment := substr(wrkComment,133,4000-133);
  else
    wrkComment := null;
  end if;
end loop;

exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt('edit_comment: ' || sqlerrm);
  end if;
end edit_comment;

procedure add_comment(in_comment varchar2)
as

begin

if rtrim(in_comment) is null then
  return;
end if;

select count(1)
  into cntRows
  from bolrequest_tmpcomment
 where vicsessionid = wrk.vicsessionid
   and vicsequence = wrk.vicsequence
   and comments = rtrim(in_comment);

if cntRows <> 0 then
  return;
end if;

insert into bolrequest_tmpcomment
values (wrk.vicsessionid,wrk.vicsequence,rtrim(in_comment),sysdate);

exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt('add_comment: ' || sqlerrm);
  end if;
end add_comment;

begin

delete from bolrequest_comment
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_comment
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_tmpcomment
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_tmpcomment
where lastupdate < trunc(sysdate);
commit;

wrk := null;
wrk.vicsessionid := in_vicsessionid;
wrk.vicsequence := in_vicsequence;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  goto return_vics_rows;
end if;

if in_comsuppmsg_yn = 'Y' then
  insert into bolrequest_comment
  values (wrk.vicsessionid,wrk.vicsequence,1,null,null,sysdate);
  insert into bolrequest_comment
  values (wrk.vicsessionid,wrk.vicsequence,2,'     SEE ATTACHED',null,sysdate);
  insert into bolrequest_comment
  values (wrk.vicsessionid,wrk.vicsequence,3,'        SUPPLEMENT PAGE',null,sysdate);
  goto return_vics_rows;
end if;

strcomment := null;
open curLoadComment;
fetch curLoadComment into strcomment;
close curLoadComment;
if trim(strcomment) is not null then
  add_comment(strcomment);
end if;

if in_bolreqtype = 'STOP' then
  strcomment := null;
  open curLoadStopComment;
  fetch curLoadStopComment into strcomment;
  close curLoadStopComment;
  if trim(strcomment) is not null then
    add_comment(strcomment);
  end if;
end if;

if in_bolreqtype in ('SHIP') then
  strcomment := null;
  open curLoadStopShipComment;
  fetch curLoadStopShipComment into strcomment;
  close curLoadStopShipComment;
  if trim(strcomment) is not null then
    add_comment(strcomment);
  end if;
  for lss in
    (select orderid,shipid,custid,shipto
       from orderhdr
      where loadno = in_loadno
        and stopno = in_stopno
        and shipno = in_shipno
        and orderstatus <> 'X'
        and nvl(qtyship,0) <> 0)
  loop
    for ohc in
      (select bolcomment
         from orderhdrbolcomments
        where orderid = lss.orderid
          and shipid = lss.shipid)
    loop
      add_comment(ohc.bolcomment);
    end loop;
    for odc in
      (select bolcomment
         from orderdtlbolcomments bc, orderdtl od
        where od.orderid = lss.orderid
          and od.shipid = lss.shipid
          and od.linestatus <> 'X'
          and nvl(od.qtyship,0) <> 0
          and od.orderid = bc.orderid
          and od.shipid = bc.shipid
          and od.item = bc.item
          and nvl(od.lotnumber,'x') = nvl(bc.lotnumber,'x'))
    loop
      add_comment(odc.bolcomment);
    end loop;
    for itm in
      (select distinct item
         from orderdtl
        where orderid = lss.orderid
          and shipid = lss.shipid
          and linestatus <> 'X'
          and nvl(qtyship,0) <> 0)
    loop
      cntRows := 0;
      for itmc in
        (select comment1
           from custitembolcomments
          where custid = lss.custid
            and item = itm.item
            and consignee = lss.shipto)
      loop
        cntRows := cntRows + 1;
        add_comment(itmc.comment1);
      end loop;
      if cntRows = 0 then
        for itmc in
          (select comment1
             from custitembolcomments
            where custid = lss.custid
              and item = itm.item
              and consignee is null)
        loop
          cntRows := cntRows + 1;
          add_comment(itmc.comment1);
        end loop;
      end if;
      cntRows := 0;
      for itmc in
        (select comment1
           from custitembolcomments
          where custid = lss.custid
            and item is null
            and consignee = lss.shipto)
      loop
        cntRows := cntRows + 1;
        add_comment(itmc.comment1);
      end loop;
      if cntRows = 0 then
        for itmc in
          (select comment1
             from custitembolcomments
            where custid = lss.custid
              and item is null
              and consignee is null)
        loop
          cntRows := cntRows + 1;
          add_comment(itmc.comment1);
        end loop;
      end if;
    end loop;
  end loop;
end if;

if in_bolreqtype in ('POME') then
  strcomment := null;
  open curLoadStopShipComment;
  fetch curLoadStopShipComment into strcomment;
  close curLoadStopShipComment;
  if trim(strcomment) is not null then
    add_comment(strcomment);
  end if;
  for lss in
    (select orderid,shipid,custid,shipto
       from orderhdr
      where loadno = in_loadno
        and stopno = in_stopno
        and shipno = in_shipno
        and orderid = in_orderid
        and shipid = in_shipid
        and orderstatus <> 'X'
        and nvl(qtyship,0) <> 0)
  loop
    for ohc in
      (select bolcomment
         from orderhdrbolcomments
        where orderid = lss.orderid
          and shipid = lss.shipid)
    loop
      add_comment(ohc.bolcomment);
    end loop;
    for odc in
      (select bolcomment
         from orderdtlbolcomments bc, orderdtl od
        where od.orderid = lss.orderid
          and od.shipid = lss.shipid
          and od.linestatus <> 'X'
          and nvl(od.qtyship,0) <> 0
          and od.orderid = bc.orderid
          and od.shipid = bc.shipid
          and od.item = bc.item
          and nvl(od.lotnumber,'x') = nvl(bc.lotnumber,'x'))
    loop
      add_comment(odc.bolcomment);
    end loop;
    for itm in
      (select distinct item
         from orderdtl
        where orderid = lss.orderid
          and shipid = lss.shipid
          and linestatus <> 'X'
          and nvl(qtyship,0) <> 0)
    loop
      cntRows := 0;
      for itmc in
        (select comment1
           from custitembolcomments
          where custid = lss.custid
            and item = itm.item
            and consignee = lss.shipto)
      loop
        cntRows := cntRows + 1;
        add_comment(itmc.comment1);
      end loop;
      if cntRows = 0 then
        for itmc in
          (select comment1
             from custitembolcomments
            where custid = lss.custid
              and item = itm.item
              and consignee is null)
        loop
          cntRows := cntRows + 1;
          add_comment(itmc.comment1);
        end loop;
      end if;
      cntRows := 0;
      for itmc in
        (select comment1
           from custitembolcomments
          where custid = lss.custid
            and item is null
            and consignee = lss.shipto)
      loop
        cntRows := cntRows + 1;
        add_comment(itmc.comment1);
      end loop;
      if cntRows = 0 then
        for itmc in
          (select comment1
             from custitembolcomments
            where custid = lss.custid
              and item is null
              and consignee is null)
        loop
          cntRows := cntRows + 1;
          add_comment(itmc.comment1);
        end loop;
      end if;
    end loop;
  end loop;
end if;

wrk.vicsubsequence := 0;
for tc in curTmpComments
loop
  edit_comment(tc.comments);
end loop;

<<return_vics_rows>>

select count(1)
  into cntComment
  from bolrequest_comment
 where vicsessionid = wrk.vicsessionid
   and vicsequence = wrk.vicsequence;

while cntComment < 6
loop
  cntComment := cntComment + 1;
  insert into bolrequest_comment
  values (wrk.vicsessionid,wrk.vicsequence,cntComment,null,null,sysdate);
  commit;
end loop;

if in_comsuppmsg_yn = 'C' then
  delete from bolrequest_comment
     where vicsessionid = wrk.vicsessionid
       and vicsequence = wrk.vicsequence;
  commit;
  insert into bolrequest_comment
  values (wrk.vicsessionid,wrk.vicsequence,1,null,cntComment,sysdate);
  commit;
end if;

commit;

open bolrequest_comment_cursor for
 select *
   from bolrequest_comment
  where vicsessionid = in_vicsessionid
    and vicsequence = in_vicsequence
  order by vicsubsequence;

end bolcommentproc;
/
show errors package bolcommentpkg;
show errors procedure bolcommentproc;
--exit;
