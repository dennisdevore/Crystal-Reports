--
-- $Id: zlhspec.sql 1 2005-05-26 12:20:03Z ed $
--
create or replace package alps.zloadhistory as
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
-- add_loadhistory
--
----------------------------------------------------------------------
PROCEDURE add_loadhistory
(
    in_loadno       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

PROCEDURE add_loadhistory_autonomous
(
    in_loadno       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

end zloadhistory;
/

exit;
