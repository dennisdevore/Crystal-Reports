--
-- $Id $
--
alter table customer_aux add
(
 overwrite_importfileid_yn char(1)
);

update customer_aux
   set overwrite_importfileid_yn = 'N'
 where overwrite_importfileid_yn is null;

exit;