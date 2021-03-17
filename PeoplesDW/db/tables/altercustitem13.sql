--
-- $Id$
--
alter table custitem add(
      parseentryfield   varchar2(12),
      parseruleid       varchar2(10),
      parseruleaction   varchar2(1)
);
update custitem
   set parseruleaction = 'C'
 where parseruleaction is null;
commit;

-- exit;

