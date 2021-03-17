--
-- $Id$
--
set serveroutput on
set verify off
accept p_facility prompt 'Enter facility: '
accept p_custid prompt 'Enter custid: '

declare

  CURSOR C_FACILITY(in_facility varchar2)
  IS
      select facility
        from facility
       where facility = in_facility;
  fac C_FACILITY%rowtype;
  
  CURSOR C_CUSTOMER(in_custid varchar2)
  IS
      select custid
        from customer
       where custid = in_custid;
  cu C_CUSTOMER%rowtype;
  
  CURSOR C_ACTIVITY(in_facility varchar2, in_custid varchar2)
  IS
      select lpid
        from plate pl
       where facility=in_facility
         and custid=in_custid
         and exists(select 1
                      from platehistory
                     where lpid=pl.lpid
                       and rownum=1)
       union
      select lpid
        from deletedplate pl
       where facility=in_facility
         and custid=in_custid
         and exists(select 1
                      from platehistory
                     where lpid=pl.lpid
                       and rownum=1);
  act C_ACTIVITY%rowtype;
          
  CURSOR C_PLATES(in_facility varchar2, in_custid varchar2)
  IS
      select 1 recordtype, pl.lpid, pl.rowid
        from plate pl
       where pl.facility = in_facility
         and pl.custid = in_custid
       union
      select 2 recordtype, pl.lpid, pl.rowid
        from deletedplate pl
       where pl.facility = in_facility
         and pl.custid = in_custid;
  pl C_PLATES%rowtype;
          
  cntTot integer;
  errmsg varchar2(400);

begin

   dbms_output.enable(1000000);

   fac := null;
   OPEN C_FACILITY(upper('&&p_facility'));
   FETCH C_FACILITY into fac;
   CLOSE C_FACILITY;
   
   if (fac.facility is null) then
      zut.prt('Invalid facility: ' || upper('&&p_facility'));
      return;
   end if;

   cu := null;
   OPEN C_CUSTOMER(upper('&&p_custid'));
   FETCH C_CUSTOMER into cu;
   CLOSE C_CUSTOMER;

   if (cu.custid is null) then
      zut.prt('Invalid custid: ' || upper('&&p_custid'));
      return;
   end if;

   act := null;
   OPEN C_ACTIVITY(fac.facility, cu.custid);
   FETCH C_ACTIVITY into act;
   CLOSE C_ACTIVITY;
   
   if (act.lpid is not null) then
      zut.prt('Activity exists for customer ' || cu.custid || ' in facility ' || fac.facility);
      return;
   end if;

   pl := null;
   OPEN C_PLATES(fac.facility, cu.custid);
   FETCH C_PLATES into pl;
   CLOSE C_PLATES;
   
   if (pl.lpid is null) then
      zut.prt('No plates exist for customer ' || cu.custid || ' in facility ' || fac.facility);
      return;
   end if;

   cntTot := 0;
   for pl in C_PLATES(fac.facility, cu.custid)
   loop
   
     cntTot := cntTot + 1;

     if pl.recordtype = 1 then
       delete
         from plate
        where rowid = pl.rowid;
     else
       delete
         from deletedplate
        where rowid = pl.rowid;
     end if;
        
     delete
       from platehistory
      where lpid = pl.lpid;
   end loop;
   
   zut.prt('Successfully deleted '||cntTot||' plate records');

   zms.log_msg('CUSTOMEX', fac.facility, cu.custid,
      'Successfully deleted '||cntTot||' plate records', 'I', 'SYNAPSE', errmsg);

   commit;

end;
/
exit;