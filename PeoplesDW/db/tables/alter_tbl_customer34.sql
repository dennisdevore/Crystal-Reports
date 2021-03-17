--
-- $Id$
--
alter table customer add(
        MasterReceiptLimits     char(1)
);
update customer set masterreceiptlimits = 'N';
commit;

exit;
