create table handling_profitability
(facility					varchar2(3)
,custid						varchar2(10)
,outbound_handling_revenue	number(15,2)
,receipt_handling_revenue	number(15,2)
,total_handling_revenue		number(15,2)
,handling_manhours			number(17,4)
,handling_equiphours		number(17,4)
,handling_labor_cost		number(17,4)
,handling_equip_cost		number(17,4)
,handling_total_cost		number(17,4)
,handling_profit			number(17,4)
,labor_cost_per_hr			number(10,2)
,equipment_cost_per_hr		number(10,2)
,time_period_from			date
,time_period_thru			date
);

create index handling_profitability_idx
 on handling_profitability(facility,custid);


exit;
