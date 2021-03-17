--
-- $Id: import_945_detail.sql 1 2005-05-26 12:20:03Z ed $
--
create table import_945_detail
(importfileid varchar2(255)
,custid varchar2(10)
,reference varchar2(20)
,orderid number(9)
,shipid number(2)
,item varchar2(50)
,lotnumber varchar2(30)
,assignedid number(16,4)
,shipticket varchar2(15)
,trackingno varchar2(81),
servicecode varchar2(4)
,lbs number(17,8)
,kgs number,gms number
,ozs number
,link_lotnumber varchar2(30)
,inventoryclass varchar2(4)
,statuscode varchar2(2)
,linenumber varchar2(255)
,orderdate date
,po varchar2(20)
,qtyordered number(7)
,qtyshipped number(7)
,qtydiff number
,uom varchar2(4)
,packlistshipdate date
,weight number(17,8)
,weightquaifier char(1)
,weightunit char(1)
,description varchar2(255)
,upc varchar2(20)
,dtlpassthruchar01 varchar2(255)
,dtlpassthruchar02 varchar2(255)
,dtlpassthruchar03 varchar2(255)
,dtlpassthruchar04 varchar2(255)
,dtlpassthruchar05 varchar2(255)
,dtlpassthruchar06 varchar2(255)
,dtlpassthruchar07 varchar2(255)
,dtlpassthruchar08 varchar2(255)
,dtlpassthruchar09 varchar2(255)
,dtlpassthruchar10 varchar2(255)
,dtlpassthruchar11 varchar2(255)
,dtlpassthruchar12 varchar2(255)
,dtlpassthruchar13 varchar2(255)
,dtlpassthruchar14 varchar2(255)
,dtlpassthruchar15 varchar2(255)
,dtlpassthruchar16 varchar2(255)
,dtlpassthruchar17 varchar2(255)
,dtlpassthruchar18 varchar2(255)
,dtlpassthruchar19 varchar2(255)
,dtlpassthruchar20 varchar2(255)
,dtlpassthruchar21 varchar2(255)
,dtlpassthruchar22 varchar2(255)
,dtlpassthruchar23 varchar2(255)
,dtlpassthruchar24 varchar2(255)
,dtlpassthruchar25 varchar2(255)
,dtlpassthruchar26 varchar2(255)
,dtlpassthruchar27 varchar2(255)
,dtlpassthruchar28 varchar2(255)
,dtlpassthruchar29 varchar2(255)
,dtlpassthruchar30 varchar2(255)
,dtlpassthruchar31 varchar2(255)
,dtlpassthruchar32 varchar2(255)
,dtlpassthruchar33 varchar2(255)
,dtlpassthruchar34 varchar2(255)
,dtlpassthruchar35 varchar2(255)
,dtlpassthruchar36 varchar2(255)
,dtlpassthruchar37 varchar2(255)
,dtlpassthruchar38 varchar2(255)
,dtlpassthruchar39 varchar2(255)
,dtlpassthruchar40 varchar2(255)
,dtlpassthrunum01 number(16,4)
,dtlpassthrunum02 number(16,4)
,dtlpassthrunum03 number(16,4)
,dtlpassthrunum04 number(16,4)
,dtlpassthrunum05 number(16,4)
,dtlpassthrunum06 number(16,4)
,dtlpassthrunum07 number(16,4)
,dtlpassthrunum08 number(16,4)
,dtlpassthrunum09 number(16,4)
,dtlpassthrunum10 number(16,4)
,dtlpassthrunum11 number(16,4)
,dtlpassthrunum12 number(16,4)
,dtlpassthrunum13 number(16,4)
,dtlpassthrunum14 number(16,4)
,dtlpassthrunum15 number(16,4)
,dtlpassthrunum16 number(16,4)
,dtlpassthrunum17 number(16,4)
,dtlpassthrunum18 number(16,4)
,dtlpassthrunum19 number(16,4)
,dtlpassthrunum20 number(16,4)
,dtlpassthrudate01 date
,dtlpassthrudate02 date
,dtlpassthrudate03 date
,dtlpassthrudate04 date
,dtlpassthrudoll01 number(10,2)
,dtlpassthrudoll02 number(10,2)
,fromlpid varchar2(15)
,smallpackagelbs number
,deliveryservice varchar2(10)
,entereduom varchar2(4)
,qtyshippedeuom number
,seq number
,created timestamp
);
create index import_945_detail_idx
on import_945_detail(importfileid, custid, reference, orderid, shipid, item, lotnumber, assignedid);
create index import_945_seq_idx
on import_945_detail(importfileid, seq, item, lotnumber, assignedid);


