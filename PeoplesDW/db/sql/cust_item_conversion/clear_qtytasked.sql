update plate
   set qtytasked = 0
 where custid = '511009'
   and nvl(qtytasked,0) != 0;
exit;
