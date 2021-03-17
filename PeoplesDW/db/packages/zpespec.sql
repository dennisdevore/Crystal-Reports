--
-- $Id$
--
create or replace package alps.zpickentry as
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
-- pick_subtask
--
----------------------------------------------------------------------
PROCEDURE pick_subtask
(
    in_taskid       IN      number,
    in_shippinglpid IN      varchar2,
    in_picklpid     IN      varchar2,
    in_pickloc      IN      varchar2,
    in_pickqty      IN      number,
    in_reason       IN      varchar2,
    in_label        IN      varchar2,
    in_serialno     IN      varchar2,
    in_lotno	    IN      varchar2,
    in_user1	    IN	    varchar2,
    in_user2        IN      varchar2,
    in_user3        IN      varchar2,
    in_user         IN      varchar2,
    in_weight       IN      number,
    out_errmsg      OUT     varchar2
);


----------------------------------------------------------------------
--
-- stage_plate
--
----------------------------------------------------------------------
PROCEDURE stage_plate
(
    in_taskid       IN      number,
    in_lpid         IN      varchar2,
    in_loc          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

procedure confirm_picks_for_load
(in_loadno IN number
,in_stageloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure load_plates_for_load
(in_facility IN varchar2
,in_loadno IN number
,in_doorloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);
end zpickentry;
/
show error package zpickentry;

exit;
