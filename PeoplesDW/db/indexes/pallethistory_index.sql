drop index pallethistory_unique;
create unique index pallethistory_unique on
  pallethistory(custid, facility, pallettype, carrier, lastupdate, 
    orderid, shipid);

drop index pallethistory_loadno;
create index pallethistory_loadno on
  pallethistory(loadno, custid, facility);

drop index pallethistory_carrier;
create index pallethistory_carrier on
       pallethistory(carrier, custid, facility);

drop index pallethistory_customer;
create index pallethistory_customer on
       pallethistory(custid, facility, carrier);

exit;
