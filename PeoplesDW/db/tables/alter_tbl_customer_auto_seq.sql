
alter table customer_aux add
(lot_seq_name varchar2(30)
,lot_seq_min number(20)
,lot_seq_max number(20)
,useritem1_seq_name varchar2(30)
,useritem1_seq_min number(20)
,useritem1_seq_max number(20)
,useritem2_seq_name varchar2(30)
,useritem2_seq_min number(20)
,useritem2_seq_max number(20)
,useritem3_seq_name varchar2(30)
,useritem3_seq_min number(20)
,useritem3_seq_max number(20)
,serial_seq_name varchar2(30)
,serial_seq_min number(20)
,serial_seq_max number(20)
);

alter table custproductgroup add
(lot_seq_name varchar2(30)
,lot_seq_min number(20)
,lot_seq_max number(20)
,useritem1_seq_name varchar2(30)
,useritem1_seq_min number(20)
,useritem1_seq_max number(20)
,useritem2_seq_name varchar2(30)
,useritem2_seq_min number(20)
,useritem2_seq_max number(20)
,useritem3_seq_name varchar2(30)
,useritem3_seq_min number(20)
,useritem3_seq_max number(20)
,serial_seq_name varchar2(30)
,serial_seq_min number(20)
,serial_seq_max number(20)
);

alter table custitem add
(lot_seq_name varchar2(30)
,lot_seq_min number(20)
,lot_seq_max number(20)
,useritem1_seq_name varchar2(30)
,useritem1_seq_min number(20)
,useritem1_seq_max number(20)
,useritem2_seq_name varchar2(30)
,useritem2_seq_min number(20)
,useritem2_seq_max number(20)
,useritem3_seq_name varchar2(30)
,useritem3_seq_min number(20)
,useritem3_seq_max number(20)
,serial_seq_name varchar2(30)
,serial_seq_min number(20)
,serial_seq_max number(20)
);

exit;
