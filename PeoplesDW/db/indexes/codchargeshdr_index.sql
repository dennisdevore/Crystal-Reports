--drop index codchargeshdr_unique;

create unique index codchargeshdr_unique
   on codchargeshdr(codid);

exit;