--
-- $Id$
--
alter table invoicehdr add
(
 statususer     varchar2(12),
 statusupdate   date,
 invoicedate    date
)
modify(
 masterinvoice  varchar2(8)
);

exit;
