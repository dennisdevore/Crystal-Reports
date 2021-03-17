--
-- $Id$
--
alter table custitem add
(
   treat_labeluom_separate    char(1) default 'N'
);

exit;
