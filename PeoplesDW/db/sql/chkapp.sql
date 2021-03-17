--
-- $Id$
--
select id.name,il.definc,il.lineinc,il.linealias
from impexp_definitions id, impexp_lines il
where il.definc = id.definc
  and il.afterprocessprocname is null
and exists
(select *
   from impexp_afterprocessprocparams ia
  where il.definc = ia.definc
    and il.lineinc = ia.lineinc);
delete from impexp_afterprocessprocparams ia
 where exists
(select *
   from impexp_lines il
  where il.definc = ia.definc
    and il.lineinc = ia.lineinc
    and il.afterprocessprocname is null);
--exit;
