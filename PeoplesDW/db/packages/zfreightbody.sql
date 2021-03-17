create or replace package body alps.zfreightbill as
--
-- $Id: zfreightbody.sql $
--
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

CURSOR C_TARIFF(in_tariff varchar2)
IS
  SELECT *
    FROM tariff
   WHERE tariff = in_tariff;
	 	 
CURSOR C_FREIGHT_SUMMARY_BY_CLASS(in_loadno number, in_stopno number)
IS
  SELECT *
    FROM FREIGHT_SUMMARY_BY_CLASS
   WHERE loadno = in_loadno
     AND stopno = in_stopno;

CURSOR C_TOTAL_FREIGHT_RESULTS(in_loadno number, in_stopno number)
IS
  SELECT cwt_qty,
		 gross_charges,
		 net_charges
	FROM freight_bill_results
   WHERE loadno = in_loadno
	 AND stopno = in_stopno
	 AND chargestype = 'FREIGHT_TOTAL_CHARGES';
		 
	log_msg					varchar2(2000);
	out_logmsg				varchar2(2000);

----------------------------------------------------------------------
-- freight_bill_calculator
----------------------------------------------------------------------
PROCEDURE freight_bill_calculator
(
  in_loadno                 IN      number,
  in_stopno                 IN      number,
  in_tariff                 IN      varchar2,
  in_discount_percent       IN      number,
  in_surchargeid            IN      varchar2,
  in_surcharge_effdate      IN      date,
  in_codid                  IN      varchar2,
  in_freightvalue           IN      number,
  in_freight_accessorials   IN      varchar2,
  in_trace                  IN OUT  varchar2,
  in_userid                 IN      varchar2,
  out_max_truckload_y_n     OUT     varchar2,
  out_max_truckload_charges OUT     number,
  out_errmsg                IN OUT  varchar2
)
IS
	CURSOR C_SYSTEMDEFAULTS(in_defaultid varchar2)
	IS
		select	defaultvalue
		  from	systemdefaults
		 where	defaultid = in_defaultid;

	TAR							tariff%rowtype;
	out_discount_amount			number(12,6);
	out_discount_y_n			varchar2(1);
	out_cod_charges     		number(12,6);
	out_yn_last_cod_charge		varchar2(1);
	out_fuelsurcharge_amt		number(12,6);
	out_surcharge_percent		fuelsurchargedtl.surcharge_percent%type;
	out_min_y_n					varchar2(1);
	FBRESULTS					FREIGHT_SUMMARY_BY_CLASS%rowtype;
	sysdefault_trace			systemdefaults.defaultvalue%type;
	
BEGIN
	out_errmsg := 'OKAY';
	
	OPEN C_SYSTEMDEFAULTS('TRACEFREIGHTBILLING');
	FETCH C_SYSTEMDEFAULTS INTO sysdefault_trace;
	CLOSE C_SYSTEMDEFAULTS;
	
	if in_trace <> 'Y' then
		in_trace := sysdefault_trace;
	end if;
	
	if in_trace = 'Y' then
		log_msg :=  ' FREIGHT_BILL_CALCULATOR( '||
					' in_loadno<'||in_loadno||
					'>  in_stopno<'||in_stopno||
					'>  in_tariff<'||in_tariff||
					'>  in_discount_percent<'||in_discount_percent||
					'>  in_surchargeid<'||in_surchargeid||
					'>  in_surcharge_effdate< '||in_surcharge_effdate||
					'>  in_codid<'||in_codid||
					'>  in_freightvalue<'||in_freightvalue||
					'>  in_trace<'||in_trace||
					'>  in_userid<'||in_userid;
		zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
	end if;
	
	-- verify loadno
	OPEN C_FREIGHT_SUMMARY_BY_CLASS(in_loadno , in_stopno);
	FETCH C_FREIGHT_SUMMARY_BY_CLASS INTO FBRESULTS;
	CLOSE C_FREIGHT_SUMMARY_BY_CLASS;
	
	if FBRESULTS.loadno is null then
		out_errmsg := 'loadno/stopno not found in FREIGHT_SUMMARY_BY_CLASS: ' || in_loadno||'/'||in_stopno;
		return;
	end if;
	
	-- verify discount percent
	if in_discount_percent is not null then
		if in_discount_percent < 0 then
			out_errmsg := 'Invalid discount percent for loadno/discount percent: '||
				in_loadno||'/'||in_discount_percent;
			return;
		end if;
	end if;
	
	-- verify freightvalue
	if in_freightvalue is not null then
		if in_freightvalue < 0 then
			out_errmsg := 'Invalid freight value for loadno/value: '||
				in_loadno||'/'||in_freightvalue;
			return;
		end if;
	end if;

	-- verif tariff
	OPEN C_TARIFF(in_tariff);
	FETCH C_TARIFF INTO TAR;
	CLOSE C_TARIFF;
	
	if TAR.tariff is null then
		out_errmsg := 'Tariff not found for loadno: '||in_loadno;
		return;
	end if;
	
	-- Calculate freight charges	
	calc_freight_charges(	in_loadno,
							in_stopno,
							in_tariff,
							in_discount_percent,
							in_trace,
							in_userid,
							out_max_truckload_charges,
							out_max_truckload_y_n,
							out_errmsg);

	if out_errmsg <> 'OKAY' then 
		return;
	end if;

	-- Calculate fuel surcharge
	if in_surchargeid is not null then
		calc_freight_fuelsurcharge(	in_loadno,
									in_stopno,
									in_tariff,
									in_surchargeid,
									in_surcharge_effdate,
									out_surcharge_percent,
									out_fuelsurcharge_amt,
									out_errmsg);

		if in_trace = 'Y' then 
			log_msg := 'FuelSurcharge for loadno='||in_loadno||' tariff='||in_tariff||
				' surchargeid='||in_surchargeid||' surcharge%='||out_surcharge_percent||' surchargeamt='||out_fuelsurcharge_amt;
			zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
		end if;

		if out_errmsg <> 'OKAY' then
			return;
		end if;
	end if;
	
	-- Calculate COD charges.
	if in_codid is not null then
		calc_freight_cod_charges(	in_loadno,
									in_stopno,
									in_tariff,
									in_codid,
									in_freightvalue,
									out_cod_charges,
									out_yn_last_cod_charge,
									out_errmsg);

		if in_trace = 'Y' then
			log_msg := 'COD charges for loadno='||in_loadno||'COD charges='||out_cod_charges;
			zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
		end if;

		if out_errmsg <> 'OKAY' then
			return;
		end if;
	end if;
	
	-- Calculate accessorials charges
	calc_freight_access_charges(in_loadno,
								in_stopno,
								in_tariff,
								in_freight_accessorials,
								in_trace,
								in_userid,
								out_errmsg);
				
	if out_errmsg <> 'OKAY' then
		return;
	end if;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'FREIGHT_BILL_CALCULATOR: ' || sqlerrm;
	if in_trace = 'Y' then
		zms.log_autonomous_msg(author,null,null,out_errmsg,'E',in_userid,out_logmsg);
	end if;
