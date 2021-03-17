--
-- $Id$
--
 insert into businessevents values('MBOL','Master Bill of Lading','MasterBOL',
       'N','SUP',sysdate);                                                                                                              
 insert into businessevents values('NOIB','No InBound Notification','No Notify',
       'N','SUP',sysdate);                                                                                                              
 insert into orderpriority values('N','No InBound Pre-Notification',
        'No Notify','N','SUP',sysdate);                                                                                                              

commit;
