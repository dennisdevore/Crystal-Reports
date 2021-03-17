drop table revactivity;

-- trantype column values:
--    AA-column headers
--    DT-Detail

create table revactivity
(sessionid       number
,groupsort       number
,catsort         number
,category        varchar2(3)
,colhead1        varchar2(12)
,colhead2        varchar2(12)
,colhead3        varchar2(12)
,colhead4        varchar2(12)
,colhead5        varchar2(12)
,colhead6        varchar2(12)
,colhead7        varchar2(12)
,colhead8        varchar2(12)
,amt1            number(16,2)
,amt2            number(16,2)
,amt3            number(16,2)
,amt4            number(16,2)
,amt5            number(16,2)
,amt6            number(16,2)
,amt7            number(16,2)
,amt8            number(16,2)
,lastupdate      date
);

create index revactivity_sessionid_idx
 on revactivity(sessionid);

create unique index revactivity_category_idx
 on revactivity(sessionid,category);

create index revactivity_lastupdate_idx
 on revactivity(lastupdate);

create or replace package revactivitypkg
as type rba_type is ref cursor return revactivity%rowtype;
end revactivitypkg;
/


create or replace procedure revactivityproc
(rba_cursor IN OUT revactivitypkg.rba_type
,in_facility IN varchar2
,in_date IN date)
as
--
-- $Id$
--

cursor curFacility(in_begdate date, in_enddate date) is
  select facility,
         rownum
    from facility fa
   where (facility = in_facility
      or  in_facility = 'ALL')
     and (exists (
          select 1
            from invoicehdr
           where postdate >= trunc(in_begdate)
             and postdate <  trunc(in_enddate)
             and invstatus = '3'
             and facility = fa.facility
             and rownum=1)
      or  exists (
          select 1
            from asofinventory
           where facility = fa.facility
             and effdate >= trunc(in_begdate)
             and effdate <  trunc(in_enddate)
             and rownum=1))
   order by facility;
fa curFacility%rowtype;

cursor curRevenue(in_facility varchar2, in_begdate date, in_enddate date) is
  select decode(ac.mincategory,'S','RS','H','RH','RO') activity,
         sum(nvl(billedamt,0)*decode(id.invtype,'C',-1,1)) billedamt
    from invoicehdr ih, invoicedtl id, activity ac
   where ih.postdate >= trunc(in_begdate)
     and ih.postdate <  trunc(in_enddate)
     and ih.facility = in_facility
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus = '3'
     and ac.code = id.activity
   group by decode(ac.mincategory,'S','RS','H','RH','RO');
rev curRevenue%rowtype;

cursor curActivity(in_facility varchar2, in_begdate date, in_enddate date) is
  select decode(aoi.trantype,'RT','RC',aoi.trantype) trantype,
         decode(aoi.trantype,'SH',aoi.orderid,0) orderid,
         decode(aoi.trantype,'SH',aoi.shipid,0) shipid,
         decode(aoi.trantype,'AD',aoi.lpid,null) lpid,
         sum(aoi.adjustment) adjustment,
         sum(aoi.weightadjustment) weightadjustment,
         count(1) reccount
    from asofinventorydtl aoi
   where aoi.facility = in_facility
     and aoi.effdate >= trunc(in_begdate)
     and aoi.effdate <  trunc(in_enddate)
   group by decode(aoi.trantype,'RT','RC',aoi.trantype),
         decode(aoi.trantype,'SH',aoi.orderid,0),
         decode(aoi.trantype,'SH',aoi.shipid,0),
         decode(aoi.trantype,'AD',aoi.lpid,null);
act curActivity%rowtype;

cursor curShipPlates(in_orderid number, in_shipid number) is
  select count(1) palletcount
    from orderhdr oh, shippingplate sp
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.shiptype <> 'S'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
     and sp.status = 'SH'
     and sp.parentlpid is null;
sp curShipPlates%rowtype;
  
numSessionId number;
lFirstOfYear date;
lFirstOfMonth date;
lEndDate date;

