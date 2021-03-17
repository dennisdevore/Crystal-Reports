--
-- $Id$
--
create or replace package alps.zbillaccess as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************




----------------------------------------------------------------------
--
-- check_multi_facility
--
----------------------------------------------------------------------
FUNCTION check_multi_facility
(
    in_orderid  IN      number,
    in_shipid   IN      number
)
RETURN integer;

----------------------------------------------------------------------
--
-- calc_access_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_access_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN  varchar2 default 'N'
)
RETURN integer;


----------------------------------------------------------------------
--
-- calc_access_bills -
--
----------------------------------------------------------------------
FUNCTION calc_access_bills
(
    in_loadno   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
-- calc_outbound_order -
--
----------------------------------------------------------------------
FUNCTION calc_outbound_order
(
    in_invoice  IN      number,
    in_loadno   IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
FUNCTION estimate_outbound_order
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;
FUNCTION rollover_estimated_charges
(
    in_invoice  IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;
FUNCTION delete_estimated_charges
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;
-- recalc_access_bills -
--
----------------------------------------------------------------------
FUNCTION recalc_access_bills
(
    in_invoice  IN      number,
    in_loadno   IN      number,   -- really a dummy field
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
-- calc_accessorial_charges -
--
----------------------------------------------------------------------
FUNCTION calc_accessorial_charges
(
    in_event    IN      varchar2,
    in_facility IN      varchar2,
    in_loadno   IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
-- locate_accessorial_invoice
--
----------------------------------------------------------------------
PROCEDURE locate_accessorial_invoice
(
    in_custid   IN      varchar2,
    in_facility IN      varchar2,
    in_userid   IN      varchar2,
    out_invoice OUT     number,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

----------------------------------------------------------------------
--
-- calc_accessorial_invoice
--
----------------------------------------------------------------------
PROCEDURE calc_accessorial_invoice
(
    in_invoice  IN      number,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

----------------------------------------------------------------------
--
-- approve_accessorials
--
----------------------------------------------------------------------
PROCEDURE approve_accessorials
(
    in_date     IN      date,
    out_errmsg  OUT     varchar2
);

----------------------------------------------------------------------
-- calc_freight_order -
----------------------------------------------------------------------
FUNCTION calc_freight_order
(
    in_loadno				IN      number,
    in_userid				IN      varchar2,
	in_trace				IN OUT	varchar2,
    out_errmsg				IN OUT	varchar2
)
RETURN integer;

----------------------------------------------------------------------
-- create_freight_invoice
----------------------------------------------------------------------
FUNCTION create_freight_invoice
(
    in_invoice				IN      number,
    in_loadno				IN      number,
	in_stopno				IN      number,
    in_orderid				IN      number,
    in_shipid				IN      number,
	in_surcharge_effdate	IN		date,
    in_userid				IN      varchar2,
	in_trace				IN OUT	varchar2,
    out_errmsg				IN OUT	varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
-- get_invoicehdr_freight_misc
--
----------------------------------------------------------------------
FUNCTION get_invoicehdr_freight_misc
(
        in_lookup       IN      varchar2,
        in_custid       IN      varchar2,
        in_facility     IN      varchar2,
		in_loadno		IN		number,
		in_orderid		IN		number,
        in_userid       IN      varchar2,
        in_effdate      IN      date,
        INVH            OUT     invoicehdr%rowtype,
		out_errmsg		OUT		varchar2
)
RETURN integer;

----------------------------------------------------------------------
--
-- get_charge_reversal_rate
--
----------------------------------------------------------------------
FUNCTION get_charge_reversal_rate
(
  in_shlpid           in shippingplate%rowtype,
  in_rategroup        in custrate.rategroup%type,
  in_activity         in custrate.activity%type,
  in_uom              in custrate.uom%type,
  out_errmsg		      out		varchar2
)
return custrate.rate%type;

end zbillaccess;
/

show errors package zbillaccess;
exit;
