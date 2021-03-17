create or replace package body alps.pkg_manage_orders as                            
--
-- $Id$
--

procedure usp_insert_orderhdr
(  order_type VARCHAR2,
   cust_id VARCHAR2,
   po VARCHAR2, 
   priority VARCHAR2,    
   from_facilty VARCHAR2,
   to_facility VARCHAR2,
   ship_to_name VARCHAR2,
   ship_to_contact VARCHAR2,
   ship_to_addr1 VARCHAR2,
   ship_to_addr2 VARCHAR2,
   ship_to_city VARCHAR2,
   ship_to_state VARCHAR2,
   ship_to_postal_code VARCHAR2,
   ship_to_country_code VARCHAR2,
   ship_to_phone VARCHAR2,
   ship_to_fax VARCHAR2,
   ship_to_email VARCHAR2,
   bill_to_name VARCHAR2,
   bill_to_contact VARCHAR2,
   bill_to_addr1 VARCHAR2, 
   bill_to_addr2 VARCHAR2,
   bill_to_city VARCHAR2,
   bill_to_state VARCHAR2,
   bill_to_postal_code VARCHAR2,
   bill_to_country_code VARCHAR2,
   bill_to_phone VARCHAR2,
   bill_to_fax VARCHAR2,
   bill_to_email VARCHAR2,
   arrival_date DATE,
   ship_type VARCHAR2,
   carrier VARCHAR2,
   reference VARCHAR2,
   ship_terms VARCHAR2,
   saturday_delivery CHAR,
   apptdate DATE, 
   shipdate DATE,
   ship_to VARCHAR2,
   consignee VARCHAR2,
   last_user VARCHAR2,
   status_user VARCHAR2,
   billoflading VARCHAR2,
   comment1 CLOB,   
   bolcomments CLOB,
   delivery_service VARCHAR2,
   in_shipper VARCHAR2,
   in_expanded_fields CHAR,
    return_status OUT NUMBER,
   return_msg OUT VARCHAR2,
   return_order_id OUT NUMBER
   ) is

/*
  Cursor Declaration 
*/
/*cursor curConsignee is
  select *
    from consignee
   where consignee = ship_to;
curCon curConsignee%rowtype;*/

/*
  Variable Declaration 
*/

cursor curCustomer is
  select nvl(unique_order_identifier,'R') as unique_order_identifier,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer C, customer_aux A
   where C.custid = rtrim(cust_id)
     and C.custid = A.custid(+);
cu curCustomer%rowtype;

maxOrderID NUMBER;
facilityTo VARCHAR2(3);
facilityFrom VARCHAR2(3);
to_ship NUMBER;
from_ship NUMBER;
temp_consignee VARCHAR2(25);
carrier_count NUMBER;
temp_carrier VARCHAR2(25);
refCount NUMBER;
lReference VARCHAR2(20);
lPO VARCHAR2(20);
ship_date DATE; /* quick hack because shipdate no being set in WebSynapse */
strMsg VARCHAR2(255);


begin

  /*curCon := null;
  open curConsignee;
  fetch curConsignee into curCon;
  close curConsignee;*/


  cu := null;
  open curCustomer;
  fetch curCustomer into cu;
  close curCustomer;
  if cu.dup_reference_ynw is null then
    return_msg := 'Customer ID not found ' || cust_id;
    return_status := -7;
    return;
  end if;

-- check for the existence of the facility
  begin
    select facility
      into facilityTo
      from facility where facility = upper(to_facility);
    exception when others then
    null;
  end;

  begin
    select facility
      into facilityFrom
      from facility where facility = upper(from_facilty);
    exception when others then
    null;
  end;

  if (facilityFrom is null) and (facilityTo is null) then
    return_msg := 'Facility not found.';
    return_status := -1;
    return;
  end if;

  begin 
    select nvl(count(*), 0) into to_ship
      from custconsignee 
      where consignee = upper(ship_to) and custid = cust_id;
    exception when others then
    null;  
  end;
 
  if (ship_to is not null) and (to_ship = 0) then
    return_status := -2;
    return_msg := 'Ship to is not found.';
    return;
  end if;
  
  temp_consignee := consignee;
  
  begin 
    select nvl(count(*), 0) into from_ship
      from custconsignee 
      where consignee = upper(temp_consignee) and custid = cust_id;
    exception when others then
    null;  
  end;
  
  if (order_type <> 'R') and (consignee is not null) and (from_ship = 0) then
    return_status := -3;
    return_msg := 'Bill to is not found.';
    return;
  end if;
  
   

  temp_carrier := carrier;
  
  begin 
    select nvl(count(*), 0) into carrier_count
      from alps.carrier 
      where carrier = upper(temp_carrier);
    exception when others then
    null;  
  end;
  
  if (carrier is not null) and (carrier_count = 0) then
    return_status := -4;
    return_msg := 'carrier is not found.';
    return;
  end if;
  
  
   begin 
    select nvl(count(*), 0) into from_ship
      from custshipper
      where shipper = upper(in_shipper) and custid = cust_id;
    exception when others then
    null;  
  end;
  
  if (order_type = 'R') and (in_shipper is not null) and (from_ship = 0) then
    return_status := -5;  
    return_msg := 'Supplier is not found.';
    return;
  end if;
--get a new order id

  if (cu.dup_reference_ynw <> 'Y') then
    lReference := reference;
    lPO := PO;
    
    select count(1)
      into refCount
      from orderhdr
     where custid = cust_id
       and upper(reference) = upper(lReference)
       and orderstatus != 'X'
       and (upper(po) = upper(lPO)
        or  cu.unique_order_identifier != 'P');

    if refCount > 0 then
      if (cu.dup_reference_ynw = 'N') then
        if (cu.unique_order_identifier = 'P') then
          return_status := -9;  
          return_msg := 'Duplicate Reference and PO number';
          return;
        else
          return_status := -8;  
          return_msg := 'Duplicate Reference';
          return;
        end if;
      end if;
    end if;
  end if;
   
   zoe.get_next_orderid(maxOrderID, return_msg);
   
   ship_date := shipdate;
   
