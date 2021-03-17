--
-- $Id$
--
alter table customer add (
      collectProNumbers      varchar2(1)
);      

update customer set
      collectProNumbers = 'N';
      

commit;

-- exit;
