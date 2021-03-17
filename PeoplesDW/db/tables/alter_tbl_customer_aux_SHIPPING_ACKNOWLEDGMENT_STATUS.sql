alter table customer_aux add(
        SHIPPING_ACKNOWLEDGMENT_STATUS            char(1)
);

update customer_aux
   set SHIPPING_ACKNOWLEDGMENT_STATUS  = 'S'
 where SHIPPING_ACKNOWLEDGMENT_STATUS is null;

commit;
exit;
