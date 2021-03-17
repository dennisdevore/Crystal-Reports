--
-- $Id$
--
alter table customer add
(
  shortreasonreqd  varchar2(1),
  latereasonreqd    varchar2(1),
  shiptimevariance number(7)
);

update customer
set shortreasonreqd = 'N',
latereasonreqd = 'N';

commit;
exit;


