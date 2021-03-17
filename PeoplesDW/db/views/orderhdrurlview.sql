
CREATE OR REPLACE VIEW ORDERHDRURLVIEW (
ORDERID,
SHIPID,
SHIPTYPE,
LOADNO,
CARRIER,
TRACKINGNO,
URL
) AS
select oh.orderid, oh.shipid, oh.shiptype, oh.loadno,
       nvl(ld.carrier,oh.carrier),
       oh.prono,
       zmn.get_tracker_url(nvl(ld.carrier,oh.carrier),oh.prono) as url
  from orderhdr oh, loads ld
 where oh.loadno = ld.loadno (+);

comment on table ORDERHDRURLVIEW is '$Id$';

exit;
