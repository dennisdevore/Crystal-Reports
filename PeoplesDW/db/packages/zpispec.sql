--
-- $Id$
--
create or replace package alps.zphinv as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
-- Physical Inventory Status
PI_READY      CONSTANT    char(2) := 'RD';
PI_COUNTED    CONSTANT    char(2) := 'CT';
PI_NOTCOUNTED CONSTANT    char(2) := 'NC';
PI_CANCELLED  CONSTANT    char(2) := 'CA';
PI_PROCESSED  CONSTANT    char(2) := 'PR';

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

PROCEDURE start_physical_inventory
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_paper        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
);
----------------------------------------------------------------------
--
-- start_phinv
--
----------------------------------------------------------------------
PROCEDURE start_phinv
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- start_phinv_paper
--
----------------------------------------------------------------------
PROCEDURE start_phinv_paper
(
    in_facility     IN      varchar2,
    in_zone         IN      varchar2,
    in_fromloc      IN      varchar2,
    in_toloc        IN      varchar2,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_id          OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- generate_phinv_task
--
----------------------------------------------------------------------
PROCEDURE generate_phinv_task
(
    in_id           IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_paper        IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- count_phinv_task
--
----------------------------------------------------------------------
PROCEDURE count_phinv_task
(
    in_taskid       IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_checkdigit   IN      varchar2,
    in_custid       IN      varchar2,
    in_lpid         IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber        IN      varchar2,
    in_qty          IN      number,
    in_override     IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- complete_phinv_task
--
----------------------------------------------------------------------
PROCEDURE complete_phinv_task
(
    in_taskid       IN      number,
    in_facility     IN      varchar2,
    in_location     IN      varchar2,
    in_checkdigit   IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- complete_phinv_request
--
----------------------------------------------------------------------
PROCEDURE complete_phinv_request
(
    in_id           IN      number,
    in_type         IN      varchar2,
    in_user         IN      varchar2,
    in_validate_only IN     varchar2,
    out_errmsg      OUT     varchar2
);


PROCEDURE recount_request
(
    in_id       IN      number,
    in_location     IN      varchar2,
    in_custid       IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber        IN      varchar2,
    in_lpid         IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- count_phinv_task
--
----------------------------------------------------------------------
procedure count_ai_phinv_task
(
    in_taskid       in      number,
    in_facility     in      varchar2,
    in_location     in      varchar2,
    in_checkdigit   in      varchar2,
    in_custid       in      varchar2,
    in_item         in      varchar2,
    in_lotnumber    in      varchar2,
    in_qty          in      number,
    in_override     in      varchar2,
    in_user         in      varchar2,
    out_errno       out     number,
    out_errmsg      out     varchar2
);

end zphinv;
/

exit;
