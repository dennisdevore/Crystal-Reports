--
-- $Id$
--

alter table batchtasks modify
(
   touserid    varchar2(12),
   curruserid  varchar2(12)
);

alter table subtasks modify
(
   touserid    varchar2(12),
   curruserid  varchar2(12)
);

alter table tasks modify
(
   touserid    varchar2(12),
   curruserid  varchar2(12)
);

exit;
