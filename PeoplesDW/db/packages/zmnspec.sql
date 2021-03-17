--
-- $Id$
--
create or replace package alps.zmanifest as

FUNCTION ignore_smallpkg_station_weight
(in_custid in varchar2
) return varchar2;

FUNCTION order_is_shipped
(in_orderid in number
,in_shipid in number
) return varchar2;

PROCEDURE shipped_order_updates
(in_orderid in number
,in_shipid in number
,in_userid in varchar2
,out_errorno OUT number
,out_errmsg OUT varchar2
);

PROCEDURE process_shipped;

PROCEDURE stage_carton
(
    in_carton    IN       varchar2,
    in_requestor IN       varchar2,
    out_errmsg   OUT      varchar2
);

PROCEDURE restage_cartons
(
    in_orderid   IN       number,
    in_shipid    IN       number,
    out_errorno  OUT      number
);

PROCEDURE send_shipped_msg
(
    in_cartonid  IN         varchar2,
    out_errmsg   IN OUT     varchar2
);

PROCEDURE change_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    out_errmsg    OUT     varchar2
);

function get_tracker_url
(
	in_actualcarrier     IN varchar2,
	in_trackingno        IN varchar2
)
return varchar2;

function get_actualcarrier
(
	in_shippingplate_lpid IN varchar2
)
return varchar2;

PROCEDURE add_multishiphdr
(
    ORD          IN      orderhdr%rowtype,
    in_requestor IN      varchar2,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- add_multishipitems
--
----------------------------------------------------------------------
PROCEDURE add_multishipitems
(
    in_orderid   IN         number,
    in_shipid    IN         number,
    in_carton    IN         varchar2,
    out_errmsg   IN OUT     varchar2
);

function correct_fromlpid
   (in_lpid in varchar2)
return varchar2;

PROCEDURE send_staged_carton_trigger(
    in_facility     varchar2,
    in_custid       varchar2,
    in_termid       varchar2,
    in_lpid         varchar2,
    in_userid       varchar2,
    out_errmsg      out   varchar2
);

PROCEDURE check_and_send_carton_trigger(
    in_facility     varchar2,
    in_termid       varchar2,
    in_lpid         varchar2,
    in_item         varchar2,
    in_userid       varchar2,
    out_errmsg      out   varchar2
);

PRAGMA RESTRICT_REFERENCES (ignore_smallpkg_station_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_is_shipped, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_tracker_url, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_actualcarrier, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (correct_fromlpid, WNDS, WNPS, RNPS);

end zmanifest;
/
exit;
