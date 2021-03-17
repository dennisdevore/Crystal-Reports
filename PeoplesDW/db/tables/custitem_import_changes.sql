create table custitem_import_changes
(
  lastupdate    timestamp            not null,
  custid        varchar2(10)         not null,
  item          varchar2(20)         not null,
  msgtext       varchar2(255),
  importfileid  varchar2(255)
);


create index cic_lastupdate on custitem_import_changes
(lastupdate, custid, item);



