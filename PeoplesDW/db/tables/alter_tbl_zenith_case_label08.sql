--
-- $Id$
--

alter table zenith_case_labels add (
   itemalias   varchar2(20),
   stopno      number(7),
   macys128    varchar2(25)
);

exit;
