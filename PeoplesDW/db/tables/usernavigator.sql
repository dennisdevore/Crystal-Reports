create table usernavigator
(
  nameid     varchar2(12) not null,
  navid      varchar2(32) not null,
  actcount   number(3),
  navdata    blob default empty_blob(), 
  lastuser   varchar2(12) null,
  lastupdate date         null 
);

alter table alps.usernavigator add (
  constraint usernavigator_pk
 primary key
 (nameid, navid));
