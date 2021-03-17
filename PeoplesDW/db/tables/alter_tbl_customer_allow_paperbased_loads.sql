--
-- $Id$
--
alter table customer add(
        allow_paperbased_loads    char(1)
);

update customer
   set allow_paperbased_loads  = 'N'
   where allow_paperbased_loads is null;

commit;
-- exit;