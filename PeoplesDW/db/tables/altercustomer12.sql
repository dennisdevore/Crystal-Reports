--
-- $Id$
--
alter table customer add(
      CycleAPercent     number(3),
      CycleAFrequency   number(2),
      CycleBPercent     number(3),
      CycleBFrequency   number(2),
      CycleCPercent     number(3),
      CycleCFrequency   number(2),
      LastCycleRequest  date,
      CycleACounts      number(6),
      CycleBCounts      number(6),
      CycleCCounts      number(6)
);

exit;
