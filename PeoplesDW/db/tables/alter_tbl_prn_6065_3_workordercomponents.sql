--
-- $Id$
--
alter table workordercomponents add
(kitted_class varchar2(2) default 'no'
,lastuser varchar2(12)
,lastupdate date
);

alter table workordercomponents drop constraint pk_workordercomponents;

drop index pk_workordercomponents;

alter table workordercomponents add constraint pk_workordercomponents primary key
  (custid,item,kitted_class,component);

update workordercomponents
   set lastuser = 'SYNAPSE',
       lastupdate = sysdate;

exit;
