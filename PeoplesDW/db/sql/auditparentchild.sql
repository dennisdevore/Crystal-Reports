--
-- $Id$
--
set serveroutput on;
set verify off;
declare
   l_tot pls_integer := 0;
   l_err pls_integer := 0;
   l_ok pls_integer := 0;
   l_bogus boolean;
   l_cnt pls_integer;
   l_itemcnt pls_integer;
   l_item plate.item%type;
   l_msg varchar2(255);
   l_update char(1) := upper('&1');
begin
   dbms_output.enable(1000000);

   dbms_output.put_line('checking single PA''s...');
   for lp in (select lpid, rowid, childfacility, childitem,
                     nvl(parentfacility,'<?>') as parentfacility,
                     nvl(parentitem,'<null>') as parentitem,
                     facility, item
               from plate
               where type = 'PA'
                 and parentlpid is null) loop

      l_tot := l_tot + 1;

      if (lp.childfacility is not null)
      or (lp.childitem is not null)
      or (lp.parentfacility != lp.facility)
      or (lp.parentitem != lp.item) then

         l_err := l_err + 1;

         dbms_output.put(lp.lpid||':');
         if lp.childfacility is not null then
            dbms_output.put(' childfacility='||lp.childfacility);
         end if;
         if lp.childitem is not null then
            dbms_output.put(' childitem='||lp.childitem);
         end if;
         if lp.parentfacility != lp.facility then
            if lp.parentfacility = '<?>' then
               dbms_output.put(' parentfacility=<null>');
            else
               dbms_output.put(' parentfacility='||lp.parentfacility);
            end if;
         end if;
         if lp.parentitem != lp.item then
            dbms_output.put(' parentitem='||lp.parentitem);
         end if;
         dbms_output.put_line('');

         if l_update = 'Y' then
            update plate
               set childfacility = null,
                   childitem = null,
                   parentfacility = lp.facility,
                   parentitem = lp.item
               where rowid = lp.rowid;
         end if;
      else
         l_ok := l_ok + 1;
      end if;
   end loop;

   dbms_output.put_line('Total: '||l_tot);
   dbms_output.put_line('OK: '||l_ok);
   dbms_output.put_line('Error: '||l_err);


   dbms_output.put_line('checking single MP''s and children...');
   l_tot := 0;
   l_err := 0;
   l_ok := 0;

   for mp in (select lpid, rowid, childfacility, childitem, parentfacility, parentitem
               from plate
               where type = 'MP') loop

      l_tot := l_tot + 1;
      l_bogus := false;

      if (mp.childfacility is not null) or (mp.childitem is not null) then

         l_bogus := true;
         dbms_output.put(mp.lpid||':');
         if mp.childfacility is not null then
            dbms_output.put(' childfacility='||mp.childfacility);
         end if;
         if mp.childitem is not null then
            dbms_output.put(' childitem='||mp.childitem);
         end if;
         dbms_output.put_line('');

         if l_update = 'Y' then
            update plate
               set childfacility = null,
                   childitem = null
               where rowid = mp.rowid;
         end if;
      end if;

      select count(distinct item) into l_itemcnt
         from plate
         where parentlpid = mp.lpid
           and type ='PA';

      if l_itemcnt = 0 then
         l_bogus := true;
         dbms_output.put_line(mp.lpid||' has no child plates');
         if l_update = 'Y' then
            l_msg := null;
            zlp.plate_to_deletedplate(mp.lpid, 'SYSTEM', null, l_msg);
            if l_msg is not null then
               dbms_output.put_line(mp.lpid||' delete error: '||l_msg);
            end if;
         end if;
      elsif (mp.parentfacility is null) and (mp.parentitem is null) then
--       should be mixed items

         if l_itemcnt = 1 then
            l_bogus := true;
            dbms_output.put_line('Mixed '||mp.lpid||' should be single');

            if l_update = 'Y' then
               select item into l_item
                  from plate
                  where parentlpid = mp.lpid
                    and rownum = 1;

               update plate
                  set parentfacility = facility,
                      parentitem = l_item
                  where rowid = mp.rowid;

               update plate
                  set childfacility = null,
                      childitem = null,
                      parentfacility = null,
                      parentitem = null
                  where parentlpid = mp.lpid;
            end if;
         else
            select count(1) into l_cnt
               from plate
               where parentlpid = mp.lpid
                 and type ='PA'
                 and (nvl(childfacility,'<?>') != facility
                   or nvl(childitem,'<null>') != item
                   or parentfacility is not null
                   or parentitem is not null);

            if l_cnt != 0 then
               l_bogus := true;
               dbms_output.put_line('Mixed '||mp.lpid||' has invalid children');

               if l_update = 'Y' then
                  update plate
                     set childfacility = facility,
                         childitem = item,
                         parentfacility = null,
                         parentitem = null
                     where parentlpid = mp.lpid;
               end if;
            end if;
         end if;

      elsif (mp.parentfacility is not null) and (mp.parentitem is not null) then
--       should be a single item

         if l_itemcnt != 1 then
            l_bogus := true;
            dbms_output.put_line('Single '||mp.lpid||' should be mixed');

            if l_update = 'Y' then
               update plate
                  set parentfacility = null,
                      parentitem = null
                  where rowid = mp.rowid;

               update plate
                  set childfacility = facility,
                      childitem = item,
                      parentfacility = null,
                      parentitem = null
                  where parentlpid = mp.lpid;
            end if;
         else
            select count(1) into l_cnt
               from plate
               where parentlpid = mp.lpid
                 and type ='PA'
                 and (childfacility is not null
                   or childitem is not null
                   or parentfacility is not null
                   or parentitem is not null);

            if l_cnt != 0 then
               l_bogus := true;
               dbms_output.put_line('Single '||mp.lpid||' has invalid children');

               if l_update = 'Y' then
                  update plate
                     set childfacility = null,
                         childitem = null,
                         parentfacility = null,
                         parentitem = null
                     where parentlpid = mp.lpid;
               end if;
            end if;
         end if;

      else
         l_bogus := true;
         dbms_output.put_line('Cannot fix '||mp.lpid
               ||': parentfacility='||nvl(mp.childfacility,'<null>')
               ||': parentitem='||nvl(mp.childitem,'<null>'));
      end if;

      if l_bogus then
         l_err := l_err + 1;
      else
         l_ok := l_ok +1;
      end if;

   end loop;

   dbms_output.put_line('Total: '||l_tot);
   dbms_output.put_line('OK: '||l_ok);
   dbms_output.put_line('Error: '||l_err);

exception when others then
   dbms_output.put_line('when others');
   dbms_output.put_line(sqlerrm);
end;
/
