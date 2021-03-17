--
-- $Id$
--

create table import_item_baseuom_error (
   load_sequence     number(7),
   record_sequence   number(7),
   custid            varchar2(10),
   item varchar2(50),
   comments          varchar2(160)
);
exit;
