--
-- $Id$
--
alter table location modify
(pickingseq number(7),
 putawayseq number(7));

alter table tasks modify (locseq number(7));

alter table subtasks modify (locseq number(7));

alter table batchtasks modify (locseq number(7));

exit;

