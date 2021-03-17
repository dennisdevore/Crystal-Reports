delete from impexp_queues;
delete from pickrequestqueues;
insert into pickrequestqueues values
('*/*','All Customers/All Facilities','Q1','Y','SYNAPSE',sysdate);
delete from taskrequestqueues;
insert into taskrequestqueues values
('*','All Facilities','Q1','Y','SYNAPSE',sysdate);
delete from putawayqueues;
insert into putawayqueues values
('*','All Facilities','Q1','Y','SYNAPSE',sysdate);
exit;