END freight_bill_calculator;

----------------------------------------------------------------------
-- calc_freight_charges
----------------------------------------------------------------------
PROCEDURE calc_freight_charges
(
  in_loadno                  IN      number,
  in_stopno                  IN      number,
  in_tariff                  IN      varchar2,
  in_discount_percent        IN      number,
  in_trace                   IN      varchar2,
  in_userid                  IN      varchar2,
  out_max_truckload_charges  OUT     number,
  out_max_truckload_y_n      OUT     varchar2,
  out_errmsg                 IN OUT  varchar2
)
IS 
	CURSOR C_TARIFFBREAKSCLASS(in_tariff varchar2, in_freight_class varchar2, in_cwt_qty number)
	IS
	  SELECT * 
		FROM tariffbreaksclass
	   WHERE tariff = in_tariff
		 AND freight_class = in_freight_class
		 AND (from_weight <= in_cwt_qty AND to_weight >= in_cwt_qty);
	
	TAR								c_tariff%rowtype;
	ACTV							activity%rowtype;
	TBKCLASS						c_tariffbreaksclass%rowtype;
	NEXT_TBKCLASS					c_tariffbreaksclass%rowtype;
	out_tot_cwt_qty					freight_bill_results.cwt_qty%type;
	l_charges_by_class				freight_bill_results.charges_by_class%type;
	l_deficit_charges_by_class		freight_bill_results.charges_by_class%type;
	l_tot_charges_by_class 			freight_bill_results.charges_by_class%type;	
	l_tot_deficit_charges_by_class	freight_bill_results.charges_by_class%type;
	out_discount_amount				freight_bill_results.discount_amount%type;
	out_discount_y_n				varchar2(1);
	out_deficit_rating_y_n			varchar2(1);

