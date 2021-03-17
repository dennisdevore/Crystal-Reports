create table pimevents
(
  pim_id           varchar2(38),
  parentid         varchar2(38),
  eventtype        number(1),
  starttime        date,
  finishtime       date,
  options          number(7),
  caption          varchar2(255),
  recurindex       number(8),
  recurinfo        blob default empty_blob(),
  facility         varchar2(3),
  message          varchar2(255),
  state            number(4),
  lblcolor         number(10),
  closed           char(1),
  resourceid       varchar2(5),
  loadno           number(7),
  ordershipid      varchar2(12),
  customer         varchar(10),
  carrier          varchar2(4),
  trailer          varchar2(12),
  reference        varchar2(20),
  po               varchar2(20),
  syncid           varchar2(255),  
  lastuser         varchar2(12),
  lastupdate       date
);

create unique index pimevents_start on pimevents(pim_id, starttime);

