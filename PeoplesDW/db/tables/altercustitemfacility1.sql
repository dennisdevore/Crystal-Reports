--
-- $Id$
--
alter table custitemfacility add(
lastuser varchar2(12),
lastupdate date
);

alter table custproductgroupfacility add(
lastuser varchar2(12),
lastupdate date
);

alter table custfacility add(
lastuser varchar2(12),
lastupdate date
);

exit;
