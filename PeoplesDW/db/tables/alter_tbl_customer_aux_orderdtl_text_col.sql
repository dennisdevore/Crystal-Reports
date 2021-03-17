alter table customer_aux add
(require_orderdtl_text_yn char(1)
,imported_orderdtl_text_col varchar2(30)
,updated_orderdtl_text_col varchar2(30)
);

update customer_aux
   set require_orderdtl_text_yn = 'N'
 where require_orderdtl_text_yn is null;
 
exit;
