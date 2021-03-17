--drop index fuelsurchargedtl_unique;

create unique index fuelsurchargedtl_unique
   on fuelsurchargedtl(surchargeid,effdate);

exit;
