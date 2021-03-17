drop table asofeffdate_temp;

create global temporary table asofeffdate_temp
(
    item varchar2(50),
    lotnumber       varchar2(30),
    uom             varchar2(4),
    invstatus       varchar2(4),
    inventoryclass  varchar2(4),
    effdate         date)
on commit delete rows;

create index asofeffdate_temp_idx on asofeffdate_temp(item,lotnumber);

-- exit
