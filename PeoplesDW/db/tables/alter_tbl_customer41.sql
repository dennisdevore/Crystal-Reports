--
-- $Id$
--
alter table customer add
(
   prtlps_on_load_arrival  char(1) default 'N',
   prtlps_profid           varchar2(4),
   prtlps_def_handling     varchar2(4),
   prtlps_putaway_dir      char(1)
);

exit;
