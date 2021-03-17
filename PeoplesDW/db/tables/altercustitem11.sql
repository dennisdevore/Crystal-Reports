--
-- $Id$
--
alter table custitem
add
(primaryhazardclass varchar2(12)
,secondaryhazardclass varchar2(12)
,primarychemcode varchar2(12)
,secondarychemcode varchar2(12)
,tertiarychemcode varchar2(12)
);
--exit;
