create or replace PACKAGE alps.zlaborprojection
IS

PROCEDURE calc_labor_projection
(in_facility varchar2
,in_custid varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE calc_labor_projection_dt
(in_facility varchar2
,in_custid varchar2
,in_cur_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

END zlaborprojection;
/
exit;
