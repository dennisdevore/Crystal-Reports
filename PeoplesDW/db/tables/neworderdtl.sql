--
-- $Id$
--
create table neworderdtl
( chgdate                          date
, chguser                          varchar2(12)
, chgrowid                         varchar2(20)
, ORDERID                          NUMBER(7) NOT NULL
, SHIPID                           NUMBER(2) NOT NULL
, item varchar2(50)
, UOM                                      VARCHAR2(4)
, LINESTATUS                               VARCHAR2(1)
, QTYENTERED                               NUMBER(7)
, ITEMENTERED                              VARCHAR2(20)
, UOMENTERED                               VARCHAR2(4)
, QTYORDER                                 NUMBER(7)
, WEIGHTORDER                              NUMBER(10,4)
, CUBEORDER                                NUMBER(10,4)
, AMTORDER                                 NUMBER(10,2)
, LASTUSER                                 VARCHAR2(12)
, LASTUPDATE                               DATE
, PRIORITY                                 VARCHAR2(1)
, LOTNUMBER                                VARCHAR2(30)
, BACKORDER                                VARCHAR2(1)
, ALLOWSUB                                 VARCHAR2(1)
, QTYTYPE                                  VARCHAR2(1)
, INVSTATUSIND                             VARCHAR2(1)
, INVSTATUS                                VARCHAR2(255)
, INVCLASSIND                              VARCHAR2(1)
, INVENTORYCLASS                           VARCHAR2(255)
, CONSIGNEESKU                             VARCHAR2(20)
);
exit;
