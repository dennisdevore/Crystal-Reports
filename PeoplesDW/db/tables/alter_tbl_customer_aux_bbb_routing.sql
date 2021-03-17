set serveroutput on;

alter table customer_aux add
(bbb_routing_yn char(1)
,bbb_order_confirmation_rpt_fmt varchar2(255)
,bbb_shortage_rpt_fmt varchar2(255)
,bbb_load_plan_rpt_fmt varchar2(255)
,bbb_routing_request_carrier varchar2(4)
,bbb_control_value_passthru_col varchar2(30)
,bbb_control_value varchar2(255)
,bbb_carton_uom varchar2(4)
,bbb_oversize_1_min_girth number(3) -- 84
,bbb_oversize_2_min_girth number(3) -- 108
,bbb_oversize_3_min_girth number(3) -- 130
,bbb_oversize_1_max_weight number(3)
,bbb_oversize_2_max_weight number(3)
,bbb_oversize_3_max_weight number(3)
,bbb_small_package_carrier varchar2(4)
);

declare
cursor curcustomer_aux is
         select rowid
           from customer_aux
          where bbb_routing_yn is null;
           
type customer_aux_tbl_type is table of rowid;

customer_aux_tbl customer_aux_tbl_type;
l_dtl_rows pls_integer;
l_customer_aux_rows pls_integer := 0;

begin

open curcustomer_aux;
loop
  
  fetch curcustomer_aux bulk collect into customer_aux_tbl limit 100000;
  
  if customer_aux_tbl.count = 0 then
    exit;
  end if;

  forall i in customer_aux_tbl.first .. customer_aux_tbl.last
    update customer_aux
       set bbb_routing_yn = 'N'
     where rowid = customer_aux_tbl(i);

  l_dtl_rows := sql%rowcount;
  l_customer_aux_rows := l_customer_aux_rows + l_dtl_rows;

  commit;     
  
end loop;

zut.prt('rows processed: ' || l_customer_aux_Rows);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;  
/
exit;
