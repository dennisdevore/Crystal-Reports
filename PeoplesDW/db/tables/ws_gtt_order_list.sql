create global temporary table ws_order_list (
  orderid number,
  shipid number
) on commit delete rows;