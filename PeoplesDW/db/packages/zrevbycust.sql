drop table revbycustrpt;

-- trantype column values:
--    AA-column headers
--    DT-Detail

create table revbycustrpt
(sessionid         number
,campus            varchar2(3)
,facility          varchar2(3)
,facilityname      varchar2(40)
,custid            varchar2(10)
,custname          varchar2(40)
,campfaccust_total number(16,2)
,faccust_total     number(16,2)
,campus_total      number(16,2)
,facility_total    number(16,2)
,customer_total    number(16,2)
,report_total      number(16,2)
,lastupdate        date
);

create index revbycustrpt_sessionid_idx
 on revbycustrpt(sessionid);

create unique index revbycustrpt_campfaccust_idx
 on revbycustrpt(sessionid,campus,facility,custid);

create index revbycustrpt_lastupdate_idx
 on revbycustrpt(lastupdate);

create or replace package revbycustrptpkg
as type rbc_type is ref cursor return revbycustrpt%rowtype;
end revbycustrptpkg;
/


create or replace procedure revbycampfaccustrptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_campus IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_allcusts IN varchar2)
as
--
-- $Id:$
--

cursor curFacility is
  select nvl(campus,'xxx') campus, facility, name
    from facility
   where (facility = upper(in_facility)
      or upper(in_facility) = 'ALL')
     and (campus = upper(in_campus)
      or upper(in_campus) = 'ALL')
   union 
  select nvl(campus,'xxx') campus, 'xxx' facility, '(none)' name
    from facility
   where (campus = upper(in_campus)
      or upper(in_campus) = 'ALL')
     and in_facility = '(none)'
   union 
  select 'xxx' campus, facility, name
    from facility
   where in_campus = '(none)'
     and (facility = upper(in_facility)
      or upper(in_facility) = 'ALL')
   union 
  select 'xxx' campus, 'xxx' facility, '(none)' name
    from dual
   where in_campus = '(none)'
     and in_facility = '(none)';
fa curFacility%rowtype;

cursor curCustomer is
  select custid, name
    from customer
   where custid = upper(in_custid)
      or upper(in_custid) = 'ALL'
   union
  select 'xxx' custid, '(none)' name
    from dual
   where in_custid = '(none)';
cu curCustomer%rowtype;

cursor curInvoiceHdr(in_campus varchar2, in_facility varchar2, in_custid varchar2) is
  select sum(nvl(billedamt,0)*decode(id.invtype,'C',-1,1)) billedamt, count(1) invcount
    from invoicehdr ih, invoicedtl id
   where ih.postdate >= trunc(in_begdate)
     and ih.postdate <  trunc(in_enddate)+1
     and ih.invstatus = '3'
     and id.billstatus = '3'
     and id.invoice = ih.invoice
     and (ih.facility = in_facility
      or  in_facility = 'xxx')
     and (ih.custid = in_custid
      or  in_custid = 'xxx')
     and (in_campus = 'xxx'
      or  exists(select 1
                   from facility
                  where facility = ih.facility
                    and campus = in_campus));

numSessionId number;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revbycustrpt
where sessionid = numSessionId;
commit;

delete from revbycustrpt
where lastupdate < trunc(sysdate);
commit;

for fa in curFacility
loop
  for cu in curCustomer
  loop
    for hdr in curInvoiceHdr(fa.campus, fa.facility, cu.custid)
    loop
      if((nvl(in_allcusts,'N') = 'Y') or (hdr.invcount > 0)) then
        begin
          insert into revbycustrpt(sessionid, campus, facility, facilityname,
            custid, custname, campfaccust_total, faccust_total, campus_total,
            facility_total, customer_total, report_total, lastupdate)
          values(numSessionId, fa.campus, fa.facility, fa.name,
            cu.custid, cu.name, nvl(hdr.billedamt,0), 0, 0,
            0, 0, 0, sysdate);
        exception
          when DUP_VAL_ON_INDEX then
            update revbycustrpt
               set campfaccust_total = nvl(campfaccust_total,0) + nvl(hdr.billedamt,0)
             where sessionid = numSessionId
               and campus = fa.campus
               and facility = fa.facility
               and custid = cu.custid;
        end;  
      end if;
    end loop;
  end loop;
end loop;

update revbycustrpt rbc
   set faccust_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbycustrpt
            where sessionid = numSessionId
              and facility = rbc.facility
              and custid = rbc.custid),0),
       campus_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbycustrpt
            where sessionid = numSessionId
              and campus = rbc.campus),0),
       facility_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbycustrpt
            where sessionid = numSessionId
              and facility = rbc.facility),0),
       customer_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbycustrpt
            where sessionid = numSessionId
              and custid = rbc.custid),0),
       report_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbycustrpt
            where sessionid = numSessionId),0)
      where sessionid = numSessionId;
  
open rbc_cursor for
select *
  from revbycustrpt
where sessionid = numSessionId;

end revbycampfaccustrptproc;
/

create or replace procedure revbycamprptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_campus IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustrptproc(rbc_cursor, in_campus, 'ALL', 'ALL', in_begdate, in_enddate, 'N');
end revbycamprptproc;
/

create or replace procedure revbyfacrptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustrptproc(rbc_cursor, 'ALL', in_facility, 'ALL', in_begdate, in_enddate, 'N');
end revbyfacrptproc;
/

create or replace procedure revbyfaccustrptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustrptproc(rbc_cursor, 'ALL', in_facility, in_custid, in_begdate, in_enddate, 'N');
end revbyfaccustrptproc;
/

create or replace procedure revbycustrptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustrptproc(rbc_cursor, 'ALL', 'ALL', in_custid, in_begdate, in_enddate, 'N');
end revbycustrptproc;
/

create or replace procedure revbydaterptproc
(rbc_cursor IN OUT revbycustrptpkg.rbc_type
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustrptproc(rbc_cursor, '(none)', 'ALL', 'ALL', in_begdate, in_enddate, 'N');
end revbydaterptproc;
/

show errors package revbycustrptpkg;
show errors package body revbycustrptpkg;
show errors procedure revbycampfaccustrptproc;
show errors procedure revbycamprptproc;
show errors procedure revbyfacrptproc;
show errors procedure revbyfaccustrptproc;
show errors procedure revbycustrptproc;
show errors procedure revbydaterptproc;
exit;
