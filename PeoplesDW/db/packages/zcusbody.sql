CREATE OR REPLACE PACKAGE BODY zcustom
IS
--
-- $Id$
--
-- ******************************************************************
-- *                                                                *
-- *    CONSTANTS                                                   *
-- *                                                                *
-- ******************************************************************


-- ******************************************************************
-- *                                                                *
-- *    CURSORS                                                     *
-- *                                                                *
-- ******************************************************************

-- ******************************************************************
-- *                                                                *
-- *  MESSAGING FUNCTIONS                                           *
-- *                                                                *
-- ******************************************************************


----------------------------------------------------------------------
--
-- execute 
--
----------------------------------------------------------------------
PROCEDURE Execute
(
    in_event    varchar2,
    in_data     IN OUT cdata
)
IS
CURSOR C_CC
IS
SELECT *
  FROM customcode
 WHERE businessevent = in_event;

CC customcode%rowtype;
bvar boolean;
sqlcode varchar2(3000);
errmsg varchar2(255);
BEGIN
    null;
    CC := null;
    OPEN C_CC;
    FETCH C_CC into CC;
    CLOSE C_CC;

	bvar := instr(cc.code, ':DAT') > 0;

    if CC.businessevent = in_event then
      sqlcode := translate(CC.code,'A'||chr(13),'A ');
      BEGIN
      if in_data is null then
        execute immediate sqlcode;
      else
        execute immediate sqlcode using IN OUT in_data;
      end if;
      EXCEPTION WHEN OTHERS THEN
        zms.log_msg('CustomEx','','',
           'Custom Execution Failed for '||in_event||' : '|| sqlerrm, 
            'E', 'CUSTOM',errmsg);
      END;
    end if;

END Execute;


FUNCTION init_cdata
return cdata
IS
    TD cdata;
BEGIN
    TD := cdata(null,null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,
                null,null);
    return TD;

END;


----------------------------------------------------------------------
--
-- ship_order - invoke custom code for shipping an order
--
----------------------------------------------------------------------
PROCEDURE ship_order
(
    in_orderid  number,
    in_shipid   number
)
IS
l_cd cdata;
BEGIN
    l_cd := init_cdata;
    l_cd.orderid := in_orderid;
    l_cd.shipid := in_shipid;
    execute('SHIP',l_cd);

END ship_order;

----------------------------------------------------------------------
--
-- fetch_prepick_load - invoke custom code for fetching prepicked pallets
--                      for a load
--
----------------------------------------------------------------------
PROCEDURE fetch_prepick_load
(
    in_loadno   number
)
IS
l_cd cdata;
BEGIN
    l_cd := init_cdata;
    l_cd.loadno := in_loadno;
    execute('FPPP',l_cd);

END fetch_prepick_load;


----------------------------------------------------------------------
--
-- multiship_process
--
----------------------------------------------------------------------
PROCEDURE multiship_process
(
    in_cartonid varchar2
)
IS
l_cd cdata;
BEGIN
    l_cd := init_cdata;
    l_cd.lpid := in_cartonid;
    l_cd.userid := 'MULTISHIP';
    execute('MSPC',l_cd);

END multiship_process;


------------------------------------------------------------------------
--
-- PACKAGE INITIALIZATION CODE
--
------------------------------------------------------------------------



-- None

END zcustom;
/
-- exit;
