--
-- $Id$
--
create table impexp_log_detail(
   logseq               integer not null,
   created              timestamp,
   logtext              varchar2(255)
);

create unique index impexp_log_detail_unique
on impexp_log_detail(logseq, created, logtext);

exit;
