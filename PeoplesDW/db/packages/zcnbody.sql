create or replace package body alps.cn as
--
-- $Id$
--


procedure get_next_controlnumber(out_controlnumber    out varchar2,
                        out_message out varchar2) is
   cnt integer := 1;
   wk_controlnumber plate.controlnumber%type;
begin
   out_message := null;

   while (cnt = 1)
   loop
      select to_char(controlnumberseq.nextval)
         into wk_controlnumber
         from dual;
      select count(1)
        into cnt
        from plate
       where controlnumber = wk_controlnumber;
   end loop;
   out_controlnumber := wk_controlnumber;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_controlnumber;


end cn;
/
show error package body cn;
exit;
