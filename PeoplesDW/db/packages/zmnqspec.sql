--
-- $Id$
--
create or replace package alps.zmanifestq as

MULTISHIP_DEFAULT_QUEUE      CONSTANT       varchar2(9) := 'multiship';
SHIPPER_DEFAULT_QUEUE      CONSTANT         varchar2(7) := 'shipper';

PROCEDURE send_shipping_msg
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_printer   IN      varchar2,
    in_report    IN      varchar2,
    in_cartonid  IN      varchar2,
    in_email_addresses  IN      varchar2,
    out_errmsg   IN OUT     varchar2
);

PROCEDURE recv_shipping_msg
(
    out_orderid  OUT      number,
    out_shipid   OUT      number,
    out_printer  OUT      varchar2,
    out_report   OUT      varchar2,
    out_cartonid OUT      varchar2,
    out_email_addresses OUT varchar2,
    out_errmsg   OUT      varchar2
);

end zmanifestq;
/
exit;
