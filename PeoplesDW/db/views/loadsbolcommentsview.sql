create or replace view loadsbolcommentsview
(
    loadno,
    bolcomment
)
as
select
    LD.loadno,
    zbol.loadsbolcomments(LD.loadno)
from
    loadsbolcomments LD;

comment on table loadsbolcommentsview is '$Id$';

exit;
