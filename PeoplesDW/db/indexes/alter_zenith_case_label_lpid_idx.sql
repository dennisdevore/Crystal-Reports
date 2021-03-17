--
-- $Id$
--
alter table zenith_case_labels drop constraint uk_zenith_case_labels;

drop index zenith_case_labels_lpid;

create index zenith_case_labels_lpid
   on zenith_case_labels(lpid);
exit;
