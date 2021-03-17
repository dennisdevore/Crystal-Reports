--
-- $Id$
--
create or replace PACKAGE zsplitorder
IS


----------------------------------------------------------------------
--
-- lock_it
--
----------------------------------------------------------------------
PROCEDURE lock_it
(
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- block_it
--
----------------------------------------------------------------------
PROCEDURE block_it
(
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- release_it
--
----------------------------------------------------------------------
PROCEDURE release_it
(
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- split_order
--
----------------------------------------------------------------------
PROCEDURE split_order
(
    in_orderid  number,
    in_shipid   number,
    in_userid   varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- split_load
--
----------------------------------------------------------------------
PROCEDURE split_load
(
    in_loadno   number,
    in_userid   varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- load_not_loaded - Return number of active order lines not fully loaded
--
----------------------------------------------------------------------
FUNCTION load_not_loaded
(
    in_loadno   number
)
RETURN number;


----------------------------------------------------------------------
--
-- split_shipment_begin
--
----------------------------------------------------------------------
PROCEDURE split_shipment_begin
(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- split_shipment_end
--
----------------------------------------------------------------------
PROCEDURE split_shipment_end
(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  OUT varchar2
);

------------------------------------------------------------------------
--
-- split_shipment
--
------------------------------------------------------------------------
PROCEDURE split_shipment
(
    in_orderid      IN number,
    in_shipid       IN number,
    in_userid       IN varchar2,
    in_new_orderid  IN OUT number,
    in_new_shipid   IN OUT number,
    out_errmsg      OUT varchar2
);

procedure get_rf_lock
(in_loadno  IN number
,in_orderid IN number
,in_shipid  IN number
,in_userid  IN varchar2
,out_msg    OUT varchar2
);

END zsplitorder;
/
exit;