procedure initialize_data(in_groupsort number, in_catsort number, in_category varchar2)
is
begin

  begin
    insert into revactivity(sessionid, groupsort, catsort, category, colhead1, colhead2,
      colhead3, colhead4, colhead5, colhead6, colhead7, colhead8,
      amt1, amt2, amt3, amt4, amt5, amt6, amt7, amt8, lastupdate)
    values(numSessionId, in_groupsort, in_catsort, in_category, null, null,
      null, null, null, null, null, null,
      0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, sysdate);
  exception
    when OTHERS then
      null;
  end;
  
exception when others then
  zut.prt('revactivityproc ' || sqlerrm);
end;

procedure insert_data(in_category varchar2, in_facility varchar2, in_rownum number, in_amount number)
is
lFacility varchar2(3);
lAmount number(16,2);
lRowNum number(3);
begin

  lFacility := in_facility;
  lAmount := nvl(in_amount,0.0);
  lRowNum := in_rownum;
  
  if (lRowNum > 8) then
     lFacility := 'xxx';
     lRowNum := 8;
     
     update revactivity
        set colhead8 = 'xxx',
            lastupdate = sysdate
      where sessionid = numSessionId
        and category = in_category
        and colhead8 <> 'xxx';
  end if; 
  
  update revactivity
     set colhead1 = nvl(colhead1, decode(lRowNum, 1, lFacility, colhead1)),
         colhead2 = nvl(colhead2, decode(lRowNum, 2, lFacility, colhead2)),
         colhead3 = nvl(colhead3, decode(lRowNum, 3, lFacility, colhead3)),
         colhead4 = nvl(colhead4, decode(lRowNum, 4, lFacility, colhead4)),
         colhead5 = nvl(colhead5, decode(lRowNum, 5, lFacility, colhead5)),
         colhead6 = nvl(colhead6, decode(lRowNum, 6, lFacility, colhead6)),
         colhead7 = nvl(colhead7, decode(lRowNum, 7, lFacility, colhead7)),
         colhead8 = nvl(colhead8, decode(lRowNum, 8, lFacility, colhead8)),
         amt1 = nvl(amt1, 0.0) + decode(lRowNum, 1, lAmount, 0.0),
         amt2 = nvl(amt2, 0.0) + decode(lRowNum, 2, lAmount, 0.0),
         amt3 = nvl(amt3, 0.0) + decode(lRowNum, 3, lAmount, 0.0),
         amt4 = nvl(amt4, 0.0) + decode(lRowNum, 4, lAmount, 0.0),
         amt5 = nvl(amt5, 0.0) + decode(lRowNum, 5, lAmount, 0.0),
         amt6 = nvl(amt6, 0.0) + decode(lRowNum, 6, lAmount, 0.0),
         amt7 = nvl(amt7, 0.0) + decode(lRowNum, 7, lAmount, 0.0),
         amt8 = nvl(amt8, 0.0) + decode(lRowNum, 8, lAmount, 0.0),
         lastupdate = sysdate
   where sessionid = numSessionId
     and category = in_category;
     
exception when others then
  zut.prt('revactivityproc ' || sqlerrm);
end;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revactivity
where sessionid = numSessionId;
commit;

delete from revactivity
where lastupdate < trunc(sysdate);
commit;

lFirstOfYear := to_date(to_char(in_date,'YYYY')||'0101','YYYYMMDD');
lFirstOfMonth := to_date(to_char(in_date,'YYYYMM')||'01','YYYYMMDD');
lEndDate := trunc(in_date)+1;

initialize_data(1, 1, 'MRS');
initialize_data(1, 2, 'MRH');
initialize_data(1, 3, 'MRO');
initialize_data(2, 1, 'YRS');
initialize_data(2, 2, 'YRH');
initialize_data(2, 3, 'YRO');
initialize_data(3, 1, 'MCR');
initialize_data(3, 2, 'MCS');
initialize_data(3, 3, 'MCA');
initialize_data(4, 1, 'YCR');
initialize_data(4, 2, 'YCS');
initialize_data(4, 3, 'YCA');
initialize_data(5, 1, 'MPR');
initialize_data(5, 2, 'MPS');
initialize_data(5, 3, 'MPA');
initialize_data(6, 1, 'YPR');
initialize_data(6, 2, 'YPS');
initialize_data(6, 3, 'YPA');
initialize_data(7, 1, 'MGR');
initialize_data(7, 2, 'MGS');
initialize_data(7, 3, 'MGA');
initialize_data(8, 1, 'YGR');
initialize_data(8, 2, 'YGS');
initialize_data(8, 3, 'YGA');
  
