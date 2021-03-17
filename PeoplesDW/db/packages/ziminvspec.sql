--
-- $Id$
--
create or replace PACKAGE alps.zimportprocinv

Is

procedure import_inventory_all
( in_lpid in varchar2
,in_item in varchar2
,in_custid in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_status in varchar2
,in_holdreason in varchar2
,in_unitofmeasure in varchar2
,in_quantity in number
,in_type in varchar2
,in_serialnumber in varchar2
,in_lotnumber in varchar2
,in_creationdate in date
,in_manufacturedate in date
,in_expirationdate in date
,in_expiryaction in varchar2
,in_lastcountdate in date
,in_po in varchar2
,in_recmethod in varchar2
,in_condition in varchar2
,in_lastoperator in varchar2
,in_lasttask in varchar2
,in_fifodate in date
,in_destlocation in varchar2
,in_destfacility in varchar2
,in_countryof in varchar2
,in_parentlpid in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_disposition in varchar2
,in_lastuser in varchar2
,in_lastupdate in date
,in_invstatus in varchar2
,in_qtyentered in number
,in_itementered in varchar2
,in_uomentered in varchar2
,in_inventoryclass in varchar2
,in_loadno in number
,in_stopno in number
,in_shipno in number
,in_orderid in number
,in_shipid in number
,in_weight in number
,in_adjreason in varchar2
,in_qtyrcvd in number
,in_controlnumber in varchar2
,in_qcdisposition in varchar2
,in_fromlpid in varchar2
,in_taskid in number
,in_dropseq in number
,in_fromshippinglpid in varchar2
,in_workorderseq in number
,in_workordersubseq in number
,in_qtytasked in number
,in_childfacility in varchar2
,in_childitem in varchar2
,in_parentfacility in varchar2
,in_parentitem in varchar2
,in_prevlocation in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_inv
(in_lpid in varchar2
,in_item in varchar2
,in_custid in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_unitofmeasure in varchar2
,in_quantity in number
,in_serialnumber in varchar2
,in_lotnumber in varchar2
,in_creationdate in varchar2
,in_manufacturedate in varchar2
,in_expirationdate in varchar2
,in_po in varchar2
,in_recmethod in varchar2
,in_condition in varchar2
,in_countryof in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_invstatus in varchar2
,in_inventoryclass in varchar2
,in_orderid in number
,in_shipid in number
,in_weight in number
,in_qtyrcvd in number
,in_masterlpid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_import_inv
(in_update IN varchar2
,in_datefmt IN varchar2
,in_min_date IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_lot_receipt_rate
(
    in_facility IN  varchar2,
    in_custid   IN  varchar2,
    in_item     IN  varchar2,
    in_lot      IN  varchar2,
    in_receiptdate IN date,
    in_quantity IN  number,
    in_uom      IN  varchar2,
    in_weight   IN  number,
    in_renewalrate IN number,
    out_errorno IN OUT number,
    out_msg     OUT varchar2
);



end zimportprocinv;
/
show error package zimportprocinv;
--exit;
