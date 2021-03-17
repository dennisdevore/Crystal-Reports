CREATE OR REPLACE procedure TrialInvoiceProc
(aoi_cursor IN OUT TrialInvoicePkg.pc_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_type    IN varchar2)
IS

errmsg varchar2(300);

st_dt date;

l_type varchar2(100);
l_err varchar2(40) := '**** ERROR **** ERROR ****'||chr(13);
mark varchar2(200);
l_parms varchar2(100);
Begin

    l_parms := in_facility
            ||'/'||in_custid
            ||'/'||to_char(in_begdate,'YYYYMMDDHH24MISS')
            ||'/'||to_char(in_enddate,'YYYYMMDDHH24MISS')
            ||'/'||in_type;

    mark := 'Start';
-- Remove old pending charges just in case

    delete from pending_charges;

    l_type := in_type;

-- Check parameters and report error if applicable
    if in_facility is null then
        insert into pending_charges(invtype,comment1)
        values('E',l_err
            ||'A facility parameter is required');
        l_type := 'E';
        goto create_cursor;
    end if;
    if in_begdate is null then
        insert into pending_charges(invtype,comment1)
        values('E',l_err
                ||'A begin date parameter is required');
        l_type := 'E';
        goto create_cursor;
    end if;
    if in_enddate is null then
        insert into pending_charges(invtype,comment1)
        values('E',l_err
                ||'An end date parameter is required');
        l_type := 'E';
        goto create_cursor;
    end if;

    mark := 'Passed Checks';

    savepoint zero_trans;

-- Update the charges for the '0' charges
    for cd in (select rowid
                 from invoicedtl
                where billstatus = '0'
                  and facility = in_facility
                  and in_begdate <= activitydate
                  and in_enddate >= activitydate
                  and 0 < instr(','||nvl(in_custid,custid)||',',
                        ','||custid||','))
    loop
        if zbill.calculate_detail_rate(cd.rowid, trunc(sysdate), errmsg)
            != zbill.GOOD then
            zut.prt('Error:'||errmsg);
        end if;

    end loop;

    mark := 'After Calc 0 charges';

-- For each date in the future run the daily billing
    st_dt := trunc(sysdate) + 1;

    if instr(nvl(in_type,'SSS'),'S') > 0 then
      loop
        exit when st_dt > in_enddate;

        trialinvoicepkg.fake_daily_billing(st_dt);

        st_dt := st_dt + 1;

      end loop;

    mark := 'After Fake Daily Billing';

-- For any custids in the facility do the renewals when do and fake
--  the printing and posting

      for cc in (select distinct custid
                 from asofinventory
                where facility = in_facility)
      loop

        mark := 'CC:'||cc.custid;
        if instr(','||nvl(in_custid,cc.custid)||',',
                ','||cc.custid||',') > 0 then
            mark := 'FR:'||st_dt||'/'||in_enddate||'/'||in_facility
                ||'/'||cc.custid;
            trialinvoicepkg.fake_renewal(st_dt, in_enddate, in_facility, 
                cc.custid, errmsg);
            mark := 'FA:'||st_dt||'/'||in_enddate||'/'||in_facility
                ||'/'||cc.custid||' Msg:'||errmsg;
        end if;
      end loop;

    end if;

    mark := 'After Fake Renewal';

-- Update the charges for the '0' charges
    for cd in (select rowid
                 from invoicedtl
                where billstatus = '0'
                  and facility = in_facility
                  and in_begdate <= activitydate
                  and in_enddate >= activitydate
                  and 0 < instr(','||nvl(in_custid,custid)||',',
                        ','||custid||','))
    loop
        if zbill.calculate_detail_rate(cd.rowid, trunc(sysdate), errmsg)
            != zbill.GOOD then
            zut.prt('Error:'||errmsg);
        end if;

    end loop;

    mark := 'After Calc Detal Rates 2';

-- Add the '0' and '1' charges to the pending_charges table
    for cd in (select *
                 from invoicedtl
                where billstatus in ('1')
                  and facility = in_facility
                  and in_begdate <= activitydate
                  and in_enddate >= activitydate
                  and 0 < instr(','||nvl(in_custid,custid)||',',
                        ','||custid||','))
    loop

        

        trialinvoicepkg.add_pending_charge(cd);

    end loop;

    mark := 'After Add pending charges';

/*
    for ci in (select *
                 from invoicehdr
                where invtype = 'S')
    loop

        zut.prt('Invoice:'||ci.invoice||' Dt:'||ci.renewfromdate||'-'
                ||ci.renewtodate);

    end loop;

*/


    rollback to zero_trans;

    mark := 'Before create cursor';

<<create_cursor>>

    open aoi_cursor for
    select *
      from pending_charges
     where 0 < instr(invtype,nvl(l_type,invtype));

EXCEPTION WHEN OTHERS THEN
    errmsg := sqlerrm;
    rollback;

    insert into pending_charges(invtype,comment1)
    values('E',l_err
            ||errmsg||chr(13)||mark||chr(13)||l_parms);
    l_type := 'E';
    open aoi_cursor for
    select *
      from pending_charges
     where 0 < instr(invtype,nvl(l_type,invtype));


End TrialInvoiceProc;
/
