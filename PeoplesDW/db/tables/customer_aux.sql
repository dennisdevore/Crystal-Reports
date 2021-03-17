drop table customer_aux;

create table customer_aux
(
  custid           varchar2(10) not null,
  generatecofa     char(1),
  cofashiprptfile  varchar2(255),
  lastuser         varchar2(12),             
  lastupdate       date       
);

create unique index custaux_unique on customer_aux(custid);

declare
  cursor cust_cur is
	  select CustID
		  from Customer;
begin
  for cust_rec in cust_cur
	loop
	  insert into customer_aux(
		  custid, generatecofa, cofashiprptfile,
		    lastuser, lastupdate)
		values(cust_rec.custid, 'N', null, 'SYSTEM', sysdate);
	end loop;
	
	commit;
end;

/