BEGIN
	out_errmsg := 'OKAY';
	out_deficit_rating_y_n := 'N';
	l_charges_by_class := 0;
	l_deficit_charges_by_class := 0;
	l_tot_charges_by_class := 0;
	l_tot_deficit_charges_by_class := 0;
	
	-- Get tariff info
	OPEN C_TARIFF(in_tariff);
	FETCH C_TARIFF INTO TAR;
	CLOSE C_TARIFF;
	
	if TAR.tariff is null then
		out_errmsg := 'tariff not found: '|| in_tariff;
		return;
	end if;
	
	-- Get activity code
	get_freight_activity('4010',ACTV, out_errmsg);
	if out_errmsg <> 'OKAY' then
		return;
	end if;

	-- Get total quantity of items for the load.
	 get_freight_tot_qty(in_loadno, in_stopno, out_tot_cwt_qty, out_errmsg);
	if out_tot_cwt_qty <= 0 then
		out_errmsg := 'CWT_QTY not found for loadno= '||in_loadno;
		return;
	end if;
	
	for crec in  C_FREIGHT_SUMMARY_BY_CLASS(in_loadno, in_stopno)
	loop
		-- Calculate charges for this weight group
		-- Rate to apply is based on total weight of all items in the load
		OPEN C_TARIFFBREAKSCLASS(crec.tariff, crec.freight_class, out_tot_cwt_qty * 100);
		FETCH C_TARIFFBREAKSCLASS into TBKCLASS;
		CLOSE C_TARIFFBREAKSCLASS;

		if TBKCLASS.rate is null then
			out_errmsg := 'Rate not found for loadno/tariff/class/total_cwt_qty: '||
				in_loadno||'/'||in_tariff||'/'||crec.freight_class||'/'||out_tot_cwt_qty;
			return;
		end if;

		l_charges_by_class := crec.cwt_qty * TBKCLASS.rate;
		l_tot_charges_by_class := l_tot_charges_by_class + l_charges_by_class;

		if in_trace = 'Y' then
			zms.log_autonomous_msg(author,null,null,
				'Freight charges='||l_charges_by_class||' for class='||crec.freight_class||' cwt_qty= '||crec.cwt_qty,
				'T',in_userid,out_logmsg);
		end if;

		-- Calculate charges for deficit rating at the lowest rate of the next weight group
		OPEN C_TARIFFBREAKSCLASS(crec.tariff, crec.freight_class, TBKCLASS.to_weight + 1);
		FETCH C_TARIFFBREAKSCLASS into NEXT_TBKCLASS;
		CLOSE C_TARIFFBREAKSCLASS;
		
		l_deficit_charges_by_class := (crec.cwt_qty / out_tot_cwt_qty * 100) * NEXT_TBKCLASS.rate;
		l_tot_deficit_charges_by_class := l_tot_deficit_charges_by_class + l_deficit_charges_by_class;
		
		if in_trace = 'Y' then
			zms.log_autonomous_msg(author,null,null,
				'Freight charges w/ deficit rating='||l_deficit_charges_by_class||
				' for class='||crec.freight_class||' cwt_qty= '||TBKCLASS.to_weight,
				'T',in_userid,out_logmsg);
		end if;
		
		insert into freight_bill_results
		(	orderseq,
			loadno,
			stopno,
			tariff,
			chargestype,
			activitycode,
			freight_class,
			cwt_qty,
			rate,
			charges_by_class,
			gross_charges,
			discount_percent,
			discount_amount,
			net_charges,
			descr,
			ratetype,
			lastuser,
			lastupdate)
		values
		(	'1',
			in_loadno,
			in_stopno,
			in_tariff,
			'FREIGHT',
			ACTV.code,
			crec.freight_class,
			crec.cwt_qty,
			TBKCLASS.rate,					
			l_charges_by_class,
			0,
			0,
			0,
			0,
			ACTV.descr,
			'CWT',
			'FREIGHTBILL',
			SYSDATE);
	end loop;
	
	-- Compare both charges and take the lowest one.
	if l_charges_by_class > l_deficit_charges_by_class then
		out_deficit_rating_y_n := 'Y';
	end if;

	if in_trace = 'Y' then
		zms.log_autonomous_msg(author,null,null,
			'Total freight charges: '||l_tot_charges_by_class||
			' - Total freight charges w/ deficit rating: '||l_tot_deficit_charges_by_class||
			' - Deficit Rating: '||out_deficit_rating_y_n,
			'T',in_userid,out_logmsg);
	end if;

	-- Determine total charges
	insert into freight_bill_results
	(	orderseq,
		loadno,
		stopno,
		tariff,
		chargestype,
		activitycode,
		freight_class,
		cwt_qty,
		rate,
		charges_by_class,
		gross_charges,
		discount_percent,
		discount_amount,
		net_charges,
		descr,
		ratetype,
		lastuser,
		lastupdate)
	values
	(	'2',
		in_loadno,
		in_stopno,
		in_tariff,
		'FREIGHT_TOTAL_CHARGES',
		ACTV.code,
		' ',
		out_tot_cwt_qty,
		0,
		0,
		decode(out_deficit_rating_y_n, 'Y', l_tot_deficit_charges_by_class, l_tot_charges_by_class),
		0,
		0,
		decode(out_deficit_rating_y_n, 'Y', l_tot_deficit_charges_by_class, l_tot_charges_by_class),
		decode(out_deficit_rating_y_n, 'Y',  ACTV.descr|| ' - with deficit rating', ACTV.descr),
		'CWT',
		'FREIGHTBILL',
		SYSDATE);
	
	-- Calculate discount amount
	calc_freight_discount(	in_loadno,
							in_stopno,
							in_tariff,
							in_discount_percent,
							out_discount_amount,
							out_discount_y_n,
							out_errmsg);

	if in_trace = 'Y' then
		log_msg := 	'Discount for loadno='||in_loadno||' tariff='||in_tariff||' amount='||out_discount_amount;
		zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
	end if;
	
	if out_errmsg <> 'OKAY' then
		return;
	end if;

	-- Calculate the truck maximum load charge
	calc_max_truckload(	in_loadno,
						in_stopno,
						in_tariff,
						out_max_truckload_charges,
						out_max_truckload_y_n,
						out_errmsg);
	
	if in_trace = 'Y' then
		log_msg := 'Truck Max Load for loadno='||in_loadno||'max_truckload='||out_max_truckload_y_n;
		zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
	end if;
	
	if out_errmsg <> 'OKAY' then
		return;
	end if;

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'calc_freight_charges: ' || sqlerrm;		
END calc_freight_charges;

