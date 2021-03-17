--
-- $Id$
--
alter table customer add
(
  prelimbolrptfile     varchar2(255),
  print_prelim_at_rel varchar2(1) default 'N'
);

update customer
set print_prelim_at_rel = 'N';

commit;

--exit;
