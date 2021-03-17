alter table customer_aux add
(locstatuschg_loctype varchar2(3)
,locstatuschg_entry_invstatus varchar2(2)
,locstatuschg_entry_adjreason varchar2(2)
,locstatuschg_exit_invstatus varchar2(2)
,locstatuschg_exit_adjreason varchar2(2)
,locstatuschg_exclude_tasktypes varchar2(4000) /* comma-delimited list */  
);

update customer_aux
   set locstatuschg_loctype = 'n/a'
 where locstatuschg_loctype is null;
 
alter table custproductgroup add
(locstatuschg_loctype varchar2(3)
,locstatuschg_entry_invstatus varchar2(2)
,locstatuschg_entry_adjreason varchar2(2)
,locstatuschg_exit_invstatus varchar2(2)
,locstatuschg_exit_adjreason varchar2(2)
,locstatuschg_exclude_tasktypes varchar2(4000) /* comma-delimited list */  
);

update custproductgroup
   set locstatuschg_loctype = 'C'
 where locstatuschg_loctype is null;
 
alter table custitem add
(locstatuschg_loctype varchar2(3)
,locstatuschg_entry_invstatus varchar2(2)
,locstatuschg_entry_adjreason varchar2(2)
,locstatuschg_exit_invstatus varchar2(2)
,locstatuschg_exit_adjreason varchar2(2)
,locstatuschg_exclude_tasktypes varchar2(4000) /* comma-delimited list */  
);

update custitem
   set locstatuschg_loctype = 'C'
 where locstatuschg_loctype is null;
 

exit;
