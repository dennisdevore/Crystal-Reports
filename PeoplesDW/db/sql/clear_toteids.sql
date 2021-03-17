set serveroutput on

declare
l_cnt integer;
begin

l_cnt := 10000;
loop
update shippingplate S
   set totelpid = null
 where totelpid is not null
   and status||'' = 'SH'
   and rownum <= l_cnt
   and exists (select 1 from orderhdr where orderid = S.orderid
    and shipid = S.shipid and orderstatus = '9');

exit when sql%rowcount < l_cnt;
zut.prt('Cleared '||sql%rowcount);
commit;
end loop;
zut.prt('Cleared '||sql%rowcount);
commit;

end;
/

