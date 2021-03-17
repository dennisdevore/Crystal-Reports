--
-- $Id$
--
create or replace package alps.zaudit as

function which_unique_index(in_table_name varchar2)
return varchar2;

procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in varchar2,
    in_old_value in varchar2,
    in_origin    in varchar2);

procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in number,
    in_old_value in number,
    in_origin    in varchar2);

procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in date,
    in_old_value in date,
    in_origin    in varchar2);

PROCEDURE get_next_modseq
(in_table_name_old varchar2
,in_table_name_new varchar2
,out_modseq OUT number
,out_msg IN OUT varchar2
);

function table_name
(in_table_name varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (which_unique_index, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (table_name, WNDS, WNPS, RNPS);

end zaudit;
/

exit;
