--
-- $Id$
--
alter table formatvalidationrule add
(
   dupesok     varchar2(1),
   mod10check  varchar2(1)
);

update formatvalidationrule
   set dupesok = 'Y',
       mod10check = 'N';
       
exit;
