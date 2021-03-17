--
-- $Id$
--
create or replace package alps.zwatch as

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

end zwatch;
/

exit;
