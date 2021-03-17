alter table customer_aux add(
        asnlineno            char(1)
);

update customer_aux
   set asnlineno  = 'N';

commit;
-- exit;