--
-- $Id$
--
create table requests
(facility varchar2(3) not null
,reqtype varchar2(12) not null
,descr varchar2(36) not null
,str01 varchar2(255)
,str02 varchar2(255)
,str03 varchar2(255)
,str04 varchar2(255)
,str05 varchar2(255)
,str06 varchar2(255)
,str07 varchar2(255)
,str08 varchar2(255)
,str09 varchar2(255)
,str10 varchar2(255)
,flag01 varchar2(1)
,flag02 varchar2(1)
,flag03 varchar2(1)
,flag04 varchar2(1)
,flag05 varchar2(1)
,flag06 varchar2(1)
,flag07 varchar2(1)
,flag08 varchar2(1)
,flag09 varchar2(1)
,flag10 varchar2(1)
,num01 number(12,2)
,num02 number(12,2)
,num03 number(12,2)
,num04 number(12,2)
,num05 number(12,2)
,date01 date
,date02 date
,date03 date
,date04 date
,date05 date
,option01 varchar2(12)
,option02 varchar2(12)
,option03 varchar2(12)
,option04 varchar2(12)
,option05 varchar2(12)
,text1 long
,lastuser varchar2(12)
,lastupdate date
);
exit;