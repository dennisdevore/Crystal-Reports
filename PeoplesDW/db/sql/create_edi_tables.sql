--
-- $Id$
--

create table EDI_Parameters_for_8475( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);

create unique index EDI_Parameters_for_8475_idx  on edi_parameters_for_8475(code);

 insert into EDI_Parameters_for_8475 values('947INVADJFMT','947 Inventory Adjustment','(format)','Y','SUP',sysdate);
 insert into EDI_Parameters_for_8475 values('UNSTATUS','Inv Stat for Unrestricted Stock','AV','Y','SUP',sysdate);
 insert into EDI_Parameters_for_8475 values('DMGSTATUS','Inv Stat for Damaged Stock','DM','Y','SUP',sysdate);

create table EDI_Parms_for_8475_REG1( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);

create unique index EDI_Parms_for_8475_REG1_idx  on edi_parms_for_8475_REG1(code);

 insert into EDI_Parms_for_8475_REG1 values('QI-AV:04','Required','04','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/??:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:06','Required','06','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QI-SU:51','Required','51','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-SU:51','Required','51','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-DM/AV:52','Required','52','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('CC-??/??:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/AV:55','SU,DM,EX','55','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QI-AV:56','Required','56','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QI-AV:AA','Required','AA','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:AA','Required','AA','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QI-AV:AH','Required','AH','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:AH','Required','AH','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/DM:AU','Required','AU','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/EX:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-DM/AV:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:53','Required','53','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:UD','Required','UD','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-EX/??:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/UN:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/DM:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/DM:AV','Required','AV','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/DM:WD','Required','AU','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QD-AV:AI','Required','AI','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/EX:EX','Optional','AX','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('QI-AV:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/AV:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-AV/??:05','SU,DM,EX','05','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/DM:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-DM/??:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-SU/??:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/SU:??','Not Allowed','Reject','Y','SUP',sysdate);
 insert into EDI_Parms_for_8475_REG1 values('SC-??/EX:AX','Optional','AX','Y','SUP',sysdate);

create table Class_To_Company_8475( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);

create unique index Class_To_Company_8475_idx  on Class_To_Company_8475(code);

create table Class_To_Warehouse_8475( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);

create unique index Class_To_Warehouse_8475_idx  on Class_To_Warehouse_8475(code);

insert into Class_To_Company_8475 values('RG','Regular Goods','REG','N','SUP',sysdate);

insert into Class_To_Warehouse_8475 values('RG','Regular','REG1','N','SUP',sysdate);

insert into tabledefs values('EDI_Parameters_for_8475','Y','Y','>Cccccccccccc;0;_','SUP',sysdate);

insert into tabledefs values('EDI_Parms_for_8475_REG1','Y','Y','>Cccccccccccc;0;_','SUP',sysdate);

insert into tabledefs values('Class_To_Company_8475','Y','Y','>Aa;0;_','SUP',sysdate);

insert into tabledefs values('Class_To_Warehouse_8475','Y','Y','>Aa;0;_','SUP',sysdate);
