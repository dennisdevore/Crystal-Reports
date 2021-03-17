--
-- $Id: generate_xp.sql 6351 2011-03-28 15:02:17Z eric $
--

set serveroutput on
set verify off
accept p_lpid prompt 'Enter LPID: '
accept p_trackingno prompt 'Enter Tracking No: '

declare
  CURSOR C_SP
  IS
      select *
        from shippingplate
       where lpid = upper('&&p_lpid')
         and type in ('M','C')
         and fromlpid is null
         and status <> 'SH';

   l_lpid plate.lpid%type;

   errmsg varchar2(400);

begin

   dbms_output.enable(1000000);

   for csp in C_SP loop
      zrf.get_next_lpid(l_lpid, errmsg);
      
      insert into plate(lpid, custid, facility, type, parentlpid, lastoperator, lastuser, lastupdate)
      values(l_lpid, csp.custid, csp.facility, 'XP', csp.lpid, csp.lastuser, csp.lastuser, sysdate);

      update shippingplate
         set fromlpid = l_lpid,
              trackingno = upper('&&p_trackingno')
       where lpid = csp.lpid;
       
      update shippingplate
         set trackingno = upper('&&p_trackingno')
       where parentlpid = csp.lpid;
       
      zut.prt('Created XP ' || l_lpid);
   end loop;
end;
/
