create or replace package pacam_becolbls as



procedure pa_plate_beco
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure pa_lp_beco_r
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure pa_order_beco
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

end pacam_becolbls;
/

show error package pacam_becolbls;
exit;
