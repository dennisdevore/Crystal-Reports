create or replace package body alps.zursa as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--

-- for 8i
-- select sys_context('USERENV','SESSIONID') from dual
--
-- for 8-0
-- SELECT distinct sid
--   FROM v$mystat;
CURSOR C_SID
IS
 SELECT sys_context('USERENV','SESSIONID')
   FROM dual;

CURSOR C_DFLT(in_id varchar2)
IS
  SELECT substr(defaultvalue,1,10)
    FROM systemdefaults
   WHERE defaultid = in_id;



--
-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- check_address
--
----------------------------------------------------------------------
PROCEDURE check_address
(
    in_userid       IN  varchar2,
    in_city         IN  varchar2,
    in_state        IN  varchar2,
    in_postalcode   IN  varchar2,
    in_service      IN  varchar2,
    in_special      IN  varchar2,
    out_errmsg      OUT varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   queuename varchar2(32) := 'URSA';
   status number;

   sid number;

uv  varchar2(20);  -- UrsaValidation
l_msg varchar2(2000);

BEGIN
   out_errmsg := 'OKAY';

    uv := null;
    OPEN C_DFLT('URSAVALIDATION');
    FETCH C_DFLT into uv;
    CLOSE C_DFLT;

    if nvl(uv,'OFF') != 'ON' then
       return;
    end if;

   sid := null;
   OPEN C_SID;
   FETCH C_SID into sid;
   CLOSE C_SID;

   queuename := queuename || to_char(nvl(sid,0));

   l_msg := in_userid || chr(9) ||
            in_city || chr(9) ||
            in_state || chr(9) ||
            in_postalcode || chr(9) ||
            in_service || chr(9) ||
            in_special || chr(9) ||
            queuename || chr(9);

   status := zqm.send(URSA_DEFAULT_QUEUE,'MSG',l_msg,1,'URSA');
   commit;

   if (status != 1) then
      out_errmsg := 'Send error ' || status;
   else
      if in_userid != 'QUIT' then
         zur.ursa_response(queuename, out_errmsg);
      end if;
   end if;

EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
      rollback;
END check_address ;




----------------------------------------------------------------------
--
-- check_order_address
--
----------------------------------------------------------------------
PROCEDURE check_order_address
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    in_userid       IN  varchar2,
    out_errmsg      OUT varchar2
)
IS


  CURSOR C_ORDHDR(in_orderid number, in_shipid number)
  IS
    SELECT OH.orderid,
           OH.carrier carrier,
           decode(OH.shiptoname,null,CN.name,OH.shiptoname) name,
           decode(OH.shiptoname,null,CN.addr1,OH.shiptoaddr1) addr1,
           decode(OH.shiptoname,null,CN.addr2,OH.shiptoaddr2) addr2,
           decode(OH.shiptoname,null,CN.city,OH.shiptocity) city,
           decode(OH.shiptoname,null,CN.state,OH.shiptostate) state,
           decode(OH.shiptoname,null,CN.postalcode,OH.shiptopostalcode)
                                                               postalcode,
           decode(OH.shiptoname,null,CN.countrycode,OH.shiptocountrycode)
                                                               countrycode,
           decode(OH.shiptoname,null,CN.phone,OH.shiptophone) phone,
           OH.deliveryservice,
           OH.saturdaydelivery,
           OH.specialservice1,
           OH.specialservice2,
           OH.specialservice3,
           OH.specialservice4
      FROM orderhdr OH, consignee CN
     WHERE OH.orderid = in_orderid
       AND OH.shipid = in_shipid
       AND OH.consignee = CN.consignee(+);

  ORD C_ORDHDR%rowtype;

cursor curMultiShipCode(in_carrier in varchar2, in_servicecode in varchar2) is
  select multishipcode
    from carrierservicecodes
   where carrier = in_carrier
     and servicecode = in_servicecode;

cursor curSpecialService(in_carrier in varchar2, in_servicecode in varchar2,
  in_specialservice varchar2) is
    select multishipcode
      from carrierspecialservice
     where carrier = in_carrier
       and servicecode = in_servicecode
       and specialservice = in_specialservice;

spec_service varchar2(16) := 'NNNNNNNNNNNNNNNN';


BEGIN
    out_errmsg := 'OKAY';

    ORD := null;

    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

    if ORD.orderid is null then
       out_errmsg := 'Invalid order';
       return;
    end if;

/*
    if ORD.carrier != 'FEDX' then
       out_errmsg := 'OKAY';
       return;
    end if;
*/

    if ORD.saturdaydelivery = 'Y' then
       spec_service := substr(spec_service,1,6 - 1) || 'Y'||
                       substr(spec_service,6+1);

    end if;


    check_address(in_userid, ORD.city, ORD.state, ORD.postalcode,
                             '7', '',
                             out_errmsg);


EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
END check_order_address ;


----------------------------------------------------------------------
--
-- clear_ursa_response
--
----------------------------------------------------------------------
PROCEDURE clear_ursa_response
(
    out_errmsg      OUT varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   queuename varchar2(30) := 'URSA';
   sid number;

   recvstatus integer;
   trans varchar2(20);
   msg varchar2(1000);
BEGIN
   out_errmsg := 'OKAY';

   sid := null;
   OPEN C_SID;
   FETCH C_SID into sid;
   CLOSE C_SID;

   queuename := queuename || to_char(nvl(sid,0));


   loop
     recvstatus := zqm.receive(ztm.USER_DEFAULT_QUEUE,queuename,
                               10,zqm.DQ_REMOVE, trans, msg);
     commit;
     if recvstatus = -1 then   -- timeout
        out_errmsg := 'OKAY';
        exit;
     elsif recvstatus != 1 then
        out_errmsg := 'Recv error ' || recvstatus;
        exit;
     else
        out_errmsg := nvl(zqm.get_field(msg,1),'(none)');
     end if;
   end loop;

EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
      rollback;
END clear_ursa_response;



----------------------------------------------------------------------
--
-- ursa_response
--
----------------------------------------------------------------------
PROCEDURE ursa_response
(
    in_queue        IN  varchar2,
    out_errmsg      OUT varchar2
)
IS  PRAGMA AUTONOMOUS_TRANSACTION;
   recvstatus integer;
   trans varchar2(20);
   msg varchar2(1000);
BEGIN
   out_errmsg := 'OKAY';

   recvstatus := zqm.receive(ztm.USER_DEFAULT_QUEUE,in_queue,
                             10,zqm.DQ_REMOVE, trans, msg);
   commit;
   if recvstatus = -1 then   -- timeout
      out_errmsg := 'OKAY';
   elsif recvstatus != 1 then
      out_errmsg := 'Recv error ' || recvstatus;
   else
      out_errmsg := nvl(zqm.get_field(msg,1),'(none)');
   end if;


EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
      rollback;
END ursa_response;

----------------------------------------------------------------------
--
-- send_response
--
----------------------------------------------------------------------
PROCEDURE send_response
(
    in_queue        IN  varchar2,
    in_msg          IN  varchar2,
    out_errmsg      OUT varchar2
)
IS  PRAGMA AUTONOMOUS_TRANSACTION;
   status integer;
   l_msg varchar2(2000);
BEGIN

   out_errmsg := 'OKAY';

   l_msg := in_msg || chr(9);

   status := zqm.send(ztm.USER_DEFAULT_QUEUE,'MSG',l_msg,1,in_queue);
   commit;

   if (status != 1) then
      out_errmsg := 'Send error ' || status;
   end if;

EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
      rollback;
END send_response;


----------------------------------------------------------------------
--
-- get_request
--
----------------------------------------------------------------------
PROCEDURE get_request
(
    out_userid      OUT varchar2,
    out_city        OUT varchar2,
    out_state       OUT varchar2,
    out_postalcode  OUT varchar2,
    out_service     OUT varchar2,
    out_special     OUT varchar2,
    out_queue       OUT varchar2,
    out_errmsg      OUT varchar2
)
IS  PRAGMA AUTONOMOUS_TRANSACTION;

   recvstatus integer;
   trans varchar2(20);
   msg varchar2(1000);
BEGIN
   out_errmsg := 'OKAY';

   recvstatus := zqm.receive(URSA_DEFAULT_QUEUE,'URSA',
                             zqm.WT_FOREVER,zqm.DQ_REMOVE, trans, msg);
   commit;
   if recvstatus != 1 then
      out_errmsg := 'Recv error ' || recvstatus;
   else
      out_userid := nvl(zqm.get_field(msg,1),'(none)');
      if (upper(out_userid) != 'QUIT') then
        out_city := nvl(zqm.get_field(msg,2),'(none)');
        out_state := nvl(zqm.get_field(msg,3),'(none)');
        out_postalcode := nvl(zqm.get_field(msg,4),'(none)');
        out_service := nvl(zqm.get_field(msg,5),'(none)');
        out_special := nvl(zqm.get_field(msg,6),'(none)');
        out_queue := nvl(zqm.get_field(msg,7),'(none)');
      end if;
   end if;


EXCEPTION
   when OTHERS then
      out_errmsg := substr(sqlerrm, 1, 80);
      rollback;
END get_request;





end zursa;
/
show errors package zursa;
show errors package body zursa;
exit;
