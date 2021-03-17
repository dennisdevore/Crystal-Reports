--
-- WS_USERHEADER 
--
create table ws_userheader
(nameid varchar2(12) primary key     -- WebSynapse Userid 
,facility varchar2(3)                        
,custid varchar2(10)                 
,userstatus varchar2(1)                
,lastuser varchar2(12)                  
,lastupdate date                     
,username varchar2(32)                
,usertype varchar2(1)                
,chgfacility varchar2(1)                
,groupid varchar2(12)                
,ws_session_id varchar2(255)             
,desc1 varchar2(40)                
,desc2 varchar2(40)                
,addr1 varchar2(40)                
,addr2 varchar2(40)                
,title varchar2(40)                
,city varchar2(30)                
,state varchar2(5)                
,postalcode varchar2(12)                
,countrycode varchar2(3)                
,phone varchar2(25)                
,fax varchar2(25)                
,email varchar2(255)                
,rptprinter varchar2(5)                
,defaultprinter varchar2(5)                
,allcusts varchar2(1)                
,blendedpword varchar2(40)                
,company varchar2(12)                
,report_format varchar2(20)                
,allreports varchar2(1)                
);

--
-- WS_USERFACILITY 
--
create table ws_userfacility
(nameid varchar2(12)          -- WebSynapse Userid 
,facility varchar2(3)                        
,groupid varchar2(12)                
,lastuser varchar2(12)                  
,lastupdate date                     
);
create unique index ws_userfacility_idx on ws_userfacility(nameid,facility);

--
-- WS_USERCUSTOMER 
--
create table ws_usercustomer
(nameid varchar2(12)          -- WebSynapse Userid 
,custid varchar2(10)                        
,lastuser varchar2(12)                  
,lastupdate date                     
);
create unique index ws_usercustomer_idx on ws_usercustomer(nameid,custid);

--
-- WS_USERDETAIL 
--
create table ws_userdetail
(nameid varchar2(12)          -- WebSynapse Userid 
,formid varchar2(32)                        
,facility varchar2(3)                  
,setting varchar2(12)                  
,lastuser varchar2(12)                  
,lastupdate date                     
);
create unique index ws_userdetail_idx on ws_userdetail(nameid,formid,facility);

insert into ws_userheader (nameid, username, allreports, lastuser, lastupdate, userstatus, usertype)
values ('SUPER', 'Supervisor User', 'A', 'SYNAPSE', sysdate, 'A', 'G');

insert into ws_userheader (nameid, username, allreports, lastuser, lastupdate, userstatus, usertype)
values ('WEBGRP', 'Web Access Group', 'S', 'SYNAPSE', sysdate, 'A', 'G');

insert into ws_userheader (nameid, groupid, allcusts, allreports, lastuser, lastupdate, 
	blendedpword, userstatus, usertype, facility)
values ('SITEMANAGER', 'SUPER', 'A', 'A', 'SYNAPSE', sysdate,
	zus.blenderize_user('SITEMANAGER','sitemgr'), 'A', 'U', 'ZET');

insert into ws_userfacility (nameid, facility, groupid, lastuser, lastupdate)
values ('SITEMANAGER', 'ZET', 'SUPER', 'SYNAPSE', sysdate);

commit;
	
exit;
