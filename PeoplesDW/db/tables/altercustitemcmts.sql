--
-- $Id$
--
alter table custitembolcomments
modify
(item varchar2(50)
);
alter table custitemincomments
modify
(item varchar2(50)
);
alter table custitemoutcomments
modify
(item varchar2(50)
);
exit;
