--
-- $Id: trailer_constraint_changes.sql 7782 2012-01-12 12:20:17Z brianb $
--


delete from trailer where carrier is null;
commit;

alter table trailer drop constraint pk_trailer;

drop index pk_trailer; -- required in 11g test database, doesn't seem to be in 10g.

delete from trailer
where carrier is not null or trailer_number is not null;

alter table trailer modify carrier not null;
alter table trailer modify trailer_number not null;

alter table trailer add
  constraint pk_trailer
 primary key
 (carrier, trailer_number);

alter table trailer_history drop constraint pk_trailer_history;

drop index pk_trailer_history;

delete from trailer_history where carrier is null;
alter table trailer_history modify carrier not null;

commit;

alter table trailer_history add constraint pk_trailer_history
 primary key(carrier, trailer_number, activity_time, activity_type);

alter table trailer_notes drop constraint pk_trailer_notes;

drop index PK_TRAILER_NOTES;

alter table trailer_notes add (carrier varchar2(4) not null);
alter table trailer_notes modify (carrier not null);

delete from trailer_notes where trailer_number not in (select trailer_number from trailer);
update trailer_notes tn set carrier = (select carrier from trailer where trailer_number = tn.trailer_number);
commit;

alter table trailer_notes add constraint pk_trailer_notes
 primary key(carrier, trailer_number, note_added, lastuser);

exit;

