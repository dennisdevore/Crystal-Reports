alter table customer add
(
   freight_billing_interface    char(1),
   fbi_passthrufield            varchar2(30),
   fbi_value                    varchar2(20)
);

update customer
   set freight_billing_interface = 'N'
 where freight_billing_interface is null;

exit;
