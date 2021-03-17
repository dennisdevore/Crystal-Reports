--
-- $Id$
--
alter table weber_case_labels add
(
   storecode            varchar2(20),
   glncode              varchar2(20),
   dunsnumber           varchar2(20)
);

alter table weber_case_labels add
(
   conspassthruchar01   varchar2(100),
   conspassthruchar02   varchar2(100),
   conspassthruchar03   varchar2(100),
   conspassthruchar04   varchar2(100),
   conspassthruchar05   varchar2(100),
   conspassthruchar06   varchar2(100),
   conspassthruchar07   varchar2(100),
   conspassthruchar08   varchar2(100),
   conspassthruchar09   varchar2(100),
   conspassthruchar10   varchar2(100)
);

exit;
