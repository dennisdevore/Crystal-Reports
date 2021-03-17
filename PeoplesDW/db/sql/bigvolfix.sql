--
-- $Id$
--
spool bigvolfix
set serveroutput on;
declare
   orderid number;
   out_errorno integer;
   out_msg varchar2(255);
   strMsg varchar2(255);
begin
   for orderid in 3424614 .. 3459908 loop
      if orderid in (3424614, 3426914, 3426915, 3426916, 3426917, 3426918, 3426919,
                     3429338, 3429372, 3429373, 3431560, 3431561, 3431562, 3432042,
                     3432657, 3432658, 3432659, 3432660, 3432661, 3432662, 3432663,
                     3432664, 3432665, 3432666, 3432667, 3432668, 3432677, 3432684,
                     3438354, 3440531, 3440593, 3440594, 3440597, 3440598, 3441445,
                     3441450, 3441451, 3441457, 3441462, 3441465, 3441470, 3441542,
                     3441563, 3442576, 3442577, 3442579, 3442580, 3442581, 3442582,
                     3442583, 3442586, 3442587, 3442589, 3442593, 3442594, 3442599,
                     3442601, 3442602, 3442605, 3442607, 3442609, 3442610, 3442613,
                     3444656, 3446476, 3446477, 3446478, 3446479, 3446480, 3446484,
                     3446486, 3446487, 3446488, 3446490, 3446491, 3446492, 3446495,
                     3446499, 3446500, 3446503, 3446504, 3446520, 3446522, 3446523,
                     3446524, 3446526, 3446527, 3446528, 3446529, 3446532, 3449444,
                     3449453, 3449454, 3449455, 3449876, 3449877, 3449878, 3449895,
                     3449897, 3449904, 3449906, 3449907, 3449908, 3449909, 3449912,
                     3449913, 3449914, 3449915, 3450479, 3450490, 3450492, 3450586,
                     3450588, 3450601, 3450605, 3450606, 3450610, 3450611, 3450614,
                     3450617, 3450620, 3450623, 3450685, 3450686, 3450691, 3450715,
                     3450729, 3450743, 3450744, 3454210, 3454798, 3454807, 3454810,
                     3454811, 3454812, 3454814, 3454817, 3454829, 3455501, 3455502,
                     3455504, 3455509, 3455516, 3455524, 3455524, 3455524, 3455534,
                     3455535, 3455536, 3455547, 3456005, 3456021, 3456026, 3456035,
                     3456053, 3456144, 3456239, 3456240, 3456244, 3456248, 3456249,
                     3456253, 3456254, 3456256, 3456258, 3456590, 3456596, 3456602,
                     3456604, 3456615, 3456619, 3456622, 3456623, 3456624, 3456634,
                     3456639, 3456640, 3458619, 3459534, 3459535, 3459536, 3459908) then

         ziem.impexp_request('E', null, '17200', 'Vollrath Ship Notification', null,
               'NOW', 0, orderid, 1, 'BRIANB', null, null, null, 'ALL', 'ALL', null,
               null, out_errorno, out_msg);

         if out_errorno != 0 then
            zut.prt('Error on order ' || orderid || ' errorno: ' || out_errorno);
            zut.prt('   out_msg: ' || substr(out_msg, 1, 200));
            zms.log_msg('IMPEXP', null, null, out_msg, 'E', 'SCRIPT', strMsg);
         else
            zut.prt('OK for order ' || orderid);
         end if;

      end if;
   end loop;
end;
/
exit;