create table custbillschedule(
    custid      varchar2(10) not null,
    type        varchar2(12) not null,
    billdate    date not null,
    lastuser    varchar2(12),
    lastupdate  date,
constraint custbillschedule_pk 
    primary key(custid, type, billdate)
);

exit;
