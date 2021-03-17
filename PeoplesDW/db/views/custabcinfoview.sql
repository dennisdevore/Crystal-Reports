create or replace view custabcinfoview
(
  custid,
  velocity, 
  cnt,
  frequency,
  monthtotal,
  monthcounts,
  perrequest,
  lastrequest
)
as
select 
  V.custid,
  velocity, 
  cnt,
  decode(velocity,'A',cycleAfrequency,'B',cycleBfrequency,'C',cycleCfrequency,0),
  cnt * decode(velocity,'A',cycleAfrequency,'B',cycleBfrequency,'C',cycleCfrequency,0),
  decode(velocity,'A',cycleAcounts,'B',cycleBcounts,'C',cycleCcounts,0),
  ceil(cnt * decode(velocity,'A',cycleAfrequency,'B',cycleBfrequency,'C',cycleCfrequency,0) * 12 / 250),
  C.lastcyclerequest
from custvelview V, customer C
where C.custid = V.custid;

comment on table custabcinfoview is '$Id$';

exit;
