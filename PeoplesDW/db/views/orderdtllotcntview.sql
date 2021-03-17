create or replace view orderdtllotcntview as 
select orderid,shipid,item, count(distinct nvl(lotnumber,'x')) as lotcount from orderdtl
group by orderid,shipid,item;

comment on table orderdtllotcntview is '$Id$';

exit;

