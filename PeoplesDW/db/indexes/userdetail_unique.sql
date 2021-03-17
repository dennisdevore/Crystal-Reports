alter table userdetail drop constraint pk_userdetail;
drop index userdetail_unique;
create unique index userdetail_unique on userdetail(nameid,formid,facility);
exit;
