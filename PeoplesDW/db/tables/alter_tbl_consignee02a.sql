--
-- $Id: $
--

alter table consignee add
(facilitycode        varchar2(255)
,shiplabelcode       varchar2(255)
,retailabelcode      varchar2(255)
,packslipcode        varchar2(255)
,tpacct              varchar2(255)
,storenumber         varchar2(255)
,distctrnumber       varchar2(255)
,consorderupdate     char(1)
 );
exit;
