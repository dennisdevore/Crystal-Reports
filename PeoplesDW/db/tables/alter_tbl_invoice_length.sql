alter table invoicehdr modify (
  invoice number(12)
);

alter table invoicedtl modify (
  invoice number(12)
);

alter table invoiceorders modify (
  invoice number(12)
);