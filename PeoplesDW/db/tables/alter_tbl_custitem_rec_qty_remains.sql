alter table customer_aux add
(rec_qty_remains char(1)
);

update customer_aux
   set rec_qty_remains = 'N'
 where rec_qty_remains is null;

alter table custproductgroup add
(rec_qty_remains char(1)
);

update custproductgroup
   set rec_qty_remains = 'C'
 where rec_qty_remains is null;

alter table custitem add
(rec_qty_remains char(1)
);

update custitem
   set rec_qty_remains = 'C'
 where rec_qty_remains is null;


exit;
