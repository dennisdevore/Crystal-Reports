create or replace PACKAGE BODY alps.barrett
IS


PROCEDURE process_load_order
(
    in_data    IN OUT cdata,
    in_custlist IN varchar2
)
IS

CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

ORD orderhdr%rowtype;

l_carr orderhdr.carrier%type;
l_shiptype orderhdr.shiptype%type;
l_delv  orderhdr.deliveryservice%type;

BEGIN
    in_data.out_no := 0;
    in_data.out_char := '';

    ORD := null;
    
    OPEN C_ORD(in_data.orderid, in_data.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        return;
    end if;

  -- Verify this is one of the customers to handle this
    if instr(','||in_custlist||',', ORD.custid) = 0 then
        return;
    end if;

    if nvl(instr(upper(ORD.shiptoname),'MICHAEL'),0) = 0 then
        return;
    end if;

    l_carr := 'FEDX';
    l_shiptype := 'S';
    l_delv := 'GRND';

    if ORD.weightorder > 250
    or ORD.qtyorder > 19 then
        l_carr := 'CPU';
        l_shiptype := 'L';
        l_delv := '';

    end if;

    update orderhdr
       set carrier = l_carr,
           shiptype = l_shiptype,
           deliveryservice = l_delv
    where orderid = ORD.orderid
      and shipid = ORD.shipid;


EXCEPTION WHEN OTHERS THEN
    in_data.out_no := sqlcode;
    in_data.out_char := substr(sqlerrm,1,80);
END process_load_order;



end barrett;
/

--exit;