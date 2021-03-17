--drop index tariffbreaks_unique;

create unique index tariffbreaks_unique
   on tariffbreaks(tariff,from_weight,to_weight);
  
--drop index tariffbreaks_abbrev;

create unique index tariffbreaks_abbrev
   on tariffbreaks(tariff,abbrev);

exit;
