--
-- $Id: barrett_label_spec.sql 1 2005-05-26 12:20:03Z ed $
--
create or replace package mass_man_lbls as


procedure mass_man_labels
	(in_taskid in number,
	 in_func   in varchar2,			-- Q - query, X - execute
	 out_stmt  out varchar2);

procedure mass_man_nolabels
	(in_wave in number);

end mass_man_lbls;
/

show error package mass_man_lbls;
exit;
