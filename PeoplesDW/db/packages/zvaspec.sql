--
-- $Id$
--
create or replace PACKAGE alps.zvalidate
IS

PROCEDURE validate_location
(in_facility IN varchar2
,in_locid IN varchar2
,in_loctype IN varchar2
,in_status IN varchar2
,in_msgprefix IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE validate_carrier
(in_carrier IN varchar2
,in_carriertype IN varchar2
,in_carrierstatus IN varchar2
,out_msg  IN OUT varchar2
);

END zvalidate;
/

exit;
