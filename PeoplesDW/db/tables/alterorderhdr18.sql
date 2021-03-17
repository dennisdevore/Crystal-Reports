--
-- $Id$
--
/*add logic to save old data */

update orderhdr set cancel_id = null
where cancel_id is not null;
commit;

alter table orderhdr modify
(cancel_id varchar2(30));
exit;
