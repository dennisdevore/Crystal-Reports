create or replace package ws_inventory
as

  -- ERROR MESSAGES --
  REQUIRE_CUSTOMER          CONSTANT varchar2(50) := 'customer required';
  REQUIRE_FACILITY          CONSTANT varchar2(50) := 'facility required';
  REQUIRE_ITEM              CONSTANT varchar2(50) := 'item required';
  REQUIRE_INV_STATUS        CONSTANT varchar2(50) := 'inventory status required';
  REQUIRE_INV_CLASS         CONSTANT varchar2(50) := 'inventory class required';
  
  -- FUNCTIONS AND PROCEDURES --
  function get_customer_product_groups (p_custid in varchar2) return sys_refcursor;
  
  function get_customer_items (p_custid in varchar2) return sys_refcursor;
  
  function get_inventory(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
    p_product_group in varchar2, p_item_exp in varchar2,
    p_item_string in varchar2, p_specific_item in varchar2) return sys_refcursor;
    
  function get_inventory_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor;
  
  function get_committed_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2, p_lot in varchar2,
    p_invstatus in varchar2, p_invclass in varchar2) return sys_refcursor;
    
  function get_picknotship_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2, p_lot in varchar2,
    p_invstatus in varchar2, p_invclass in varchar2) return sys_refcursor;

end ws_inventory;
/

show error package ws_inventory;
exit;