alter table custitemalias drop constraint pk_custitemalias;

drop index custitemalias_idx;

create unique index custitemalias_idx
  on custitemalias(custid,itemalias,item);

alter table custitemalias add constraint pk_custitemalias
primary key(custid,itemalias,item) using index custitemalias_idx;

exit;
