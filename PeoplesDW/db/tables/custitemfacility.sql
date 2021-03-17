--
-- $Id$
--
create table custitemfacility
(CUSTID                          VARCHAR2(10) NOT NULL
,item varchar2(50) NOT NULL
,FACILITY                        VARCHAR2(3) NOT NULL
,PROFID VARCHAR2(2)
,ALLOCRULE VARCHAR2(10)
,REPLALLOCRULE VARCHAR2(10)
,lastuser varchar2(12)
,lastupdate date
);
create table custproductgroupfacility
(CUSTID                          VARCHAR2(10) NOT NULL
,PRODUCTGROUP                       VARCHAR2(4) NOT NULL
,FACILITY                        VARCHAR2(3) NOT NULL
,PROFID VARCHAR2(2)
,ALLOCRULE VARCHAR2(10)
,REPLALLOCRULE VARCHAR2(10)
,lastuser varchar2(12)
,lastupdate date
);
create table custfacility
(CUSTID                          VARCHAR2(10) NOT NULL
,FACILITY                        VARCHAR2(3) NOT NULL
,PROFID VARCHAR2(2)
,ALLOCRULE VARCHAR2(10)
,REPLALLOCRULE VARCHAR2(10)
,lastuser varchar2(12)
,lastupdate date
);
exit;
