--
-- $Id: zfreightspec.sql $
--
create or replace package alps.zfreightbill as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
-- freight_bill_calculator
----------------------------------------------------------------------
PROCEDURE freight_bill_calculator
(
    in_loadno   					IN      number,
	in_stopno						IN      number,
	in_tariff						IN		varchar2,
	in_discount_percent				IN      number,
	in_surchargeid					IN      varchar2,
	in_surcharge_effdate			IN		date,
	in_codid						IN      varchar2,
	in_freightvalue					IN      number,
	in_freight_accessorials			IN      varchar2,
	in_trace						IN OUT	varchar2,
    in_userid   					IN      varchar2,
	out_max_truckload_y_n			OUT		varchar2,
	out_max_truckload_charges		OUT		number,
    out_errmsg  					IN OUT  varchar2
);

----------------------------------------------------------------------
-- calc_freight_charges
----------------------------------------------------------------------
PROCEDURE calc_freight_charges
(
	in_loadno   				IN      number,
	in_stopno					IN      number,
	in_tariff					IN		varchar2,
	in_discount_percent			IN		number,
	in_trace					IN		varchar2,
	in_userid					IN		varchar2,
	out_max_truckload_charges	OUT		number,
	out_max_truckload_y_n		OUT		varchar2,
    out_errmsg  				IN OUT	varchar2
);

----------------------------------------------------------------------
-- calc_freight_access_charges
----------------------------------------------------------------------
PROCEDURE calc_freight_access_charges
(
    in_loadno   				IN      number,
	in_stopno					IN      number,
	in_tariff					IN		varchar2,
	in_freight_accessorials		IN		varchar2,
	in_trace					IN		varchar2,
    in_userid   				IN      varchar2,
    out_errmsg  				IN OUT  varchar2
);

----------------------------------------------------------------------
-- calc_freight_cod_charges
----------------------------------------------------------------------
PROCEDURE calc_freight_cod_charges
(
	in_loadno				IN		number,
	in_stopno				IN		number,
	in_tariff				IN      varchar2,
    in_codid   				IN      varchar2,
	in_freightvalue			IN      number,
	out_cod_charges			OUT		number,
	out_yn_last_cod_charge	OUT		varchar2,
	out_errmsg				IN OUT	varchar2
);

----------------------------------------------------------------------
-- calc_freight_fuelsurcharge
----------------------------------------------------------------------
PROCEDURE calc_freight_fuelsurcharge
(
	in_loadno				IN		number,
	in_stopno				IN		number,
	in_tariff				IN		varchar2,
    in_surchargeid			IN      varchar2,
	in_surcharge_effdate	IN      date,
	out_surcharge_percent	OUT		number,
	out_fuelsurcharge_amt	OUT		number,
    out_errmsg  			IN OUT  varchar2
);

----------------------------------------------------------------------
-- rd_freight_fuelsurcharge
----------------------------------------------------------------------
PROCEDURE rd_freight_fuelsurcharge
(
    in_surchargeid			IN      varchar2,
	in_surcharge_effdate	IN      date,
	out_surcharge_percent	OUT		number,
    out_errmsg  			IN OUT  varchar2
);

----------------------------------------------------------------------
-- calc_max_truckload
----------------------------------------------------------------------
PROCEDURE calc_max_truckload
(
    in_loadno					IN      number,
	in_stopno					IN      number,
	in_tariff					IN		varchar2,
	out_max_truckload_charges	OUT		number,
	out_max_truckload_y_n		OUT		varchar2,
    out_errmsg  				IN OUT	varchar2
);

----------------------------------------------------------------------
-- calc_freight_discount
----------------------------------------------------------------------
PROCEDURE calc_freight_discount
(
    in_loadno   		IN      number,
	in_stopno			IN      number,
	in_tariff			IN		varchar2,
	in_discount_percent	IN		number,
	out_discount_amount	OUT		number,
	out_discount_y_n	OUT		varchar2,
    out_errmsg  		IN OUT  varchar2
);

----------------------------------------------------------------------
-- get_freight_tot_qty
----------------------------------------------------------------------
PROCEDURE get_freight_tot_qty
(
	in_loadno				IN		number,
	in_stopno				IN		number,
	out_tot_cwt_qty			OUT		number,
	out_errmsg				OUT		varchar2
);

----------------------------------------------------------------------
-- get_freight_activity
----------------------------------------------------------------------
PROCEDURE get_freight_activity
(
	in_code				IN		varchar2,
	ACTV				OUT		activity%rowtype,
    out_errmsg  		IN OUT	varchar2
);

----------------------------------------------------------------------
-- get_freight_access_activity
----------------------------------------------------------------------
PROCEDURE get_freight_access_activity
(
	in_tariff			IN		varchar2,
	in_activitycode		IN		varchar2,
	out_descr			OUT		varchar2,
    out_errmsg  		IN OUT	varchar2
);

----------------------------------------------------------------------
-- get_freight_default_activity
----------------------------------------------------------------------
PROCEDURE get_freight_default_activity
(
	in_defaultid		IN		varchar2,
	ACTV				OUT		systemdefaults%rowtype,
    out_errmsg  		IN OUT	varchar2
);

----------------------------------------------------------------------
-- rd_freight_rategroup
----------------------------------------------------------------------
PROCEDURE rd_freight_rategroup
(
	in_custid			IN		varchar2,
	in_billmethod		IN		varchar2,
	in_businessevent	IN		varchar2,
	in_effdate			IN		date,
	out_rategroup		OUT		custrategroup%rowtype,
	out_errmsg			IN OUT	varchar2
);

----------------------------------------------------------------------
-- rd_freight_minumum
----------------------------------------------------------------------
PROCEDURE rd_freight_minumum
(
	in_tariff				IN		varchar2,
	in_activitycode			IN		varchar2,
	out_tariffaccessorials	OUT		tariffaccessorials%rowtype,
	out_errmsg				IN OUT	varchar2
);

AUTHOR constant varchar2(12) := 'FREIGHTBILL';

end zfreightbill;
/

show errors package zfreightbill;
exit;
