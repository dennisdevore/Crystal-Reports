CREATE OR REPLACE VIEW alps.parseruleview
(ruleid
,descr
,serialnomask
,lotmask
,user1mask
,user2mask
,user3mask
,mfgdatemask
,expdatemask
,countrymask
,lastuser
,lastupdate
,ruletype
)
as
select
ruleid
,descr
,serialnomask
,lotmask
,user1mask
,user2mask
,user3mask
,mfgdatemask
,expdatemask
,countrymask
,lastuser
,lastupdate
,'R'
from parserule
union
select
groupid
,descr
,null
,null
,null
,null
,null
,null
,null
,null
,lastuser
,lastupdate
,'G'
from parserulegroup
order by 1;

comment on table parseruleview is '$Id: parseruleview.sql 1 2005-05-26 12:20:03Z ed $';

exit;

