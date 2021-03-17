--
-- $Id$
--
set serveroutput on
declare
   cursor c_itm is
      select *
         from custitem
         where custid = '1HAFOE'
           and status = 'ACTV';

   cursor c_sq10(p_item varchar2) is
      select rowid, custitemuom.*
         from custitemuom
         where custid = '1HAFOE'
           and item = p_item
           and sequence = 10;
   sq10 c_sq10%rowtype;

   cursor c_sq20(p_item varchar2) is
      select *
         from custitemuom
         where custid = '1HAFOE'
           and item = p_item
           and fromuom = 'CUIN'
           and sequence = 20;
   sq20 c_sq20%rowtype;

   cnt_item integer := 0;
   cnt_cube integer := 0;
   cnt_weight integer := 0;
begin
   dbms_output.enable(1000000);

   for itm in c_itm loop
      cnt_item := cnt_item + 1;
      open c_sq10(itm.item);
      fetch c_sq10 into sq10;
      if c_sq10%found then
         open c_sq20(itm.item);
         fetch c_sq20 into sq20;
         if c_sq20%found then
            sq10.cube := sq20.qty;
            cnt_cube := cnt_cube + 1;
         end if;
         close c_sq20;
         update custitemuom
            set weight = itm.weight * sq10.qty,
                cube = sq10.cube
            where rowid = sq10.rowid;
         cnt_weight := cnt_weight + 1;
      end if;
      close c_sq10;
   end loop;

   dbms_output.put_line('items = ' || cnt_item);
   dbms_output.put_line('weight = ' || cnt_weight);
   dbms_output.put_line('cube = ' || cnt_cube);
end;
/
