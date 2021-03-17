drop table zinvsumdtrpt;

create table zinvsumdtrpt (
   sessionid      number,
   custid         varchar2(10),
   facility       varchar2(3),
   item           varchar2(50),
   descr          varchar2(255),
   lotnumber      varchar2(30),
   uom            varchar2(4),
   qty            number(16),
   weight         number(13,4),
   lastupdate     date
);


create index zinvsumdtrpt_sessionid_idx
   on zinvsumdtrpt(sessionid);

create index zinvsumdtrpt_lastupdate_idx
   on zinvsumdtrpt(lastupdate);


create or replace package zinvsumdtrptpkg
   as type isdr_type is ref cursor return zinvsumdtrpt%rowtype;
end zinvsumdtrptpkg;
/


create or replace procedure zinvsumdtrptproc
   (isdr_cursor in out zinvsumdtrptpkg.isdr_type,
    in_custid in varchar2,
    in_facility in varchar2,
    in_item in varchar2,
    in_inventoryclass in varchar2,
    in_date in date)
is
--
-- $Id: zinvsumdtrptobjects.sql 1139 2006-12-02 00:00:00Z eric $
--

cursor curFacility is
  select facility
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr
    from custitem
   where custid = in_custid
     and (in_item = 'ALL'
      or  item = in_item)
   order by item;
cci curCustItems%rowtype;

cursor curAsOfEndSearch(in_facility IN varchar, in_item IN varchar2) is
  select lotnumber, uom, sum(currentqty) as qty, sum(currentweight) as weight
    from  asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = aoi1.facility
                       and aoi2.custid = aoi1.custid
                       and aoi2.item = aoi1.item
                       and nvl(aoi2.lotnumber,'x') = nvl(aoi1.lotnumber, 'x')
                       and nvl(aoi2.invstatus,'x') = nvl(aoi1.invstatus, 'x')
                       and nvl(aoi2.inventoryclass,'x') = nvl(aoi1.inventoryclass,'x')
                       and aoi2.uom = aoi1.uom
                       and effdate <= in_date)
     and invstatus != 'SU'
     and (inventoryclass = in_inventoryclass
      or  in_inventoryclass = 'ALL')
   group by lotnumber, uom
   order by lotnumber, uom;
caoes curAsOfEndSearch%rowtype;

  l_sessionid number;
  
begin
  select sys_context('USERENV','SESSIONID')
    into l_sessionid
    from dual;

  delete from zinvsumdtrpt
   where sessionid = l_sessionid;
  commit;

  delete from zinvsumdtrpt
   where lastupdate < trunc(sysdate);
  commit;

  for cf in curFacility loop
    for cci in curCustItems loop
      for caoes in curAsOfEndSearch(cf.facility, cci.item) loop
        
        insert into zinvsumdtrpt values(l_sessionid, in_custid, cf.facility, cci.item, cci.descr,
                    caoes.lotnumber, caoes.uom, caoes.qty,	caoes.weight, sysdate);
      end loop;
      commit;
    end loop;
    commit;
  end loop;
  commit;

  open isdr_cursor for
     select *
        from zinvsumdtrpt
        where sessionid = l_sessionid
          and qty <> 0
        order by custid, facility, item, lotnumber, uom;

end zinvsumdtrptproc;
/

show errors package zinvsumdtrptpkg;
show errors procedure zinvsumdtrptproc;
exit;