----------------------------------------------------------------------
-- calc_freight_access_charges
----------------------------------------------------------------------
PROCEDURE calc_freight_access_charges
(
  in_loadno                IN      number,
  in_stopno                IN      number,
  in_tariff                IN      varchar2,
  in_freight_accessorials  IN      varchar2,
  in_trace                 IN      varchar2,
  in_userid                IN      varchar2,
  out_errmsg               IN OUT  varchar2
) 
IS
	TYPE  CUR_TYP is REF CURSOR;
	cdata CUR_TYP;
	
	crec_accessorials		tariffaccessorials%rowtype;
	out_activitycode		varchar2(4);
	out_descr				varchar2(32);	
	out_tot_cwt_qty			freight_bill_results.cwt_qty%type;
  	l_gross_charges			freight_bill_results.gross_charges%type;
	l_net_charges			freight_bill_results.net_charges%type;
	out_min_y_n				varchar2(1);
	l_freight_accessorials	loadstop.freight_accesssorials%type;
BEGIN
	out_errmsg := 'OKAY';
	out_min_y_n := 'N';

	if trim(in_freight_accessorials) is null then
		return;
	end if;

	-- Parse comma delimited list of accessorial values
	l_freight_accessorials := ''''||replace(in_freight_accessorials, ',' , ''',''')||'''';

	-- Get total quantity of items for the load.
	get_freight_tot_qty(in_loadno, in_stopno, out_tot_cwt_qty, out_errmsg);
	if out_tot_cwt_qty <= 0 then
		out_errmsg := 'CWT_QTY not found for loadno: '||in_loadno;
		return;
	end if;

	open cdata for	
			'select *'||
			' from tariffaccessorials'||
			' where tariff = :in_tariff'||
			'  and activitycode in ('||l_freight_accessorials||')'
	using in_tariff;
			
	loop
		fetch cdata into crec_accessorials;
		exit when cdata%notfound;
		
		l_gross_charges := 0;
		
		-- get activity
		get_freight_access_activity(in_tariff, crec_accessorials.activitycode, out_descr, out_errmsg);	
		if out_descr is null then
			out_errmsg := 'Activity descr not found for loadno/tariff/activitycode: '||
				in_loadno||'/'||in_tariff||'/'||crec_accessorials.activitycode;
			return;
		end if;

		if crec_accessorials.rateflag = 'F' then
			l_gross_charges := crec_accessorials.flat_charge;
		elsif crec_accessorials.rateflag = 'C' then
			l_gross_charges := (out_tot_cwt_qty * crec_accessorials.cwt_rate);
		end if;
		l_net_charges := l_gross_charges;
		
		-- check for mininum
		if l_gross_charges < nvl(crec_accessorials.min_cwt_charge,0) then
			l_net_charges := crec_accessorials.min_cwt_charge;
			out_min_y_n := 'Y';
		end if;

		insert into freight_bill_results
		(	orderseq,
			loadno,
			stopno,
			tariff,
			chargestype,
			activitycode,
			freight_class,
			cwt_qty,
			rate,
			charges_by_class,
			gross_charges,
			discount_percent,
			discount_amount,
			net_charges,
			descr,
			ratetype,
			lastuser,
			lastupdate)
		values
		(	'3',
			in_loadno,
			in_stopno,
			in_tariff,
			'ACCESSORIALS'||crec_accessorials.activitycode,
			crec_accessorials.activitycode,
			' ',
			out_tot_cwt_qty,
			decode (crec_accessorials.rateflag, 'C', crec_accessorials.cwt_rate,0),
			0,
			l_gross_charges,
			0,
			0,
			l_net_charges,
			decode (out_min_y_n, 'N', out_descr,
								 'Y', out_descr||' - minimum='||out_min_y_n),
			decode (crec_accessorials.rateflag,	'C', 'CWT',
									'F', 'FLAT',
									null),
			'FREIGHTBILL',
			SYSDATE);
			
		if in_trace = 'Y' then
			log_msg := 'Accessorial charges='||l_net_charges||' for loadno='||in_loadno||
				' tariff='||in_tariff||' actvity='||out_descr||' minimum applied= '||out_min_y_n;
			zms.log_autonomous_msg(author,null,null,log_msg,'T',in_userid,out_logmsg);
		end if;
	end loop;

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'calc_freight_access_charges: ' || sqlerrm;		
END calc_freight_access_charges;

----------------------------------------------------------------------
-- calc_freight_discount
----------------------------------------------------------------------
PROCEDURE calc_freight_discount
(
  in_loadno           IN      number,
  in_stopno           IN      number,
  in_tariff           IN      varchar2,
  in_discount_percent IN      number,
  out_discount_amount OUT     number,
  out_discount_y_n    OUT     varchar2,
  out_errmsg          IN OUT  varchar2
)
IS

		 
	TOTALFREIGHT	C_TOTAL_FREIGHT_RESULTS%rowtype;
	TAR 			C_TARIFF%rowtype;
	
