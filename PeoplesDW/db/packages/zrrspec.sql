create or replace package alps.report_request as

function facility_where_clause
(in_userid       IN varchar2
,in_column_names IN varchar2 -- comma-delimited list of column names
) return varchar2;

function custid_where_clause
(in_userid       IN varchar2
,in_column_names IN varchar2 -- comma-delimited list of column names
) return varchar2;

function orderlookup_where_clause
(in_userid     IN varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (facility_where_clause, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custid_where_clause, WNDS, WNPS, RNPS);
--PRAGMA RESTRICT_REFERENCES (orderlookup_where_clause, WNDS, WNPS, RNPS);

end report_request;
/
show errors package report_request;
exit;
