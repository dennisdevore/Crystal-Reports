create table storage_profitability
(facility					varchar2(3)
,custid						varchar2(10)
,renewal_storage_revenue	number(15,2)
,receipt_storage_revenue	number(15,2)
,total_storage_revenue		number(15,2)
,full_location_sqft			number(17,4)
,partial_location_sqft		number(17,4)
,total_location_sqft		number(17,4)
,gross_location_sqft		number(17,4)
,gross_cost_sqft			number(17,4)
,storage_profit				number(17,4)
,time_period_from			date
,time_period_thru			date
,space_utilization_pct		number(3,0)
,cost_per_sqft				number(9,2)
);

create index storage_profitability_idx
 on storage_profitability(facility,custid);


exit;
