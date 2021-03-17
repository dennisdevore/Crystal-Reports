create or replace PACKAGE BODY alps.zprofitability
IS

PROCEDURE calc_storage_profitability
(in_facility varchar2
,in_custid varchar2
,in_cost_per_sqft number
,in_space_utilization_pct number default 60
,in_number_of_days number  default 30
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10);
v_prv_date varchar2(10);

BEGIN

out_errorno := 0;
out_msg := 'Okay';

select to_char(sysdate, 'YYYY-MM-DD') into v_cur_date from dual;
select to_char(sysdate - in_number_of_days, 'YYYY-MM-DD') into v_prv_date from dual;

calc_storage_profitability_dt(in_facility, in_custid, in_cost_per_sqft,
	in_space_utilization_pct, v_prv_date, v_cur_date, out_errorno, out_msg);

END calc_storage_profitability;

PROCEDURE calc_storage_profitability_dt
(in_facility varchar2
,in_custid varchar2
,in_cost_per_sqft number
,in_space_utilization_pct number default 60
,in_from_date varchar2
,in_thru_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10) := in_thru_date;
v_prv_date varchar2(10) := in_from_date;

v_total_storage_revenue storage_profitability.total_storage_revenue%type := 0.0;
v_renewal_storage_revenue storage_profitability.renewal_storage_revenue%type := 0.0;
v_receipt_storage_revenue storage_profitability.receipt_storage_revenue%type := 0.0;

v_total_location_sqft storage_profitability.total_location_sqft%type := 0.0;
v_full_location_sqft storage_profitability.full_location_sqft%type := 0.0;
v_partial_location_sqft storage_profitability.partial_location_sqft%type := 0.0;
v_gross_location_sqft storage_profitability.gross_location_sqft%type := 0.0;

v_gross_cost_sqft storage_profitability.gross_cost_sqft%type := 0.0;
v_storage_profit storage_profitability.storage_profit%type := 0.0;

BEGIN

out_errorno := 0;
out_msg := 'Okay';

-- Calc Renewal Storage Revenue
BEGIN
  select sum(billedamt) into v_renewal_storage_revenue
    from invoicedtl id, activity a
    where id.activity = a.code
    and to_char(id.activitydate, 'YYYY-MM-DD') >= v_prv_date
    and to_char(id.activitydate, 'YYYY-MM-DD') <= v_cur_date
    and id.invtype = 'S'
    and a.mincategory = 'S'
    and id.facility = in_facility
    and id.custid = in_custid;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_renewal_storage_revenue := 0.0;
END;	

-- Calc Receipt Storage Revenue
BEGIN
  select sum(billedamt) into v_receipt_storage_revenue
    from invoicedtl id, activity a
    where id.activity = a.code
    and to_char(id.activitydate, 'YYYY-MM-DD') >= v_prv_date
    and to_char(id.activitydate, 'YYYY-MM-DD') <= v_cur_date
    and id.invtype = 'R'
    and a.mincategory = 'S'
    and id.facility = in_facility
    and id.custid = in_custid;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_receipt_storage_revenue := 0.0;
END;	

-- Calc Total Storage Revenue 
v_total_storage_revenue := nvl(v_renewal_storage_revenue,0) + nvl(v_receipt_storage_revenue,0);

-- Calc Space Utilization, Full and Partial Locations
for sq in (select x.cnt as cnt, us.stdpallets as stdpallets, 
				(nvl(us.width,0) * nvl(us.depth,0)) as sqft
			from location loc, unitofstorage us,
			(select facility, location, count(*) as cnt from plate 
			  where facility = in_facility and custid = in_custid 
				and quantity is not null
				and type = 'PA'
			  group by facility, location) x
			where loc.unitofstorage = us.unitofstorage
			and x.facility = loc.facility and x.location = loc.locid
			and loc.facility = in_facility)
	loop
	  if sq.cnt >= sq.stdpallets then
		v_full_location_sqft := v_full_location_sqft + sq.sqft;
	  else
	    v_partial_location_sqft := v_partial_location_sqft + ((sq.cnt / sq.stdpallets) * sq.sqft);
	  end if;
	end loop;

-- Calc Space Utilization, Net Total and Gross
v_total_location_sqft := v_full_location_sqft + v_partial_location_sqft;
v_gross_location_sqft := v_total_location_sqft / (nvl(in_space_utilization_pct,60) / 100);
v_gross_cost_sqft := v_gross_location_sqft * nvl(in_cost_per_sqft,0.55);

