--
-- $Id$
--
CREATE OR REPLACE PACKAGE ALPS.zpack as
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
--
-- verify_carton
--
----------------------------------------------------------------------
PROCEDURE verify_carton
(
    in_carton       IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- start_a_carton
--
----------------------------------------------------------------------
PROCEDURE start_a_carton
(
    in_tote         IN      varchar2,
    in_cartonid     IN      varchar2,
    in_user         IN      varchar2,
    out_carton      OUT     varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- abandon_carton
--
----------------------------------------------------------------------
PROCEDURE abandon_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);


----------------------------------------------------------------------
--
-- pick_item_into_carton
--
----------------------------------------------------------------------
PROCEDURE pick_item_into_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_lpid         IN      varchar2,
    in_qty          IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- unpick_item
--
----------------------------------------------------------------------
PROCEDURE unpick_item
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_lpid         IN      varchar2,
    in_qty          IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- print_a_carton
--
----------------------------------------------------------------------
PROCEDURE print_a_carton
(
    in_carton       IN      varchar2,
    in_event        IN      varchar2,
    in_slbl         IN      varchar2,
    in_mlbl         IN      varchar2,
    in_llbl         IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);


----------------------------------------------------------------------
--
-- route_a_carton
--
----------------------------------------------------------------------
PROCEDURE route_a_carton
(
    in_carton       IN      varchar2,
    out_location    OUT     varchar2,
    out_type        OUT     varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- close_a_carton
--
----------------------------------------------------------------------
PROCEDURE close_a_carton
(
    in_carton       IN      varchar2,
    in_type         IN      varchar2,
    in_location     IN      varchar2,
    in_weight       IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- bind_carton
--
----------------------------------------------------------------------
PROCEDURE bind_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- unbind_carton
--
----------------------------------------------------------------------
PROCEDURE unbind_carton
(
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
);

----------------------------------------------------------------------
--
-- pick_item_into_carton_by_upc
--
----------------------------------------------------------------------
PROCEDURE pick_item_into_carton_by_upc
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_item         IN      varchar2,
    in_qty          IN      number,
	in_old_qty      IN      number,
    in_user         IN      varchar2,
	out_errnum      OUT     number,
    out_errmsg      OUT     varchar2
);

FUNCTION packing_comments
(
    in_orderid      IN      number,
    in_shipid       IN      number
)
RETURN varchar2;

FUNCTION item_packing_comments
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_item         IN      varchar2,
    in_lotnumber    IN      varchar2
)
RETURN varchar2;

PROCEDURE print_carton_pack_list
(in_orderid IN number
,in_shipid IN number
,in_cartonid IN varchar2
,in_printer IN varchar2
,in_report IN varchar2
,in_userid IN varchar2
,out_msg IN OUT varchar2
);

FUNCTION carton_packlist_format
(in_custid IN varchar2
)
RETURN varchar2;
PRAGMA RESTRICT_REFERENCES (packing_comments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_packing_comments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (carton_packlist_format, WNDS, WNPS, RNPS);

end zpack;
/

exit;
