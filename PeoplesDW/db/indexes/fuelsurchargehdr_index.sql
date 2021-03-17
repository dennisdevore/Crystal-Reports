--drop index fuelsurchargehdr_unique;

create unique index fuelsurchargehdr_unique
   on fuelsurchargehdr(surchargeid);

exit;
