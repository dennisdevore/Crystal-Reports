--
-- $Id$
--
create or replace PACKAGE alps.zrate
IS

FUNCTION handling_abbrev
(in_handling IN varchar2
) return varchar2;

FUNCTION activity_abbrev
(in_activity IN varchar2
) return varchar2;

FUNCTION rategroup_abbrev
(in_custid IN varchar2
,in_rategroup IN varchar2
) return varchar2;

FUNCTION rategroup_descr
(in_custid IN varchar2
,in_rategroup IN varchar2
) return varchar2;

FUNCTION billmethod_abbrev
(in_billmethod IN varchar2
) return varchar2;

PROCEDURE rate_change
(in_custid varchar2
,in_rategroup varchar2
,in_effdate date
,in_activity varchar2
,in_billmethod varchar2
,in_userid varchar2
,in_new_effdate date
,in_new_rate number
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (handling_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (activity_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (rategroup_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (rategroup_descr, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (billmethod_abbrev, WNDS, WNPS, RNPS);

END zrate;
/
exit;
