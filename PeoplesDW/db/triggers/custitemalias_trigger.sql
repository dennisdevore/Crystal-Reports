drop trigger alps.custitemalias_biu;
drop trigger alps.custitemalias_au;
create or replace trigger alps.custitemalias_bi
before insert
on alps.custitemalias
for each row
declare
l_upc_count pls_integer;

begin

  if :new.aliasdesc like 'UPC%' then

    select count(1)
      into l_upc_count
      from custitemalias
     where custid = :new.custid
       and item = :new.item
       and aliasdesc like 'UPC%';

    if l_upc_count > 0 then
      raise_application_error(-20009,
                              'Only one alias can be designated as a UPC code');
    end if;
    
  end if;

end;
/
show error trigger custitemalias_bi;
exit;
