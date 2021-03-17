alter table custrate add(tare_adj char(1) default 'N');
update custrate set tare_adj = 'N'
where tare_adj is null;
commit;

exit;
