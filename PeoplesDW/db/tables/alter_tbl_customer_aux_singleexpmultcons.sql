alter table customer_aux add(
        singleexpmultcons    char(1)
);

update customer_aux
   set singleexpmultcons  = 'N'
   where singleexpmultcons is null;

commit;
-- exit;