--get shipdate
 if (order_type <> 'R' ) and (ship_date is null) then
   	zms.compute_shipdate(upper(from_facilty),upper(ship_to),to_char(arrival_date,'yyyymmdd'),ship_date,return_msg);
   	if (return_msg <> 'OKAY') then
   		return_status := -6;
   		return;
 	end if;
  end if; 	     
    
  savepoint orders;
  
  begin
  insert into orderhdr(orderid, ordertype, shipid, custid, po, fromfacility, tofacility, priority, arrivaldate,
                 shiptype, carrier, reference, shipterms, shiptoname, shiptocontact, shiptoaddr1, shiptoaddr2,shiptocity, shiptostate,
                 shiptopostalcode, shiptocountrycode, shiptophone, shiptofax, shiptoemail, billtoname, billtocontact, billtoaddr1,
                 billtoaddr2, billtocity, billtostate, billtopostalcode, billtocountrycode, billtophone, billtofax, 
                 billtoemail, saturdaydelivery,orderstatus, commitstatus, entrydate, statusupdate,lastupdate,
                 apptdate, shipdate, shipto, consignee, lastuser, statususer, comment1, billoflading, deliveryservice, cod,
                  rfautodisplay, source, companycheckok,shipper,expanded_websynapse_fields) 
                  values(maxOrderID, order_type, 1, cust_id, upper(po), upper(from_facilty), upper(to_facility), priority, arrival_date, ship_type, upper(carrier),
                 upper(reference), ship_terms, ship_to_name, ship_to_contact, ship_to_addr1, ship_to_addr2, ship_to_city, ship_to_state, ship_to_postal_code,
                 ship_to_country_code, ship_to_phone, ship_to_fax, ship_to_email, bill_to_name, bill_to_contact, bill_to_addr1, bill_to_addr2, bill_to_city, bill_to_state, bill_to_postal_code,
                 bill_to_country_code, bill_to_phone, bill_to_fax, bill_to_email, saturday_delivery,                    
                 0, 0, sysdate, sysdate, sysdate, apptdate, ship_date, upper(ship_to), upper(consignee), last_user, last_user, comment1, billoflading, delivery_service, 'N',
                  'N', 'WEB', 'N',upper(in_shipper),in_expanded_fields);

  strMsg := 'Order ' || trim(to_char(maxOrderID)) || '-1 added via WebSynapse by ' || last_user; 
  zms.log_msg('WEBORDER', nvl(facilityFrom, facilityTo), cust_id,
     substr(strMsg,1,254), 'I', 'SYNAPSE', return_msg);

  exception WHEN OTHERS THEN        
      return_status := 0;
      return_msg := sqlerrm;      
      rollback to savepoint  orders;
      return;
  end;                    
  
  if bolcomments is not null then
    begin                               
      insert into orderhdrbolcomments(orderid, shipid, bolcomment, lastuser, lastupdate)                    
      values(maxOrderId, 1, bolcomments, last_user, sysdate);
      
      exception WHEN OTHERS THEN
        return_status := 0;
        return_msg := sqlerrm;      
        rollback to savepoint  orders;
        return;            
    end;
  end if;

  commit;         
  return_status := 1;
  return_msg := 'OK';
  return_order_id := maxOrderId;
  
exception WHEN OTHERS THEN  
  return_status := 0;
  return_msg := sqlerrm;  
  rollback to savepoint  orders;
      
end usp_insert_orderhdr;  

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
procedure usp_update_orderhdr
(  in_order_type VARCHAR2,
   in_cust_id VARCHAR2,
   in_po VARCHAR2, 
   in_priority VARCHAR2,    
   in_from_facilty VARCHAR2,
   in_to_facility VARCHAR2,
   in_ship_to_name VARCHAR2,
   in_ship_to_contact VARCHAR2,
   in_ship_to_addr1 VARCHAR2,
   in_ship_to_addr2 VARCHAR2,
   in_ship_to_city VARCHAR2,
   in_ship_to_state VARCHAR2,
   in_ship_to_postal_code VARCHAR2,
   in_ship_to_country_code VARCHAR2,
   in_ship_to_phone VARCHAR2,
   in_ship_to_fax VARCHAR2,
   in_ship_to_email VARCHAR2,
   in_bill_to_name VARCHAR2,
   in_bill_to_contact VARCHAR2,
   in_bill_to_addr1 VARCHAR2, 
   in_bill_to_addr2 VARCHAR2,
   in_bill_to_city VARCHAR2,
   in_bill_to_state VARCHAR2,
   in_bill_to_postal_code VARCHAR2,
   in_bill_to_country_code VARCHAR2,
   in_bill_to_phone VARCHAR2,
   in_bill_to_fax VARCHAR2,
   in_bill_to_email VARCHAR2,
   in_arrival_date DATE,
   in_ship_type VARCHAR2,
   in_carrier VARCHAR2,
   in_reference VARCHAR2,
   in_ship_terms VARCHAR2,
   in_saturday_delivery CHAR,
   in_apptdate DATE, 
   in_shipdate DATE,
   in_ship_to VARCHAR2,
   in_consignee VARCHAR2,
   in_last_user VARCHAR2,
   in_status_user VARCHAR2,
   in_billoflading VARCHAR2,
   in_comment1 CLOB,   
   in_bolcomments CLOB,
   in_delivery_service VARCHAR2,
   in_shipper VARCHAR2,
   in_expanded_fields CHAR,
   in_orderid NUMBER,
   in_shipid NUMBER,
   return_status OUT NUMBER,
   return_msg OUT VARCHAR2
   ) is

/*
  Cursor Declaration 
*/
/*cursor curConsignee is
  select *
    from consignee
   where consignee = ship_to;
curCon curConsignee%rowtype;*/

/*
  Variable Declaration 
*/
facilityTo VARCHAR2(3);
facilityFrom VARCHAR2(3);
to_ship NUMBER;
from_ship NUMBER;
temp_consignee VARCHAR2(25);
carrier_count NUMBER;
temp_carrier VARCHAR2(25);
strMsg VARCHAR2(255);


begin

-- check for the existence of the facility
  begin
    select facility
      into facilityTo
      from facility where facility = upper(in_to_facility);
    exception when others then
    null;
  end;

  begin
    select facility
      into facilityFrom
      from facility where facility = upper(in_from_facilty);
    exception when others then
    null;
  end;

  if (facilityFrom is null) and (facilityTo is null) then
    return_msg := 'Facility not found.';
    return_status := -1;
    return;
  end if;

  begin 
    select nvl(count(*), 0) into to_ship
      from custconsignee 
      where consignee = upper(in_ship_to) and custid = in_cust_id;
    exception when others then
    null;  
  end;
 
  if (in_ship_to is not null) and (to_ship = 0) then
    return_status := -2;
    return_msg := 'Ship to is not found.';
    return;
  end if;
  
  temp_consignee := in_consignee;
  
  begin 
    select nvl(count(*), 0) into from_ship
      from custconsignee 
      where consignee = upper(temp_consignee) and custid = in_cust_id;
    exception when others then
    null;  
  end;
  
  if (in_order_type <> 'R') and (in_consignee is not null) and (from_ship = 0) then
    return_status := -3;
    return_msg := 'Bill to is not found.';
    return;
  end if;
  
   

  temp_carrier := in_carrier;
  
  begin 
    select nvl(count(*), 0) into carrier_count
      from alps.carrier 
      where carrier = upper(temp_carrier);
    exception when others then
    null;  
  end;
  
  if (in_carrier is not null) and (carrier_count = 0) then
    return_status := -4;
    return_msg := 'carrier is not found.';
    return;
  end if;
  
  
   begin 
    select nvl(count(*), 0) into from_ship
      from custshipper
      where shipper = upper(in_shipper) and custid = in_cust_id;
    exception when others then
    null;  
  end;
  
  if (in_order_type = 'R') and (in_shipper is not null) and (from_ship = 0) then
    return_status := -5;  
    return_msg := 'Supplier is not found.';
    return;
  end if;
