alter table custitem add
(
   allow_uom_chgs    char(1)
);

update custitem set allow_uom_chgs = 'N';

commit;

exit;
