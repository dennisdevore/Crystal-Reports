--
-- $Id$
--
insert into BillingMethod values('SCLN','LINE/LOT SURCHARGE','LINE SC',
       'N','SUP',sysdate);
insert into BillingMethod values('SCIT','ITEM SURCHARGE','ITEM SC',
       'N','SUP',sysdate);
insert into BillingMethod values('SCOR','ORDER SURCHARGE','ORDER SC',
       'N','SUP',sysdate);
insert into BillingMethod values('SCIN','INVOICE SURCHARGE','INVOICE SC',
       'N','SUP',sysdate);

commit;
