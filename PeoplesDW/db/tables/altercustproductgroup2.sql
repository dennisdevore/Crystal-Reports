--
-- $Id$
--
alter table custproductgroup add(
      parseentryfield   varchar2(12),
      parseruleid       varchar2(10),
      parseruleaction   varchar2(1)
);
update custproductgroup
   set parseruleaction = 'C'
 where parseruleaction is null;
commit;

-- exit;
