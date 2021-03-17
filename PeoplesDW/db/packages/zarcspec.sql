--
-- $Id$
--
CREATE OR REPLACE package      zarchive
as


function compareArchiveTable
(in_tablename IN varchar2) return char;

procedure creatArchiveTable
(in_tablename IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure dropArchiveTables
(out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (compareArchiveTable, WNDS, WNPS, RNPS);


end zarchive;
/
exit;
