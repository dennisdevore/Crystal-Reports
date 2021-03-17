--
-- $Id$
--
create or replace package ztms_transynd
AS

----------------------------------------------------------------------
--
-- check_wave_format
--
----------------------------------------------------------------------
PROCEDURE check_wave_format
(
    in_wave     IN      integer,
    in_format   IN      varchar2,
    in_status   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- send_wave - send a waves orders to TMS
--
----------------------------------------------------------------------
PROCEDURE send_wave
(
    in_wave     IN      integer,
    in_format   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- deplan_order
--
----------------------------------------------------------------------
PROCEDURE deplan_order
(
    in_wave     IN      integer,
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- plan_order
--
----------------------------------------------------------------------
PROCEDURE plan_order
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_shipment IN      varchar2,
    in_release  IN      varchar2,
    in_carrier  IN      varchar2,
    in_deliveryservice IN varchar2,
    in_shipdate IN      date,
    in_arrivaldate IN   date,
    in_apptdate IN      date,
    in_shiptype IN      varchar2,
    in_scac     IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- release_wave - release an optimized wave to planning
--
----------------------------------------------------------------------
PROCEDURE release_wave
(
    in_wave     IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);


----------------------------------------------------------------------
--
-- send_order_change - send an orderstatus change to TMS
--
----------------------------------------------------------------------
PROCEDURE send_order_change
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- send_order_ship - send an order shipped to TMS
--
----------------------------------------------------------------------
PROCEDURE send_order_ship
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- send_item_info - send item information to TMS
--
----------------------------------------------------------------------
PROCEDURE send_item_info
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- process_transmission
--
----------------------------------------------------------------------
PROCEDURE process_transmission
(
    in_transmission  IN      number,
    in_userid       IN  varchar2,
    out_errmsg  IN OUT  varchar2
);

end ztms_transynd;
/
exit;

