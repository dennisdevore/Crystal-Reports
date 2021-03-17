create or replace package d2_labels as

procedure d2_order
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure d2_plate
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

end d2_labels;
/

show error package d2_labels;
exit;
