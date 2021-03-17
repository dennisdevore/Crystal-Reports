--
-- $Id$
--
alter table cartontypes
add
(typeorgroup char(1)
);
alter table cartontypes modify (length number(10,4) null);
alter table cartontypes modify (width number(10,4) null);
alter table cartontypes modify (height number(10,4) null);
alter table cartontypes modify (maxweight number(10,4) null);
alter table cartontypes modify (maxcube number(10,4) null);
exit;
