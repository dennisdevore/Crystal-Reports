--
-- $Id$
--

create table LotRequiredOptions( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);

create unique index LotRequiredOptions_idx  on LotRequiredOptions(code);

insert into LotRequiredOptions values('Y','Upon Receipt','Upon Receipt','Y','SUP',sysdate);
insert into LotRequiredOptions values('O','Upon Receipt and Outbound','AlsoOutbound','Y','SUP',sysdate);
insert into LotRequiredOptions values('S','Upon Receipt and Some Outbound','SomeOutbound','Y','SUP',sysdate);
insert into LotRequiredOptions values('P','Upon Pick','Upon Pick','Y','SUP',sysdate);
insert into LotRequiredOptions values('N','Not required','Not Required','Y','SUP',sysdate);
insert into LotRequiredOptions values('C','Use Customer Default','Use Default','Y','SUP',sysdate);

insert into tabledefs values('LotRequiredOptions','N','N','>C;0;_','SUP',sysdate);

exit;
