--
-- $Id$
--
create or replace package alps.zreturns as
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
-- add_return
--
----------------------------------------------------------------------
PROCEDURE add_return
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_shipno    IN      number,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_serial    IN      varchar2,
    in_useritem1 IN      varchar2,
    in_useritem2 IN      varchar2,
    in_useritem3 IN      varchar2,
    in_qty       IN      number,
    in_uom       IN      varchar2,
    in_lpid      IN      varchar2,
    in_mlpid     IN      varchar2,
    in_reason    IN      varchar2,
    in_invstatus IN      varchar2,
    in_invclass  IN      varchar2,
    in_facility  IN      varchar2,
    in_location  IN      varchar2,
    in_user      IN      varchar2,
    in_weight    IN      number,
    in_expdate   IN      date,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- close_return
--
----------------------------------------------------------------------
PROCEDURE close_return
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_user      IN      varchar2,
    out_errmsg   OUT     varchar2
);

--------------------------------------------------------------------
--
-- close_multi_returns
--
----------------------------------------------------------------------
PROCEDURE close_multi_returns
(   
    in_included_rowids         IN      clob,
    in_facility                IN      varchar2,
    in_user                    IN      varchar2,
    out_errmsg                 OUT     varchar2,
    out_errorno                IN OUT  number,
    out_error_count            IN OUT  number,
    out_completed_count        IN OUT  number
);

PROCEDURE return_carryover
(in_orderid IN number
,in_shipid IN number
,in_new_orderid IN OUT number
,in_new_shipid IN OUT number
,in_user IN varchar2
,out_errmsg OUT varchar2
);

end zreturns;
/

exit;
