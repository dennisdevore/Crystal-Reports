--
-- $Id$
--
create or replace package alps.zloadplates as
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
-- start_loading
--
----------------------------------------------------------------------

PROCEDURE crt_start_loading
(
    in_facility  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    out_overage  OUT     varchar2,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- load_plate
--
----------------------------------------------------------------------
PROCEDURE load_plate
(
    in_facility  IN      varchar2,
    in_stageloc  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_lpid      IN      varchar2,
    in_user      IN      varchar2,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- check_plate_load
--
----------------------------------------------------------------------
procedure check_plate_load
(
    in_lpid        in varchar2,
    in_termid      in varchar2,
    in_userid      in varchar2,
    out_message    out varchar2
);


end zloadplates;
/

exit;
