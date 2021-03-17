--
-- $Id$
--
drop table InvAdj947dtlEx;

create table InvAdj947DtlEx (
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   whenoccurred date,
   lpid      varchar2(15),
   facility  varchar2(3),
   custid    varchar2(10),
   rsncode   varchar2(20),
   quantity  number(5),
   uom       varchar2(4),
   upc       varchar2(20),
   item varchar2(50),
   lotno     varchar2(30),
   dmgdesc   varchar2(45)
);

-- exit;
