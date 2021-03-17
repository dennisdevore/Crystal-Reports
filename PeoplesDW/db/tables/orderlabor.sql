--
-- $Id$
--
create table orderlabor
(wave                             NUMBER(9)
,ORDERID                          NUMBER(7)
,SHIPID                           NUMBER(2)
,item varchar2(50)
,LOTNUMBER                        VARCHAR2(30)
,category varchar2(4)
,zoneid varchar2(10)
,uom varchar2(4)
,qty number(10,4)
,lastuser varchar2(12)
,lastupdate date
);