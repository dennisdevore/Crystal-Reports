--
-- $Id$
--
create or replace PACKAGE zcustom
IS


----------------------------------------------------------------------
--
-- execute 
--
----------------------------------------------------------------------
PROCEDURE Execute
(
    in_event    varchar2,
    in_data     IN OUT cdata
);


FUNCTION init_cdata
return cdata;

----------------------------------------------------------------------
--
-- ship_order - invoke custom code for shipping an order
--
----------------------------------------------------------------------
PROCEDURE ship_order
(
    in_orderid  number,
    in_shipid   number
);

----------------------------------------------------------------------
--
-- fetch_prepick_load - invoke custom code for fetching prepicked pallets
--                      for a load
--
----------------------------------------------------------------------
PROCEDURE fetch_prepick_load
(
    in_loadno   number
);

----------------------------------------------------------------------
--
-- multiship_process
--
----------------------------------------------------------------------
PROCEDURE multiship_process
(
    in_cartonid varchar2
);


END zcustom;
/
-- exit;
