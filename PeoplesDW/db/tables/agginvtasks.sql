--
-- $Id$
--
drop table agginvtasks;

create table agginvtasks (
   shippinglpid varchar2(15) not null,
   lpid         varchar2(15),
   qty          number(7) not null
);

exit;
