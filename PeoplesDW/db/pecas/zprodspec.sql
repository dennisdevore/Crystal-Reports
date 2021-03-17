--
-- $Id$
--
create or replace package zprod as

BaseAddType constant number(3) := 0;

BaseUOM_    constant varchar2(4) := 'PCS';
CtnUOM_    constant varchar2(4) := 'CTN';
PltUOM_    constant varchar2(4) := 'PLT';


----------------------------------------------------------------------
--
-- create_load_flag - Create Load Flags for an Order
--
----------------------------------------------------------------------
PROCEDURE create_load_flag
(
    in_orderid  number,
    in_shipid   number,
    in_jobno    varchar2,
    in_item     varchar2,
    in_pieces   number,
    in_cartons  number,
    in_overage  number,
    in_dt       date,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- next_skid_build
--
----------------------------------------------------------------------
PROCEDURE next_skid_build
(
    out_buildno  OUT number
);

----------------------------------------------------------------------
--
-- clear_cartons - Clear cartons for a session
--
----------------------------------------------------------------------
PROCEDURE clear_cartons
(
    in_buildno  number
);

----------------------------------------------------------------------
--
-- create_cartons - Create Cartons for an Order
--
----------------------------------------------------------------------
PROCEDURE create_cartons
(
    in_buildno  number,
    in_orderid  number,
    in_shipid   number,
    in_jobno    varchar2,
    in_item     varchar2,
    in_pieces   number,
    in_cartons  number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- merge_cartons - Merge Cartons into skids
--
----------------------------------------------------------------------
PROCEDURE merge_cartons
(
    in_buildno  number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- create_carton_skids - Merge Cartons into skids
--
----------------------------------------------------------------------
PROCEDURE create_carton_skids
(
    in_buildno  number,
    in_jobno    varchar2,
    in_cartons  number,
    in_method   varchar2,   -- ORDER, SIZE
    out_errmsg  OUT varchar2
);


----------------------------------------------------------------------
--
-- create_carton_load_flags - Merge Cartons into load_flags
--
----------------------------------------------------------------------
PROCEDURE create_carton_load_flags
(
    in_buildno  number,
    in_jobno    varchar2,
    in_type     varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- update_carton_skid - update carton number for skid
--
----------------------------------------------------------------------
PROCEDURE update_carton_skid
(
    in_buildno  number,
    in_orderid  number,
    in_shipid   number,
    in_carton   number,
    in_skid     number, 
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- update_carton_weights - update carton weights by size
--
----------------------------------------------------------------------
PROCEDURE update_carton_weight
(
    in_buildno  number,
    in_item     varchar2,
    in_pieces   number,
    in_weight   number, 
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- receive_wip_plate - receive a work in process plate
--
----------------------------------------------------------------------
PROCEDURE receive_wip_plate
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_jobno    varchar2,
    in_custid   varchar2,
    in_item     varchar2,
    in_qty      number,
    in_uom      varchar2,
    in_weight   number,
    in_userid   varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT  varchar2
);

----------------------------------------------------------------------
--
-- receive_fg_over_plate - receive a finished goods overs plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_over_plate
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_jobno    varchar2,
    in_custid   varchar2,
    in_item     varchar2,
    in_qty      number,
    in_uom      varchar2,
    in_weight   number,
    in_userid   varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT  varchar2
);

----------------------------------------------------------------------
--
-- plate_to_production
--
----------------------------------------------------------------------
PROCEDURE plate_to_production(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- complete_production_order
--
----------------------------------------------------------------------
PROCEDURE complete_production_order(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  out varchar2
);

----------------------------------------------------------------------
--
-- putaway_plate
--
----------------------------------------------------------------------
PROCEDURE putaway_plate(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- copy_load_flag_dtl_wk - copies current load_flag_dtl table to work table
--
----------------------------------------------------------------------
PROCEDURE copy_load_flag_dtl_wk(
    in_lpid     IN  varchar2
);

----------------------------------------------------------------------
--
-- clear_load_flag_dtl_wk - clears current load_flag_dtl work table
--
----------------------------------------------------------------------
PROCEDURE clear_load_flag_dtl_wk(
    in_lpid     IN  varchar2
);

----------------------------------------------------------------------
--
-- update_load_flag_dtl_wk - copies current load_flag_dtl_wk table to 
--          actual load_flag_dtl table
--
----------------------------------------------------------------------
PROCEDURE update_load_flag_dtl_wk(
    in_lpid     IN  varchar2
);

----------------------------------------------------------------------
--
-- update_LFD_entry - update new values for a single LFD work entry
--
----------------------------------------------------------------------
PROCEDURE update_LFD_entry
(
    in_lpid     IN  varchar2,
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_item     IN  varchar2,
    in_orig_pieces  IN  varchar2,
    in_pieces   IN  number,
    in_quantity IN  number,
    in_weight   IN  number,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- receive_fg_load_flag - receive a finished goods overs plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_load_flag
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- fetch_picked_inventory
--
----------------------------------------------------------------------
PROCEDURE fetch_picked_inventory
(
    in_orderid  varchar2,
    in_shipid   varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- fetch_picked_load
--
----------------------------------------------------------------------
PROCEDURE fetch_picked_load
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- lp_to_prod
--
----------------------------------------------------------------------
PROCEDURE lp_to_prod
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- split_order
--
----------------------------------------------------------------------
PROCEDURE split_order
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- cancel_load_flag
--
----------------------------------------------------------------------
PROCEDURE cancel_load_flag
(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- regen_load_flag
--
----------------------------------------------------------------------
PROCEDURE regen_load_flag
(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_qty      IN  number,
    in_pieces   IN  number,
    in_cartons  IN  number,
    in_userid   IN  varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- process_multiship_carton
--
----------------------------------------------------------------------
PROCEDURE process_multiship_carton
(
    in_data IN OUT alps.cdata
);

END zprod;
/
exit;
