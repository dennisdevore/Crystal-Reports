--
-- $Id$
--
alter table customer_aux add
(
   invbaserptemail   char(1),
   invmstrrptemail   char(1),
   invsummrptemail   char(1),
   invemailaddr      varchar2(255),
   rnewrptemail      char(1),
   rcptrptemail      char(1),
   miscrptemail      char(1),
   outbrptemail      char(1)
);

alter table customer_aux add
(
   invrcptemail      varchar2(255)
);

update customer_aux set invbaserptemail = 'N' where invbaserptemail is null;
update customer_aux set invmstrrptemail = 'N' where invmstrrptemail is null;
update customer_aux set invsummrptemail = 'N' where invsummrptemail is null;
update customer_aux set rnewrptemail = 'N' where rnewrptemail is null;
update customer_aux set rcptrptemail = 'N' where rcptrptemail is null;
update customer_aux set miscrptemail = 'N' where miscrptemail is null;
update customer_aux set outbrptemail = 'N' where outbrptemail is null;

exit;