BEGIN
	out_errmsg := 'OKAY';
	out_discount_y_n := 'N';

	if nvl(trim(in_discount_percent),0) = 0 then
		return;
	end if;
	
	OPEN C_TARIFF(in_tariff);
	FETCH C_TARIFF INTO TAR;
	CLOSE C_TARIFF;
	if nvl(TAR.discountable_flag,'N') <> 'Y' then
		return;
	end if;

	OPEN C_TOTAL_FREIGHT_RESULTS(in_loadno,in_stopno);
	FETCH C_TOTAL_FREIGHT_RESULTS INTO TOTALFREIGHT;
	CLOSE C_TOTAL_FREIGHT_RESULTS;

	out_discount_amount := (TOTALFREIGHT.gross_charges * in_discount_percent) / 100;
	out_discount_y_n := 'Y';

	update freight_bill_results
	set net_charges			= TOTALFREIGHT.net_charges - out_discount_amount,
		discount_percent	= in_discount_percent,
		discount_amount		= out_discount_amount,
		lastupdate			= SYSDATE
	where loadno = in_loadno
	and   stopno = in_stopno
	and   tariff = in_tariff
	and   chargestype = 'FREIGHT_TOTAL_CHARGES';

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'calc_freight_discount: ' || sqlerrm;		
END calc_freight_discount;

----------------------------------------------------------------------
-- calc_freight_cod_charges
--
----------------------------------------------------------------------
PROCEDURE calc_freight_cod_charges
(
  in_loadno               IN      number,
  in_stopno               IN      number,
  in_tariff               IN      varchar2,
  in_codid                IN      varchar2,
  in_freightvalue         IN      number,
  out_cod_charges         OUT     number,
  out_yn_last_cod_charge  OUT     varchar2,
  out_errmsg              IN OUT  varchar2
)
IS
	CURSOR	C_CODCHARGESDTL(in_codid varchar2, in_freightvalue number)
	IS
		SELECT *
		FROM	codchargesdtl
		WHERE   codid = in_codid
		  AND	(in_freightvalue >= from_amount
					AND	
				in_freightvalue <= to_amount);
	
	COD				C_CODCHARGESDTL%rowtype;
	ACTV			SYSTEMDEFAULTS%rowtype;
	max_cod_amount 	codchargesdtl.from_amount%type;
	out_tot_cwt_qty	freight_bill_results.cwt_qty%type;
	
BEGIN

	out_errmsg := 'OKAY';

	if trim(in_codid) is null then
		return;
	end if;
	
	if nvl(in_freightvalue,0) = 0 then
		return;
	end if;

	OPEN C_CODCHARGESDTL(in_codid, nvl(in_freightvalue,0));
	FETCH C_CODCHARGESDTL INTO COD;
	CLOSE C_CODCHARGESDTL;

	if COD.codid is null then
		out_errmsg := 'CODID not found: '|| in_codid;
		return;
	end if;

	-- Get activity code
	get_freight_default_activity('FREIGHT_COD_CHARGES', ACTV, out_errmsg);
	if out_errmsg <> 'OKAY' then
		return;
	end if;
	
	select	max (from_amount)
	into	max_cod_amount
	from	codchargesdtl
	where	codid = in_codid;
	
	-- COD charges are listed as flat rate except
	-- for the last one which is a percentage
	
	if COD.from_amount = max_cod_amount then
		out_yn_last_cod_charge := 'Y';
		out_cod_charges := in_freightvalue * (COD.cod_charge/100);
	else
		out_yn_last_cod_charge := 'N';
		out_cod_charges := COD.cod_charge;
	end if;
	
	-- Get total quantity of items for the load.
	get_freight_tot_qty(in_loadno, in_stopno, out_tot_cwt_qty, out_errmsg);
	if out_tot_cwt_qty <= 0 then
		out_errmsg := 'CWT_QTY not found for loadno: '||in_loadno;
		return;
	end if;
	
	insert into freight_bill_results
	(	orderseq,
		loadno,
		stopno,
		tariff,
		chargestype,
		activitycode,
		freight_class,
		cwt_qty,
		rate,
		charges_by_class,
		gross_charges,
		discount_percent,
		discount_amount,
		net_charges,
		descr,
		ratetype,
		lastuser,
		lastupdate)
	values
	(	'4',
		in_loadno,
		in_stopno,
		in_tariff,
		'COD_CHARGES',
		ACTV.defaultvalue,
		' ',
		out_tot_cwt_qty, -- Only needed so invoice record is not in Red and can be approved,
		0,
		0,
		out_cod_charges,
		0,
		0,
		out_cod_charges,
		ACTV.defaultid,
		null,
		'FREIGHTBILL',
		SYSDATE);
		
EXCEPTION WHEN OTHERS THEN
	out_errmsg := 'calc_freight_cod_charges: '||sqlerrm;
END calc_freight_cod_charges;

