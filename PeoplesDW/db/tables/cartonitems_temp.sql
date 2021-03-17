drop table cartonitems_temp;

create global temporary table cartonitems_temp
(cartongroup varchar2(4),
cartontype varchar2(4),
item varchar2(50),
qty number(7),
uom varchar2(4),
weight number(13,4),
cube number(10,4),
cartonseq number(4),
pickseq number(7),
location varchar2(10)
) on commit delete rows;

exit;
