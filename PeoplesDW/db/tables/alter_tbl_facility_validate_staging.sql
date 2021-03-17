alter table facility add
(
  validate_staging       char(1) default 'N'
);

update facility 
set validate_staging = 'N'
where validate_staging is null;
/

commit;
/ 

exit;