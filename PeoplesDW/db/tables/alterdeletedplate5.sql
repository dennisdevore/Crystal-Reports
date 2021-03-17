--
-- $Id$
--
alter table deletedplate add
(
   workorderseq		number(8),
   workordersubseq	number(8)
);

exit;
