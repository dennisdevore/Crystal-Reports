alter table facility add
(generate_carton_packlist_yn char(1)
);

update facility
   set generate_carton_packlist_yn = 'N'
 where generate_carton_packlist_yn is null;

exit;
