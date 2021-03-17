--
-- $Id$
--
create or replace package alps.rfloading as

procedure set_ancestor_data
   (in_lpid     in varchar2,
    out_message out varchar2);

procedure start_loading
   (in_facility  in varchar2,
    in_dockdoor  in varchar2,
    in_equipment in varchar2,
	 in_user      in varchar2,
    out_loadno   out number,
    out_checkid  out varchar2,
    out_overage  out varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure wand_shipplate
   (io_shlpid    in out varchar2,
    in_user      in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_fac       in varchar2,
    in_loc       in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure load_shipplates
   (in_fac       in varchar2,
    in_user      in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_dockdoor  in varchar2,
    out_error    out varchar2,
    out_message  out varchar2,
    out_is_loaded out varchar2);

procedure start_unloading
   (in_facility  in varchar2,
    in_dockdoor  in varchar2,
    in_equipment in varchar2,
	 in_user      in varchar2,
    out_loadno   out number,
    out_error    out varchar2,
    out_message  out varchar2);

procedure wand_shlp_for_unload
   (io_shlpid    in out varchar2,
    in_user      in varchar2,
    in_loadno    in number,
    in_fac       in varchar2,
    in_dock      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure unload_a_plate
   (in_shlpid    in varchar2,
    in_stage_loc in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure combine_mast
   (in_fromlp     in varchar2,
    in_tolp       in varchar2,
    in_mplp       in varchar2,
    in_user       in varchar2,
    in_use_carton in varchar2,
    out_toloc     out varchar2,
    out_cust      out varchar2,
    out_error     out varchar2,
    out_message   out varchar2);

procedure split_mast
   (in_qty       in number,
    in_id        in varchar2,
    in_idtype    in varchar2,
    in_idlot     in varchar2,
    in_fromlp    in varchar2,
    in_fromtype  in varchar2,
    in_frommship in varchar2,
    in_tolp      in varchar2,
    in_tomship   in varchar2,
    in_user      in varchar2,
    in_cust      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure build_mast
   (in_master   in varchar2,
    io_mstlpid  in out varchar2,
    in_addlpid  in varchar2,
    in_user     in varchar2,
    in_facility in varchar2,
    in_location in varchar2,
    out_custid  out varchar2,
    out_error   out varchar2,
    out_message out varchar2);

end rfloading;
/

exit;
