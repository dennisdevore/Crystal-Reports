CREATE OR REPLACE package TrialInvoicePkg
as type pc_type is ref cursor return pending_charges%rowtype;

PROCEDURE add_pending_charge(ID invoicedtl%rowtype);

----------------------------------------------------------------------
--
-- fake_daily_billing
--
----------------------------------------------------------------------
PROCEDURE fake_daily_billing(
    in_effdate  date
);

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
);

end TrialInvoicePkg;
/
