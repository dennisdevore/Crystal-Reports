--
-- $Id$
--
update custfacility
	set profid = null
 where profid = 'C';
update custfacility
	set allocrule = null
 where allocrule = 'C';
update custfacility
	set replallocrule = null
 where replallocrule = 'C';
update custproductgroup
	set fifowindowdays = null
 where fifowindowdays = 0;
exit;
