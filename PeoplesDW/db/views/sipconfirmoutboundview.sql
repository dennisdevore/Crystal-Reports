create or replace view sipconfirmoutboundview
as
select *
  from sipconfirmview
 where ordertype = 'O';

comment on table sipconfirmoutboundview is '$Id$';

exit;
