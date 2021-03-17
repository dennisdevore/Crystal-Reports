--
-- $Id$
--

alter table customer_aux add
(reduceorderqtybycancel char(1)
);

update customer_aux
set reduceorderqtybycancel='D'
where reduceorderqtybycancel is null;

commit;
exit;
