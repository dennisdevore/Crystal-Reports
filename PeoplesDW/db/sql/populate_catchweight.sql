set serveroutput on

truncate table custitemlotcatchweight;

declare
   l_msg varchar2(255) := 'OKAY';
begin
   dbms_output.enable(1000000);

   for cwt in (select PL.facility, PL.custid, PL.item, PL.lotnumber,
                      sum(PL.weight) as weight
                  from plate PL, custitemview CI
                  where PL.type = 'PA'
                    and CI.custid = PL.custid
                    and CI.item = PL.item
                    and CI.use_catch_weights = 'Y'
                  group by PL.facility, PL.custid, PL.item, PL.lotnumber) loop
      zcwt.add_item_lot_catch_weight(cwt.facility, cwt.custid, cwt.item,
            cwt.lotnumber, cwt.weight, l_msg);
      if l_msg != 'OKAY' then
         dbms_output.put_line(cwt.facility||'/'||cwt.custid||'/'||cwt.item
               ||'/'||cwt.lotnumber||'/'||cwt.weight||': '||l_msg);
         rollback;
         exit;
      end if;
   end loop;

   if l_msg = 'OKAY' then
      commit;
   end if;
end;
/



