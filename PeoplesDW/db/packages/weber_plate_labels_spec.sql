--
-- $Id: weber_plate_labels_spec.sql 8844 2012-08-28 21:19:04Z ed $
--
create or replace package weber_platelbls as


procedure caseqty
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only
	 out_stmt  out varchar2);

end weber_platelbls;
/

show error package weber_platelbls;
exit;
