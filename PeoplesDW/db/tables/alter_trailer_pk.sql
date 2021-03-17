alter table trailer drop constraint pk_trailer;
alter table trailer modify trailer_number not null;
alter table trailer modify carrier not null;
create unique index pk_trailer on trailer(carrier,trailer_number);
exit;
