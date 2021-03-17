--
-- $Id$
--
create or replace package alps.zcloneitem as
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
-- clone_item
--
----------------------------------------------------------------------
PROCEDURE clone_item
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_new_custid IN      varchar2,
    in_new_item   IN      varchar2,
    in_userid     IN      varchar2,
    out_errmsg  OUT     varchar2
);

PROCEDURE clone_kit
(
    in_from_custid   IN      varchar2,
    in_from_item     IN      varchar2,
    in_to_custid     IN      varchar2,
    in_to_item       IN      varchar2,
    in_userid        IN      varchar2,
    out_errmsg       OUT     varchar2
);

end zcloneitem;
/

-- exit;
