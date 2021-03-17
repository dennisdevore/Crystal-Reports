--
-- $Id$
--
alter table loads add
(
   putonwater           date,
   etatoport            date,
   arrivedatport        date,
   lastfreedate         date,
   carriercontactdate   date,
   arrivedinyard        date,
   appointmentdate      date,
   dueback              date,
   returnedtoport       date,
   trackingnotes        clob,
   trackforcustomer     varchar2(10)
);

exit;
