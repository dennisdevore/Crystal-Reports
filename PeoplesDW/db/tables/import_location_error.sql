--
-- $Id$
--

create table import_location_error (
   load_sequence     number(7),
   record_sequence   number(7),
   locid             varchar2(10),
   facility          varchar2(3),
   comments          varchar2(160)
);
exit;
