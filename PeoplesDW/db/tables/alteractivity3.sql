--
-- $Id$
--
alter table activity add(
      irisclass      varchar2(8),   -- service class
      irisname       varchar2(4),   -- service name
      irischarge     varchar2(1),   -- include charge = 'Y'
      iristype       varchar2(4),   -- type = SHIP, RECV, ANCL
      irisorder      number(3)      -- Order in sequence
);

exit;
