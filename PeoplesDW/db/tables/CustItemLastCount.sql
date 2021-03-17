declare
  cursor cca_cur is
    select custid, item, Max(whenoccurred) as whenoccurred
      from CycleCountActivity
        group by custid, item;
begin
  for cca_rec in cca_cur 
  loop
    update CustItem set CustItem.LastCount = cca_rec.whenoccurred
      where CustItem.custid = cca_rec.custid and
        CustItem.item = cca_rec.item;
  end loop;
  
  commit;
end;
/
  
