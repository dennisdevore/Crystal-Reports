--
-- $Id$
--

alter table customer add
(
  carryover_unrcvd_qty_yn  char(1),
  carryover_unrcvd_qty_return_yn  char(1)
);

update customer
set carryover_unrcvd_qty_yn = 'N' 
where carryover_unrcvd_qty_yn is null;

update customer
set carryover_unrcvd_qty_return_yn = 'N' 
where carryover_unrcvd_qty_return_yn is null;

exit;
