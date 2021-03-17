--
-- $Id: zydspec.sql 727 2006-03-27 16:12:12Z ed $
--
create or replace package alps.zyard
as

procedure get_yard_totals
(in_yard in varchar2
,out_empties_in_yard out number
,out_loaded_in_yard out number
,out_empties_in_door out number
,out_loading_in_door out number
,out_loaded_in_door out number
,out_msg out varchar2
);

procedure validate_trailer
(in_loadno in number
,in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,in_facility in varchar2
,out_errorno out number
,out_message out varchar2
);

procedure update_trailer
(in_loadno in number
,in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,out_errorno out number
,out_message out varchar2
,in_location in varchar2 default null
);

function has_cust_data
(in_loadno in number
,in_disposition in varchar2
,in_custid in varchar2
,in_item in varchar2
)
return varchar2;

procedure move_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure move_closed_load_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure assign_trailer_to_load
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_loadno varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure deassign_trailer_from_load
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure late_trailer_check;

procedure check_trailer_in
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location in varchar2
,in_loadno in number
,in_gate_time_in in date
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure check_trailer_out
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,in_gate_time_out in date
,out_errorno out number
,out_msg out varchar2
);

procedure back_to_intransit
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

procedure release_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_location in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
);

PRAGMA RESTRICT_REFERENCES (has_cust_data, WNDS, WNPS, RNPS);

end zyard;
/

show errors package zyard;
exit;

