--
-- $Id$
--
create or replace package alps.zpurge
as

procedure do_purge
(out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure retention_update
(in_old_tablename IN varchar2
,in_old_rule1field IN varchar2
,in_old_rule1operator IN varchar2
,in_old_rule1value IN varchar2
,in_old_rule2field IN varchar2
,in_old_rule2operator IN varchar2
,in_old_rule2value IN varchar2
,in_old_rule3field IN varchar2
,in_old_rule3operator IN varchar2
,in_old_rule3value IN varchar2
,in_new_tablename IN varchar2
,in_new_rule1field IN varchar2
,in_new_rule1operator IN varchar2
,in_new_rule1value IN varchar2
,in_new_rule2field IN varchar2
,in_new_rule2operator IN varchar2
,in_new_rule2value IN varchar2
,in_new_rule3field IN varchar2
,in_new_rule3operator IN varchar2
,in_new_rule3value IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

function item_purgable
(in_custid varchar2
,in_item varchar2
) return number;

function custid_purgable
(in_custid varchar2
) return number;

function xp_plate_purgable
(in_parentlpid varchar2
) return number;

PRAGMA RESTRICT_REFERENCES (item_purgable, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custid_purgable, WNDS, WNPS, RNPS);
end zpurge;
/

--exit;

