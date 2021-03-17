create or replace view alps.ststatgt_hdr
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
,app_recvr_code)
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
null
from customer;

create or replace view alps.ststatgt_rpt
(custid
,record_type
,date_created
,depositor_code
,name)
as
select
custid,
'H',
to_char(sysdate, 'YYYYMMDD'),
custid,
name
from customer;

create or replace view alps.ststatgt_dtl
(record_type
,custid                               --     X(12)        4   15
,item                                 --     X(20)       19   38
,descr                                --     X(25)       63   87
,lotnumber                            --     X(15)      119  133
,serialnumber                         --     X(15)      137  151
,facility                             --     X(2)       155  156 warehouse code
,location                             --     X(8)       160  167
,quantity                             --     +9(7).99   174  184
,unitofmeasure                        --     X(4)       187  190
,qtyonholddetail                      --     +9(7).99   193  203
,qtydamaged                           --     +9(7).99   205  215
,qtyonholdlot                         --     +9(7).99   217  227
,weight                               --     9(6).99    279  287
,productgroup                         --     X(5)       290  294
,creationdate                         --     9(8)       339  346
,source                               --     X(1)       349  349 (shp/rect/adj)
,document                             --     9(6)       352  357
,sequence                             --     9(3)       359  361
,linenumber                           --     9(3)       363  365
,manufacturedate                      --     9(8)       376  383
,qtyavailable                         --     +9(7).99   430  440
,lpid
,lpidlast6
,lpidlast7
,rategroup
,useritem2
,holdflag
,statabbrev)
as select
'L',
p.custid,
p.item,
ci.descr,
p.lotnumber,
p.serialnumber,
p.facility,
p.location,
p.quantity,
p.unitofmeasure,
p.quantity,
p.quantity,
p.quantity,
p.weight,
ci.productgroup,
p.creationdate,
'R',
p.orderid,
p.shipid,
'000',
p.manufacturedate,
p.quantity,
p.lpid,
substr(p.lpid,10),
substr(p.lpid,9),
ci.rategroup,
p.useritem2,
'H',
i.abbrev
from plate p, custitem ci, inventorystatus i
where p.custid = ci.custid
  and p.item = ci.item
  and p.invstatus = i.code(+);

CREATE OR REPLACE VIEW alps.ststatgt_fac
(
   facility
)
as
select
   distinct facility
  from alps.ststatgt_dtl;
--
CREATE OR REPLACE VIEW alps.ststatgt_mbr
(facility,
lotnumber,
lpid,
item,
weight,
qty
)
as
select
facility,
lotnumber,
lpid,
item,
weight,
quantity
from alps.ststatgt_dtl;

exit;
