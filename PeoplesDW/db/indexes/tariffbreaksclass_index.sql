--drop index tariffbreaksclass_unique;

create unique index tariffbreaksclass_unique
   on tariffbreaksclass(tariff,from_weight,to_weight,freight_class);
 
 exit;
