--
-- $Id$
--
set serveroutput on
declare
   cursor c_desc is
      select *
         from gedesc
         order by item;
   cursor c_icv is
      select *
         from geicv
         order by item;
   selcnt integer := 0;
   updcnt integer := 0;
   rejcnt integer := 0;
   trncnt integer := 0;
begin
 	dbms_output.enable(1000000);

   for gd in c_desc loop
      selcnt := selcnt + 1;

      update custitem
         set descr = substr(gd.descr, 1, 40),
             lastuser = 'GECONV',
             lastupdate = sysdate
         where custid = '1GEMEM'
           and item = gd.item;

      if sql%rowcount = 0 then
         rejcnt := rejcnt + 1;
  	      dbms_output.put_line('Item: ' || gd.item || ' "' || gd.descr || '" NOT FOUND');
      elsif length(gd.descr) > 40 then
         trncnt := trncnt + 1;
  	      dbms_output.put_line('Item: ' || gd.item || ' "' || gd.descr || '" TRUNCATED');
      else
         updcnt := updcnt + 1;
      end if;
   end loop;
  	dbms_output.put_line('Selected: ' || selcnt);
  	dbms_output.put_line('Updated: ' || updcnt);
  	dbms_output.put_line('Truncated: ' || trncnt);
  	dbms_output.put_line('Rejected: ' || rejcnt);

   selcnt := 0;
   updcnt := 0;
   rejcnt := 0;
   for gi in c_icv loop
      selcnt := selcnt + 1;

      update custitem
         set useramt1 = gi.icv,
             lastuser = 'GECONV',
             lastupdate = sysdate
         where custid = '1GEMEM'
           and item = gi.item;

      if sql%rowcount = 0 then
         rejcnt := rejcnt + 1;
  	      dbms_output.put_line('Item: ' || gi.item || ' $' || gi.icv || ' NOT FOUND');
      else
         updcnt := updcnt + 1;
      end if;
   end loop;
  	dbms_output.put_line('Selected: ' || selcnt);
  	dbms_output.put_line('Updated: ' || updcnt);
  	dbms_output.put_line('Rejected: ' || rejcnt);

end;
/
