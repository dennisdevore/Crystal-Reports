alter table trailer modify trailer_number not null;
alter table trailer modify carrier not null;
alter table trailer_notes modify carrier not null;
alter table trailer_history modify carrier not null;
exit;
