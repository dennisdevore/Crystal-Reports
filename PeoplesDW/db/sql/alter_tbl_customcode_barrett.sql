--
-- $Id
--
delete from customcode where businessevent = 'LDOP';
insert into customcode(businessevent, code, lastuser, lastupdate)
values('LDOP','begin' || chr(13)||chr(10)||
'   barrett.process_load_order(:DAT,''9900'');' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);

-- exit;
