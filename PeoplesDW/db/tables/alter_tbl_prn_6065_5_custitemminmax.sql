--
-- $Id$
--
alter table custitemminmax add
(kitted_class varchar2(2) default 'no'
,lastuser varchar2(12)
,lastupdate date
);

alter table custitemminmax drop constraint pk_custitemminmax;

drop index pk_custitemminmax;

alter table custitemminmax add constraint pk_custitemminmax primary key
  (custid,item,kitted_class);

update custitemminmax
   set lastuser = 'SYNAPSE',
       lastupdate = sysdate;

exit;
