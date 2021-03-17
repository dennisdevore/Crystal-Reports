update
bbb_routing_parms
set
shiptocountrycode = '(DEFAULT)'
where shiptocountrycode = '(Default)';
update
bbb_carrier_assignment
set
from_zipcode_match = '(DEFAULT)'
where from_zipcode_match = '(Default)';
update
bbb_carrier_assignment
set
to_zipcode_match = '(DEFAULT)'
where to_zipcode_match = '(Default)';
update
bbb_routing_parms
set
shipto = '(DEFAULT)'
where shipto = '(Default)';
exit;

