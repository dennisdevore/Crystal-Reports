--drop index codchargesdtl_unique;

create unique index codchargesdtl_unique
   on codchargesdtl(codid,from_amount,to_amount);

exit;
