--
-- $Id$
--

alter table consignee add
(
   storecode            varchar2(20),
   glncode              varchar2(20),
   dunsnumber           varchar2(20),
   conspassthruchar09   varchar2(100),
   conspassthruchar10   varchar2(100)
);

exit;
