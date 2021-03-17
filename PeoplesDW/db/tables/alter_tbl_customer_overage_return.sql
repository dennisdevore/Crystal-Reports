--
-- $Id: $
--

alter table customer add
(
   overageunits_return         number(10,2),
   overageunitstype_return     char(1),
   overagedollars_return       number(10,2),
   overagedollarstype_return   char(1),
   overagedollarsfield_return  char(1),
   overagesupcode_return       varchar2(10)
);

update customer
set overageunitstype_return = 'N' 
where overageunitstype_return is null;

update customer
set overagedollarstype_return = 'N' 
where overagedollarstype_return is null;

update customer
set overagedollarsfield_return = '1' 
where overagedollarsfield_return is null;

exit;
