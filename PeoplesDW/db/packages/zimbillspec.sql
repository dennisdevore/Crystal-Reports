--
-- $Id$
--
create or replace PACKAGE alps.zimportprocbill

Is

procedure import_invoice_header
(
 in_facility in varchar2
,in_custid in varchar2
,in_invoice_type in varchar2
,in_charge_date in date
,in_loadno in number
,in_orderid in number
,in_shipid in number
,out_invoice IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_invoice_charge
(
 in_facility in varchar2
,in_custid in varchar2
,in_invoice_type in varchar2
,in_activity_date in date
,in_loadno in number
,in_orderid in number
,in_shipid in number
,in_invoice number
,in_activity in varchar2
,in_item in varchar2
,in_lot in varchar2
,in_uom in varchar2
,in_quantity in number
,in_billmethod in varchar2
,in_rate in number
,in_useinvoice number
,in_comment in varchar2
,in_recalc_invoice in varchar2
,out_invoice IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportprocbill;
/
show error package zimportprocbill;
exit;
