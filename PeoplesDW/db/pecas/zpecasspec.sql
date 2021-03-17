--
-- $Id$
--
create or replace package zpecas as

BaseAddType constant number(3) := 0;

BaseUOM_    constant varchar2(4) := 'PCS';
CtnUOM_    constant varchar2(4) := 'CTN';
PltUOM_    constant varchar2(4) := 'PLT';


----------------------------------------------------------------------
--
-- update_custitem_uom
--
----------------------------------------------------------------------
PROCEDURE update_custitem_uom
(
    in_custid   varchar2,
    in_jobno     varchar2,
    in_item     varchar2,
    in_crtn     number,
    in_plt      number,
    in_overage  number,
    in_userid   varchar2
);

----------------------------------------------------------------------
--
-- process_input - process the input notify queue
--
----------------------------------------------------------------------
PROCEDURE process_input;

----------------------------------------------------------------------
--
-- startup_process
--
----------------------------------------------------------------------
PROCEDURE startup_process;

PROCEDURE Custom
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- process_exp_receipt
--
----------------------------------------------------------------------
PROCEDURE process_exp_receipt(
    TRN xchngin%rowtype
);

----------------------------------------------------------------------
--
-- process_exp_shipment
--
----------------------------------------------------------------------
PROCEDURE process_exp_shipment(
    TRN xchngin%rowtype
);

----------------------------------------------------------------------
--
-- inv_adj - create inventory adjustment record
--
----------------------------------------------------------------------
PROCEDURE inv_adj
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- prod_receipt - create actual receipt record
--
----------------------------------------------------------------------
PROCEDURE prod_receipt
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- ship_order - create actual shipment record
--
----------------------------------------------------------------------
PROCEDURE ship_order
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- check_lpid - check if a lpid is to be used for production
--
----------------------------------------------------------------------
PROCEDURE check_lpid
(
    in_data IN OUT alps.cdata
);

----------------------------------------------------------------------
--
-- update_customer
--
----------------------------------------------------------------------
PROCEDURE update_customer
(
    in_custid   varchar2
);

END zpecas;
/
exit;
