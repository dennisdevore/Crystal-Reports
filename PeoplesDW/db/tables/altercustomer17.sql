--
-- $Id$
--
alter table customer add(
      parseentryfield   varchar2(12),
      parseruleid       varchar2(10),
      parseruleaction   varchar2(1)
);
update customer
set parseruleaction = 'N'
where parseruleaction is null;
commit;

-- exit;

