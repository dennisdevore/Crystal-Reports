create or replace package body alps.zbillmisc as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
-- Constants are defined in zbillspec.sql
--
-- MOVE TO zbillspec when get a chance
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
-- Cursors are defined in zbillspec.sql
--
----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;
----------------------------------------------------------------------


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- recalc_misc -
--
----------------------------------------------------------------------
FUNCTION recalc_misc
(
    in_invoice  IN      number,
    in_loadno   IN      number,   -- really a dummy field
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND custid = in_custid
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_INVH(in_invoice number)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE invoice = in_invoice;

  CURSOR C_FORDHDR(in_orderid number)
  RETURN orderhdr%rowtype
  IS
     SELECT *
       FROM orderhdr
      WHERE orderid = in_orderid
		AND (ordertype = 'F'
				OR
			(ordertype = 'O' AND bill_freight_yn = 'Y'));

  INVH invoicehdr%rowtype;
  ORDHDR orderhdr%rowtype;
  rc integer;

  errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

    INVH := null;
    OPEN C_INVH(in_invoice);
    FETCH C_INVH into INVH;
    CLOSE C_INVH;

    if INVH.invoice is null then
       out_errmsg := 'Invalid reference number:'||in_invoice;
       return zbill.BAD;
    end if;

    if INVH.invstatus = zbill.BILLED then
       out_errmsg := 'Invalid Invoice. Already billed.';
       return zbill.BAD;
    end if;

    -- Handle freight order
    ORDHDR := null;
    OPEN C_FORDHDR(INVH.orderid);
    FETCH C_FORDHDR into ORDHDR;
    CLOSE C_FORDHDR;
    if ORDHDR.orderid is not null then
       rc := recalc_freight_misc(in_invoice, in_loadno, in_custid, in_userid, out_errmsg);
       if ORDHDR.ordertype = 'F' then
         return rc;
       end if;
    end if;

-- remove stuff we will recalc
    DELETE FROM invoicedtl
     WHERE invoice = INVH.invoice
       AND billmethod in ('PCHG','LINE','ITEM','ORDR','INV','ACCT',
                      'SCLN','SCIT','SCOR','SCIN');

    update invoicedtl
       set billstatus = zbill.UNCHARGED
     where invoice = in_invoice
       and billstatus not in  (zbill.DELETED, zbill.BILLED);


-- Calculate the existing uncalculated line items.
    for crec in C_INVD(in_invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, INVH.invdate,
                                errmsg) = zbill.BAD then
           null;
           -- zut.prt('CR: '||errmsg);
        end if;
    end loop;


    rc := zbsc.calc_minimums(INVH, zbill.EV_MISC ,
         null,null,in_userid,INVH.invdate,out_errmsg);

    rc := zbsc.calc_surcharges(INVH, zbill.EV_MISC ,
         null,null,in_userid,INVH.invdate, out_errmsg);

    UPDATE invoicehdr
       SET invstatus = zbill.NOT_REVIEWED,
           masterinvoice = null
     WHERE invoice = in_invoice;

    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
  out_errmsg := sqlerrm;
  return zbill.BAD;
END recalc_misc;

----------------------------------------------------------------------
--
-- recalc_freight_misc -
--
----------------------------------------------------------------------
FUNCTION recalc_freight_misc
(
    in_invoice  IN      number,
    in_loadno   IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN INTEGER
IS
  CURSOR C_INVD(in_invoice number, in_custid varchar2)
  IS
    select distinct loadno, 
		   stopno, 
		   orderid, 
		   shipid
      from invoicedtl
     where invoice = in_invoice
       and custid = in_custid
       and billstatus = zbill.uncharged;

  CURSOR C_INVH(in_invoice number)
  RETURN invoicehdr%rowtype
  IS
     select *
       from invoicehdr
      where invoice = in_invoice;
	  
  CURSOR C_FORDHDR(in_orderid number, in_shipid number)
  IS
     select dateshipped, statusupdate
       from orderhdr
      where orderid = in_orderid
	    and shipid = in_shipid
		AND (ordertype = 'F'
				OR
			(ordertype = 'O' AND bill_freight_yn = 'Y'));
			
	CURSOR C_SYSTEMDEFAULTS(in_defaultid varchar2)
	IS
		select	defaultvalue
		  from	systemdefaults
		 where	defaultid = in_defaultid;
		 
	sysdefault_trace    systemdefaults.defaultvalue%type;
	
  ORDHDR		C_FORDHDR%rowtype;
  INVD			C_INVD%rowtype;
  INVH			C_INVH%rowtype;
  
  now_date		date;
  rc			number;
  
BEGIN

    out_errmsg := 'OKAY';
	
    INVH := null;
    OPEN C_INVH(in_invoice);
    FETCH C_INVH INTO INVH;
    CLOSE C_INVH;

    if INVH.invoice is null then
       out_errmsg := 'Invalid reference number:'||in_invoice;
       return zbill.BAD;
    end if;
	
    update invoicedtl
       set billstatus = zbill.UNCHARGED
     where invoice = in_invoice
       and billstatus not in  (zbill.DELETED, zbill.BILLED);
	
	delete from freight_summary_by_class
     where loadno = invh.loadno;
	 
    delete from freight_bill_results
     where loadno = invh.loadno;

	-- create invoices
	OPEN C_INVD(in_invoice, in_custid);
	FETCH C_INVD INTO INVD;
	if C_INVD%notfound then
		out_errmsg := 'Invoice='||in_invoice||' was not found. Check invoice status';
		return zbill.BAD;
	end if;
	CLOSE C_INVD;
	
    for crec in C_INVD(in_invoice, in_custid) loop
	    OPEN C_FORDHDR(crec.orderid, crec.shipid);
        FETCH C_FORDHDR into ORDHDR;
        CLOSE C_FORDHDR;
	
		now_date := nvl(nvl(ORDHDR.dateshipped,ORDHDR.statusupdate),sysdate);
		
	-- remove stuff we will recalc
    delete from invoicedtl
     where invoice = INVH.invoice
	   and loadno = crec.loadno
	   and stopno = crec.stopno
	   and shipid = crec.shipid
       and billmethod = 'FGHT';

		rc := zba.create_freight_invoice
				(	NULL,
					crec.loadno,
					crec.stopno,
					crec.orderid,
					crec.shipid,
					now_date,
					in_userid,
					sysdefault_trace,
					out_errmsg );

		if rc != zbill.GOOD then
			return zbill.BAD;
		end if;
		
    end loop;

    update invoicehdr
       set invstatus = zbill.NOT_REVIEWED,
           masterinvoice = null
     where invoice = in_invoice;

	update invoicedtl
       set billstatus = zbill.NOT_REVIEWED
     where invoice = in_invoice;

    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
  out_errmsg := 'recalc_freight_misc: ' || sqlerrm;
  return zbill.BAD;
END recalc_freight_misc;

FUNCTION recalc_misc_min_and_srchg
(
    INVH        IN      invoicehdr%rowtype,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN    varchar2 default 'N'
)
RETURN integer
as
  rc integer;
begin
  out_errmsg := 'OKAY';

  rc := zbsc.calc_minimums(INVH, zbill.EV_MISC ,
         null,null,in_userid,INVH.invdate,out_errmsg,in_keep_deleted);
         
  if (rc <> zbill.GOOD) then
    return rc;
  end if;

  rc := zbsc.calc_surcharges(INVH, zbill.EV_MISC ,
       null,null,in_userid,INVH.invdate, out_errmsg);
       
  return rc;
       
exception 
  when others then
    out_errmsg := 'recalc_misc_min_and_srchg: ' || sqlerrm;
    return zbill.BAD;
end recalc_misc_min_and_srchg;

end zbillmisc;
/

show error package body zbillmisc;
exit;
