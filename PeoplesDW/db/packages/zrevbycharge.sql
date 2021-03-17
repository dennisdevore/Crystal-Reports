drop table revbychargerpt;

-- trantype column values:
--    AA-column headers
--    DT-Detail

create table revbychargerpt
(sessionid         number
,campus            varchar2(3)
,facility          varchar2(3)
,facilityname      varchar2(40)
,custid            varchar2(10)
,custname          varchar2(40)
,chargecode        varchar2(4)
,chargedescr       varchar2(32)
,campfaccust_total number(16,2)
,faccust_total     number(16,2)
,campus_total      number(16,2)
,facility_total    number(16,2)
,customer_total    number(16,2)
,report_total      number(16,2)
,campfaccust_mtd   number(16,2)
,faccust_mtd       number(16,2)
,campus_mtd        number(16,2)
,facility_mtd      number(16,2)
,customer_mtd      number(16,2)
,report_mtd        number(16,2)
,campfaccust_ytd   number(16,2)
,faccust_ytd       number(16,2)
,campus_ytd        number(16,2)
,facility_ytd      number(16,2)
,customer_ytd      number(16,2)
,report_ytd        number(16,2)
,lastupdate        date
);

create index revbychargerpt_sessionid_idx
 on revbychargerpt(sessionid);

create unique index revbychargerpt_campfaccust_idx
 on revbychargerpt(sessionid,campus,facility,custid,chargecode);

create index revbychargerpt_lastupdate_idx
 on revbychargerpt(lastupdate);

create or replace package revbychargerptpkg
as type rbc_type is ref cursor return revbychargerpt%rowtype;
end revbychargerptpkg;
/


create or replace procedure revbycampfaccustchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
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

cursor curInvoiceHdr(in_campus varchar2, in_facility varchar2, in_custid varchar2,
    in_begdate date, in_enddate date) is
  select id.activity, ac.descr, sum(nvl(billedamt,0)*decode(id.invtype,'C',-1,1)) billedamt, count(1) invcount
    from invoicehdr ih, invoicedtl id, activity ac
   where ih.postdate >= in_begdate
     and ih.postdate <  in_enddate
     and ih.invstatus = '3'
     and id.billstatus = '3'
     and id.invoice = ih.invoice
     and ac.code = id.activity
     and (ih.facility = in_facility
      or  in_facility = 'xxx')
     and (ih.custid = in_custid
      or  in_custid = 'xxx')
     and (in_campus = 'xxx'
      or  exists(select 1
                   from facility
                  where facility = ih.facility
                    and campus = in_campus))
   group by id.activity, ac.descr;
hdr curInvoiceHdr%rowtype;

numSessionId number;
begDate date;
endDate date;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revbychargerpt
where sessionid = numSessionId;
commit;

delete from revbychargerpt
where lastupdate < trunc(sysdate);
commit;

for fa in curFacility
loop
  for cu in curCustomer
  loop
    begDate := trunc(in_begdate);
    endDate := trunc(in_enddate)+1;
    for hdr in curInvoiceHdr(fa.campus, fa.facility, cu.custid, begDate, endDate)
    loop
      if((nvl(in_allcusts,'N') = 'Y') or (hdr.invcount > 0)) then
        begin
          insert into revbychargerpt(sessionid, campus, facility, facilityname,
            custid, custname, chargecode, chargedescr, campfaccust_total,
            faccust_total, campus_total, facility_total, customer_total,
            report_total, campfaccust_mtd, faccust_mtd, campus_mtd,
            facility_mtd, customer_mtd, report_mtd, campfaccust_ytd,
            faccust_ytd, campus_ytd, facility_ytd, customer_ytd,
            report_ytd, lastupdate)
          values(numSessionId, fa.campus, fa.facility, fa.name,
            cu.custid, cu.name, hdr.activity, hdr.descr, nvl(hdr.billedamt,0),
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, sysdate);
        exception
          when DUP_VAL_ON_INDEX then
            update revbychargerpt
               set campfaccust_total = nvl(campfaccust_total,0) + nvl(hdr.billedamt,0)
             where sessionid = numSessionId
               and campus = fa.campus
               and facility = fa.facility
               and custid = cu.custid
               and chargecode = hdr.activity;
        end;  
      end if;
    end loop;
    begDate := to_date(to_char(sysdate,'YYYYMM')||'01','YYYYMMDD');
    endDate := trunc(sysdate)+1;
    for hdr in curInvoiceHdr(fa.campus, fa.facility, cu.custid, begDate, endDate)
    loop
      if((nvl(in_allcusts,'N') = 'Y') or (hdr.invcount > 0)) then
        begin
          insert into revbychargerpt(sessionid, campus, facility, facilityname,
            custid, custname, chargecode, chargedescr, campfaccust_total,
            faccust_total, campus_total, facility_total, customer_total,
            report_total, campfaccust_mtd, faccust_mtd, campus_mtd,
            facility_mtd, customer_mtd, report_mtd, campfaccust_ytd,
            faccust_ytd, campus_ytd, facility_ytd, customer_ytd,
            report_ytd, lastupdate)
          values(numSessionId, fa.campus, fa.facility, fa.name,
            cu.custid, cu.name, hdr.activity, hdr.descr, 0,
            0, 0, 0, 0,
            0, nvl(hdr.billedamt,0), 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, sysdate);
        exception
          when DUP_VAL_ON_INDEX then
            update revbychargerpt
               set campfaccust_mtd = nvl(campfaccust_mtd,0) + nvl(hdr.billedamt,0)
             where sessionid = numSessionId
               and campus = fa.campus
               and facility = fa.facility
               and custid = cu.custid
               and chargecode = hdr.activity;
        end;  
      end if;
    end loop;
    begDate := to_date(to_char(sysdate,'YYYY')||'0101','YYYYMMDD');
    endDate := trunc(in_enddate)+1;
    for hdr in curInvoiceHdr(fa.campus, fa.facility, cu.custid, begDate, endDate)
    loop
      if((nvl(in_allcusts,'N') = 'Y') or (hdr.invcount > 0)) then
        begin
          insert into revbychargerpt(sessionid, campus, facility, facilityname,
            custid, custname, chargecode, chargedescr, campfaccust_total,
            faccust_total, campus_total, facility_total, customer_total,
            report_total, campfaccust_mtd, faccust_mtd, campus_mtd,
            facility_mtd, customer_mtd, report_mtd, campfaccust_ytd,
            faccust_ytd, campus_ytd, facility_ytd, customer_ytd,
            report_ytd, lastupdate)
          values(numSessionId, fa.campus, fa.facility, fa.name,
            cu.custid, cu.name, hdr.activity, hdr.descr, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, nvl(hdr.billedamt,0),
            0, 0, 0, 0,
            0, sysdate);
        exception
          when DUP_VAL_ON_INDEX then
            update revbychargerpt
               set campfaccust_ytd = nvl(campfaccust_ytd,0) + nvl(hdr.billedamt,0)
             where sessionid = numSessionId
               and campus = fa.campus
               and facility = fa.facility
               and custid = cu.custid
               and chargecode = hdr.activity;
        end;  
      end if;
    end loop;
  end loop;
