--
-- $Id$
--
create or replace package alps.zorderhistory as
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
-- add_orderhistory_item
--
----------------------------------------------------------------------
PROCEDURE add_orderhistory_item
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_lpid         IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber    IN      varchar2,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- add_orderhistory
--
----------------------------------------------------------------------
PROCEDURE add_orderhistory
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

end zorderhistory;
/

exit;
