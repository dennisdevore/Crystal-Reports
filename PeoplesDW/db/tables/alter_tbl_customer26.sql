--
-- $Id$
--
alter table customer add
(
  ordshiprptfile varchar2(255),
  ordshipemail   varchar2(1) default 'N'
);

update customer
set ordshipemail = 'N';

commit;

--exit;
