--
-- new flag to indicate an object is related to websynapse
-- and is available for security maintenance to a company user
-- (a regular synapse user has access to all applicationobjects)
alter table applicationobjects add (
  websynapse_yn  char(1)
);

update applicationobjects
   set websynapse_yn = 'N'
where websynapse_yn is null;

exit;
