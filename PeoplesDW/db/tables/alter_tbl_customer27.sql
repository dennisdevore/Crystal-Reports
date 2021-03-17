--
-- $Id$
--

alter table customer add
(
   overageunits         number(10,2),
   overageunitstype     char(1) default 'N',
   overagedollars       number(10,2),
   overagedollarstype   char(1) default 'N',
   overagedollarsfield  char(1) default '1',
   overagesupcode       varchar2(10)
);

exit;
