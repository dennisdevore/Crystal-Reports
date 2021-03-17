CREATE OR REPLACE package body TrialInvoicePkg
IS



PROCEDURE add_pending_charge(ID invoicedtl%rowtype)
IS  PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR C_ACT(in_ac varchar2)
IS
SELECT *
  FROM activity
 WHERE code = in_ac;

ACT activity%rowtype;

CURSOR C_BM(in_bm varchar2)
IS
SELECT *
  FROM billingmethod
 WHERE code = in_bm;

BM billingmethod%rowtype;

CURSOR C_CUST(in_custid varchar2)
IS
SELECT *
  FROM customer
 WHERE custid = in_custid;

CUST customer%rowtype;



BEGIN

    ACT := null;
    OPEN C_ACT(ID.activity);
    FETCH C_ACT into ACT;
    CLOSE C_ACT;

    BM := null;
    OPEN C_BM(ID.billmethod);
    FETCH C_BM into BM;
    CLOSE C_BM;

    CUST := null;
    OPEN C_CUST(ID.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;


    INSERT into pending_charges(
        facility,
        custid,
        custname,
        invoice,
        orderid,
        shipid,
        invtype,
        item,
        lotnumber,
        activity,
        activitydesc,
        activitydate,
        billmethod,
        billmethoddesc,
        qty,
        weight,
        uom,
        rate,
        amt,
        moduom,
        comment1,
        activitydatetime
    )
    VALUES
    (
        ID.facility,
        ID.custid,
        CUST.name,
        ID.invoice,
        ID.orderid,
        ID.shipid,
        ID.invtype,
        ID.item,
        ID.lotnumber,
        ID.activity,
        ACT.descr,
        trunc(ID.activitydate),
        ID.billmethod,
        BM.descr,
        ID.billedqty,
        ID.weight,
        ID.calceduom,
        ID.billedrate,
        ID.billedamt,
        ID.moduom,
        ID.comment1,
        ID.activitydate
    );


    commit;

EXCEPTION WHEN OTHERS THEN 
    null;
END add_pending_charge;


----------------------------------------------------------------------
--
-- fake_daily_billing
--
----------------------------------------------------------------------
PROCEDURE fake_daily_billing(
    in_effdate  date
)
IS
errmsg varchar2(100);
datime varchar2(10) := '0110';
nowtime varchar2(10);

da_job integer;

nowdt varchar2(20);

effdate     date;

CURSOR C_DBR
    IS 
select max(effdate)
  from daily_billing_run;

lastrun date;

rc integer;

BEGIN
    
    effdate := trunc(in_effdate);

    lastrun := null;

    if lastrun is null then
        lastrun := effdate - 1;
    end if;

    if lastrun >= effdate then
        return;
    end if;

    loop
        exit when lastrun >= effdate;

        lastrun := lastrun + 1;

        insert into daily_billing_run (effdate, start_dt, end_dt)
            values (lastrun, sysdate, null);


-- Run the daily renewal process
        rc := zbs.daily_renewal_process(lastrun, errmsg);
        if rc = zbill.BAD then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);

        end if; 


-- Reset the customer next billdates daily
/*
        for crec in (select custid from customer) loop
            zbill.set_custbilldates(
                crec.custid,
                'BillDaily',
                errmsg
            );
        end loop;
*/

-- Auto-Approve pending accessorials that have completed.
/*
        zba.approve_accessorials(lastrun, errmsg);
        if errmsg != 'OKAY' then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);

        end if;
*/


-- Do pallet and location dounts for them thats got em
        zbs.count_pallets_today(lastrun, 'BillDaily', errmsg);
        if errmsg != 'OKAY' then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);
        end if;

        update daily_billing_run 
           set end_dt = sysdate
         where effdate = lastrun;

    end loop;


END fake_daily_billing;

----------------------------------------------------------------------
--
-- fake_renewal
--
----------------------------------------------------------------------
PROCEDURE fake_renewal(
    in_effdate  date,
    in_enddate  date,
    in_facility varchar2,
    in_custid   varchar2,
    out_errmsg  OUT varchar2
)
IS

CURSOR C_CBD(in_custid varchar2)
IS
SELECT *
  FROM custbilldates
 WHERE custid = in_custid;

CBD custbilldates%rowtype;

cnt integer;
errmsg varchar2(300);
BEGIN

    cnt := 0;
    out_errmsg := '';

    loop

        CBD := null;
        OPEN C_CBD(in_custid);
        FETCH C_CBD into CBD;
        CLOSE C_CBD;


        exit when in_enddate < nvl(CBD.nextrenewal,in_enddate+1);

/*
        zut.prt('Calc renewal:'||in_facility
            ||'/'||in_custid
            ||'/'||CBD.nextrenewal);
*/

        update invoicehdr
           set invstatus = zbill.REVIEWED
         where facility = in_facility
           and custid = in_custid
           and invtype = 'S';


        if zbs.calc_customer_renewal(in_custid, in_facility, CBD.nextrenewal,
            'Y','TT',errmsg) != zbill.GOOD then
          zut.prt('CALCERR:'||errmsg);
          out_errmsg := errmsg;
        end if;

        update custbilldates
           set lastrenewal = nextrenewal
         where custid = in_custid;

        zbill.set_custbilldates(in_custid,'TT',errmsg);

        cnt := cnt + 1;
        exit when cnt >= 20;

    end loop;

EXCEPTION WHEN OTHERS THEN
    null;
    
END fake_renewal;




end TrialInvoicePkg;
/

exit;
