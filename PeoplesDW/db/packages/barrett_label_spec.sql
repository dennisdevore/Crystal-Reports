--
-- $Id$
--
create or replace package barrett_lbls as


procedure lpyr_michaels
	(in_taskid in number,
	 in_func   in varchar2,			-- Q - query, X - execute
	 out_stmt  out varchar2);


end barrett_lbls;
/

show error package barrett_lbls;
exit;
