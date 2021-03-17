create or replace PACKAGE alps.zprofitability
IS

PROCEDURE calc_storage_profitability
(in_facility varchar2
,in_custid varchar2
,in_cost_per_sqft number
,in_space_utilization_pct number default 60
,in_number_of_days number  default 30
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE calc_storage_profitability_dt
(in_facility varchar2
,in_custid varchar2
,in_cost_per_sqft number
,in_space_utilization_pct number default 60
,in_from_date varchar2
,in_thru_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE calc_handling_profitability
(in_facility varchar2
,in_custid varchar2
,in_labor_cost_per_hr number  default 20
,in_equipment_cost_per_hr number  default 15
,in_number_of_days number  default 30
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE calc_handling_profitability_dt
(in_facility varchar2
,in_custid varchar2
,in_labor_cost_per_hr number  default 20
,in_equipment_cost_per_hr number  default 15
,in_from_date varchar2
,in_thru_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

END zprofitability;
/
exit;
