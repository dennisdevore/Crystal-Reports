--
-- $Id$
--
create or replace PACKAGE alps.zpronumber
IS

FUNCTION unused_prono_count
(in_carrier IN varchar2
,in_zone IN varchar2
) return number;

FUNCTION max_prono_seq
(in_carrier IN varchar2
,in_zone IN varchar2
) return number;

PROCEDURE cancel_prono
(in_carrier  IN varchar2
,in_zone    IN varchar2
,in_seq      IN number
,in_prono    IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

PROCEDURE undo_cancel_prono
(in_carrier  IN varchar2
,in_zone    IN varchar2
,in_seq      IN number
,in_prono    IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

PROCEDURE check_for_prono_assignment
(in_orderid  IN number
,in_shipid   IN number
,in_event    IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

PROCEDURE assign_pallet_defaults
(in_loadno   IN varchar2
,in_userid   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (unused_prono_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (max_prono_seq, WNDS, WNPS, RNPS);

END zpronumber;
/
show error package zpronumber;
--exit;