--drop index freight_bill_results_unique;

create unique index freight_bill_results_unique
   on freight_bill_results(loadno, stopno, freight_class, chargestype);

--drop index freight_bill_results_unique_ac;

create unique index freight_bill_results_unique_ac
   on freight_bill_results(loadno, stopno, freight_class, activitycode);
exit;