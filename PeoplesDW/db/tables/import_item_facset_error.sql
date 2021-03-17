--
-- $Id$
--

create table import_item_facset_error (
   load_sequence     number(7),
   record_sequence   number(7),
   custid            varchar2(10),
   item varchar2(50),
   facility          varchar2(3),
   comments          varchar2(160)
);
exit;


