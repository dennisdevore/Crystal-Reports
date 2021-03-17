create or replace PACKAGE BODY alps.zlaborprojection
IS

PROCEDURE calc_labor_projection
(in_facility varchar2
,in_custid varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10);

BEGIN

out_errorno := 0;
out_msg := 'Okay';

select to_char(sysdate, 'YYYY-MM-DD') into v_cur_date from dual;

calc_labor_projection_dt(in_facility, in_custid, v_cur_date, out_errorno, out_msg);

END calc_labor_projection;

PROCEDURE calc_labor_projection_dt
(in_facility varchar2
,in_custid varchar2
,in_cur_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10) := in_cur_date;
v_prv_date varchar2(10);
v_prv_date7 varchar2(10);
v_prv_date30 varchar2(10);
v_tomorrow varchar2(10);
v_dt date;

v_orders_yesterday labor_projections.orders_yesterday%type := 0;
v_orders_last7 labor_projections.orders_last7%type := 0;
v_orders_last30 labor_projections.orders_last30%type := 0;
v_orders_tomorrow labor_projections.orders_tomorrow%type := 0;

v_manhours_yesterday labor_projections.manhours_yesterday%type := 0.0;
v_manhours_last7 labor_projections.manhours_last7%type := 0.0;
v_manhours_last30 labor_projections.manhours_last30%type := 0.0;

v_manhours_proj_yesterday labor_projections.manhours_yesterday%type := 0.0;
v_manhours_proj_last7 labor_projections.manhours_last7%type := 0.0;
v_manhours_proj_last30 labor_projections.manhours_last30%type := 0.0;


BEGIN

out_errorno := 0;
out_msg := 'Okay';

v_dt := to_date(in_cur_date, 'YYYY-MM-DD');

select to_char(v_dt + 1, 'YYYY-MM-DD') into v_tomorrow from dual;
select to_char(v_dt - 1, 'YYYY-MM-DD') into v_prv_date from dual;
select to_char(v_dt - 7, 'YYYY-MM-DD') into v_prv_date7 from dual;
select to_char(v_dt - 30, 'YYYY-MM-DD') into v_prv_date30 from dual;

-- Calc Order Counts for Yesterday, tomorrow, last 7 days, and last 30 days
BEGIN
  select count(distinct(orderid)) into v_orders_yesterday
	 from orderhdrview
	where ordertype = 'O'
	  and fromfacility = in_facility
	  and custid = in_custid
	  and to_char(dateshipped, 'YYYY-MM-DD') = v_prv_date;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_orders_yesterday := 0;
END;	
BEGIN
  select count(distinct(orderid)) into v_orders_tomorrow
	 from orderhdrview
	where ordertype = 'O'
	  and fromfacility = in_facility
	  and custid = in_custid
	  and to_char(dateshipped, 'YYYY-MM-DD') = v_tomorrow;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_orders_tomorrow := 0;
END;	
BEGIN
  select count(distinct(orderid)) into v_orders_last7
	 from orderhdrview
	where ordertype = 'O'
	  and fromfacility = in_facility
	  and custid = in_custid
	  and to_char(dateshipped, 'YYYY-MM-DD') <= v_prv_date
	  and to_char(dateshipped, 'YYYY-MM-DD') >= v_prv_date7;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_orders_last7 := 0;
END;	
BEGIN
  select count(distinct(orderid)) into v_orders_last30
	 from orderhdrview
	where ordertype = 'O'
	  and fromfacility = in_facility
	  and custid = in_custid
	  and to_char(dateshipped, 'YYYY-MM-DD') <= v_prv_date
	  and to_char(dateshipped, 'YYYY-MM-DD') >= v_prv_date30;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_orders_last30 := 0;
END;	

-- Calc Manhours for Yesterday, last 7 days, and last 30 days
BEGIN
  select sum((lav.task_time / 60) / 60) into v_manhours_yesterday
  from laboractivityview lav, orderhdrview ohv
   where lav.facility = in_facility
     and lav.custid = in_custid
     and lav.order_id = ohv.orderid and lav.ship_id = ohv.shipid
	 and ohv.ordertype = 'O'
     and to_char(lav.beg_time, 'YYYY-MM-DD') = v_prv_date;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_manhours_yesterday := 0.0;
END;	
BEGIN
  select sum((lav.task_time / 60) / 60) into v_manhours_last7
  from laboractivityview lav, orderhdrview ohv
   where lav.facility = in_facility
     and lav.custid = in_custid
     and lav.order_id = ohv.orderid and lav.ship_id = ohv.shipid
	 and ohv.ordertype = 'O'
     and to_char(lav.beg_time, 'YYYY-MM-DD') <= v_prv_date
     and to_char(lav.beg_time, 'YYYY-MM-DD') >= v_prv_date7;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_manhours_last7 := 0.0;
END;	
BEGIN
  select sum((lav.task_time / 60) / 60) into v_manhours_last30
    from laboractivityview lav, orderhdrview ohv
   where lav.facility = in_facility
     and lav.custid = in_custid
     and lav.order_id = ohv.orderid and lav.ship_id = ohv.shipid
	 and ohv.ordertype = 'O'
     and to_char(lav.beg_time, 'YYYY-MM-DD') <= v_prv_date
     and to_char(lav.beg_time, 'YYYY-MM-DD') >= v_prv_date30;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_manhours_last30 := 0.0;
END;	

-- Calculate the Manhour Projections for Tomorrow based on yesterday, last 7, and last 30 days
v_manhours_proj_yesterday := (v_manhours_yesterday / v_orders_yesterday) * v_orders_tomorrow;
v_manhours_proj_last7 := (v_manhours_last7 / v_orders_last7) * v_orders_tomorrow;
v_manhours_proj_last30 := (v_manhours_last30 / v_orders_last30) * v_orders_tomorrow;

-- Delete and Insert the Database Row
delete from labor_projections where facility = in_facility and custid = in_custid;

insert into labor_projections
  (facility, custid,
   cur_date_used,
   orders_yesterday, 
   orders_last7, 
   orders_last30, 
   orders_tomorrow, 
   manhours_yesterday, 
   manhours_last7, 
   manhours_last30, 
   manhours_proj_yesterday,
   manhours_proj_last7,
   manhours_proj_last30)
  values
   (in_facility, in_custid,
	to_date(v_cur_date, 'YYYY-MM-DD'),
	nvl(v_orders_yesterday,0),  
	nvl(v_orders_last7,0),
	nvl(v_orders_last30,0),
	nvl(v_orders_tomorrow,0),
	nvl(v_manhours_yesterday,0),  
	nvl(v_manhours_last7,0),
	nvl(v_manhours_last30,0),
	nvl(v_manhours_proj_yesterday,0),  
	nvl(v_manhours_proj_last7,0),
	nvl(v_manhours_proj_last30,0)
	);
commit;

EXCEPTION
  when others then
    out_msg := substr(sqlerrm,1,255);
    out_errorno := sqlcode;

END calc_labor_projection_dt;

END zlaborprojection;
/
show error package zlaborprojection;
show error package body zlaborprojection;
exit;
