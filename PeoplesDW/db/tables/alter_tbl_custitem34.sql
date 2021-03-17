--
-- $Id$
--
alter table custitem add
(
   prtlps_on_load_arrival  char(1),
   prtlps_profid           varchar2(4),
   prtlps_def_handling     varchar2(4),
   prtlps_putaway_dir      char(1)
);

exit;
