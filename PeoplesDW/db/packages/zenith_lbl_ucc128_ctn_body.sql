create or replace package body zenith_lbl_ucc128_ctn as
--
-- $Id: zenith_case_labels_body.sql 2794 2008-06-27 15:25:04Z ed $
--
FUNCTION get_seq
(in_lpid IN varchar2
) return integer
IS
l_seq integer;
cursor curOrderhdr is
  select orderid, shipid
    from shippingplate
   where lpid = in_lpid;
oh curOrderhdr%rowtype;


BEGIN

    l_seq := null;
    open curOrderhdr;
    fetch curOrderhdr into oh;
    close curOrderhdr;
    select count(1) into l_seq
       from shippingplate
       where orderid = oh.orderid
         and shipid = oh.shipid
         and lpid <= in_lpid
         and type in ('F','P');
    return l_seq;
EXCEPTION WHEN OTHERS THEN
    return 0;
END get_seq;

FUNCTION get_seqof
(in_lpid IN varchar2
) return integer
IS
l_seqof integer;
cursor curOrderhdr is
  select orderid, shipid
    from shippingplate
   where lpid = in_lpid;
oh curOrderhdr%rowtype;


BEGIN

    l_seqof := null;
    open curOrderhdr;
    fetch curOrderhdr into oh;
    close curOrderhdr;
    select count(1) into l_seqof
       from shippingplate
       where orderid = oh.orderid
         and shipid = oh.shipid
         and type in ('F','P');
    return l_seqof;
EXCEPTION WHEN OTHERS THEN
    return 0;
END get_seqof;



end zenith_lbl_ucc128_ctn;
/

show errors package body zenith_lbl_ucc128_ctn;
exit;
