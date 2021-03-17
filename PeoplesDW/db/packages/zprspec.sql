--
-- $Id$
--
create or replace package alps.zparserule as
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

PROCEDURE lookup_data
(
    in_ruleid   IN  varchar2,
    in_string   IN  varchar2,
    in_mask     IN  varchar2,
    out_string  OUT varchar2,
    out_mask    OUT varchar2
);


----------------------------------------------------------------------
--
-- parse_string
--
----------------------------------------------------------------------
PROCEDURE parse_string
(
    in_ruleid    IN         varchar2,
    in_string    IN         varchar2,
    out_serialno OUT        varchar2,
    out_lot      OUT        varchar2,
    out_user1    OUT        varchar2,
    out_user2    OUT        varchar2,
    out_user3    OUT        varchar2,
    out_mfgdate  OUT        varchar2,
    out_expdate  OUT        varchar2,
    out_country  OUT        varchar2,
    out_errmsg   IN OUT     varchar2
);

end zparserule;
/

-- exit;