--get a new order id
   
  savepoint orders;
  
  begin
  	update orderhdr
  	   set ordertype = in_order_type,
  	       po = upper(in_po),
  	       fromfacility = upper(in_from_facilty),
  	       tofacility = upper(in_to_facility),
  	       priority = in_priority,
  	       arrivaldate = in_arrival_date,
           shiptype = in_ship_type,
           carrier = upper(in_carrier),
           reference = upper(in_reference),
           shipterms = in_ship_terms,
           shiptoname = in_ship_to_name,
           shiptocontact = in_ship_to_contact,
           shiptoaddr1 = in_ship_to_addr1,
           shiptoaddr2 = in_ship_to_addr2,
           shiptocity = in_ship_to_city,
           shiptostate = in_ship_to_state,
           shiptopostalcode = in_ship_to_postal_code,
           shiptocountrycode = in_ship_to_country_code,
           shiptophone = in_ship_to_phone,
           shiptofax = in_ship_to_fax,
           shiptoemail = in_ship_to_email,
           billtoname = in_bill_to_name,
           billtocontact = in_bill_to_contact,
           billtoaddr1 = in_bill_to_addr1,
           billtoaddr2 = in_bill_to_addr2,
           billtocity = in_bill_to_city,
           billtostate = in_bill_to_state,
           billtopostalcode = in_bill_to_postal_code,
           billtocountrycode = in_bill_to_country_code,
           billtophone = in_bill_to_phone,
           billtofax = in_bill_to_fax, 
           billtoemail = in_bill_to_email,
           saturdaydelivery = in_saturday_delivery,
           statusupdate = sysdate,
           lastupdate = sysdate,
           apptdate = in_apptdate,
           shipdate = in_shipdate,
           shipto = upper(in_ship_to),
           consignee = upper(in_consignee),
           lastuser = in_last_user,
           statususer = in_last_user,
           comment1 = in_comment1,
           billoflading = in_billoflading,
           deliveryservice = in_delivery_service,
           shipper = upper(in_shipper),
           expanded_websynapse_fields = in_expanded_fields 
     where orderid = in_orderid
       and shipid = in_shipid;

  strMsg := 'Order ' || trim(to_char(in_orderid)) || '-' || trim(to_char(in_shipid)) || ' updated via WebSynapse by ' || in_last_user; 
  zms.log_msg('WEBORDER', nvl(facilityFrom, facilityTo), in_cust_id,
     substr(strMsg,1,254), 'I', 'SYNAPSE', return_msg);

  exception WHEN OTHERS THEN        
      return_status := 0;
      return_msg := sqlerrm;      
      rollback to savepoint  orders;
      return;
  end;                    
  
  if in_bolcomments is not null then
    begin
    	update orderhdrbolcomments
    	   set bolcomment = in_bolcomments,
    	       lastuser= in_last_user,
    	       lastupdate = sysdate
    	 where orderid = in_orderid
         and shipid = in_shipid;
      
      exception WHEN OTHERS THEN
        return_status := 0;
        return_msg := sqlerrm;      
        rollback to savepoint  orders;
        return;            
    end;
  end if;

  commit;         
  return_status := 1;
  return_msg := 'OK';
  
exception WHEN OTHERS THEN  
  return_status := 0;
  return_msg := sqlerrm;  
  rollback to savepoint  orders;
      
end usp_update_orderhdr;  

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
procedure usp_update_orderhdr_passthrus
(  in_orderid NUMBER,
   in_shipid NUMBER,
   in_hdrpassthruchar01 VARCHAR2,
   in_hdrpassthruchar02 VARCHAR2,
   in_hdrpassthruchar03 VARCHAR2,
   in_hdrpassthruchar04 VARCHAR2,
   in_hdrpassthruchar05 VARCHAR2,
   in_hdrpassthruchar06 VARCHAR2,
   in_hdrpassthruchar07 VARCHAR2,
   in_hdrpassthruchar08 VARCHAR2,
   in_hdrpassthruchar09 VARCHAR2,
   in_hdrpassthruchar10 VARCHAR2,
   in_hdrpassthruchar11 VARCHAR2,
   in_hdrpassthruchar12 VARCHAR2,
   in_hdrpassthruchar13 VARCHAR2,
   in_hdrpassthruchar14 VARCHAR2,
   in_hdrpassthruchar15 VARCHAR2,
   in_hdrpassthruchar16 VARCHAR2,
   in_hdrpassthruchar17 VARCHAR2,
   in_hdrpassthruchar18 VARCHAR2,
   in_hdrpassthruchar19 VARCHAR2,
   in_hdrpassthruchar20 VARCHAR2,
   in_hdrpassthruchar21 VARCHAR2,
   in_hdrpassthruchar22 VARCHAR2,
   in_hdrpassthruchar23 VARCHAR2,
   in_hdrpassthruchar24 VARCHAR2,
   in_hdrpassthruchar25 VARCHAR2,
   in_hdrpassthruchar26 VARCHAR2,
   in_hdrpassthruchar27 VARCHAR2,
   in_hdrpassthruchar28 VARCHAR2,
   in_hdrpassthruchar29 VARCHAR2,
   in_hdrpassthruchar30 VARCHAR2,
   in_hdrpassthruchar31 VARCHAR2,
   in_hdrpassthruchar32 VARCHAR2,
   in_hdrpassthruchar33 VARCHAR2,
   in_hdrpassthruchar34 VARCHAR2,
   in_hdrpassthruchar35 VARCHAR2,
   in_hdrpassthruchar36 VARCHAR2,
   in_hdrpassthruchar37 VARCHAR2,
   in_hdrpassthruchar38 VARCHAR2,
   in_hdrpassthruchar39 VARCHAR2,
   in_hdrpassthruchar40 VARCHAR2,
   in_hdrpassthruchar41 VARCHAR2,
   in_hdrpassthruchar42 VARCHAR2,
   in_hdrpassthruchar43 VARCHAR2,
   in_hdrpassthruchar44 VARCHAR2,
   in_hdrpassthruchar45 VARCHAR2,
   in_hdrpassthruchar46 VARCHAR2,
   in_hdrpassthruchar47 VARCHAR2,
   in_hdrpassthruchar48 VARCHAR2,
   in_hdrpassthruchar49 VARCHAR2,
   in_hdrpassthruchar50 VARCHAR2,
   in_hdrpassthruchar51 VARCHAR2,
   in_hdrpassthruchar52 VARCHAR2,
   in_hdrpassthruchar53 VARCHAR2,
   in_hdrpassthruchar54 VARCHAR2,
   in_hdrpassthruchar55 VARCHAR2,
   in_hdrpassthruchar56 VARCHAR2,
   in_hdrpassthruchar57 VARCHAR2,
   in_hdrpassthruchar58 VARCHAR2,
   in_hdrpassthruchar59 VARCHAR2,
   in_hdrpassthruchar60 VARCHAR2,
   in_hdrpassthrudate01 VARCHAR2,
   in_hdrpassthrudate02 VARCHAR2,
   in_hdrpassthrudate03 VARCHAR2,
   in_hdrpassthrudate04 VARCHAR2,
   in_hdrpassthrudoll01 VARCHAR2,
   in_hdrpassthrudoll02 VARCHAR2,
   in_hdrpassthrunum01 VARCHAR2,
   in_hdrpassthrunum02 VARCHAR2,
   in_hdrpassthrunum03 VARCHAR2,
   in_hdrpassthrunum04 VARCHAR2,
   in_hdrpassthrunum05 VARCHAR2,
   in_hdrpassthrunum06 VARCHAR2,
   in_hdrpassthrunum07 VARCHAR2,
   in_hdrpassthrunum08 VARCHAR2,
   in_hdrpassthrunum09 VARCHAR2,
   in_hdrpassthrunum10 VARCHAR2,
   in_cancelafterdate VARCHAR2,
   in_deliveryrequesteddate VARCHAR2,
   in_requestedshipdate VARCHAR2,
   in_shipnotbeforedate VARCHAR2,
   in_shipnolaterdate VARCHAR2,
   in_cancelifnotdeliveredbydate VARCHAR2,
   in_donotdeliverafterdate VARCHAR2,
   in_donotdeliverbeforedate VARCHAR2,
   in_lastuser VARCHAR2,
   return_status OUT NUMBER,
   return_msg OUT VARCHAR2
) is

  lhdrpassthrudate01 DATE;
  lhdrpassthrudate02 DATE;
  lhdrpassthrudate03 DATE;
  lhdrpassthrudate04 DATE;
  lhdrpassthrudoll01 NUMBER;
  lhdrpassthrudoll02 NUMBER;
  lhdrpassthrunum01 NUMBER;
  lhdrpassthrunum02 NUMBER;
  lhdrpassthrunum03 NUMBER;
  lhdrpassthrunum04 NUMBER;
  lhdrpassthrunum05 NUMBER;
  lhdrpassthrunum06 NUMBER;
  lhdrpassthrunum07 NUMBER;
  lhdrpassthrunum08 NUMBER;
  lhdrpassthrunum09 NUMBER;
  lhdrpassthrunum10 NUMBER;
  lcancelafterdate DATE;
  ldeliveryrequesteddate DATE;
  lrequestedshipdate DATE;
  lshipnotbeforedate DATE;
  lshipnolaterdate DATE;
  lcancelifnotdeliveredbydate DATE;
  ldonotdeliverafterdate DATE;
  ldonotdeliverbeforedate DATE;

