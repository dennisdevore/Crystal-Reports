--
-- $Id$
--
create table neworderhdr
(chgdate                          date
,chguser                          varchar2(12)
,orderid number(7) not null
,shipid number(2) not null
,custid varchar(10)
,ordertype varchar2(1)
,entrydate date
,apptdate date
,shipdate date
,po varchar2(20)
,rma varchar2(20)
,orderstatus varchar2(1)
,commitstatus varchar2(1)
,fromfacility varchar2(3)
,tofacility varchar2(3)
,loadno number(7)
,stopno number(7)
,shipno number(7)
,shipto varchar(10)
,delarea varchar2(3)
,qtyorder number(7)
,weightorder number(10,4)
,cubeorder number(10,4)
,amtorder number(10,2)
,lastuser varchar2(12)
,lastupdate date
, BILLOFLADING                             VARCHAR2(20)
, PRIORITY                                 VARCHAR2(1)
, SHIPPER                                  VARCHAR2(10)
, ARRIVALDATE                              DATE
, CONSIGNEE                                VARCHAR2(10)
, SHIPTYPE                                 VARCHAR2(1)
, CARRIER                                  VARCHAR2(10)
, REFERENCE                                VARCHAR2(20)
, SHIPTERMS                                VARCHAR2(3)
, WAVE                                     NUMBER(9)
, STAGELOC                                 VARCHAR2(10)
,shiptoname varchar2(40)
,shiptocontact varchar2(40)
,shiptoaddr1 varchar2(40)
,shiptoaddr2 varchar2(40)
,shiptocity varchar2(30)
,shiptostate varchar2(2)
,shiptopostalcode varchar2(12)
,shiptocountrycode varchar2(3)
,shiptophone varchar2(15)
,shiptofax varchar2(15)
,shiptoemail varchar2(255)
,billtoname varchar2(40)
,billtocontact varchar2(40)
,billtoaddr1 varchar2(40)
,billtoaddr2 varchar2(40)
,billtocity varchar2(30)
,billtostate varchar2(2)
,billtopostalcode varchar2(12)
,billtocountrycode varchar2(3)
,billtophone varchar2(15)
,billtofax varchar2(15)
,billtoemail varchar2(255)
);
exit;

