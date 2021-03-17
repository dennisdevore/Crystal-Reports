--
-- $Id$
--
alter table customer add
(resubmitorder char(1)
,lastshipsum date
,lastrcptnote date
,lastshipnote date
,outrejectbatchmap varchar(255)
,outstatusbatchmap varchar(255)
,outshipsumbatchmap varchar2(255)
);
exit;
