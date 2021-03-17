--
-- $Id$
--
alter table customer add (
      QAAllowed      varchar2(1),
      QAHoldReceipt  varchar2(1)
);

update customer set
      QAAllowed = 'N',
      QAHoldReceipt = 'Y';

commit;

-- exit;
