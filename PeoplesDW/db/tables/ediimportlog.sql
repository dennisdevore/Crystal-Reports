--
-- $Id:ediimportlog.sql 1 2010-01286 12:20:03Z jeff $
--
create table ediimportlog
(
  created      timestamp         not null,
  transaction  varchar2(3),
  importfileid varchar2(255),
  custid       varchar2(10),
  msgtext      varchar2(255)
);
create index ediimportlog_created on
   ediimportlog(created);
exit;
