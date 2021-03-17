create or replace PACKAGE alps.zreaddata

IS

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
-- debug_trace - turn on/off debug tracing
--
----------------------------------------------------------------------
PROCEDURE debug_trace(in_mode boolean);


----------------------------------------------------------------------
--
-- get_orderhdr - 
--
----------------------------------------------------------------------
PROCEDURE get_orderhdr(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_orderid OUT number,
    out_shipid OUT number);

----------------------------------------------------------------------
--
-- get_returns_orderhdr - 
--
----------------------------------------------------------------------
PROCEDURE get_returns_orderhdr(
    in_facility IN  varchar2,
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_orderid OUT number,
    out_shipid OUT number);

----------------------------------------------------------------------
--
-- get_loads - 
--
----------------------------------------------------------------------
PROCEDURE get_loads(
    in_loadno  IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_loadno OUT number);

----------------------------------------------------------------------
--
-- get_plate - 
--
----------------------------------------------------------------------
PROCEDURE get_plate(
    in_table    IN  varchar2,
    in_lpid     IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_lpid  OUT varchar2);

----------------------------------------------------------------------
--
-- get_shippingplate - 
--
----------------------------------------------------------------------
PROCEDURE get_shippingplate(
    in_lpid     IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_lpid  OUT varchar2);

----------------------------------------------------------------------
--
-- get_customer - 
--
----------------------------------------------------------------------
PROCEDURE get_customer(
    in_custid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid  OUT varchar2);

----------------------------------------------------------------------
--
-- get_label - 
--
----------------------------------------------------------------------
PROCEDURE get_label(
    in_code        IN  varchar2,
    in_action      IN  varchar2,
    in_labelfilter IN varchar2,
    out_code       OUT varchar2,
	out_first      OUT varchar2,	    
	out_last       OUT varchar2);	
	
----------------------------------------------------------------------
--
-- get_consignee - 
--
----------------------------------------------------------------------
PROCEDURE get_consignee(
    in_consignee   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_consignee  OUT varchar2);

----------------------------------------------------------------------
--
-- get_carrier - 
--
----------------------------------------------------------------------
PROCEDURE get_carrier(
    in_carrier   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_carrier  OUT varchar2);

----------------------------------------------------------------------
--
-- get_userheader - 
--
----------------------------------------------------------------------
PROCEDURE get_userheader(
    in_nameid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_nameid  OUT varchar2);

----------------------------------------------------------------------
--
-- get_location - 
--
----------------------------------------------------------------------
PROCEDURE get_location(
    in_fac   IN  varchar2,
    in_locid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_fac  OUT varchar2,
    out_locid  OUT varchar2);

----------------------------------------------------------------------
--
-- get_allocruleshdr - 
--
----------------------------------------------------------------------
PROCEDURE get_allocruleshdr(
    in_fac   IN  varchar2,
    in_allocrule   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_fac  OUT varchar2,
    out_allocrule  OUT varchar2);

----------------------------------------------------------------------
--
-- get_custitem - 
--
----------------------------------------------------------------------
PROCEDURE get_custitem(
    in_custid   IN  varchar2,
    in_item   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid  OUT varchar2,
    out_item  OUT varchar2);

----------------------------------------------------------------------
--
-- get_pallethistory - 
--
----------------------------------------------------------------------
PROCEDURE get_pallethistory(
    in_custid   IN  varchar2,
    in_facility   IN  varchar2,
    in_pallettype   IN  varchar2,
    in_carrier   IN  varchar2,
    in_lastupdate   IN  date,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid   OUT  varchar2,
    out_facility   OUT  varchar2,
    out_pallettype   OUT  varchar2,
    out_carrier   OUT  varchar2,
    out_lastupdate   OUT  date);

----------------------------------------------------------------------
--
-- get_nmfc - 
--
----------------------------------------------------------------------
PROCEDURE get_nmfc(
    in_nmfc  IN  varchar2,
    in_action   IN  varchar2,
    out_nmfc OUT varchar2);

END zreaddata;
/

exit;
