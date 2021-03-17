--drop index tariffaccessorials_unique;

create unique index tariffaccessorials_unique
   on tariffaccessorials(tariff,activitycode);
   
exit;
