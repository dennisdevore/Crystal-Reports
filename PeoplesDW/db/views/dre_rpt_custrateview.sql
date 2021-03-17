CREATE OR REPLACE VIEW DRE_RPT_CUSTRATEVIEW
(CUSTID, RATEGROUP, RATE, RATEGROUPDESCR, BILLMETHOD,
 BILLMETHODDESCR, ACTIVITY, ACTIVITYDESCR, UOM, UOMDESCR)
AS
select custrate.custid,
        custrate.rategroup,
        custrate.rate,
        custrategroup.descr,
        custrate.billmethod,
        billingmethod.descr,
        custrate.activity,
        activity.descr,
        custrate.uom,
        unitsofmeasure.descr
   from custrate,
        billingmethod,
        activity,
        custrategroup,
        unitsofmeasure
  where custrate.billmethod=billingmethod.code and
        custrate.activity=activity.code and
        custrate.custid=custrategroup.custid and
        custrate.rategroup=custrategroup.rategroup and
        (custrategroup.linkyn='N' or custrategroup.linkyn is null) and
        custrate.uom=unitsofmeasure.code (+)
union
 select custid,
        '',
        to_number(null),
        'Customer uses DEFAULT rates',
        '',
        '',
        '',
        '',
        '',
        ''
   from custrategroup
  where linkyn='Y' and
        custid<>'DEFAULT';

comment on table DRE_RPT_CUSTRATEVIEW is '$Id$';

exit;
