create or replace package body alps.zmanifestq as
--
-- $Id$
--
----------------------------------------------------------------------
--
-- send_shipping_msg
--
----------------------------------------------------------------------
PROCEDURE send_shipping_msg
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_printer   IN      varchar2,
    in_report    IN      varchar2,
    in_cartonid  IN      varchar2,
    in_email_addresses  IN      varchar2,
    out_errmsg   IN OUT     varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   l_status integer;
   l_qmsg qmsg := qmsg(null, null);
   strMsg varchar2(255);
   l_cartonid shippingplate.lpid%type;
   
BEGIN

    out_errmsg := 'OKAY';

   l_qmsg.trans := 'MSG';
   if in_cartonid is null then
     l_cartonid := 'ORDER';
   else
     l_cartonid := in_cartonid;
   end if;
   l_qmsg.message := in_orderid || chr(9) ||
                     in_shipid || chr(9) ||
                     in_printer || chr(9) ||
                     in_report || chr(9) ||
                     in_cartonid || chr(9) ||
                     in_email_addresses || chr(9);

   l_status := zqm.send(SHIPPER_DEFAULT_QUEUE,l_qmsg.trans,l_qmsg.message,1,null);

   commit;

   if l_status != 1 then
     out_errmsg := 'Shipper send error ' || to_char(l_status);
     zms.log_autonomous_msg('SHIPPER', null, null,
        out_errmsg,'E', 'SHIPPER', strMsg);
   end if;

exception when others then
  out_errmsg := 'zamsem:'||sqlerrm;
  zms.log_autonomous_msg('SHIPPER', null, null,
        out_errmsg,'E', 'SHIPPER', strMsg);
  rollback;
END send_shipping_msg;


----------------------------------------------------------------------
--
-- recv_shipping_msg
--
----------------------------------------------------------------------
PROCEDURE recv_shipping_msg
(
    out_orderid  OUT      number,
    out_shipid   OUT      number,
    out_printer  OUT      varchar2,
    out_report   OUT      varchar2,
    out_cartonid OUT      varchar2,
    out_email_addresses OUT varchar2,
    out_errmsg   OUT      varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   l_status integer;
   l_qmsg qmsg := qmsg(null, null);
   strMsg varchar2(255);

BEGIN

    out_errmsg := 'OKAY';

    out_orderid := 0;
    out_shipid := 0;
    out_printer := '';
    out_report := '';

    l_status := zqm.receive(SHIPPER_DEFAULT_QUEUE,l_qmsg.message,30);

    commit;

    if l_status = -1 then -- TIMEOUT
        out_errmsg := 'OKAY--Receive timed out';
        return;
    end if;

    if l_status <> 1 then
      out_errmsg := 'Shipper bad receive status: ' || to_char(l_status);
      zms.log_autonomous_msg('SHIPPER', null, null,
        out_errmsg, 'E', 'SHIPPER', strMsg);
      return;
    end if;

    out_orderid := nvl(zqm.get_field(l_qmsg.message,1),0);
    out_shipid := nvl(zqm.get_field(l_qmsg.message,2),0);
    out_printer := nvl(zqm.get_field(l_qmsg.message,3),'(none)');
    out_report := nvl(zqm.get_field(l_qmsg.message,4),'(none)');
    out_cartonid := nvl(zqm.get_field(l_qmsg.message,5),'(none)');
    out_email_addresses := nvl(zqm.get_field(l_qmsg.message,6),'(none)');

exception when others then

   zms.log_autonomous_msg('SHIPPER', null, null, sqlerrm,'E', 'SHIPPER', strMsg);
   out_errmsg := substr(sqlerrm,1,80);
   rollback;

END recv_shipping_msg;

end zmanifestq;
/
show error package body zmanifestq;

exit;
