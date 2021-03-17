--
-- $Id$
--
alter table putawayprofline add
(
   putaway_during_picking_ok  varchar2(1)
);

update putawayprofline
   set putaway_during_picking_ok = 'Y'
   where putaway_during_picking_ok is null;

exit;