begin
  savepoint orders;
  
  if in_hdrpassthrudate01 is not null then
    lhdrpassthrudate01 := to_date(in_hdrpassthrudate01,'MMDDYYYY');
  end if;
  if in_hdrpassthrudate02 is not null then
    lhdrpassthrudate02 := to_date(in_hdrpassthrudate02,'MMDDYYYY');
  end if;
  if in_hdrpassthrudate03 is not null then
    lhdrpassthrudate03 := to_date(in_hdrpassthrudate03,'MMDDYYYY');
  end if;
  if in_hdrpassthrudate04 is not null then
    lhdrpassthrudate04 := to_date(in_hdrpassthrudate04,'MMDDYYYY');
  end if;
  if in_hdrpassthrudoll01 is not null then
    lhdrpassthrudoll01 := to_number(in_hdrpassthrudoll01,'99999999.99');
  end if;
  if in_hdrpassthrudoll02 is not null then
    lhdrpassthrudoll02 := to_number(in_hdrpassthrudoll02,'99999999.99');
  end if;
  if in_hdrpassthrunum01 is not null then
    lhdrpassthrunum01 := to_number(in_hdrpassthrunum01,'999999999999.9999');
  end if;
  if in_hdrpassthrunum02 is not null then
    lhdrpassthrunum02 := to_number(in_hdrpassthrunum02,'999999999999.9999');
  end if;
  if in_hdrpassthrunum03 is not null then
    lhdrpassthrunum03 := to_number(in_hdrpassthrunum03,'999999999999.9999');
  end if;
  if in_hdrpassthrunum04 is not null then
    lhdrpassthrunum04 := to_number(in_hdrpassthrunum04,'999999999999.9999');
  end if;
  if in_hdrpassthrunum05 is not null then
    lhdrpassthrunum05 := to_number(in_hdrpassthrunum05,'999999999999.9999');
  end if;
  if in_hdrpassthrunum06 is not null then
    lhdrpassthrunum06 := to_number(in_hdrpassthrunum06,'999999999999.9999');
  end if;
  if in_hdrpassthrunum07 is not null then
    lhdrpassthrunum07 := to_number(in_hdrpassthrunum07,'999999999999.9999');
  end if;
  if in_hdrpassthrunum08 is not null then
    lhdrpassthrunum08 := to_number(in_hdrpassthrunum08,'999999999999.9999');
  end if;
  if in_hdrpassthrunum09 is not null then
    lhdrpassthrunum09 := to_number(in_hdrpassthrunum09,'999999999999.9999');
  end if;
  if in_hdrpassthrunum10 is not null then
    lhdrpassthrunum10 := to_number(in_hdrpassthrunum10,'999999999999.9999');
  end if;
  if in_cancelafterdate is not null then
    lcancelafterdate := to_date(in_cancelafterdate,'MMDDYYYY');
  end if;
  if in_deliveryrequesteddate is not null then
    ldeliveryrequesteddate := to_date(in_deliveryrequesteddate,'MMDDYYYY');
  end if;
  if in_requestedshipdate is not null then
    lrequestedshipdate := to_date(in_requestedshipdate,'MMDDYYYY');
  end if;
  if in_shipnotbeforedate is not null then
    lshipnotbeforedate := to_date(in_shipnotbeforedate,'MMDDYYYY');
  end if;
  if in_shipnolaterdate is not null then
    lshipnolaterdate := to_date(in_shipnolaterdate,'MMDDYYYY');
  end if;
  if in_cancelifnotdeliveredbydate is not null then
    lcancelifnotdeliveredbydate := to_date(in_cancelifnotdeliveredbydate,'MMDDYYYY');
  end if;
  if in_donotdeliverafterdate is not null then
    ldonotdeliverafterdate := to_date(in_donotdeliverafterdate,'MMDDYYYY');
  end if;
  if in_donotdeliverbeforedate is not null then
    ldonotdeliverbeforedate := to_date(in_donotdeliverbeforedate,'MMDDYYYY');
  end if;
  
  begin
  update orderhdr
     set hdrpassthruchar01 = in_hdrpassthruchar01,
         hdrpassthruchar02 = in_hdrpassthruchar02,
         hdrpassthruchar03 = in_hdrpassthruchar03,
         hdrpassthruchar04 = in_hdrpassthruchar04,
         hdrpassthruchar05 = in_hdrpassthruchar05,
         hdrpassthruchar06 = in_hdrpassthruchar06,
         hdrpassthruchar07 = in_hdrpassthruchar07,
         hdrpassthruchar08 = in_hdrpassthruchar08,
         hdrpassthruchar09 = in_hdrpassthruchar09,
         hdrpassthruchar10 = in_hdrpassthruchar10,
         hdrpassthruchar11 = in_hdrpassthruchar11,
         hdrpassthruchar12 = in_hdrpassthruchar12,
         hdrpassthruchar13 = in_hdrpassthruchar13,
         hdrpassthruchar14 = in_hdrpassthruchar14,
         hdrpassthruchar15 = in_hdrpassthruchar15,
         hdrpassthruchar16 = in_hdrpassthruchar16,
         hdrpassthruchar17 = in_hdrpassthruchar17,
         hdrpassthruchar18 = in_hdrpassthruchar18,
         hdrpassthruchar19 = in_hdrpassthruchar19,
         hdrpassthruchar20 = in_hdrpassthruchar20,
         hdrpassthruchar21 = in_hdrpassthruchar21,
         hdrpassthruchar22 = in_hdrpassthruchar22,
         hdrpassthruchar23 = in_hdrpassthruchar23,
         hdrpassthruchar24 = in_hdrpassthruchar24,
         hdrpassthruchar25 = in_hdrpassthruchar25,
         hdrpassthruchar26 = in_hdrpassthruchar26,
         hdrpassthruchar27 = in_hdrpassthruchar27,
         hdrpassthruchar28 = in_hdrpassthruchar28,
         hdrpassthruchar29 = in_hdrpassthruchar29,
         hdrpassthruchar30 = in_hdrpassthruchar30,
         hdrpassthruchar31 = in_hdrpassthruchar31,
         hdrpassthruchar32 = in_hdrpassthruchar32,
         hdrpassthruchar33 = in_hdrpassthruchar33,
         hdrpassthruchar34 = in_hdrpassthruchar34,
         hdrpassthruchar35 = in_hdrpassthruchar35,
         hdrpassthruchar36 = in_hdrpassthruchar36,
         hdrpassthruchar37 = in_hdrpassthruchar37,
         hdrpassthruchar38 = in_hdrpassthruchar38,
         hdrpassthruchar39 = in_hdrpassthruchar39,
         hdrpassthruchar40 = in_hdrpassthruchar40,
         hdrpassthruchar41 = in_hdrpassthruchar41,
         hdrpassthruchar42 = in_hdrpassthruchar42,
         hdrpassthruchar43 = in_hdrpassthruchar43,
         hdrpassthruchar44 = in_hdrpassthruchar44,
         hdrpassthruchar45 = in_hdrpassthruchar45,
         hdrpassthruchar46 = in_hdrpassthruchar46,
         hdrpassthruchar47 = in_hdrpassthruchar47,
         hdrpassthruchar48 = in_hdrpassthruchar48,
         hdrpassthruchar49 = in_hdrpassthruchar49,
         hdrpassthruchar50 = in_hdrpassthruchar50,
         hdrpassthruchar51 = in_hdrpassthruchar51,
         hdrpassthruchar52 = in_hdrpassthruchar52,
         hdrpassthruchar53 = in_hdrpassthruchar53,
         hdrpassthruchar54 = in_hdrpassthruchar54,
         hdrpassthruchar55 = in_hdrpassthruchar55,
         hdrpassthruchar56 = in_hdrpassthruchar56,
         hdrpassthruchar57 = in_hdrpassthruchar57,
         hdrpassthruchar58 = in_hdrpassthruchar58,
         hdrpassthruchar59 = in_hdrpassthruchar59,
         hdrpassthruchar60 = in_hdrpassthruchar60,
         hdrpassthrudate01 = lhdrpassthrudate01,
         hdrpassthrudate02 = lhdrpassthrudate02,
         hdrpassthrudate03 = lhdrpassthrudate03,
         hdrpassthrudate04 = lhdrpassthrudate04,
         hdrpassthrudoll01 = lhdrpassthrudoll01,
         hdrpassthrudoll02 = lhdrpassthrudoll02,
         hdrpassthrunum01 = lhdrpassthrunum01,
         hdrpassthrunum02 = lhdrpassthrunum02,
         hdrpassthrunum03 = lhdrpassthrunum03,
         hdrpassthrunum04 = lhdrpassthrunum04,
         hdrpassthrunum05 = lhdrpassthrunum05,
         hdrpassthrunum06 = lhdrpassthrunum06,
         hdrpassthrunum07 = lhdrpassthrunum07,
         hdrpassthrunum08 = lhdrpassthrunum08,
         hdrpassthrunum09 = lhdrpassthrunum09,
         hdrpassthrunum10 = lhdrpassthrunum10,
         cancel_after = lcancelafterdate,
         delivery_requested = ldeliveryrequesteddate,
         requested_ship = lrequestedshipdate,
         ship_not_before = lshipnotbeforedate,
         ship_no_later = lshipnolaterdate,
         cancel_if_not_delivered_by = lcancelifnotdeliveredbydate,
         do_not_deliver_after = ldonotdeliverafterdate,
         do_not_deliver_before = ldonotdeliverbeforedate,
         lastuser = in_lastuser,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

  exception WHEN OTHERS THEN        
      return_status := 0;
      return_msg := sqlerrm;      
      rollback to savepoint  orders;
      return;
  end;                    
  
	
	commit;         
  return_status := 1;
  return_msg := 'OK';
  
