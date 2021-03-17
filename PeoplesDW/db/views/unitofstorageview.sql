create or replace view unitofstorageview as
select unitofstorage as code, description as descr, abbrev
from unitofstorage;

comment on table unitofstorageview is '$Id$';

exit;
