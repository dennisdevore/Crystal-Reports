--
-- $Id$
--

alter table consignee add
(facilitycode        varchar2(255)
,shiplabelcode       varchar2(255)
,retailabelcode      varchar2(255)
,packslipcode        varchar2(255)
,tpacct              varchar2(255)
,storenumber         varchar2(255)
,distctrnumber       varchar2(255)
,conspassthruchar01  varchar2(255)
,conspassthruchar02  varchar2(255)
,conspassthruchar03  varchar2(255)
,conspassthruchar04  varchar2(255)
,conspassthruchar05  varchar2(255)
,conspassthruchar06  varchar2(255)
,conspassthruchar07  varchar2(255)
,conspassthruchar08  varchar2(255)
,consorderupdate     char(1)
 );
exit;
