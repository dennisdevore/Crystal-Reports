--
-- $Id$
--
alter table custitem
add
(needs_review_yn char(1)
);

update custitem
   set needs_review_yn = 'N'
 where needs_review_yn is null;
commit;

exit;
