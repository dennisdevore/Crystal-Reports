--
-- $Id$
--
alter table workorderinstructions drop column destfacility;
alter table workorderinstructions drop column destlocation;
alter table workorderinstructions drop column destloctype;

alter table workorderinstructions add
(kitted_class varchar2(2) default 'no'
,lastuser varchar2(12)
,lastupdate date
);

alter table workorderinstructions drop constraint pk_workorderinstructions;

drop index pk_workorderinstructions;

alter table workorderinstructions add constraint pk_workorderinstructions primary key
  (custid,item,kitted_class,seq);

update workorderinstructions
   set lastuser = 'SYNAPSE',
       lastupdate = sysdate;


exit;