-- Calc the Total Storage Profit
if v_gross_cost_sqft != 0 then
  v_storage_profit := (nvl(v_total_storage_revenue,0) / v_gross_cost_sqft) - 1;
end if;  

-- Delete and Insert the Database Row
delete from storage_profitability 
where facility = in_facility and custid = in_custid
and time_period_from = to_date(v_prv_date, 'YYYY-MM-DD')
and time_period_thru = to_date(v_cur_date, 'YYYY-MM-DD');

insert into storage_profitability
  (facility, custid,
   time_period_from,
   time_period_thru,
   cost_per_sqft,
   space_utilization_pct,
   renewal_storage_revenue, 
   receipt_storage_revenue, 
   total_storage_revenue,
   full_location_sqft, 
   partial_location_sqft, 
   total_location_sqft,
   gross_location_sqft, 
   gross_cost_sqft, 
   storage_profit)
  values
   (in_facility, in_custid,
    to_date(v_prv_date, 'YYYY-MM-DD'), 
	to_date(v_cur_date, 'YYYY-MM-DD'),
    in_cost_per_sqft,
    in_space_utilization_pct,	
    nvl(v_renewal_storage_revenue,0), 
	nvl(v_receipt_storage_revenue,0),  
	nvl(v_total_storage_revenue,0),  
	nvl(v_full_location_sqft,0),  
	nvl(v_partial_location_sqft,0),  
	nvl(v_total_location_sqft,0),  
	nvl(v_gross_location_sqft,0),  
	nvl(v_gross_cost_sqft,0),  
	nvl(v_storage_profit,0)
	);
commit;

EXCEPTION
  when others then
    out_msg := substr(sqlerrm,1,255);
    out_errorno := sqlcode;

END calc_storage_profitability_dt;

PROCEDURE calc_handling_profitability
(in_facility varchar2
,in_custid varchar2
,in_labor_cost_per_hr number  default 20
,in_equipment_cost_per_hr number  default 15
,in_number_of_days number  default 30
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10);
v_prv_date varchar2(10);

BEGIN

out_errorno := 0;
out_msg := 'Okay';

select to_char(sysdate, 'YYYY-MM-DD') into v_cur_date from dual;
select to_char(sysdate - in_number_of_days, 'YYYY-MM-DD') into v_prv_date from dual;

calc_handling_profitability_dt(in_facility, in_custid, 
		in_labor_cost_per_hr, in_equipment_cost_per_hr,
		v_prv_date, v_cur_date, out_errorno, out_msg);

END calc_handling_profitability;

PROCEDURE calc_handling_profitability_dt
(in_facility varchar2
,in_custid varchar2
,in_labor_cost_per_hr number  default 20
,in_equipment_cost_per_hr number  default 15
,in_from_date varchar2
,in_thru_date varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) IS

v_cur_date varchar2(10) := in_thru_date;
v_prv_date varchar2(10) := in_from_date;

v_total_handling_revenue handling_profitability.total_handling_revenue%type := 0.0;
v_outbound_handling_revenue handling_profitability.outbound_handling_revenue%type := 0.0;
v_receipt_handling_revenue handling_profitability.receipt_handling_revenue%type := 0.0;

v_handling_manhours handling_profitability.handling_manhours%type := 0.0;
v_handling_equiphours handling_profitability.handling_equiphours%type := 0.0;

v_handling_total_cost handling_profitability.handling_total_cost%type := 0.0;
v_handling_labor_cost handling_profitability.handling_labor_cost%type := 0.0;
v_handling_equip_cost handling_profitability.handling_equip_cost%type := 0.0;

v_handling_profit handling_profitability.handling_profit%type := 0.0;

v_eq_hrly_cost equipmentcost.hourlycost%type;
v_us_hrly_cost userheader.hourlycost%type;

BEGIN

out_errorno := 0;
out_msg := 'Okay';

-- Calc Outbound Handling Revenue
BEGIN
  select sum(billedamt) into v_outbound_handling_revenue
    from invoicedtl id, activity a
    where id.activity = a.code
    and to_char(id.activitydate, 'YYYY-MM-DD') >= v_prv_date
    and to_char(id.activitydate, 'YYYY-MM-DD') <= v_cur_date
    and id.invtype = 'A'
    and a.mincategory = 'H'
    and id.facility = in_facility
    and id.custid = in_custid;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_outbound_handling_revenue := 0.0;
