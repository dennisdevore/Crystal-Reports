--
-- $Id$
--
declare
qty number(7);

errno number;
errmsg varchar2(200);
 ix integer;

begin



   for ix in 1..10000 loop
       insert into zseq
       values (ix);

   end loop;

end;

/

