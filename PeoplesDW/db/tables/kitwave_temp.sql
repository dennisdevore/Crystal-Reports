drop table kitwave_temp;

create global temporary table kitwave_temp
(
    wave    number,
    userid  varchar2(12)
)
on commit delete rows;

-- exit;
