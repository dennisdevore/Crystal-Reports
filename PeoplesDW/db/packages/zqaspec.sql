--
-- $Id$
--
create or replace package alps.zqainspection as
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

PROCEDURE establish_auto_po_item_request
(
    in_custid    IN      varchar2,
    in_po        IN      varchar2,
    in_userid    IN      varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- next_id
--
----------------------------------------------------------------------
PROCEDURE next_id
(
    out_id  OUT   number,
    out_msg OUT   varchar2
);

----------------------------------------------------------------------
--
-- add_qa_plate
--
----------------------------------------------------------------------
PROCEDURE add_qa_plate
(
    in_lpid      IN      varchar2,
    in_user      IN      varchar2,
    out_action   OUT     varchar2,
    out_id       OUT     number,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- change_qa_plate
--
----------------------------------------------------------------------
PROCEDURE change_qa_plate
(
    in_lpid      IN      varchar2,
    in_status    IN      varchar2,
    in_user      IN      varchar2,
    out_adj1     OUT     varchar2,
    out_adj2     OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
);


----------------------------------------------------------------------
--
-- check_qa_order
--
----------------------------------------------------------------------
PROCEDURE check_qa_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_user      IN      varchar2,
    out_action   OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- check_qa_order_item
--
----------------------------------------------------------------------
PROCEDURE check_qa_order_item
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_qty       IN      number,
    in_user      IN      varchar2,
    out_qty      OUT     number,
    out_action   OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- complete_inspection-
--
-----------------------------------------------------------------------
PROCEDURE complete_inspection
(
    in_id       IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_item     IN      varchar2,
    in_lot      IN      varchar2,
    in_passfail IN      varchar2, -- PASS if matches percentage
                                  -- FAIL if matches percentage
                                  -- F_PASS - force pass
                                  -- F_FAIL - force fail
    in_user     IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

PROCEDURE qa_cancel_request
(
    in_id       IN      number,
    in_userid   IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

PROCEDURE inspect_lp
(
    in_lpid     IN      varchar2,
    in_result   IN      varchar2, -- '1'-Pass; '2'-Fail
    in_userid   IN      varchar2,
    in_facility IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

procedure delete_in_plate
(
    in_lpid      in  varchar2,
    out_errmsg   out varchar2
);

PROCEDURE set_virtual_status
(
    in_lpid     IN      varchar2,
    in_invstatus IN     varchar2,
    in_po       IN      varchar2,
    in_userid   IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
);

end zqainspection;
/

exit;