end loop;

update revbychargerpt rbc
   set faccust_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility
              and custid = rbc.custid),0),
       campus_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbychargerpt
            where sessionid = numSessionId
              and campus = rbc.campus),0),
       facility_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility),0),
       customer_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbychargerpt
            where sessionid = numSessionId
              and custid = rbc.custid),0),
       report_total =
      nvl((select sum(nvl(campfaccust_total,0))
             from revbychargerpt
            where sessionid = numSessionId),0),
       faccust_mtd =
      nvl((select sum(nvl(campfaccust_mtd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility
              and custid = rbc.custid),0),
       campus_mtd =
      nvl((select sum(nvl(campfaccust_mtd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and campus = rbc.campus),0),
       facility_mtd =
      nvl((select sum(nvl(campfaccust_mtd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility),0),
       customer_mtd =
      nvl((select sum(nvl(campfaccust_mtd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and custid = rbc.custid),0),
       report_mtd =
      nvl((select sum(nvl(campfaccust_mtd,0))
             from revbychargerpt
            where sessionid = numSessionId),0),
       faccust_ytd =
      nvl((select sum(nvl(campfaccust_ytd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility
              and custid = rbc.custid),0),
       campus_ytd =
      nvl((select sum(nvl(campfaccust_ytd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and campus = rbc.campus),0),
       facility_ytd =
      nvl((select sum(nvl(campfaccust_ytd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and facility = rbc.facility),0),
       customer_ytd =
      nvl((select sum(nvl(campfaccust_ytd,0))
             from revbychargerpt
            where sessionid = numSessionId
              and custid = rbc.custid),0),
       report_ytd =
      nvl((select sum(nvl(campfaccust_ytd,0))
             from revbychargerpt
            where sessionid = numSessionId),0)
      where sessionid = numSessionId;
  
open rbc_cursor for
select *
  from revbychargerpt
where sessionid = numSessionId;

end revbycampfaccustchgrptproc;
/

create or replace procedure revbycampchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_campus IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, in_campus, 'ALL', 'ALL', in_begdate, in_enddate, 'N');
end revbycampchgrptproc;
/

create or replace procedure revbyfacchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, 'ALL', in_facility, 'ALL', in_begdate, in_enddate, 'N');
end revbyfacchgrptproc;
/

create or replace procedure revbyfacnocustchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, 'ALL', in_facility, '(none)', in_begdate, in_enddate, 'N');
end revbyfacnocustchgrptproc;
/

create or replace procedure revbyfaccustchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, 'ALL', in_facility, in_custid, in_begdate, in_enddate, 'N');
end revbyfaccustchgrptproc;
/

create or replace procedure revbycustchgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, 'ALL', 'ALL', in_custid, in_begdate, in_enddate, 'N');
end revbycustchgrptproc;
/

create or replace procedure revbydatechgrptproc
(rbc_cursor IN OUT revbychargerptpkg.rbc_type
,in_begdate IN date
,in_enddate IN date)
as
begin
  revbycampfaccustchgrptproc(rbc_cursor, '(none)', 'ALL', 'ALL', in_begdate, in_enddate, 'N');
end revbydatechgrptproc;
/

show errors package revbychargerptpkg;
show errors package body revbychargerptpkg;
show errors procedure revbycampfaccustchgrptproc;
show errors procedure revbycampchgrptproc;
show errors procedure revbyfacchgrptproc;
show errors procedure revbyfacnocustchgrptproc;
show errors procedure revbyfaccustchgrptproc;
show errors procedure revbycustchgrptproc;
show errors procedure revbydatechgrptproc;
exit;
