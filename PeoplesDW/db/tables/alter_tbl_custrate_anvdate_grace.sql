alter table custrate add(anvdate_grace char(1) default 'N');
update custrate set anvdate_grace = 'N' where anvdate_grace is null;
commit;
exit;