exception WHEN OTHERS THEN  
  return_status := 0;
  return_msg := sqlerrm;  
  rollback to savepoint  orders;
      
end usp_update_orderhdr_passthrus;  

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
procedure usp_insert_lineitems
(  
   from_facility VARCHAR2,
   order_id NUMBER, 
	ship_id NUMBER,
   cust_id VARCHAR2,
   in_item VARCHAR2,
   qty_order NUMBER,
   qty_entered NUMBER,
   --item_descr String,
   --weight_order NUMBER,
   --cube_order NUMBER,
   lot_number VARCHAR2,
   last_user VARCHAR2,
   item_entered VARCHAR2,
   uom_entered VARCHAR2,
   in_comment1 CLOB,
   in_consigneesku VARCHAR2,   
 return_status OUT NUMBER,
   return_msg OUT VARCHAR2--,
--   return_order_id OUT NUMBER
) is 

/*
  Cursor Declaration 
*/
cursor curCustDetails is
  select baseuom,backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,inventoryclass,recvinvstatus,lotrequired
  from custitemview  where custid = cust_id AND custitemview.item = in_item;
curCust curCustDetails%rowtype;

/*
  Variable Declaration 
*/
priority VARCHAR2(1);
inv_status VARCHAR2(255);
weight_order NUMBER(17,8);
cube_order NUMBER(10,4);
order_type VARCHAR2(1);

