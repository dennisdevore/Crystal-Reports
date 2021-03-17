create or replace trigger multiship_charges_bi
--
-- $Id:
--
before insert
on multiship_charges
for each row
declare
cursor C_MSD(in_cartonid varchar2)
IS
    select *
      from multishipdtl
     where cartonid = in_cartonid;

MSD multishipdtl%rowtype;

cursor C_SP(in_trackid varchar2)
IS
   select lpid, fromlpid
     from shippingplate
    where trackingno = in_trackid
      and parentlpid is null;

SP C_SP%rowtype;

cursor C_ORD(in_orderid number, in_shipid number)
is
    select *
      from orderhdr
     where orderid = in_orderid
       and shipid = in_shipid;

ORD orderhdr%rowtype;

cnt integer;
tot_charge number(7,2);
l_invoice invoicehdr.invoice%type;
l_charge_cmt varchar2(1000);

errno number;
errmsg varchar2(255);

begin

-- Locate multishipdtl based on cartonid or trackno
    if :new.cartonid is not null then
        MSD := null;
        OPEN C_MSD(:new.cartonid);
        FETCH C_MSD into MSD;
        CLOSE C_MSD;

        if MSD.cartonid is null then
            raise_application_error(-20001, 'Invalid cartonid');
        end if;                            
    elsif :new.trackid is not null then
        SP := null;
        OPEN C_SP(:new.trackid);
        FETCH C_SP into SP;
        CLOSE C_SP;

        MSD := null;
        OPEN C_MSD(SP.fromlpid);
        FETCH C_MSD into MSD;
        CLOSE C_MSD;

        if MSD.cartonid is null then
            raise_application_error(-20002, 'Invalid trackid');
        end if;                            

    else
        raise_application_error(-20003, 'Must provide cartonid or trackid');
    end if;

-- Locate Order
    ORD := null;
    OPEN C_ORD(MSD.orderid, MSD.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        raise_application_error(-20004,'Could not locate order:'
                ||MSD.orderid||'/'||MSD.shipid);
    end if;

-- Validate shipping charge activity
    cnt := 0;
    select count(1)
      into cnt
      from activity
     where code = :new.shipcharge_activity;

    if nvl(cnt,0) = 0 then
        raise_application_error(-20005,
            'Invalid activity for charge:'||:new.shipcharge_activity);
    end if;

-- Insert charges into multiship_charges table
    :new.orderid := MSD.orderid;
    :new.shipid := MSD.shipid;
    :new.trackid := MSD.trackid;
    :new.cartonid := MSD.cartonid;
    :new.lastupdate := sysdate;

-- Update multishipdtl and shippingplate with total charges
    tot_charge :=
        nvl(:new.published_rate,0)
        - nvl(:new.discount,0)
        + nvl(:new.residential_das,0)
        + nvl(:new.transport,0)
        + nvl(:new.other,0)
        + nvl(:new.fsc,0)
        + nvl(:new.manifest,0);

    l_charge_cmt := 
           'Track ID: '||MSD.trackid||chr(13)||chr(10)||
           'Pub Rt'||chr(9)||'Dis   '||chr(9)
            ||'Res/OAS'||chr(9)||'Trans'||chr(9)||'Other'||chr(9)||'FSC  '
            ||chr(9)||'Manifest'
        ||chr(13)||chr(10)
        ||'$'|| ltrim(to_char(nvl(:new.published_rate,0),'9990.99'))||chr(9)
        ||'$-'|| ltrim(to_char(nvl(:new.discount,0),'9990.99'))||chr(9)
        ||'$'|| ltrim(to_char(nvl(:new.residential_das,0),'9990.99'))||chr(9)
        ||'$'|| ltrim(to_char(nvl(:new.transport,0),'9990.99'))||chr(9)
        ||'$'|| ltrim(to_char(nvl(:new.other,0),'9990.99'))||chr(9)
        ||'$'|| ltrim(to_char(nvl(:new.fsc,0),'9990.99'))||chr(9)
        ||'$'|| ltrim(to_char(nvl(:new.manifest,0),'9990.99'));

    update multishipdtl
       set cost = tot_charge
     where cartonid = MSD.cartonid;

    update shippingplate
       set shippingcost = tot_charge
     where trackingno = MSD.trackid;

-- Locate current accessorial invoicehdr record
    zba.locate_accessorial_invoice(ORD.custid, ORD.fromfacility,
        'IMPCHARGES', l_invoice, errno, errmsg);

    if (errno != 0) then
        raise_application_error(-20006, errmsg);
    end if;

-- Create shipping charges for order, carton with detail note information
    INSERT INTO invoicedtl
    (
        billstatus,
        facility,
        custid,
        orderid,
        item,
        lotnumber,
        activity,
        activitydate,
        billmethod,
        enteredqty,
        entereduom,
        enteredweight,
        enteredrate,
        enteredamt,
        loadno,
        invoice,
        invtype,
        invdate,
        statusrsn,
        shipid,
        orderitem,
        orderlot,
        lastuser,
        lastupdate,
        comment1,
        businessevent
    )
    values
    (
        zbill.UNCHARGED,
        ORD.fromfacility,
        ORD.custid,
        ORD.orderid,
        '',
        '',
        :new.shipcharge_activity,
        sysdate,
        'FLAT',
        1,
        '',
        null,
        tot_charge,
        tot_charge,
        ORD.loadno,
        l_invoice,
        'A',
        sysdate,
        '',
        ORD.shipid,
        '',
        '',
        'IMPCHARGES',
        sysdate,
        l_charge_cmt,
        zbill.EV_MULTISHIP
        );


    zba.calc_accessorial_invoice(l_invoice, errno, errmsg);



end;
/

show error trigger multiship_charges_bi;
exit;
