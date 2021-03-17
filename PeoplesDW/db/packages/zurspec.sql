--
-- $Id$
--
create or replace package alps.zursa as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
URSA_DEFAULT_QUEUE   CONSTANT    varchar2(10) := 'ursa';

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
--
-- check_order_address
--
----------------------------------------------------------------------
PROCEDURE check_order_address
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    in_userid       IN  varchar2,
    out_errmsg      OUT varchar2
);

----------------------------------------------------------------------
--
-- check_address
--
----------------------------------------------------------------------
PROCEDURE check_address
(
    in_userid       IN  varchar2,
    in_city         IN  varchar2,
    in_state        IN  varchar2,
    in_postalcode   IN  varchar2,
    in_service      IN  varchar2,
    in_special      IN  varchar2,
    out_errmsg      OUT varchar2
);

----------------------------------------------------------------------
--
-- clear_ursa_response
--
----------------------------------------------------------------------
PROCEDURE clear_ursa_response
(
    out_errmsg      OUT varchar2
);


----------------------------------------------------------------------
--
-- ursa_response
--
----------------------------------------------------------------------
PROCEDURE ursa_response
(
    in_queue        IN  varchar2,
    out_errmsg      OUT varchar2
);

----------------------------------------------------------------------
--
-- send_response
--
----------------------------------------------------------------------
PROCEDURE send_response
(
    in_queue        IN  varchar2,
    in_msg          IN  varchar2,
    out_errmsg      OUT varchar2
);

----------------------------------------------------------------------
--
-- get_request
--
----------------------------------------------------------------------
PROCEDURE get_request
(
    out_userid      OUT varchar2,
    out_city        OUT varchar2,
    out_state       OUT varchar2,
    out_postalcode  OUT varchar2,
    out_service     OUT varchar2,
    out_special     OUT varchar2,
    out_queue       OUT varchar2,
    out_errmsg      OUT varchar2
);


end zursa;
/

-- exit;
