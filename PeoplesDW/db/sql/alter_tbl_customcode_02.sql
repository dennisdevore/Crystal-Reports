--
-- $Id$
--
insert into customcode(businessevent, code, lastuser, lastupdate)
values('STPR','begin' || chr(13)||chr(10)||
'   pecas.zprod.lp_to_prod(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);

exit;
