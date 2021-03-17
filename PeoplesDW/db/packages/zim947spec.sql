--
-- $Id: zim7spec.sql 2540 2008-02-02 14:42:00Z jeff $
--
CREATE OR REPLACE PACKAGE Zimportproc947

IS

procedure begin_invadj947std_susp
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PROCEDURE end_invadj947std_susp
(in_custid IN VARCHAR2
,in_viewsuffix IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT VARCHAR2
);

procedure begin_invadj947std
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_rowid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PROCEDURE end_invadj947std
(in_custid IN VARCHAR2
,in_viewsuffix IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT VARCHAR2
);

procedure begin_952
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_952
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
END Zimportproc947;
/

show error package zimportproc947;
exit;
