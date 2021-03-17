create or replace view appmsgsview
(
MSGID,
CREATED,                      
AUTHOR,                       
FACILITY,                     
CUSTID,                       
MSGTEXT,                      
STATUS,                       
LASTUSER,                     
LASTUPDATE,                   
MSGTYPe,
authorabbrev,
statusabbrev,
typeabbrev,
appmsgsrowid
)
as
select
MSGID,
CREATED,                      
AUTHOR,                       
FACILITY,                     
CUSTID,                       
MSGTEXT,                      
STATUS,                       
appmsgs.LASTUSER,                     
appmsgs.LASTUPDATE,                   
MSGTYPe,
nvl(messageauthors.abbrev,author),
nvl(messagestatus.abbrev,status),
nvl(messagetypes.abbrev,msgtype),
rowidtochar(appmsgs.rowid)
from appmsgs, messageauthors, messagestatus,
     messagetypes
where msgtype = messagetypes.code (+)
  and author = messageauthors.code (+)
  and status = messagestatus.code (+);
  
comment on table appmsgsview is '$Id$';
  
create or replace view alertmanagerview
(
ALERTID,
USERALERTID,
CONTACTUSERID,
CREATED,                      
AUTHOR,                       
AUTHORABBREV,
FACILITY,                     
CUSTID,                       
MSGTEXT,                      
MSGTYPE,
TYPEABBREV,
STATUS,                       
STATUSABBREV,
NEXTSEND,
LASTUSER,                     
LASTUPDATE,                   
ALERTMANAGERROWID,
ESCALATIONCOUNT,
SENDER,
NOTIFY
)
as
select
am.alertid,
am.useralertid,
am.contactuserid,
am.created,                      
am.author,                       
nvl(ma.abbrev,author),
am.facility,                     
am.custid,                       
am.msgtext,                      
am.msgtype,
nvl(mt.abbrev,msgtype),
am.status,                       
nvl(ms.abbrev,status),
am.nextsend,
am.lastuser,                     
am.lastupdate,                   
rowidtochar(am.rowid),
(select count(1) from alert_history ah where ah.alertid = am.alertid and ah.escalateid <> 0),
am.sender,
am.notify
from alert_manager am, messageauthors ma, messagestatus ms,
     messagetypes mt
where am.msgtype = mt.code (+)
  and am.author = ma.code (+)
  and am.status = ms.code (+);
  
comment on table alertmanagerview is '$Id$';
  
exit;
