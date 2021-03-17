create table userhistory_new
(
   nameid      varchar2(12) not null,
   begtime     date not null,
   event       varchar2(4) not null,
   endtime     date,
   facility    varchar2(3),
   custid      varchar2(10),
   equipment   varchar2(2),
   units       number(7),
   etc         varchar2(255),
   orderid     number(9),
   shipid      number(2),
   location    varchar2(10),
   lpid        varchar2(15),
   item varchar2(50),
   uom         varchar2(4),
   baseuom     varchar2(4),
   baseunits   number(7),
   cube        number(10,4),
   weight      number(17,8)
);

exit;