----------------------------------------------------------------------
-- calc_freight_fuelsurcharge
----------------------------------------------------------------------
PROCEDURE calc_freight_fuelsurcharge
(
  in_loadno              IN      number,
  in_stopno              IN      number,
  in_tariff              IN      varchar2,
  in_surchargeid         IN      varchar2,
  in_surcharge_effdate   IN      date,
  out_surcharge_percent  OUT     number,	
  out_fuelsurcharge_amt  OUT     number,
  out_errmsg             IN OUT  varchar2
)
IS
	CURSOR	C_FUELSURCHARGE(in_surchargeid varchar2, in_surcharge_effdate date)
	IS								
		SELECT * 
		FROM 	FUELSURCHARGEDTL
		WHERE 	surchargeid = in_surchargeid
		AND 	effdate = 
				(	SELECT MAX(effdate) 
					FROM 	FUELSURCHARGEDTL
					WHERE 	effdate <= in_surcharge_effdate
					AND 	surchargeid = in_surchargeid);
		 
	FUELSURCHARGE				C_FUELSURCHARGE%rowtype;
	TOTALFREIGHT				C_TOTAL_FREIGHT_RESULTS%rowtype;
	
	l_default_fuelsurcharge		systemdefaults.defaultvalue%type;
	ACTV						systemdefaults%rowtype;
	out_tot_cwt_qty				freight_bill_results.cwt_qty%type;
BEGIN

	out_errmsg := 'OKAY';
	out_fuelsurcharge_amt := 0;
	
	-- Get activity code
	get_freight_default_activity('FREIGHT_FUEL_SURCHARGE', ACTV, out_errmsg);
	if out_errmsg <> 'OKAY' then
		return;
	end if;
	
	OPEN C_FUELSURCHARGE(in_surchargeid, in_surcharge_effdate);
	FETCH C_FUELSURCHARGE INTO FUELSURCHARGE;
	CLOSE C_FUELSURCHARGE;

	if FUELSURCHARGE.surchargeid is null then
		select defaultvalue
		into l_default_fuelsurcharge
		from  systemdefaults
		where defaultid = 'FUELSURCHARGE';
		
		OPEN C_FUELSURCHARGE(l_default_fuelsurcharge, in_surcharge_effdate);
		FETCH C_FUELSURCHARGE INTO FUELSURCHARGE;
		CLOSE C_FUELSURCHARGE;
		
		if FUELSURCHARGE.surchargeid is null then
			out_errmsg := 'Fuelsurchargeid not found: ' || in_surchargeid;
			return;
		end if;
	end if;
	
	OPEN C_TOTAL_FREIGHT_RESULTS(in_loadno,in_stopno);
	FETCH C_TOTAL_FREIGHT_RESULTS INTO TOTALFREIGHT;
	CLOSE C_TOTAL_FREIGHT_RESULTS;
	
	if nvl(TOTALFREIGHT.net_charges,0) <= 0 then
		out_errmsg := 'Cannot calculate fuelsurcharge. Net_charges must be greater than zero.';
		return;
	end if;
	
	out_surcharge_percent := FUELSURCHARGE.surcharge_percent;
	
	if  FUELSURCHARGE.surcharge_percent > 0 then
		out_fuelsurcharge_amt := (TOTALFREIGHT.net_charges  * FUELSURCHARGE.surcharge_percent)/100;
	end if;
	
	-- Get total quantity of items for the load.
	 get_freight_tot_qty(in_loadno, in_stopno, out_tot_cwt_qty, out_errmsg);
	if out_tot_cwt_qty <= 0 then
		out_errmsg := 'CWT_QTY not found for loadno: '||in_loadno;
		return;
	end if;
	
	insert into freight_bill_results
	(	orderseq,
		loadno,
		stopno,
		tariff,
		chargestype,
		activitycode,
		freight_class,
		cwt_qty,
		rate,
		charges_by_class,
		gross_charges,
		discount_percent,
		discount_amount,
		net_charges,
		descr,
		ratetype,
		lastuser,
		lastupdate)
	values
	(	'5',
		in_loadno,
		in_stopno,
		in_tariff,
		'FUELSURCHARGE',
		ACTV.defaultvalue,
		' ',
		out_tot_cwt_qty, -- Only needed so invoice record is not in Red and can be approved
		0,
		0,
		out_fuelsurcharge_amt,
		0,
		0,
		out_fuelsurcharge_amt,
		ACTV.defaultid ||' at '||FUELSURCHARGE.surcharge_percent||'%',
		null,
		'FREIGHTBILL',
		SYSDATE);

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'calc_freight_fuelsurcharge: ' || sqlerrm;			
END calc_freight_fuelsurcharge;


----------------------------------------------------------------------
-- rd_freight_fuelsurcharge
----------------------------------------------------------------------
PROCEDURE rd_freight_fuelsurcharge
(
    in_surchargeid			IN      varchar2,
	in_surcharge_effdate	IN      date,
	out_surcharge_percent	OUT		number,
    out_errmsg  			IN OUT  varchar2
)
IS
	CURSOR	C_FUELSURCHARGE(in_surchargeid varchar2, in_surcharge_effdate date)
	IS								
		SELECT * 
		FROM 	FUELSURCHARGEDTL
		WHERE 	surchargeid = in_surchargeid
		AND 	effdate = 
				(	SELECT MAX(effdate) 
					FROM 	FUELSURCHARGEDTL
					WHERE 	effdate <= in_surcharge_effdate
					AND 	surchargeid = in_surchargeid);
					
	FUELSURCHARGE				C_FUELSURCHARGE%rowtype;
	l_default_fuelsurcharge		systemdefaults.defaultvalue%type;
	ACTV						systemdefaults%rowtype;
