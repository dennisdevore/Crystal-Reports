--
-- $Id$
--
create or replace PACKAGE alps.zplate
IS

FUNCTION platestatus_abbrev
(in_platestatus IN varchar2
) return varchar2;

FUNCTION invstatus_abbrev
(in_invstatus IN varchar2
) return varchar2;

FUNCTION handlingtype_abbrev
(in_handlingtype IN varchar2
) return varchar2;

FUNCTION inventoryclass_abbrev
(in_inventoryclass IN varchar2
) return varchar2;

FUNCTION platetype_abbrev
(in_platetype IN varchar2
) return varchar2;

FUNCTION condition_abbrev
(in_condition IN varchar2
) return varchar2;

FUNCTION holdreason_abbrev
(in_holdreason IN varchar2
) return varchar2;

FUNCTION adjreason_abbrev
(in_adjreason IN varchar2
) return varchar2;

FUNCTION tasktype_abbrev
(in_tasktype IN varchar2
) return varchar2;

FUNCTION expiryaction_abbrev
(in_expiryaction IN varchar2
) return varchar2;

PROCEDURE plate_to_deletedplate
(in_lpid IN varchar2
,in_userid IN varchar2
,in_tasktype IN varchar2
,out_msg IN OUT varchar2
);

FUNCTION shippingplatestatus_abbrev
(in_shippingplatestatus IN varchar2
) return varchar2;

FUNCTION shippingplatetype_abbrev
(in_shippingplatetype IN varchar2
) return varchar2;

FUNCTION phyinv_difference
(in_status IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_location IN varchar2
,in_systemcount IN number
,in_countcustid IN varchar2
,in_countitem IN varchar2
,in_countlot IN varchar2
,in_countlocation IN varchar2
,in_usercount IN number
) return varchar2;

FUNCTION is_lpid
(in_lpid IN varchar2
) return boolean;

PRAGMA RESTRICT_REFERENCES (platestatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (invstatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (handlingtype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (inventoryclass_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (platetype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (condition_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (holdreason_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (adjreason_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (tasktype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (expiryaction_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shippingplatestatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shippingplatetype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (phyinv_difference, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_lpid, WNDS, WNPS, RNPS);

END zplate;
/
exit;
