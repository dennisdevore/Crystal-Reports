--
-- $Id$
--
create or replace package alps.simplesort as

procedure check_order
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    out_stageloc out varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure sort_and_stage_order
   (in_facility in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_lpid     in varchar2,
    in_stageloc in varchar2,
    in_user     in varchar2,
    out_toplpid out varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure sort_and_stage_wave
   (in_wave     in number,
    in_user     in varchar2,
    out_message out varchar2);

procedure sort_and_stage_sst
   (in_facility in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_lpid     in varchar2,
    in_stageloc in varchar2,
    in_user     in varchar2,
    out_toplpid out varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure add_extra_pick
   (in_subtask_rowid in varchar2,
    in_shlpid        in varchar2,
    in_pickqty       in number,
    in_pickuom       in varchar2,
    in_user          in varchar2,
    in_pickedlp      in varchar2,
    out_lpid         out varchar2,
    out_rowid        out varchar2,
    out_message out varchar2);


end simplesort;
/

exit;
