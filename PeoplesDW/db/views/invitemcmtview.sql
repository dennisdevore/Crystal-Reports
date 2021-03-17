create or replace view invitemcmt
(
idrowid,
invoice,
comment1
)
as
select ID.rowid,
       ID.invoice,
       ID.comment1
  from invoicedtl ID
 where ID.invoice is not null
   and ID.comment1 is not null;

comment on table invitemcmt is '$Id$';

create or replace view invitemcmtA
(
idrowid,
invoice,
comment1
)
as
select ID.rowid,
       ID.invoice,
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice)
  from invoicedtl ID
 where ID.invoice is not null
   and ID.comment1 is not null;

comment on table invitemcmtA is '$Id$';

exit;