begin
    
-- get the customer details
  curCust := null;
  open curCustDetails;
  fetch curCustDetails into curCust;
  close curCustDetails;


-- get the priority, and ordertype
  begin
    select priority,ordertype into priority, order_type from orderhdr where orderid = order_id and shipid = ship_id;       
    exception when others then          
    null;
  end;
  
-- get weight order
  begin
      select zci.item_weight(cust_id, in_item, curCust.baseuom) * qty_entered into weight_order from dual;
  end;  

-- get cube order
  begin
      select zci.item_cube(cust_id, in_item, curCust.baseuom) * qty_entered into cube_order from dual;
  end;  
  
-- clear inventory status and class for inbound
  if (order_type in('R','Q')) then
    curCust.invstatusind := null;
    curCust.invstatus := null;
    curCust.invclassind := null;
    curCust.inventoryclass := null;
  end if;
  
  insert into orderdtl(fromfacility,orderid,shipid,custid,item,lotnumber,qtyorder,qtyentered,uom, --itemdescr,
                     linestatus,weightorder,cubeorder,priority,lastuser,lastupdate,itementered,uomentered,amtorder,
                     backorder,allowsub,qtytype,invstatusind,invstatus, invclassind,inventoryclass, statususer, 
                     statusupdate, rfautodisplay,comment1,consigneesku) 
  values(upper(from_facility), order_id, ship_id, cust_id, in_item, upper(lot_number), qty_order, qty_entered, curCust.baseuom, --item_descr,
              'A', weight_order, cube_order, priority, last_user, sysdate, item_entered, uom_entered,0,
              curCust.backorder, curCust.allowsub, curCust.qtytype, curCust.invstatusind, curCust.invstatus, curCust.invclassind, curCust.inventoryclass, last_user,
               sysdate, 'N',in_comment1,in_consigneesku);              

  return_status := 1;
  return_msg := 'OKAY';
  --return_order_id := order_id;
  
exception when others then
  return_status := 0;
  return_msg := sqlerrm;
  --return_order_id := order_id;
  
end usp_insert_lineitems;

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
procedure usp_update_orderdtl
(  
   order_id NUMBER, 
   ship_id NUMBER,
   cust_id VARCHAR2,
   in_item VARCHAR2,
   qty_order NUMBER,
   qty_entered NUMBER,
   lot_number VARCHAR2,
   last_user VARCHAR2,
   uom_entered VARCHAR2,
   in_comment1 CLOB,
   in_consigneesku VARCHAR2,   
   return_status OUT NUMBER,
   return_msg OUT VARCHAR2--,
) is 

/*
  Variable Declaration 
*/
uom VARCHAR2(4);
weight_order NUMBER(17,8);
cube_order NUMBER(10,4);

begin
    
-- check for the base uom  
  
  begin
      select baseuom into uom
		from custitemview 
	where custid = cust_id and custitemview.item = in_item;
     
	 exception when others then
        null;      
  end; 

-- get weight order
  begin
      select zci.item_weight(cust_id, in_item, uom) * qty_entered into weight_order from dual;
  end;  

-- get weight order
  begin
      select zci.item_cube(cust_id, in_item, uom) * qty_entered into cube_order from dual;
  end;  
  
  update orderdtl
    set qtyorder = qty_order,
        qtyentered = qty_entered,
        uom = uom,
        weightorder = weight_order,
        cubeorder = cube_order,
        lastuser = last_user,
        lastupdate = sysdate,
        uomentered = uom_entered,
        comment1 = in_comment1,
        consigneesku = in_consigneesku
  where orderid = order_id
    and ship_id = ship_id
    and item = in_item
    and nvl(lotnumber,'(none)') = nvl(lot_number,'(none)');

  return_status := 1;
  return_msg := 'OKAY';
  
exception when others then
  return_status := 0;
  return_msg := sqlerrm;
