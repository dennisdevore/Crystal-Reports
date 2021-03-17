create or replace view bbb_carrier_assign_effdte_view
(custid
,from_countrycode
,from_state
,to_countrycode
,to_state
,from_zipcode_match
,to_zipcode_match
,effdate
)
as
select 
custid,
from_countrycode,
from_state,
to_countrycode,
to_state,
from_zipcode_match,
to_zipcode_match,
max(effdate)
from bbb_carrier_assignment
where effdate <= trunc(sysdate)
group by custid,from_countrycode,from_state,to_countrycode,to_state,from_zipcode_match,to_zipcode_match;

comment on table bbb_carrier_assign_effdte_view is '$Id: bbb_carrier_assign_effdte_view.sql 5330 2010-08-18 16:44:25Z mike $';

create or replace view bbb_carrier_assign_today_view
(custid
,from_countrycode
,from_state
,to_countrycode
,to_state
,from_zipcode_match
,to_zipcode_match
,effdate
,ltl_carrier
,tl_carrier
,lastuser
,lastupdate
)
as
select
a.custid,
a.from_countrycode,
a.from_state,
a.to_countrycode,
a.to_state,
a.from_zipcode_match,
a.to_zipcode_match,
b.effdate,
b.ltl_carrier,
b.tl_carrier,
b.lastuser,
b.lastupdate
from bbb_carrier_assign_effdte_view a, bbb_carrier_assignment b
where a.custid = b.custid
  and a.from_countrycode = b.from_countrycode
  and a.from_state = b.from_state
  and a.to_countrycode = b.to_countrycode
  and a.to_state = b.to_state
  and a.from_zipcode_match = b.from_zipcode_match
  and a.to_zipcode_match = b.to_zipcode_match;

comment on table bbb_carrier_assign_today_view is '$Id: bbb_carrier_assign_today_view.sql 5330 2010-08-18 16:44:25Z mike $';
  
create or replace view bbb_routing_effdte_view
(custid
,fromfacility
,shiptocountrycode
,shipto
,shiptype
,effdate
)
as
select
custid,
fromfacility,
shiptocountrycode,
shipto,
shiptype,
max(effdate)
from bbb_routing_parms
where effdate <= trunc(sysdate)
group by custid,fromfacility,shiptocountrycode,shipto,shiptype;

comment on table bbb_routing_effdte_view is '$Id: bbb_routing_effdte_view.sql 5330 2010-08-18 16:44:25Z mike $';

create or replace view bbb_routing_today_view
(custid
,fromfacility
,shiptocountrycode
,shipto
,shiptype
,shiptype_abbrev
,effdate
,carton_count_min
,carton_count_max
,weight_min
,weight_max
,cube_min
,cube_max
,lastuser
,lastupdate
)
as
select
a.custid,
a.fromfacility,
a.shiptocountrycode,
a.shipto,
a.shiptype,
nvl(shty.abbrev,a.shiptype),
b.effdate,
b.carton_count_min,
b.carton_count_max,
b.weight_min,
b.weight_max,
b.cube_min,
b.cube_max,
b.lastuser,
b.lastupdate
from bbb_routing_effdte_view a, bbb_routing_parms b,
     shipmenttypes shty
where a.custid = b.custid
  and a.fromfacility = b.fromfacility
  and a.shiptocountrycode = b.shiptocountrycode
  and a.shipto = b.shipto
  and a.shiptype = b.shiptype
  and a.shiptype = shty.code(+);

comment on table bbb_routing_today_view is '$Id: bbb_routing_today_view.sql 5330 2010-08-18 16:44:25Z mike $';
  
exit;
