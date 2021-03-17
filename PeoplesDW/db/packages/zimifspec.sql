--
-- $Id: zimifspec.sql
--
create or replace PACKAGE alps.zimportprocif

is

procedure begin_malvern_stage_carton
(in_custid IN varchar2
,in_filename IN varchar2
,in_datafield IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_malvern_stage_carton
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportprocif;
/
show error package zimportprocif;
exit;
