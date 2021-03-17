--
-- $Id$
--
drop  table XchngCustomer;

create table XchngCustomer(
    customer        varchar2(8),
    address_type    number(3),
    name            varchar2(35),
    contactname     varchar2(40),
    addr1           varchar2(40),
    addr2           varchar2(40),
    city            varchar2(30),
    state           varchar2(2),
    postalcode      varchar2(12),
    countrycode     varchar2(3),
    phone           varchar2(25),
    fax             varchar2(25),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index XchngCustomer_cust_idx 
    on XchngCustomer(customer, address_type);

exit;
