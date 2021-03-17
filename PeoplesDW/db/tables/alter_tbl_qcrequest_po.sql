--
-- $Id: alter_tbl_qcrequest_po.sql 1 2005-05-26 12:20:03Z ed $
--
alter table qcrequest add
(
  po varchar2(20)
);

alter table qcrequest add
(
  qa_by_po_item char(1) default 'N'
);

alter table qcrequest modify
(
  facility varchar2(3) null
);

alter table qcrequest add
(
  putaway_before_inspection_yn char(1) default 'N',
  putaway_after_inspection_yn char(1) default 'N'
);

alter table qcrequest drop column inspectrouting;

exit;
