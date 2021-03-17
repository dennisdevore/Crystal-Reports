--
-- $Id$
--
create table impexp_log(
   logseq               integer not null,
   reqtype              varchar2(1),
   facility             varchar2(3),
   custid               varchar2(15),
   formatid             varchar2(35),
   filepath             varchar2(255),
   when_to              varchar2(255),
   loadno               number(7),
   orderid              number(9),
   shipid               number(2),
   userid               varchar2(12),
   tablename            varchar2(35),
   columnname           varchar2(35),
   filtercolumnname     varchar2(35),
   company              varchar2(4),
   warehouse            varchar2(4),
   begindatetimestr     varchar2(35),
   enddatetimestr       varchar2(35),
   requested            timestamp,
   ie_instance          varchar2(255),
   ie_start             timestamp,
   ie_finish            timestamp,
   rerequested          char(1)
);

create unique index impexp_log_unique
on impexp_log(logseq);

create index impexp_log_requested
on impexp_log(requested);

create index impexp_log_rerequest
on impexp_log(ie_instance, requested, ie_finish, rerequested);



-- exit;