END;	

-- Calc Receipt Handling Revenue
BEGIN
  select sum(billedamt) into v_receipt_handling_revenue
    from invoicedtl id, activity a
    where id.activity = a.code
    and to_char(id.activitydate, 'YYYY-MM-DD') >= v_prv_date
    and to_char(id.activitydate, 'YYYY-MM-DD') <= v_cur_date
    and id.invtype = 'R'
    and a.mincategory = 'H'
    and id.facility = in_facility
    and id.custid = in_custid;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_receipt_handling_revenue := 0.0;
END;	

-- Calc Total Handling Revenue 
v_total_handling_revenue := nvl(v_outbound_handling_revenue,0) + nvl(v_receipt_handling_revenue,0);

-- Calc Total Handling Manhours and Equipment Hours, as well as the fully loaded cost for each
for uhx in (select nameid, equipment, nvl(sum((endtime - begtime) * 24),0) as tothrs
			from userhistory
			where facility = in_facility and custid = in_custid
			  and to_char(begtime, 'YYYY-MM-DD') >= v_prv_date
			  and to_char(begtime, 'YYYY-MM-DD') <= v_cur_date
			  and event not in ('LGIN','PKME','PKNO')
			group by nameid, equipment)
	loop
		v_handling_manhours := v_handling_manhours + uhx.tothrs;
		v_handling_equiphours := v_handling_equiphours + uhx.tothrs;
		
		-- Get the hourly cost for the equipment usage
		BEGIN 
			select nvl(hourlycost,in_equipment_cost_per_hr) into v_eq_hrly_cost
			  from equipmentcost
			 where facility = in_facility 
			   and equipid = uhx.equipment; 
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_eq_hrly_cost := in_equipment_cost_per_hr;
		END;
		v_handling_equip_cost := v_handling_equip_cost + (uhx.tothrs * v_eq_hrly_cost);
		
		-- Get the hourly cost for the employee's time
		BEGIN 
			select nvl(hourlycost,in_labor_cost_per_hr) into v_us_hrly_cost
			  from userheader
			 where nameid = uhx.nameid; 
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_us_hrly_cost := in_labor_cost_per_hr;
		END;
		v_handling_labor_cost := v_handling_labor_cost + (uhx.tothrs * v_us_hrly_cost);
		
	end loop;

-- Calc the total handling cost
v_handling_total_cost := v_handling_labor_cost + v_handling_equip_cost;	

-- Calc the Total Handling Profit
if v_handling_total_cost != 0 then
  v_handling_profit := (nvl(v_total_handling_revenue,0) / v_handling_total_cost) - 1;
end if;  

-- Delete and Insert the Database Row
delete from handling_profitability
where facility = in_facility and custid = in_custid
and time_period_from = to_date(v_prv_date, 'YYYY-MM-DD')
and time_period_thru = to_date(v_cur_date, 'YYYY-MM-DD');

insert into handling_profitability
  (facility, custid,
   time_period_from,
   time_period_thru,
   labor_cost_per_hr,
   equipment_cost_per_hr,
   outbound_handling_revenue, 
   receipt_handling_revenue, 
   total_handling_revenue,
   handling_manhours,
   handling_equiphours,
   handling_labor_cost,
   handling_equip_cost,
   handling_total_cost,
   handling_profit)
  values
   (in_facility, in_custid,
    to_date(v_prv_date, 'YYYY-MM-DD'), 
	to_date(v_cur_date, 'YYYY-MM-DD'),
    in_labor_cost_per_hr,
    in_equipment_cost_per_hr,	
    nvl(v_outbound_handling_revenue,0), 
	nvl(v_receipt_handling_revenue,0),  
	nvl(v_total_handling_revenue,0),  
	nvl(v_handling_manhours,0),
	nvl(v_handling_equiphours,0),
	nvl(v_handling_labor_cost,0),
	nvl(v_handling_equip_cost,0),
	nvl(v_handling_total_cost,0),
	nvl(v_handling_profit,0)
	);
commit;

EXCEPTION
  when others then
    out_msg := substr(sqlerrm,1,255);
    out_errorno := sqlcode;

END calc_handling_profitability_dt;

END zprofitability;
/
show error package zprofitability;
show error package body zprofitability;
exit;
