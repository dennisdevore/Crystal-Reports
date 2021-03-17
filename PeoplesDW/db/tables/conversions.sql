--
-- $Id$
--
drop table conversions;

create table conversions (
	fromuom	      varchar2(4),
	touom         varchar2(4),
    qty           number(9,2)
);

create unique index conversions_idx on
       conversions(fromuom, touom);


insert into conversions values('LBS','CWT',100);
insert into conversions values('MINS','HOUR',60);
insert into conversions values('MINS','QTRH',15);
insert into conversions values('LBS','KG',2.2);

exit;
