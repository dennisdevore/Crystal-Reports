
create or replace view posted
(
   custid,
   postdate
)
as
select distinct 
  custid, 
  postdate
  from posthdr;
  
comment on table posted is '$Id$';
  
exit;
