--
-- $Id$
--
alter table waves add
(openfacility varchar2(3)
);
update waves
   set openfacility = facility
 where wavestatus < '4';
exit;
