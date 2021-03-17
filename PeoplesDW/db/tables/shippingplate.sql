--
-- $Id$
--
drop table shippingplate;

create table shippingplate
(
  LPID                                     VARCHAR2(15) not null
, item varchar2(50) not null
, CUSTID                                   VARCHAR2(10) not null
, FACILITY                                 VARCHAR2(3) not null
, LOCATION                                 VARCHAR2(10)
, STATUS                                   VARCHAR2(2)
, HOLDREASON                               VARCHAR2(2)
, UNITOFMEASURE                            VARCHAR2(4)
, QUANTITY                                 NUMBER(7)
, TYPE                                     VARCHAR2(2)
, FROMLPID                                 VARCHAR2(15)
, SERIALNUMBER                             VARCHAR2(30)
, LOTNUMBER                                VARCHAR2(30)
, PARENTLPID                               VARCHAR2(15)
, USERITEM1                                VARCHAR2(20)
, USERITEM2                                VARCHAR2(20)
, USERITEM3                                VARCHAR2(20)
, LASTUSER                                 VARCHAR2(12)
, LASTUPDATE                               DATE
, INVSTATUS                                VARCHAR2(2)
, QTYENTERED                               NUMBER(7)
, ORDERitem varchar2(50)
, UOMENTERED                               VARCHAR2(4)
, INVENTORYCLASS                           VARCHAR2(2)
, LOADNO                                   NUMBER(7)
, STOPNO                                   NUMBER(7)
, SHIPNO                                   NUMBER(7)
, ORDERID                                  NUMBER(7)
, SHIPID                                   NUMBER(2)
, WEIGHT                                   NUMBER(10,4)
, UCC128                                   VARCHAR2(20)
, LABELFORMAT                              VARCHAR2(10)
, TASKID                                   NUMBER(15)
);
