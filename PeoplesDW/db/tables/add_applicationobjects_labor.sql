--
-- $Id$
--
insert into applicationobjects 
  values('GoalTimeForm', 'F', 'LABOR', 'SYNAPSE', sysdate);
insert into applicationobjects 
  values('LaborReportLookDlg', 'F', 'LABOR', 'SYNAPSE', sysdate);

update applicationobjects
   set objectdescr = null
   where objectname in ('LaborStandardsForm', 'LaborLookDlg')
     and objectdescr is not null;

exit;

