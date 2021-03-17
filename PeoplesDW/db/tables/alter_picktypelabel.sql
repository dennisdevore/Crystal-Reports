alter table picktypelabel drop constraint pk_picktypelabel;
alter table picktypelabel modify code not null;
alter table picktypelabel modify descr not null;
alter table picktypelabel modify abbrev not null;
alter table picktypelabel add constraint pk_picktypelabel
primary key (code) using index picktypelabel_idx;
alter table shipshortreasons drop constraint pk_shipshortreasons;
alter table shipshortreasons modify code not null;
alter table shipshortreasons modify descr not null;
alter table shipshortreasons modify abbrev not null;
alter table shipshortreasons add constraint pk_shipshortreasons
primary key (code) using index shipshortreasons_idx;
exit;