end usp_update_orderdtl;

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
procedure usp_update_orderdtl_passthrus
(  in_orderid NUMBER,
   in_shipid NUMBER,
   in_item VARCHAR2,   
   in_lotnumber VARCHAR2,
   in_dtlpassthruchar01 VARCHAR2,
   in_dtlpassthruchar02 VARCHAR2,
   in_dtlpassthruchar03 VARCHAR2,
   in_dtlpassthruchar04 VARCHAR2,
   in_dtlpassthruchar05 VARCHAR2,
   in_dtlpassthruchar06 VARCHAR2,
   in_dtlpassthruchar07 VARCHAR2,
   in_dtlpassthruchar08 VARCHAR2,
   in_dtlpassthruchar09 VARCHAR2,
   in_dtlpassthruchar10 VARCHAR2,
   in_dtlpassthruchar11 VARCHAR2,
   in_dtlpassthruchar12 VARCHAR2,
   in_dtlpassthruchar13 VARCHAR2,
   in_dtlpassthruchar14 VARCHAR2,
   in_dtlpassthruchar15 VARCHAR2,
   in_dtlpassthruchar16 VARCHAR2,
   in_dtlpassthruchar17 VARCHAR2,
   in_dtlpassthruchar18 VARCHAR2,
   in_dtlpassthruchar19 VARCHAR2,
   in_dtlpassthruchar20 VARCHAR2,
   in_dtlpassthruchar21 VARCHAR2,
   in_dtlpassthruchar22 VARCHAR2,
   in_dtlpassthruchar23 VARCHAR2,
   in_dtlpassthruchar24 VARCHAR2,
   in_dtlpassthruchar25 VARCHAR2,
   in_dtlpassthruchar26 VARCHAR2,
   in_dtlpassthruchar27 VARCHAR2,
   in_dtlpassthruchar28 VARCHAR2,
   in_dtlpassthruchar29 VARCHAR2,
   in_dtlpassthruchar30 VARCHAR2,
   in_dtlpassthruchar31 VARCHAR2,
   in_dtlpassthruchar32 VARCHAR2,
   in_dtlpassthruchar33 VARCHAR2,
   in_dtlpassthruchar34 VARCHAR2,
   in_dtlpassthruchar35 VARCHAR2,
   in_dtlpassthruchar36 VARCHAR2,
   in_dtlpassthruchar37 VARCHAR2,
   in_dtlpassthruchar38 VARCHAR2,
   in_dtlpassthruchar39 VARCHAR2,
   in_dtlpassthruchar40 VARCHAR2,
   in_dtlpassthrudate01 VARCHAR2,
   in_dtlpassthrudate02 VARCHAR2,
   in_dtlpassthrudate03 VARCHAR2,
   in_dtlpassthrudate04 VARCHAR2,
   in_dtlpassthrudoll01 VARCHAR2,
   in_dtlpassthrudoll02 VARCHAR2,
   in_dtlpassthrunum01 VARCHAR2,
   in_dtlpassthrunum02 VARCHAR2,
   in_dtlpassthrunum03 VARCHAR2,
   in_dtlpassthrunum04 VARCHAR2,
   in_dtlpassthrunum05 VARCHAR2,
   in_dtlpassthrunum06 VARCHAR2,
   in_dtlpassthrunum07 VARCHAR2,
   in_dtlpassthrunum08 VARCHAR2,
   in_dtlpassthrunum09 VARCHAR2,
   in_dtlpassthrunum10 VARCHAR2,
   in_dtlpassthrunum11 VARCHAR2,
   in_dtlpassthrunum12 VARCHAR2,
   in_dtlpassthrunum13 VARCHAR2,
   in_dtlpassthrunum14 VARCHAR2,
   in_dtlpassthrunum15 VARCHAR2,
   in_dtlpassthrunum16 VARCHAR2,
   in_dtlpassthrunum17 VARCHAR2,
   in_dtlpassthrunum18 VARCHAR2,
   in_dtlpassthrunum19 VARCHAR2,
   in_dtlpassthrunum20 VARCHAR2,
   in_lastuser VARCHAR2,
   return_status OUT NUMBER,
   return_msg OUT VARCHAR2
) is

  ldtlpassthrudate01 DATE;
  ldtlpassthrudate02 DATE;
  ldtlpassthrudate03 DATE;
  ldtlpassthrudate04 DATE;
  ldtlpassthrudoll01 NUMBER;
  ldtlpassthrudoll02 NUMBER;
  ldtlpassthrunum01 NUMBER;
  ldtlpassthrunum02 NUMBER;
  ldtlpassthrunum03 NUMBER;
  ldtlpassthrunum04 NUMBER;
  ldtlpassthrunum05 NUMBER;
  ldtlpassthrunum06 NUMBER;
  ldtlpassthrunum07 NUMBER;
  ldtlpassthrunum08 NUMBER;
  ldtlpassthrunum09 NUMBER;
  ldtlpassthrunum10 NUMBER;
  ldtlpassthrunum11 NUMBER;
  ldtlpassthrunum12 NUMBER;
  ldtlpassthrunum13 NUMBER;
  ldtlpassthrunum14 NUMBER;
  ldtlpassthrunum15 NUMBER;
  ldtlpassthrunum16 NUMBER;
  ldtlpassthrunum17 NUMBER;
  ldtlpassthrunum18 NUMBER;
  ldtlpassthrunum19 NUMBER;
  ldtlpassthrunum20 NUMBER;

