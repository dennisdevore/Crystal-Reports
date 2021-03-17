--
-- $Id$
--
create or replace PACKAGE alps.zloadentry
IS

FUNCTION inbound_variance_on_order
(in_orderid IN number
,in_shipid IN number
) return varchar2;

PROCEDURE get_next_loadno
(out_loadno OUT number
,out_msg IN OUT varchar2
);

FUNCTION loadtype_abbrev
(in_loadtype IN varchar2
) return varchar2;

FUNCTION unknown_lip_count
(in_loadno IN number
) return number;

FUNCTION loads_rcvddate
(in_loadno IN number
) return date;

PROCEDURE assign_inbound_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

function calccheckdigit (in_Data in varchar2)
  RETURN varchar2;

PROCEDURE assign_outbound_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE assign_freight_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE arrive_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_receiptdate IN date
,in_useplateloc IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE arrive_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE close_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
,in_yard IN varchar2 default null
);

PROCEDURE close_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_prono IN varchar2
,in_shipdate IN date
,in_userid IN varchar2
,in_force_close IN varchar2
,out_regen_needed OUT varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE deassign_order_from_load
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_manual IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE unarrive_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_trailer_location in varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE unarrive_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_trailer_location in varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE cancel_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE min_load_status
(in_loadno in number
,in_facility in varchar2
,in_min_status varchar2
,in_userid varchar2);

PROCEDURE min_loadstop_status
(in_loadno in number
,in_stopno in number
,in_facility in varchar2
,in_min_status varchar2
,in_userid varchar2);

PROCEDURE release_inbound_door
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE free_door
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE check_for_interface
(in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_regordtypeparam IN varchar2
,in_regfmtparam IN varchar2
,in_retordtypeparam IN varchar2
,in_retfmtparam IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE begin_inbound_load
(in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE begin_outbound_load
(in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

FUNCTION loadstopstatus_abbrev
(in_loadstopstatus varchar2
) return varchar2;

FUNCTION loadstatus_abbrev
(in_loadstatus varchar2
) return varchar2;

PROCEDURE check_for_vics
(in_loadno IN number
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

function is_split_facility_order
   (in_orderid in number,
    in_shipid  in number)
return boolean;

PROCEDURE check_reopen_inbound
(in_loadno IN number
,out_msg  IN OUT varchar2
);


PROCEDURE reopen_inbound
(in_loadno IN number
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);


PROCEDURE move_out_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_yard_facility varchar2
,in_yard_location varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE move_out_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_yard_facility varchar2
,in_yard_location varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE move_load_in
(in_loadno IN number
,in_facility IN varchar2
,in_doorloc IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

procedure set_trailer_temps
(in_loadno IN number
,in_user IN varchar2
,in_nosetemp IN number
,in_middletemp IN number
,in_tailtemp IN number
,out_msg IN OUT varchar2
);

PROCEDURE close_freight_load
(in_loadno IN number
,in_facility IN varchar2
,in_prono IN varchar2
,in_shipdate IN date
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

procedure request_pack_lists
(in_loadno number
,in_printer varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

FUNCTION outbound_arrivaldate
(in_loadno IN number
) return date;

procedure calc_door_rankings
(in_facility varchar2
,in_loadtype varchar2 -- 'inbound' or 'outbound'
,in_loadno number
,in_orderid number
,in_shipid number
,in_userid varchar2
,out_msg OUT varchar2
);
procedure insert_dummy_plate_row
(lp IN plate%rowtype
,out_msg IN OUT varchar2
);
procedure delete_dummy_plate_row
(in_lpid IN varchar2
,out_msg IN OUT varchar2
);
PROCEDURE ld_debug_msg
(in_author varchar2
,in_facility varchar2
,in_custid varchar2
,in_msgtext varchar2
,in_msgtype varchar2
,in_userid varchar2
);
PROCEDURE update_stop_shipment_stageloc
(in_facility IN varchar2
,in_loadno IN number
,in_wave IN number
,in_shipto IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_stopno IN OUT number
,in_shipno IN OUT number
,in_stageloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);
PROCEDURE receipt_carryover
(in_orderid IN number
,in_shipid IN number
,in_new_orderid IN OUT number
,in_new_shipid IN OUT number
,in_userid IN varchar2
,out_msg OUT varchar2
);

FUNCTION get_load_for_plate
(in_lpid IN varchar2)
return number;

FUNCTION specify_changeproc
(in_changeproc IN varchar2)
return varchar2;

PROCEDURE check_labels
(in_loadno IN number
,in_no_label_orders IN varchar2
,out_regen_needed OUT varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE log_no_regen_close
(in_loadno IN number
,in_userid IN varchar2
,in_facility IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE close_inbound_upadj
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (loadtype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (unknown_lip_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loads_rcvddate, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadstopstatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadstatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_split_facility_order, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (inbound_variance_on_order, WNDS, WNPS, RNPS);

END zloadentry;
/
show error package zloadentry;
exit;
