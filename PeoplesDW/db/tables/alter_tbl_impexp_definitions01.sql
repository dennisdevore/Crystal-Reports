--
-- $Id$
--
alter table impexp_definitions
add
(sip_format_yn char(1)
);

update impexp_definitions
set sip_format_yn = 'N'
where sip_format_yn is null;
commit;

--exit;
