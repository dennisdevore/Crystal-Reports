--
-- $Id$
--
create table ursa
(zipcode varchar2(5)
,state varchar2(2)
,cityprefixes varchar2(255)
,lastuser varchar2(12)
,lastupdate date
);

create unique index ursa_idx on
  ursa(zipcode,state);


exit;
