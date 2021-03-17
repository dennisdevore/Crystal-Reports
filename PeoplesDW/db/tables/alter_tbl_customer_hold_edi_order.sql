--
-- $Id: alter_tbl_customer_hold_edi_order.sql 1955 2007-05-16 19:33:01Z ed $
--
alter table customer_aux add
(
 hold_edi_order_yn char(1)
);

update customer_aux
set hold_edi_order_yn = 'N'
where hold_edi_order_yn is null;

commit;

exit;
