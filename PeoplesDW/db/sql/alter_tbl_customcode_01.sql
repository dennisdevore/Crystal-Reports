--
-- $Id$
--
insert into customcode(businessevent, code, lastuser, lastupdate)
values('MSPC','begin' || chr(13)||chr(10)||
'   pecas.zprod.process_multiship_carton(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);

-- exit;
