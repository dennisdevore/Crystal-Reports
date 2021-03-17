--
-- $Id$
--
create or replace package alps.formatvalidation
as

procedure verify_format
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,	-- L(lot), S(serial), 1(user1), 2(user2), 3(user3)
	 in_data_value in varchar2,
	 out_action    out varchar2,  -- W(warn), P(prohibit)
    out_errno     out number, 	-- 0 implies no error
    out_errmsg    out varchar2); -- null implies no error

procedure verify_asncap_fmt
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,	-- L(lot), S(serial), 1(user1), 2(user2), 3(user3)
	 in_data_value in varchar2,
    in_orderid    in number,
    in_shipid     in number,
	 out_action    out varchar2,  -- W(warn), P(prohibit)
    out_errno     out number, 	-- 0 implies no error
    out_errmsg    out varchar2); -- null implies no error

procedure verify_format_lp_exists
	(in_lpid       in varchar2,
    in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,	-- L(lot), S(serial), 1(user1), 2(user2), 3(user3)
	 in_data_value in varchar2,
	 out_action    out varchar2,  -- W(warn), P(prohibit)
    out_errno     out number, 	-- 0 implies no error
    out_errmsg    out varchar2); -- null implies no error

function get_rcpt_dupes
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,	-- L(lot), S(serial), 1(user1), 2(user2), 3(user3)
	 in_data_value in varchar2)
return number;
pragma restrict_references (get_rcpt_dupes, wnds, wnps, rnps);

function is_value_for_mask
   (in_value in varchar2,
    in_mask  in varchar2)
return boolean;

function is_check_digit_ok
	(in_value in varchar2)
return boolean;

function is_valid_format
(in_custid      in varchar2,
 in_item        in varchar2,
 in_data_name	in varchar2,
 in_data_value  in varchar2
) return varchar2;

FUNCTION is_value_for_exclude_mask
   (in_value in varchar2,
    in_mask  in varchar2)
RETURN boolean;

procedure verify_orderedlot_format
	(in_custid 		in varchar2,
	 in_item 		  in varchar2,
	 in_lotnumber in varchar2,
	 out_errno    out number, 	  -- 0 implies no error
   out_errmsg   out varchar2); -- null implies no error

PRAGMA RESTRICT_REFERENCES (is_check_digit_ok, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_value_for_mask, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_valid_format, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_value_for_exclude_mask, WNDS, WNPS, RNPS);

end formatvalidation;
/

exit;
