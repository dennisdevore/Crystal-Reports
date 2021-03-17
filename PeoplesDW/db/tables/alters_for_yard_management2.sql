alter table facility drop column
facility_type;


alter table facility add
(
use_yard char(1)
);

drop table facility_types;

