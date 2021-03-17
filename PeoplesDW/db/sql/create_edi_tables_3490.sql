--
-- $Id$
--

create table EDI_Parameters_for_3490( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);            

create unique index EDI_Parameters_for_3490_idx  on edi_parameters_for_3490(code);                                                                                                                      

 insert into EDI_Parameters_for_3490 values('UNSTATUS','Inv Stat for Unrestricted Stock','AV','Y','SUP',sysdate);                                                                                       
 insert into EDI_Parameters_for_3490 values('852PRDACTFMT','852 Product Activity','(format)','Y','SUP',sysdate);                                                                                        

create table EDI_Parms_for_3490_REG1( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);            

create unique index EDI_Parms_for_3490_REG1_idx  on edi_parms_for_3490_REG1(code);                                                                                                                      

 insert into EDI_Parms_for_3490_REG1 values('SC-AV/??:??','Optional','+20-33','Y','SUP',sysdate);                                                                                                       
 insert into EDI_Parms_for_3490_REG1 values('QD-AV:??','Optional','-33','Y','SUP',sysdate);                                                                                                             
 insert into EDI_Parms_for_3490_REG1 values('SC-??/AV:??','Optional','-20+33','Y','SUP',sysdate);                                                                                                       
 insert into EDI_Parms_for_3490_REG1 values('QI-AV:??','Optional','+33','Y','SUP',sysdate);                                                                                                             
 insert into EDI_Parms_for_3490_REG1 values('QD-??:??','Optional','-20','Y','SUP',sysdate);                                                                                                             
 insert into EDI_Parms_for_3490_REG1 values('QI-??:??','Optional','+20','Y','SUP',sysdate);                                                                                                             
 insert into EDI_Parms_for_3490_REG1 values('SC-AV/SU:??','Not Allowed','Reject','Y','SUP',sysdate);                                                                                                    
 insert into EDI_Parms_for_3490_REG1 values('SC-SU/AV:??','Not Allowed','Reject','Y','SUP',sysdate);                                                                                                    
 insert into EDI_Parms_for_3490_REG1 values('QD-SU:??','Optional','+33','Y','SUP',sysdate);                                                                                                             
 insert into EDI_Parms_for_3490_REG1 values('QI-SU:??','Optional','-33','Y','SUP',sysdate);                                                                                                             

create table Class_To_Company_3490( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);              

create unique index Class_To_Company_3490_idx  on Class_To_Company_3490(code);                                                                                                                          

create table Class_To_Warehouse_3490( code varchar2(12) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);            

create unique index Class_To_Warehouse_3490_idx  on Class_To_Warehouse_3490(code);                                                                                                                      

insert into Class_To_Company_3490 values('RG','Regular Goods','REG','N','SUP',sysdate);                                                                                                                 

insert into Class_To_Warehouse_3490 values('RG','Regular','REG1','N','SUP',sysdate);                                                                                                                    

insert into tabledefs values('EDI_Parameters_for_3490','Y','Y','>Cccccccccccc;0;_','SUP',sysdate);                                                                                                      

insert into tabledefs values('EDI_Parms_for_3490_REG1','Y','Y','>Cccccccccccc;0;_','SUP',sysdate);                                                                                                      

insert into tabledefs values('Class_To_Company_3490','Y','Y','>Aa;0;_','SUP',sysdate);                                                                                                                  

insert into tabledefs values('Class_To_Warehouse_3490','Y','Y','>Aa;0;_','SUP',sysdate);                                                                                                                