BEGIN

	out_errmsg := 'OKAY';

	OPEN C_FUELSURCHARGE(in_surchargeid, in_surcharge_effdate);
	FETCH C_FUELSURCHARGE INTO FUELSURCHARGE;
	CLOSE C_FUELSURCHARGE;

	if FUELSURCHARGE.surchargeid is null then
		select defaultvalue
		into l_default_fuelsurcharge
		from  systemdefaults
		where defaultid = 'FUELSURCHARGE';
		
		OPEN C_FUELSURCHARGE(l_default_fuelsurcharge, in_surcharge_effdate);
		FETCH C_FUELSURCHARGE INTO FUELSURCHARGE;
		CLOSE C_FUELSURCHARGE;
		
		if FUELSURCHARGE.surchargeid is null then
			out_errmsg := 'Fuelsurchargeid not found: ' || in_surchargeid;
			return;
		end if;
	end if;

	out_surcharge_percent := FUELSURCHARGE.surcharge_percent;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'rd_freight_fuelsurcharge: ' || sqlerrm;			
END rd_freight_fuelsurcharge;

----------------------------------------------------------------------
-- calc_max_truckload
----------------------------------------------------------------------
PROCEDURE calc_max_truckload
(
  in_loadno                  IN      number,
  in_stopno                  IN      number,
  in_tariff                  IN      varchar2,
  out_max_truckload_charges  OUT     number,
  out_max_truckload_y_n      OUT     varchar2,
  out_errmsg                 IN OUT  varchar2
)
IS		 
	TAR				C_TARIFF%rowtype;
	TOTALFREIGHT	C_TOTAL_FREIGHT_RESULTS%rowtype;
	
BEGIN
	out_errmsg := 'OKAY';	
	out_max_truckload_charges := 0;
	out_max_truckload_y_n := 'N';
		
	OPEN C_TARIFF(in_tariff);
	FETCH C_TARIFF INTO TAR;
	CLOSE C_TARIFF;
	if TAR.tariff is null then
		out_errmsg := 'Tariff not found: ' || in_tariff;
	end if;

	OPEN C_TOTAL_FREIGHT_RESULTS(in_loadno,in_stopno);
	FETCH C_TOTAL_FREIGHT_RESULTS INTO TOTALFREIGHT;
	CLOSE C_TOTAL_FREIGHT_RESULTS;
	
	-- Check the truck maximum load charge
	if TOTALFREIGHT.net_charges > nvl(TAR.max_truckload_charge,0) then
		out_max_truckload_charges := TAR.max_truckload_charge;
		out_max_truckload_y_n := 'Y';
		
		update	freight_bill_results
		set		net_charges = out_max_truckload_charges,
				descr = descr || ' - maxtruckload=Y',
				lastupdate = SYSDATE
		where	loadno = in_loadno
		and		stopno = in_stopno
		and		chargestype = 'FREIGHT_TOTAL_CHARGES';
	end if;

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'calc_max_truckload: ' || sqlerrm;
END calc_max_truckload;

----------------------------------------------------------------------
-- get_freight_activity
----------------------------------------------------------------------
PROCEDURE get_freight_activity
(
  in_code     IN      varchar2,
  ACTV        OUT     activity%rowtype,
  out_errmsg  IN OUT  varchar2
)
IS
  	CURSOR C_FREIGHT_ACTIVITY(in_code varchar2)
	IS
	  SELECT *
		FROM activity
		WHERE code = in_code;
	
BEGIN
	out_errmsg := 'OKAY';
	
	OPEN C_FREIGHT_ACTIVITY(in_code);
	FETCH C_FREIGHT_ACTIVITY INTO ACTV;
	CLOSE C_FREIGHT_ACTIVITY;

	if ACTV.code is null then
		out_errmsg := 'Activity not found for code: '||in_code;
		return;
	end if;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'get_freight_activity: ' || sqlerrm;
END get_freight_activity;

----------------------------------------------------------------------
-- get_freight_default_activity
----------------------------------------------------------------------
PROCEDURE get_freight_default_activity
(
  in_defaultid    IN      varchar2,
  ACTV            OUT     systemdefaults%rowtype,
  out_errmsg      IN OUT  varchar2
)
IS
	CURSOR C_SYSTEMDEFAULTS(in_defaultid varchar2)
	IS
		select	*
		  from	systemdefaults
		 where	defaultid = in_defaultid;
BEGIN
	out_errmsg := 'OKAY';
	
	OPEN C_SYSTEMDEFAULTS(in_defaultid);
	FETCH C_SYSTEMDEFAULTS INTO ACTV;
	CLOSE C_SYSTEMDEFAULTS;

	if ACTV.defaultid is null then
		out_errmsg := 'System DefaultID not found: '||in_defaultid;
		return;
	end if;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'get_freight_default_activity: ' || sqlerrm;
END get_freight_default_activity;

