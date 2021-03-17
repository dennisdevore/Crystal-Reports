--
-- $Id$
--
drop table skid_build;

create table skid_build(
    buildno number(9),
    skidno  number(5),
    orderid number(9),
    shipid  number(2),
    item    varchar2(20),
    pieces  number(10),
    cartonno number(5),
    weight  number(16,4)
);

create index skid_build_idx on skid_build(buildno);

drop public synonym skid_build;

create public synonym skid_build for pecas.skid_build;

exit;
