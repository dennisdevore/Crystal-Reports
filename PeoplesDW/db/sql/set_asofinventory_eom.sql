set serveroutput on
accept p_eom prompt 'Enter End OF Month (YYYYMMDD): '

declare
l_eom date;
errmsg varchar2(255);
begin

    l_eom := to_date('&p_eom','YYYYMMDD');

    if to_char(l_eom+1,'DD') != '01' then
        zut.prt('Not EOM date');
        return;
    end if;
    for cf in (select distinct facility, custid
                 from asofinventory)
    loop
--        zut.prt('Fac:'||cf.facility||' Cust:'||cf.custid);

-- Add the temp table information
        delete from asofeffdate_temp;

        insert into asofeffdate_temp
            select item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass,
                max(effdate)
              from asofinventory
             where facility = cf.facility
               and custid = cf.custid
               and effdate <= l_eom
            group by item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass;

        for ci in (
            SELECT item,lotnumber, uom, invstatus, inventoryclass, 
                    currentqty qty, currentweight weight
              FROM asofinventory A
             WHERE A.facility = cf.facility
               AND A.custid = cf.custid
               AND A.currentqty != 0
               AND (A.item, nvl(A.lotnumber,'(none)'), uom, invstatus, inventoryclass,
                A.effdate) in
                    (select item, lotnumber, uom, invstatus, inventoryclass,
                    effdate from asofeffdate_temp))
        loop
--            zut.prt('ASOF:'||cf.facility||'/'||cf.custid||'/'
--                ||ci.item||'/'||ci.lotnumber||'/'
--                ||ci.invstatus||'/'||ci.inventoryclass||' = '
--                ||ci.qty||' '||ci.weight);

            zbill.add_asof_inventory(
                cf.facility, cf.custid, ci.item, ci.lotnumber,ci.uom, l_eom,
                0,0, 'EOM Mark', 'EM', ci.inventoryclass, ci.invstatus,
                null, null, null, 'SYNAPSE', errmsg);

        end loop;

    end loop;

    insert into systemdefaults
    values('asofeomstart',to_char(l_eom, 'YYYYMMDD'), 'SYNAPSE',sysdate);

    zut.prt('EOM:'||l_eom);

-- Add EOM Marks as needed
--   l_eom := last_day(tr_effdate);
   l_eom := add_months(l_eom, 1);

   while (l_eom < trunc(sysdate))
   loop
        zut.prt('Set EOM:'||l_eom);
        zbill.set_asofinventory_eom(l_eom, 'SYSTEM',errmsg);
        l_eom := add_months(l_eom, 1);
   end loop;

end;
/
