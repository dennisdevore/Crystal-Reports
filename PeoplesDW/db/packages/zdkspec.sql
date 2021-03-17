--
-- $Id$
--
create or replace package alps.zdekit as
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
-- add_restored_lpid
--
----------------------------------------------------------------------
PROCEDURE add_restored_lpid
(
    in_kitlpid   IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_serial    IN      varchar2,
    in_useritem1 IN      varchar2,
    in_useritem2 IN      varchar2,
    in_useritem3 IN      varchar2,
    in_countryof IN      varchar2,
    in_expdate   IN      date,
    in_mfgdate   IN      date,
    in_qty       IN      number,
    in_uom       IN      varchar2,
    in_lpid      IN      varchar2,
    in_mlpid     IN      varchar2,
    in_invstatus IN      varchar2,
    in_invclass  IN      varchar2,
    in_facility  IN      varchar2,
    in_location  IN      varchar2,
    in_user      IN      varchar2,
    in_handtype  IN      varchar2,
    in_action    IN      varchar2,
    in_weight    IN      number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- complate_dekit -
--
----------------------------------------------------------------------
PROCEDURE complete_dekit
(
   in_lpid     IN  varchar2,
   in_location IN  varchar2,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
);


end zdekit;
/

exit;
