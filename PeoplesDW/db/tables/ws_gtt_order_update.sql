create global temporary table ws_order_updates (
  order_field varchar2(255),
  order_type varchar2(255),
  order_value varchar2(255)
) on commit delete rows;