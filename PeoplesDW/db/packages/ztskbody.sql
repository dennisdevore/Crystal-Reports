create or replace package body alps.ztaskutilities as
--
-- $Id$
--


procedure get_next_taskid(out_taskid  out number,
                          out_message out varchar2) is
   cnt integer := 1;
begin
   out_message := null;

   while (cnt = 1)
   loop
      select taskseq.nextval
         into out_taskid
         from dual;
      select count(1)
         into cnt
         from tasks
         where taskid = out_taskid;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_taskid;


end ztaskutilities;
/

exit;
