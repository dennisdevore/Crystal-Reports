--
-- $Id: oodailyloads.sql 7079 2011-08-02 18:42:26Z ed $
--
create table oodailyloads
(
   capturedate    date,
   facility       varchar2(3) not null,
   custid         varchar2(10) not null,
   loadno         number(7),
   loadtype       char(1),
   constraint pk_oodailyloads
      primary key (capturedate, facility, custid, loadno, loadtype))
organization index;

exit;
