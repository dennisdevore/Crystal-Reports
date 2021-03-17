--
-- $Id$
--
create or replace package alps.sp as

procedure get_next_shippinglpid(out_shippinglpid    out varchar2,
                                out_message out varchar2);

FUNCTION carrierused
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return varchar2;

FUNCTION reason
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return varchar2;

FUNCTION cost
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return number;

function mp_count
(in_orderid IN number
,in_shipid IN number
) return number;

PRAGMA RESTRICT_REFERENCES (carrierused, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (reason, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (cost, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (mp_count, WNDS, WNPS, RNPS);

end sp;
/

exit;
