--
-- $Id$
--
alter table plate add
(
   fromlpid          varchar2(15),
   taskid            number(15),
   dropseq           number(5),
   fromshippinglpid  varchar2(15)
);

exit;