----------------------------------------------------------------------
-- get_freight_access_activity
----------------------------------------------------------------------
PROCEDURE get_freight_access_activity
(
  in_tariff         IN      varchar2,
  in_activitycode   IN      varchar2,
  out_descr         OUT     varchar2,
  out_errmsg        IN OUT  varchar2
)
IS
  	CURSOR C_FREIGHT_ACTIVITY(in_tariff varchar2, in_activitycode varchar2)
	IS
	  SELECT A.activitycode, B.descr
		FROM tariffaccessorials A,
			(select distinct code, descr, abbrev, glacct
				from activity) B
		WHERE A.activitycode = B.code
		  AND A.tariff = in_tariff
		  AND A.activitycode = in_activitycode; 
	FREIGHT_ACTIVITY 	C_FREIGHT_ACTIVITY%rowtype;
	
BEGIN
	out_errmsg := 'OKAY';
	
	OPEN C_FREIGHT_ACTIVITY(in_tariff,in_activitycode);
	FETCH C_FREIGHT_ACTIVITY INTO FREIGHT_ACTIVITY;
	CLOSE C_FREIGHT_ACTIVITY;

	if FREIGHT_ACTIVITY.activitycode is null then
		out_errmsg := 'Activity code not found for tariff: '||in_tariff;
		return;
	end if;
	out_descr := FREIGHT_ACTIVITY.descr;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'get_freight_access_activity: ' || sqlerrm;
END get_freight_access_activity;

----------------------------------------------------------------------
-- get_freight_tot_qty
----------------------------------------------------------------------
PROCEDURE get_freight_tot_qty
(
	in_loadno				IN		number,
	in_stopno				IN		number,
	out_tot_cwt_qty			OUT		number,
	out_errmsg				OUT		varchar2
)
IS	 
	CURSOR C_TOTAL_CWT_QTY(in_loadno number, in_stopno number)
	IS
	  SELECT NVL(SUM(cwt_qty),0) cwt_qty
		FROM freight_summary_by_class
	   WHERE loadno = in_loadno
		 AND stopno = in_stopno;
	TOTAL_CWT_QTY	C_TOTAL_CWT_QTY%rowtype;
BEGIN

	-- Total quantity of items for the load.
	OPEN C_TOTAL_CWT_QTY(in_loadno, in_stopno);
	FETCH C_TOTAL_CWT_QTY INTO TOTAL_CWT_QTY;
	CLOSE C_TOTAL_CWT_QTY;

	if TOTAL_CWT_QTY.cwt_qty > 0 then
		out_tot_cwt_qty := TOTAL_CWT_QTY.cwt_qty;
	else
		out_tot_cwt_qty := 0;
	end if;
	
EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'get_freight_tot_qty: ' || sqlerrm;
END get_freight_tot_qty;

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
)
IS		
   CURSOR C_FREIGHT_RATEGROUP(in_custid varchar2, in_billmethod varchar2, in_businessevent varchar2, in_effdate date)
   IS
     SELECT *
       FROM custrategroup
      WHERE custid = in_custid
        AND rategroup =
              (SELECT rategroup
                 FROM custrate
                WHERE custid = in_custid
                  AND effdate <= in_effdate
                  AND billmethod = in_billmethod
                  AND rate is null
                  AND rategroup = 
                        (SELECT rategroup
                           FROM custratewhen W
                          WHERE custid = in_custid
                            AND effdate <= in_effdate
                            AND billmethod = in_billmethod
                            AND businessevent = in_businessevent
                            AND effdate = 
                                  (SELECT max(effdate)
                                     FROM custrate
                                    WHERE custid = W.custid
                                      AND activity = W.activity
                                      AND billmethod = W.billmethod
                                      AND effdate <= in_effdate)));
BEGIN
    out_rategroup := NULL;

    OPEN C_FREIGHT_RATEGROUP(in_custid, in_billmethod, in_businessevent, in_effdate);
    FETCH C_FREIGHT_RATEGROUP INTO out_rategroup;
    CLOSE C_FREIGHT_RATEGROUP;

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'rd_freight_rategroup: ' || sqlerrm;
END rd_freight_rategroup;


----------------------------------------------------------------------
-- rd_freight_minumum
----------------------------------------------------------------------
PROCEDURE rd_freight_minumum
(
	in_tariff				IN		varchar2,
	in_activitycode			IN		varchar2,
	out_tariffaccessorials	OUT		tariffaccessorials%rowtype,
	out_errmsg				IN OUT	varchar2
)
IS		
   CURSOR C_TARIFFACCESSORIALS(in_tariff varchar2, in_activitycode varchar2)
   IS
     SELECT *
       FROM TARIFFACCESSORIALS
      WHERE tariff = in_tariff
        AND activitycode = in_activitycode;
BEGIN
    OPEN C_TARIFFACCESSORIALS(in_tariff, in_activitycode);
    FETCH C_TARIFFACCESSORIALS INTO out_tariffaccessorials;
    CLOSE C_TARIFFACCESSORIALS;

EXCEPTION WHEN OTHERS THEN
	out_errmsg :=  'rd_freight_minumum: ' || sqlerrm;
END rd_freight_minumum;

END zfreightbill;
/
show errors package body zfreightbill;
exit;