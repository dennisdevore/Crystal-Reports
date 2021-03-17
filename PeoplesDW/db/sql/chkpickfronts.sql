--
-- $Id$
--
select pickfront, item
  from itempickfronts i
 where custid = 'HP'
   and not exists (select *
                     from plate p
                    where i.facility = p.facility
                      and i.pickfront = p.location
                      and p.type = 'PA')
   and not exists (select *
                     from plate p
                    where i.facility = p.facility
                      and i.pickfront != p.location
                      and p.type = 'PA');

select pickfront, item
  from itempickfronts i
 where custid = 'HP'
   and not exists (select *
                     from plate p
                    where i.facility = p.facility
                      and i.pickfront = p.location
                      and p.type = 'PA')
   and exists (select *
                     from plate p
                    where i.facility = p.facility
                      and i.pickfront != p.location
                      and p.type = 'PA');
exit;




