--
-- $Id$
--

create table import_plate_error (
   load_sequence     number(7),
   record_sequence   number(7),
   lpid              varchar2(15),
   item varchar2(50),
   custid            varchar2(10),
   facility          varchar2(3),
   location          varchar2(10),
   unitofmeasure     varchar2(4),
   quantity          number(7),
   comments          varchar2(160)
);
exit;
