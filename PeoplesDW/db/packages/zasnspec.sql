--
-- $Id$
--
create or replace package alps.zasncapture as
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
-- check_plate
--
----------------------------------------------------------------------
PROCEDURE check_plate
(
    in_lpid           IN      varchar2,
    in_print          IN      varchar2,
    in_ignore_anvdate IN      varchar2,
    out_errno         OUT     number,
    out_errmsg        OUT     varchar2
);

----------------------------------------------------------------------
--
-- consolidate_plate
--
----------------------------------------------------------------------
PROCEDURE consolidate_plate
(
    in_lpid         IN      varchar2,
    in_user         IN      varchar2,
    out_errno       OUT     number,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- plate_has_asn_data
--
----------------------------------------------------------------------
FUNCTION plate_has_asn_data
(
    in_lpid   IN     varchar2
)
RETURN varchar2;


PRAGMA RESTRICT_REFERENCES (plate_has_asn_data, WNDS, WNPS, RNPS);

end zasncapture;
/

exit;
