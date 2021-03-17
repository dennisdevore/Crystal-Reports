--
-- $Id$
--
alter table customer add
(
   require_seal_verification    char(1),
   seal_passthrufield           varchar2(30)
);

update customer
   set require_seal_verification = 'N'
 where require_seal_verification is null;

exit;
