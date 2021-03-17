--
-- $Id$
--
alter table custitem add
(
   pallet_qty              number(7),
   pallet_uom              varchar2(4),
   limit_pallet_to_qty_yn  char(1) default 'N'
);

exit;
