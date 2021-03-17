
alter table customer_aux add
(allow_direct_release_yn char(1)
,allow_manual_pick_select_yn char(1)
);

update customer_aux
   set allow_direct_release_yn = 'N',
       allow_manual_pick_select_yn = 'N'
 where allow_direct_release_yn is null;

exit;
