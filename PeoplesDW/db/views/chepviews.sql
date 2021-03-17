create or replace view chep_hdr_view
(loadno
,communicator_country
,communicator_code
,file_date
,dtl_count
,seq_number
,country_and_code
,facility
,custid
)
as select
1,
'XXX',
'YYYYYYYYYYYYYYYYYY',
sysdate,
2,
3,
'XXYYYYYYYYYYYYYYYYYYZZZZZ',
'WWW',
'QQQQQQQQQQ'
from dual;

comment on table chep_hdr_view is '$Id$';

create or replace view chep_dtl_view
(loadno
,detail_number
,informer_flag
,informer_country
,sender_code_qualifier
,sender_code
,receiver_code_qualifier
,receiver_code
,equip_code_qualifier
,equip_code
,date_of_dispatch
,date_of_receipt
,qty
,reference_1
,reference_2
,reference_3
,transport_responsibility
,sys_parm_1
,sys_parm_2
,sys_parm_3
,special_processing_code
,flow_code
,counter_part_name
,counter_part_addr
,counter_part_city
,counter_part_postal_code
,counter_part_state
,counter_part_country
,third_party_code_qualifier
,third_party_code
)
as select
1,
2,
'A',
'BBB',
'CC',
'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD',
'EE',
'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
'GG',
'HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH',
sysdate,
sysdate + 1,
3,
'IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII',
'JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ',
'KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK',
'L',
'M',
'N',
'OOOOOO',
'PPP',
'Q',
'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR',
'SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS',
'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT',
'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUU',
'VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV',
'WWW',
'XX',
'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY'
from dual;

comment on table chep_dtl_view is '$Id$';

create or replace view chep_trl_view
(loadno
,dtl_count
,qty_sum
)
as select
1,
2,
3
from dual;

comment on table chep_trl_view is '$Id$';

--exit;
