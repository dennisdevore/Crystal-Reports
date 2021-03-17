create or replace view alps.gt947_hdr
(custid
,record_type
,transaction_set
,partner_edi_code
,date_created
,time_created
,depositor_code
,batch_reference
,other_reference
,sender_edi_code
,app_sender_code
,app_recvr_code
,document)
as
select
custid,
'I',
'846',
custid,
to_char(sysdate, 'YYYYMMDD'),
to_char(sysdate, 'HHMMSS'),
custid,
to_char(sysdate, 'YYYYMMDDHHMMSS'),
null,
custid,
custid,
null,
to_char(sysdate, 'YYYYMMDDHHMMSS')
from customer;

create or replace view alps.gt947_rpt
(custid
,record_type
,date_created
,document
,depositor_code
,name)
as
select
custid,
'H',
to_char(sysdate, 'YYYYMMDD'),
'000000',
custid,
name
from customer;

create or replace view alps.gt947_dtl
(record_type
,custid
,item
,lotnumber
,serialnumber
,facility
,location
,quantity
,unitofmeasure
,detialstatus
,document
,adjreference
,adjreason
,reasoncode
,originalreasoncode
,lpid
,lpidlast6
,lpidlast7
,itemsub1
,weight
,pallets)
as select
'D',
custid,
item,
lotnumber,
serialnumber,
facility,
null,
adjqty,
uom,
null,
'000000',
to_char(whenoccurred,'YYYYMMDDHH24MISS') || lpid,
adjreason,
null,
null,
lpid,
substr(lpid,10),
substr(lpid,9),
item,
null,
null
from invadjactivity;

exit;
