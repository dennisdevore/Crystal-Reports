--
-- $Id$
--
alter table customer
add
(bolfax char(1)
,bolemail char(1)
);
update customer
set bolfax = 'N',
    bolemail = 'N'
where bolfax is null;
commit;
exit;

