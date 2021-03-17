--
-- $Id$
--
alter table impexp_chunks
add
(fieldprefix varchar2(255)
,substring_position number(7)
,substring_length number(7)
);
alter table oldexp_chunks
add
(fieldprefix varchar2(35)
,substring_position number(7)
,substring_length number(7)
);
--exit;
