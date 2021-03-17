--
-- $Id$
--
create or replace package alps.zuser
is

procedure drop_user
(in_dropuserid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2);

procedure get_setting
(in_userid IN varchar2
,in_groupid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
,out_setting IN OUT varchar2
);

function user_setting
(in_userid IN varchar2
,in_groupid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (user_setting, WNDS, WNPS, RNPS);

function user_form_setting
(in_userid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (user_form_setting, WNDS, WNPS, RNPS);

function blenderize_user
(in_u1 in varchar2
,in_u2 in varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (blenderize_user, WNDS, WNPS, RNPS);

procedure upsert_setting
(in_nameid in varchar2
,in_formid in varchar2
,in_facility in varchar2
,in_setting in varchar2
,in_userid in varchar2
,out_msg IN OUT varchar2);

function max_begtime
(in_userid in varchar2
) return date;

PRAGMA RESTRICT_REFERENCES (max_begtime, WNDS, WNPS, RNPS);

function max_endtime
(in_userid in varchar2
) return date;

PRAGMA RESTRICT_REFERENCES (max_endtime, WNDS, WNPS, RNPS);

procedure close_user_events (
  in_userid in varchar2,
  in_event in varchar2
);

end zuser;
/
exit;
