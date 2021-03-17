--
-- $Id$
--
set serveroutput on;

declare

  curTest asofinvactpkg.aoih_type;
  aoh curTest%rowtype;

begin

 asofinvactproc(curTest,
   'HP','ZC',
   to_date('20020101','yyyymmdd'),
   to_date('20030101','yyyymmdd'));

 if not curTest%isopen then
   zut.prt('cursor is NOT opened');
 else
   zut.prt('cursor is open');
 end if;

 fetch curTest into aoh;
 while curTest%found
 loop
   zut.prt(aoh.item || ' ' || aoh.trantype || ' ' ||
     aoh.effdate || ' ' || aoh.invstatus || ' ' ||
     aoh.inventoryclass || ' ' || aoh.qty);
   fetch curTest into aoh;
 end loop;
 close curTest;
 zut.prt('cursor is closed');
exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
