create table labor_projections
(facility					varchar2(3)
,custid						varchar2(10)
,manhours_yesterday			number(17,4)
,orders_yesterday			number(12,0)
,manhours_last7				number(17,4)
,orders_last7				number(12,0)
,manhours_last30			number(17,4)
,orders_last30				number(12,0)
,manhours_proj_yesterday 	number(17,4)
,manhours_proj_last7		number(17,4)
,manhours_proj_last30		number(17,4)
,orders_tomorrow			number(12,0)
,cur_date_used				date
);

create index labor_projections_idx
 on labor_projections(facility,custid);


exit;
