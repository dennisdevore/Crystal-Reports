create or replace view platereceiptview
(
  lpid,
  recmethod
)
as
select
  lpid,
  recmethod
 from plate
union
select
  lpid,
  recmethod
 from deletedplate;

comment on table platereceiptview is '$Id$';

exit;

