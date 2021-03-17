drop table dynamicpf_temp;

create global temporary table dynamicpf_temp
(
   facility    varchar2(3),
   custid      varchar2(10),
   item 	   varchar2(50),
   locid       varchar2(20)
)
on commit delete rows;

exit;