begin
  savepoint orders;
  
  if in_dtlpassthrudate01 is not null then
    ldtlpassthrudate01 := to_date(in_dtlpassthrudate01,'MMDDYYYY');
  end if;
  if in_dtlpassthrudate02 is not null then
    ldtlpassthrudate02 := to_date(in_dtlpassthrudate02,'MMDDYYYY');
  end if;
  if in_dtlpassthrudate03 is not null then
    ldtlpassthrudate03 := to_date(in_dtlpassthrudate03,'MMDDYYYY');
  end if;
  if in_dtlpassthrudate04 is not null then
    ldtlpassthrudate04 := to_date(in_dtlpassthrudate04,'MMDDYYYY');
  end if;
  if in_dtlpassthrudoll01 is not null then
    ldtlpassthrudoll01 := to_number(in_dtlpassthrudoll01,'99999999.99');
  end if;
  if in_dtlpassthrudoll02 is not null then
    ldtlpassthrudoll02 := to_number(in_dtlpassthrudoll02,'99999999.99');
  end if;
  if in_dtlpassthrunum01 is not null then
    ldtlpassthrunum01 := to_number(in_dtlpassthrunum01,'999999999999.9999');
  end if;
  if in_dtlpassthrunum02 is not null then
    ldtlpassthrunum02 := to_number(in_dtlpassthrunum02,'999999999999.9999');
  end if;
  if in_dtlpassthrunum03 is not null then
    ldtlpassthrunum03 := to_number(in_dtlpassthrunum03,'999999999999.9999');
  end if;
  if in_dtlpassthrunum04 is not null then
    ldtlpassthrunum04 := to_number(in_dtlpassthrunum04,'999999999999.9999');
  end if;
  if in_dtlpassthrunum05 is not null then
    ldtlpassthrunum05 := to_number(in_dtlpassthrunum05,'999999999999.9999');
  end if;
  if in_dtlpassthrunum06 is not null then
    ldtlpassthrunum06 := to_number(in_dtlpassthrunum06,'999999999999.9999');
  end if;
  if in_dtlpassthrunum07 is not null then
    ldtlpassthrunum07 := to_number(in_dtlpassthrunum07,'999999999999.9999');
  end if;
  if in_dtlpassthrunum08 is not null then
    ldtlpassthrunum08 := to_number(in_dtlpassthrunum08,'999999999999.9999');
  end if;
  if in_dtlpassthrunum09 is not null then
    ldtlpassthrunum09 := to_number(in_dtlpassthrunum09,'999999999999.9999');
  end if;
  if in_dtlpassthrunum10 is not null then
    ldtlpassthrunum10 := to_number(in_dtlpassthrunum10,'999999999999.9999');
  end if;
  if in_dtlpassthrunum11 is not null then
    ldtlpassthrunum11 := to_number(in_dtlpassthrunum11,'999999999999.9999');
  end if;
  if in_dtlpassthrunum12 is not null then
    ldtlpassthrunum12 := to_number(in_dtlpassthrunum12,'999999999999.9999');
  end if;
  if in_dtlpassthrunum13 is not null then
    ldtlpassthrunum13 := to_number(in_dtlpassthrunum13,'999999999999.9999');
  end if;
  if in_dtlpassthrunum14 is not null then
    ldtlpassthrunum14 := to_number(in_dtlpassthrunum14,'999999999999.9999');
  end if;
  if in_dtlpassthrunum15 is not null then
    ldtlpassthrunum15 := to_number(in_dtlpassthrunum15,'999999999999.9999');
  end if;
  if in_dtlpassthrunum16 is not null then
    ldtlpassthrunum16 := to_number(in_dtlpassthrunum16,'999999999999.9999');
  end if;
  if in_dtlpassthrunum17 is not null then
    ldtlpassthrunum17 := to_number(in_dtlpassthrunum17,'999999999999.9999');
  end if;
  if in_dtlpassthrunum18 is not null then
    ldtlpassthrunum18 := to_number(in_dtlpassthrunum18,'999999999999.9999');
  end if;
  if in_dtlpassthrunum19 is not null then
    ldtlpassthrunum19 := to_number(in_dtlpassthrunum19,'999999999999.9999');
  end if;
  if in_dtlpassthrunum20 is not null then
    ldtlpassthrunum20 := to_number(in_dtlpassthrunum20,'999999999999.9999');
  end if;
  
  begin
  update orderdtl
     set dtlpassthruchar01 = in_dtlpassthruchar01,
         dtlpassthruchar02 = in_dtlpassthruchar02,
         dtlpassthruchar03 = in_dtlpassthruchar03,
         dtlpassthruchar04 = in_dtlpassthruchar04,
         dtlpassthruchar05 = in_dtlpassthruchar05,
         dtlpassthruchar06 = in_dtlpassthruchar06,
         dtlpassthruchar07 = in_dtlpassthruchar07,
         dtlpassthruchar08 = in_dtlpassthruchar08,
         dtlpassthruchar09 = in_dtlpassthruchar09,
         dtlpassthruchar10 = in_dtlpassthruchar10,
         dtlpassthruchar11 = in_dtlpassthruchar11,
         dtlpassthruchar12 = in_dtlpassthruchar12,
         dtlpassthruchar13 = in_dtlpassthruchar13,
         dtlpassthruchar14 = in_dtlpassthruchar14,
         dtlpassthruchar15 = in_dtlpassthruchar15,
         dtlpassthruchar16 = in_dtlpassthruchar16,
         dtlpassthruchar17 = in_dtlpassthruchar17,
         dtlpassthruchar18 = in_dtlpassthruchar18,
         dtlpassthruchar19 = in_dtlpassthruchar19,
         dtlpassthruchar20 = in_dtlpassthruchar20,
         dtlpassthruchar21 = in_dtlpassthruchar21,
         dtlpassthruchar22 = in_dtlpassthruchar22,
         dtlpassthruchar23 = in_dtlpassthruchar23,
         dtlpassthruchar24 = in_dtlpassthruchar24,
         dtlpassthruchar25 = in_dtlpassthruchar25,
         dtlpassthruchar26 = in_dtlpassthruchar26,
         dtlpassthruchar27 = in_dtlpassthruchar27,
         dtlpassthruchar28 = in_dtlpassthruchar28,
         dtlpassthruchar29 = in_dtlpassthruchar29,
         dtlpassthruchar30 = in_dtlpassthruchar30,
         dtlpassthruchar31 = in_dtlpassthruchar31,
         dtlpassthruchar32 = in_dtlpassthruchar32,
         dtlpassthruchar33 = in_dtlpassthruchar33,
         dtlpassthruchar34 = in_dtlpassthruchar34,
         dtlpassthruchar35 = in_dtlpassthruchar35,
         dtlpassthruchar36 = in_dtlpassthruchar36,
         dtlpassthruchar37 = in_dtlpassthruchar37,
         dtlpassthruchar38 = in_dtlpassthruchar38,
         dtlpassthruchar39 = in_dtlpassthruchar39,
         dtlpassthruchar40 = in_dtlpassthruchar40,
         dtlpassthrudate01 = ldtlpassthrudate01,
         dtlpassthrudate02 = ldtlpassthrudate02,
         dtlpassthrudate03 = ldtlpassthrudate03,
         dtlpassthrudate04 = ldtlpassthrudate04,
         dtlpassthrudoll01 = ldtlpassthrudoll01,
         dtlpassthrudoll02 = ldtlpassthrudoll02,
         dtlpassthrunum01 = ldtlpassthrunum01,
         dtlpassthrunum02 = ldtlpassthrunum02,
         dtlpassthrunum03 = ldtlpassthrunum03,
         dtlpassthrunum04 = ldtlpassthrunum04,
         dtlpassthrunum05 = ldtlpassthrunum05,
         dtlpassthrunum06 = ldtlpassthrunum06,
         dtlpassthrunum07 = ldtlpassthrunum07,
         dtlpassthrunum08 = ldtlpassthrunum08,
         dtlpassthrunum09 = ldtlpassthrunum09,
         dtlpassthrunum10 = ldtlpassthrunum10,
         dtlpassthrunum11 = ldtlpassthrunum11,
         dtlpassthrunum12 = ldtlpassthrunum12,
         dtlpassthrunum13 = ldtlpassthrunum13,
         dtlpassthrunum14 = ldtlpassthrunum14,
         dtlpassthrunum15 = ldtlpassthrunum15,
         dtlpassthrunum16 = ldtlpassthrunum16,
         dtlpassthrunum17 = ldtlpassthrunum17,
         dtlpassthrunum18 = ldtlpassthrunum18,
         dtlpassthrunum19 = ldtlpassthrunum19,
         dtlpassthrunum20 = ldtlpassthrunum20,
         lastuser = in_lastuser,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)')=nvl(in_lotnumber,'(none)');

  exception WHEN OTHERS THEN        
      return_status := 0;
      return_msg := sqlerrm;      
      rollback to savepoint  orders;
      return;
  end;                    
  
	
	commit;         
  return_status := 1;
  return_msg := 'OK';
  
exception WHEN OTHERS THEN  
  return_status := 0;
  return_msg := sqlerrm;  
  rollback to savepoint  orders;
      
end usp_update_orderdtl_passthrus;  

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
procedure usp_delete_lineitems
(     
   order_id NUMBER, 
   ship_id NUMBER,
   item VARCHAR2,
   return_status OUT NUMBER,
   return_msg OUT VARCHAR2
) is 

item_id VARCHAR2(20);
order_no NUMBER;

begin
  item_id := item;
  order_no :=order_id;
  
  delete orderdtl where orderid = order_no and shipid = ship_id and item = item_id;  
  return_status := 1;
  return_msg := 'OKAY';
  
  exception when others then
    return_status := 0;
    return_msg := sqlerrm;
end usp_delete_lineitems;

function item_alias
(  in_custid varchar2,
	in_item varchar2
) return varchar2 is

 cursor curCustItemAlias is
 	select itemalias 
		from custitemalias
			where custid = in_custid and
					item	 = in_item;
alias curCustItemAlias%rowtype;
   theAlias varchar2(500);
	cnt number;

	begin
	    cnt := 0;
		 theAlias := null; 
       open curCustItemAlias;
		 loop
		 	fetch curCustITemAlias into alias;
			if curCustItemAlias%notfound then
				close curCustItemAlias;
				return theAlias;
		   end if;
			if cnt > 0 then
				theAlias := theAlias || ', ';
		   end if;
			if alias.itemalias is not null then
				theAlias := theAlias || alias.itemalias;
				cnt := cnt + 1;
			end if;
			 

		 end loop;
      
		exception when others then
			if curCustItemAlias%isopen then
				close curCustItemAlias;
			end if;
			return theAlias;

	end item_alias;




end pkg_manage_orders;
/
exit;
