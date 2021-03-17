--
-- $Id$
--
create table carrierzone
(
  carrier                 varchar2(4) not null,
  zone                    varchar2(32) not null,
  min_unused_prono_count  number(12),
  lastuser                varchar2(12),
  lastupdate              date
);
--exit;