for fa in curFacility(lFirstOfYear, lEndDate)
loop
  for rev in curRevenue(fa.facility, lFirstOfMonth, lEndDate)
  loop
    insert_data('M'||rev.activity, fa.facility, fa.rownum, rev.billedamt);
  end loop;

  for rev in curRevenue(fa.facility, lFirstOfYear, lEndDate)
  loop
    insert_data('Y'||rev.activity, fa.facility, fa.rownum, rev.billedamt);
  end loop;

  for act in curActivity(fa.facility, lFirstOfMonth, lEndDate)
  loop
    if (act.trantype = 'RC') then
      insert_data('MCR', fa.facility, fa.rownum, act.adjustment);
      insert_data('MPR', fa.facility, fa.rownum, act.reccount);
      insert_data('MGR', fa.facility, fa.rownum, act.weightadjustment);
    end if;
    
    if (act.trantype = 'SH') then
      insert_data('MCS', fa.facility, fa.rownum, act.adjustment);
      
      sp := null;
      open curShipPlates(act.orderid, act.shipid);
      fetch curShipPlates into sp;
      close curShipPlates;
      insert_data('MPS', fa.facility, fa.rownum, sp.palletcount * -1);

      insert_data('MGS', fa.facility, fa.rownum, act.weightadjustment);
    end if;
    
    if (act.trantype = 'AD') then
      insert_data('MCA', fa.facility, fa.rownum, act.adjustment);
      if (act.adjustment >= 0) then
        insert_data('MPA', fa.facility, fa.rownum, act.reccount);
      else
        insert_data('MPA', fa.facility, fa.rownum, act.reccount * -1);
      end if;
      insert_data('MGA', fa.facility, fa.rownum, act.weightadjustment);
    end if;
  end loop;

  for act in curActivity(fa.facility, lFirstOfYear, lEndDate)
  loop
    if (act.trantype = 'RC') then
      insert_data('YCR', fa.facility, fa.rownum, act.adjustment);
      insert_data('YPR', fa.facility, fa.rownum, act.reccount);
      insert_data('YGR', fa.facility, fa.rownum, act.weightadjustment);
    end if;
    
    if (act.trantype = 'SH') then
      insert_data('YCS', fa.facility, fa.rownum, act.adjustment);
      
      sp := null;
      open curShipPlates(act.orderid, act.shipid);
      fetch curShipPlates into sp;
      close curShipPlates;
      insert_data('YPS', fa.facility, fa.rownum, sp.palletcount * -1);

      insert_data('YGS', fa.facility, fa.rownum, act.weightadjustment);
    end if;
    
    if (act.trantype = 'AD') then
      insert_data('YCA', fa.facility, fa.rownum, act.adjustment);
      if (act.adjustment >= 0) then
        insert_data('YPA', fa.facility, fa.rownum, act.reccount);
      else
        insert_data('YPA', fa.facility, fa.rownum, act.reccount * -1);
      end if;
      insert_data('YGA', fa.facility, fa.rownum, act.weightadjustment);
    end if;
  end loop;
end loop;

open rba_cursor for
select *
  from revactivity
where sessionid = numSessionId;

end revactivityproc;
/

create or replace procedure revactivitycurrentproc
(rba_cursor IN OUT revactivitypkg.rba_type)
as
begin
  revactivityproc(rba_cursor, 'ALL', trunc(sysdate));
end revactivitycurrentproc;
/

show errors package revactivitypkg;
show errors package body revactivitypkg;
show errors procedure revactivityproc;
show errors procedure revactivitycurrentproc;
exit;
