create or replace package body alps.zbuildmap as
--
-- $Id$
--


procedure build_map(in_facility in varchar2,
                    in_userid   in varchar2,
                    out_msg     in out varchar2) is
   cursor c_sects is
      select sectionid, sectionn, sectionne, sectione, sectionse,
             sections, sectionsw, sectionw, sectionnw
         from section
         where facility = in_facility;
   adj c_sects%rowtype;
   sid section.sectionid%type;
   srchstr sectionsearch.searchstr%type;
   i integer;
   fnd boolean;
begin
   zms.log_msg('BuildMap', in_facility, '', 'Begin section search map build',
         'I', in_userid, out_msg);

   delete from sectionsearch
      where facility = in_facility;

   for me in c_sects loop
      -- srchstr := rpad(me.sectionid, 10) || '<>';
      srchstr := '|'||rpad(me.sectionid,10)||'|';
      i := 2;
      loop
         fnd := FALSE;

         begin
            select sectionid, sectionn, sectionne, sectione, sectionse,
                   sections, sectionsw, sectionw, sectionnw
            into adj
            from section
            where facility = in_facility
              and rpad(sectionid, 10) = substr(srchstr, i, 10);
         exception
            when NO_DATA_FOUND then
               rollback;
               zms.log_msg('BuildMap', in_facility, '',
                     'Building section ' || me.sectionid ||
                     ': Cannot find adjacent section ' || substr(srchstr, i, 10),
                     'E', in_userid, out_msg);
               commit;

               zut.prt('BuildMap for '|| in_facility|| ' '||
                     'Building section ' || me.sectionid ||
                     ': Cannot find adjacent section '
                     || substr(srchstr, i, 10));
               zut.prt(' So far i='||to_char(i)||' srchstr='||srchstr);

               out_msg := 'Map NOT rebuilt - see appmsgs for details';
               return;
         end;

         if 0 = instr(srchstr, rpad(adj.sectionn, 10)) then
            srchstr := srchstr || rpad(adj.sectionn, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectionne, 10)) then
            srchstr := srchstr || rpad(adj.sectionne, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectione, 10)) then
            srchstr := srchstr || rpad(adj.sectione, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectionse, 10)) then
            srchstr := srchstr || rpad(adj.sectionse, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sections, 10)) then
            srchstr := srchstr || rpad(adj.sections, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectionsw, 10)) then
            srchstr := srchstr || rpad(adj.sectionsw, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectionw, 10)) then
            srchstr := srchstr || rpad(adj.sectionw, 10) || '|';
            fnd := TRUE;
         end if;
         if 0 = instr(srchstr, rpad(adj.sectionnw, 10)) then
            srchstr := srchstr || rpad(adj.sectionnw, 10) || '|';
            fnd := TRUE;
         end if;

         i := i + 11;
         -- exit loop if we are at the end
         if fnd then
            exit when i > 3900;
         else
            exit when i >= length(srchstr);
         end if;
      end loop;

      insert
         into sectionsearch values (me.sectionid, in_facility, srchstr);
   end loop;

   zms.log_msg('BuildMap', in_facility, '',
      'Successful end of section search map build.',
      'I', in_userid, out_msg);
   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end build_map;


end zbuildmap;
/
exit;
