--
-- $Id$
--
create or replace package alps.zabccycle as
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
-- calc_velocity
--
----------------------------------------------------------------------
PROCEDURE calc_velocity
(
    in_custid       IN      varchar2,
    in_start        IN      date,
    in_end          IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- create_tasks
--
----------------------------------------------------------------------
PROCEDURE create_tasks
(
    in_custid       IN      varchar2,
    in_days         IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- calc_abc_tasks
--
----------------------------------------------------------------------
PROCEDURE calc_abc_tasks
(
    in_custid       IN      varchar2,
    out_A_items     OUT     number,
    out_B_items     OUT     number,
    out_C_items     OUT     number,
    out_A_tasks     OUT     number,
    out_B_tasks     OUT     number,
    out_C_tasks     OUT     number,
    out_errmsg      OUT     varchar2
);

end zabccycle;
/

exit;
