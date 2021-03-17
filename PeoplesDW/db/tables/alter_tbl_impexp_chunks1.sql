--
-- $Id$
--
alter table impexp_chunks
modify
(paramname varchar2(35)
);
alter table oldexp_chunks
modify
(paramname varchar2(35)
);
exit;
