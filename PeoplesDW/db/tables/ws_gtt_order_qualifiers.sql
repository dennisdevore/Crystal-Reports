create global temporary table ws_order_qualifiers (
  qualifier_type varchar2(255),
  qualifier_field varchar2(255),
  qualifier_comparison varchar2(255),
  qualifier_source varchar2(255),
  qualifier_value varchar2(255)
) on commit delete rows;