--
-- $Id$
--
create or replace package alps.zbillutility as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- from_uom_to_uom - try to go from one uom to another uom
--
----------------------------------------------------------------------
PROCEDURE from_uom_to_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    in_skips    IN      varchar2,
    io_level    IN OUT  integer,
    io_qty      IN OUT     number,
    io_errmsg   IN OUT     varchar2
);

----------------------------------------------------------------------
--
-- translate_uom - determine uom qty from one uom to another
--
----------------------------------------------------------------------
PROCEDURE translate_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    out_qty     OUT     number,
    out_errmsg  OUT     varchar2
);


----------------------------------------------------------------------
--
-- translate_uom_function - determine uom qty from one uom to another
--
----------------------------------------------------------------------
FUNCTION translate_uom_function
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2
)
RETURN number;


----------------------------------------------------------------------
--
-- invoice_total
--
----------------------------------------------------------------------
FUNCTION invoice_total
(
    in_invoice   IN      number,
    in_invtype   IN      varchar2
)
RETURN number;


----------------------------------------------------------------------
--
-- master_invoice_total
--
----------------------------------------------------------------------
FUNCTION master_invoice_total
(
    in_master    IN      varchar2
)
RETURN number;

----------------------------------------------------------------------
--
-- invoice_check_sum
--
----------------------------------------------------------------------
FUNCTION invoice_check_sum
(
    in_invoice   IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- asof_begin
--
----------------------------------------------------------------------
FUNCTION asof_begin
(
    in_facility  IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_inventoryclass IN      varchar2,
    in_effdate   IN      date
)
RETURN number;

----------------------------------------------------------------------
--
-- asof_end
--
----------------------------------------------------------------------
FUNCTION asof_end
(
    in_facility  IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_inventoryclass IN      varchar2,
    in_effdate   IN      date
)
RETURN number;

----------------------------------------------------------------------
--
-- item_rategroup
--
----------------------------------------------------------------------
FUNCTION item_rategroup
(
    in_custid    IN      varchar2,
    in_item      IN      varchar2
)
RETURN rategrouptype;

----------------------------------------------------------------------
--
-- rategroup
--
----------------------------------------------------------------------
FUNCTION rategroup
(
    in_custid    IN      varchar2,
    in_rategroup IN      varchar2
)
RETURN rategrouptype;

----------------------------------------------------------------------
--
-- check_rg_bm_event
--
----------------------------------------------------------------------
function check_rg_bm_event
(
  in_custid in varchar2,
  in_rategroup in varchar2,
  in_billmethod in varchar2,
  in_event in varchar2,
  in_effdate in date
)
return number;

----------------------------------------------------------------------
--
-- get_handling_types
--
----------------------------------------------------------------------
function get_handling_types
(
  in_lpid in varchar2
)
return varchar2;

----------------------------------------------------------------------
--
-- get_lottrack_req
--
----------------------------------------------------------------------
function prnt_get_lottrack_req
(
  in_lpid in varchar2,
  in_event in varchar2,
  in_effdate in date
)
return varchar2;

----------------------------------------------------------------------
--
-- check_asof - determine if there is inventory in facility for
--      the customer on the specified date
--
----------------------------------------------------------------------
FUNCTION check_asof
(in_facility IN varchar2
,in_custid IN varchar2
,in_billdate IN date
) return varchar2;

----------------------------------------------------------------------
--
-- next_daily_billing - return datetime when daily billing job should run
--
----------------------------------------------------------------------
FUNCTION next_daily_billing
return date;

----------------------------------------------------------------------
--
-- check_expiregrace - determine if there is any item with 
-- expired grace period.
--
----------------------------------------------------------------------
FUNCTION check_expiregrace
(  in_facility IN varchar2
  ,in_custid   IN varchar2
  ,in_billdate IN date

) return varchar2;

function in_num_clause
(in_indicator varchar2
,in_values varchar2
) return varchar2;
PRAGMA RESTRICT_REFERENCES (from_uom_to_uom, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (invoice_total, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (master_invoice_total, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (invoice_check_sum, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (asof_begin, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (asof_end, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_rategroup, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (rategroup, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (check_asof, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (in_num_clause, WNDS, WNPS, RNPS);

end zbillutility;
/

exit;
