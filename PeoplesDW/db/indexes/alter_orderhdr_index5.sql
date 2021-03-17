--
-- $Id$
--
drop index orderhdr_dateshipped_idx;

create index orderhdr_dateshipped_idx
on orderhdr(dateshipped);

drop index orderhdr_entrydate_idx;

create index orderhdr_entrydate_idx
on orderhdr(entrydate);

drop index orderhdr_statusupdate_idx;

create index orderhdr_statusupdate_idx
on orderhdr(statusupdate);

drop index orderhdr_arrivaldate_idx;

create index orderhdr_arrivaldate_idx
on orderhdr(arrivaldate);

drop index orderhdr_edicancelpending_idx;

create index orderhdr_edicancelpending_idx
on orderhdr(edicancelpending);

exit;

