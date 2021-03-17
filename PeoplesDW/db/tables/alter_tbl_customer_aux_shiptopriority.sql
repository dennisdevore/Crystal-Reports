--
-- $Id$
--
alter table customer_aux add(
        shiptopriority    char(1)
);

update customer_aux
   set shiptopriority  = 'N'
   where shiptopriority is null;

commit;
-- exit;