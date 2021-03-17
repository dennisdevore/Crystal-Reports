--
-- $Id: alter_tbl_custitem_passthrus.sql 2149 2010-04-30 19:11:27Z jeff $
--
alter table custitem add
(
   itmpassthrunum05         number(16,4),
   itmpassthrunum06         number(16,4),
   itmpassthrunum07         number(16,4),
   itmpassthrunum08         number(16,4),
   itmpassthrunum09         number(16,4),
   itmpassthrunum10         number(16,4),
   itmpassthruchar05        varchar2(255),
   itmpassthruchar06        varchar2(255),
   itmpassthruchar07        varchar2(255),
   itmpassthruchar08        varchar2(255),
   itmpassthruchar09        varchar2(255),
   itmpassthruchar10        varchar2(255)
);

exit;
