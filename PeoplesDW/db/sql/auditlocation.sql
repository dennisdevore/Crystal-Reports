--
-- $Id$
--

set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool auditlocation.out

declare

   cursor c_loc is
      select facility, locid, status, nvl(lpcount, 0) lpcount, rowid, loctype
         from location
			where status != 'O'
         order by facility, locid;

   here integer;
   coming integer;
   updflag varchar2(1);
   l_facility facility.facility%type;
   l_tot pls_integer;
   l_err pls_integer;
   l_oky pls_integer;

begin

   updflag := upper('&&1');
   l_facility := 'xxx';
   l_tot := 0;
   l_err := 0;
   l_oky := 0;

   dbms_output.enable(1000000);
   dbms_output.put_line('Begin location audit');

   for l in c_loc
   loop
      l_tot := l_tot + 1;
      select count(1) into here
         from plate
         where facility = l.facility
           and location = l.locid
           and type = 'PA';
      select count(1) into coming
         from plate
         where destfacility = l.facility
           and destlocation = l.locid
           and type = 'PA';

      if (l.lpcount != (here + coming)) then
         dbms_output.put_line(l.facility || '.' || l.locid || '.' || l.loctype
               || ' invalid count : lpcount='
               || l.lpcount || ' here=' || here || ' coming=' || coming || ' calc lpcount=' || (here + coming));
         l_err := l_err + 1;
         if (updflag = 'Y') then
            update location
               set lpcount = (here + coming),
                   status = decode(status, 'O', 'O',decode((here + coming), 0, 'E', 'I'))
               where rowid = l.rowid;
            commit;
         end if;
      elsif ((l.status = 'E') and (l.lpcount != 0 or (here + coming) != 0)) then
         dbms_output.put_line(l.facility || '.' || l.locid || '.' || l.loctype
               || ' should NOT be empty: lpcount='
               || l.lpcount || ' here=' || here || ' coming=' || coming);
         l_err := l_err + 1;
         if (updflag = 'Y') then
            update location
               set status = 'I'
               where rowid = l.rowid
                 and status != 'O';
            commit;
         end if;
      elsif ((l.status = 'I') and (l.lpcount = 0 or (here + coming) = 0)) then
         dbms_output.put_line(l.facility || '.' || l.locid || '.' || l.loctype
               || ' should BE empty: lpcount='
               || l.lpcount || ' here=' || here || ' coming=' || coming);
         l_err := l_err + 1;
         if (updflag = 'Y') then
            update location
               set status = 'E'
               where rowid = l.rowid
                 and status != 'O';
            commit;
         end if;
      else
        l_oky := l_oky + 1;
      end if;
   end loop;

   dbms_output.put_line('total ' || l_tot);
   dbms_output.put_line('okay  ' || l_oky);
   dbms_output.put_line('error ' || l_err);
   dbms_output.put_line('End location audit');

end;
/
exit;

