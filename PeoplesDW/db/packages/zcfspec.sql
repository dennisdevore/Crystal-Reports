--
-- $Id$
--
create or replace package alps.zcreatefuncs
is

procedure create_func
(in_custid in varchar2
,in_funcname in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure drop_func
(in_custid in varchar2
,in_funcname in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

function profid
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2;

function allocrule
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2;

function replallocrule
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2;

function group_profid
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2;

function group_allocrule
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2;

function group_replallocrule
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (profid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (allocrule, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (replallocrule, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (group_profid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (group_allocrule, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (group_replallocrule, WNDS, WNPS, RNPS);

end zcreatefuncs;
/
--exit;
