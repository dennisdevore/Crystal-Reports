--drop index tariff_unique;

create unique index tariff_unique
   on tariff(tariff);

exit;