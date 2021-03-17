--
-- $Id$
--
update customer
set resubmitorder = 'N',
    lastshipsum = sysdate,
    lastrcptnote = sysdate,
    lastshipnote = sysdate
where resubmitorder is null;
commit;
exit;

