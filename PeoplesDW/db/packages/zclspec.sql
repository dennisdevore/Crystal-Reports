--
-- $Id$
--
create or replace PACKAGE zclone
IS

PROCEDURE set_debug_mode
(in_mode boolean
);

PROCEDURE debug_msg
(in_text IN varchar2
);
------------------------------------------------------------------------
--
-- clone_table_row - generic clone table
--
------------------------------------------------------------------------
PROCEDURE clone_table_row
(
	in_table        IN varchar2,    -- table name to clone must be upper
	in_from         IN varchar2,    -- where clause of table row to clone
	in_to           IN varchar2,    -- to values of new row index
	in_index        IN varchar2,    -- index columns
	in_dblink       IN varchar2,    -- database link where to clone the objects
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_orderhdr -
--
------------------------------------------------------------------------
PROCEDURE clone_orderhdr
(
	in_orderid      IN number,
	in_shipid       IN number,
	in_new_orderid  IN number,
	in_new_shipid   IN number,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_orderdtl -
--
------------------------------------------------------------------------
PROCEDURE clone_orderdtl
(
	in_orderid      IN number,
	in_shipid       IN number,
	in_item         IN varchar2,
	in_lot          IN varchar2,
	in_new_orderid  IN number,
	in_new_shipid   IN number,
	in_new_item     IN varchar2,
	in_new_lot      IN varchar2,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_customer -
--
------------------------------------------------------------------------
PROCEDURE clone_customer
(
	in_customer_flag    IN varchar2,  -- flag to clone customer
	in_item_flag        IN varchar2,  -- flag to clone item
	in_rategroup_flag   IN varchar2,  -- flag to clone rate group
	in_itemalias_flag   IN varchar2,  -- flag to clone item alias
	in_itempickfronts_flag IN varchar2,  -- flag to clone item pickfronts
	in_custid           IN varchar2,  -- customer to clone from
	in_item             IN varchar2,  -- item to clone from
	in_new_custid       IN varchar2,  -- new customer to clone to
	in_new_item         IN varchar2,  -- new item to clone to
	in_dblink           IN varchar2,  -- database link where to clone the objects
	in_userid           IN varchar2,
	out_errmsg          OUT varchar2
);

------------------------------------------------------------------------
--
-- update_customer -
--
------------------------------------------------------------------------
PROCEDURE update_customer
(
	in_custid		IN varchar2,
	in_new_custid	IN varchar2,
	in_dblink		IN varchar2,
	in_userid		IN varchar2,
	out_errmsg		OUT varchar2
);

------------------------------------------------------------------------
--
-- validate_customer -
--
------------------------------------------------------------------------
PROCEDURE validate_customer
(
	in_custid		IN varchar2,
	in_new_custid	IN varchar2,
	in_dblink		IN varchar2,
	in_userid		IN varchar2,
	out_errmsg		OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_rategroup -
--
------------------------------------------------------------------------
PROCEDURE clone_rategroup
(
	in_custid        IN varchar2,
 in_rategroup     IN varchar2,
	in_new_custid    IN varchar2,
 in_new_rategroup IN varchar2,
	in_dblink        IN varchar2,
	in_userid        IN varchar2,
	out_errmsg       OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_productgroup -
--
------------------------------------------------------------------------
PROCEDURE clone_productgroup
(
	in_custid        IN varchar2,
	in_new_custid    IN varchar2,
	in_dblink        IN varchar2,
	in_userid        IN varchar2,
	out_errmsg       OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_custitem -
--
------------------------------------------------------------------------
PROCEDURE clone_custitem
(
	in_custid       IN varchar2,
	in_item         IN varchar2,
	in_new_custid   IN varchar2,
	in_new_item     IN varchar2,
	in_itemalias_flag IN varchar2,
	in_itempickfronts_flag IN varchar2,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      IN OUT varchar2
);

------------------------------------------------------------------------
--
-- update_custitem -
--
------------------------------------------------------------------------
PROCEDURE update_custitem
(
	in_custid       IN varchar2,
	in_item         IN varchar2,
	in_new_custid   IN varchar2,
	in_new_item     IN varchar2,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- validate_custitem -
--
------------------------------------------------------------------------
PROCEDURE validate_custitem
(
	in_custid       IN varchar2,
	in_item         IN varchar2,
	in_new_custid   IN varchar2,
	in_new_item     IN varchar2,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_kit -
--
------------------------------------------------------------------------
PROCEDURE clone_kit
(
	in_custid       IN varchar2,
	in_item         IN varchar2,
	in_new_custid   IN varchar2,
	in_new_item     IN varchar2,
	in_dblink       IN varchar2,
	in_userid       IN varchar2,
	out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_receipt_order -
--
------------------------------------------------------------------------
PROCEDURE clone_receipt_order
(
    in_orderid      IN number,
    in_shipid       IN number,
	   in_dblink       IN varchar2,
    in_userid       IN varchar2,
    in_new_orderid  IN OUT number,
    in_new_shipid   IN OUT number,
    out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_outbound_order -
--
------------------------------------------------------------------------
PROCEDURE clone_outbound_order
(
    in_orderid      IN number,
    in_shipid       IN number,
	   in_dblink       IN varchar2,
    in_userid       IN varchar2,
    in_reference    IN varchar2,
    out_new_orderid OUT number,
    out_new_shipid  OUT number,
    out_errmsg      OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_ownerxfer_order -
--
------------------------------------------------------------------------
procedure clone_ownerxfer_order
(
	in_orderid      in number,
	in_shipid       in number,
	in_dblink       in varchar2,
	in_userid       in varchar2,
	out_new_orderid out number,
	out_new_shipid  out number,
	out_errmsg      out varchar2
);

------------------------------------------------------------------------
--
-- validate_chemical_codes -
--
------------------------------------------------------------------------
PROCEDURE validate_chemical_codes(
	in_chemcode        IN chemicalcodes.chemcode%type,
	in_new_custid      IN customer.custid%type,
	in_dblink          IN varchar2,
	in_msgtext         IN varchar2,
	in_userid          IN varchar2,
	out_errmsg         IN OUT varchar2
);

------------------------------------------------------------------------
--
-- validate_sara_casnumbers -
--
------------------------------------------------------------------------
PROCEDURE validate_sara_casnumbers(	
	in_cas             IN casnumbers.cas%type,
	in_new_custid      IN customer.custid%type,
	in_dblink          IN varchar2,
	in_msgtext         IN varchar2,
	in_userid          IN varchar2,
	out_errmsg         IN OUT varchar2
);

------------------------------------------------------------------------
--
-- Validate BASEUOM
--
------------------------------------------------------------------------
FUNCTION validate_uom
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN NUMBER;

------------------------------------------------------------------------
--
-- Validate BILLMETHOD
--
------------------------------------------------------------------------
FUNCTION validate_billmethod
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN NUMBER;

------------------------------------------------------------------------
--
-- Validate BUSINESSEVENT
--
------------------------------------------------------------------------
FUNCTION validate_businessevent
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN NUMBER;

------------------------------------------------------------------------
--
-- Validate ACTIVITY
--
------------------------------------------------------------------------
FUNCTION validate_activity
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN NUMBER;

------------------------------------------------------------------------
--
-- clone_facility -
--
------------------------------------------------------------------------
PROCEDURE clone_facility
(
    in_facility                   IN varchar2,  -- facility to clone from
    in_new_facility               IN varchar2,  -- new facility to clone to
    in_dblink                     IN varchar2,  -- database link where to clone the objects
    in_copy_missing_carriers      in varchar2,
    in_carrier_prono_zone_flag    in varchar2,
    in_carrier_tender_flag        in varchar2,
    in_equipment_cost_flag        in varchar2,
    in_ship_days_flag             in varchar2,
    in_alloc_rules_flag           IN varchar2, -- flag on whether to clone allocation rules
    in_locations_flag             in varchar2,
    in_goaltime_flag              in varchar2,
    in_copy_missing_customers     in varchar2,
    in_printers_flag              in varchar2,
    in_putaway_profile_flag       in varchar2,
    in_wave_profile_flag          in varchar2,
    in_requests_flag              in varchar2,
    in_userid                     IN varchar2,
    out_msg                       OUT varchar2
);

------------------------------------------------------------------------
--
-- clone_map -
--
------------------------------------------------------------------------
PROCEDURE clone_map 
(
    in_map                        in varchar2,
    in_new_map                    in varchar2,
    in_dblink                     in varchar2,
    in_userid                     in varchar2,
    out_msg                       out varchar2
);

------------------------------------------------------------------------
--
-- quote_string -
--
------------------------------------------------------------------------
function quote (in_string in varchar2) return varchar2;
function enabled (in_string in varchar2) return boolean;

PROCEDURE validate_item
(
    in_custid       IN varchar2,
    in_new_custid   IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
);

END zclone;
/
exit;
