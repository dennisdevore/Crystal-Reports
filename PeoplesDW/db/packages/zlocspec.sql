--
-- $Id$
--
create or replace package alps.zlocation
as

procedure get_drop_loc
	(in_facility  in varchar2,
    in_fromloc   in varchar2,
    in_destloc   in varchar2,
    in_equipment in varchar2,
    in_zone_col  in varchar2,
    out_droploc  out varchar2,
    out_message  out varchar2);

procedure drop_plate_at_loc
	(in_lpid         in varchar2,
    in_destloc      in varchar2,
    in_droploc      in varchar2,
    in_lpstatus     in varchar2,
    in_user         in varchar2,
    in_taskid       in number,
    in_tasktype     in varchar2,
    out_error       out varchar2,
    out_msgno       out number,
    out_message     out varchar2,
	 out_loaded_load out varchar2);  -- non-zero if load switched to status '8'; else 0

procedure get_stage_loc
	(in_facility  in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_orderid   in number,
    in_shipid    in number,
    io_stageloc  in out varchar2,
    out_loadloc  out varchar2,
    out_message  out varchar2);

procedure rank_locations
	(in_facility  in varchar2);
procedure reset_location_status
  (in_facility  in varchar2,
   in_locid     in varchar2,
   out_error    out varchar2,
   out_message  out varchar2);
	
end zlocation;
/

exit;
