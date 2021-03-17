create or replace view shippingplatelotcntview as 
select orderid,shipid,item, count(distinct nvl(lotnumber,'x')) as lotcount from shippingplate
where type in ('F','P')
group by orderid,shipid,item;

comment on table shippingplatelotcntview  is '$Id$';

exit;

