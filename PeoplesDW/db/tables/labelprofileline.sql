--
-- $Id$
--
drop table labelprofileline;

create table labelprofileline
(
   profid            varchar2(4) not null,
   businessevent     varchar2(4) not null,
   uom               varchar2(4),
   seq               number(3) not null,
   printerstock      varchar2(1) not null,
   copies            number(4) not null,
   print             varchar2(1) not null,
   apply             varchar2(1) not null,
   rfline1           varchar2(20),
   rfline2           varchar2(20),
   rfline3           varchar2(20),
   rfline4           varchar2(20),
   scfpath           varchar2(255) not null,
   viewname          varchar2(30) not null,
   viewkeycol        varchar2(30) not null,
   viewkeyorigin     varchar2(1) not null,
   facility          varchar2(3),
   station           varchar2(10),
   prtid             varchar2(5),
   lastuser          varchar2(12),
   lastupdate        date
);

exit;
