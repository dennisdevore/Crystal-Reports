--
-- $Id$
--
drop table impexp_request;

create table impexp_request(
   reqtype              varchar2(1),
   facility             varchar2(3),
   custid               varchar2(3),
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
   requested            date
);


create index impexp_request_requested
on impexp_request(requested,reqtype,formatid);


-- exit;
