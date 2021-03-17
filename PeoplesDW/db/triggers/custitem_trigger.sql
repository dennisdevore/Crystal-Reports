CREATE OR REPLACE TRIGGER ALPS.CUSTITEM_AIU
--
-- $Id$
--
BEFORE INSERT OR UPDATE 
ON ALPS.CUSTITEM
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW 
declare
intCtoStoprefix integer;

begin

zmi3.get_cto_sto_prefix(:new.custid,:new.item,intCtoStoprefix);
if nvl(intCtoStoprefix,0) <> nvl(:new.CtoStoprefix,0) then
  :new.CtoStoprefix := intCtoStoprefix;
end if;

if (inserting) and
   (:new.entrydate is null) then
  :new.entrydate := sysdate;  
end if;

end;
/

CREATE OR REPLACE TRIGGER ALPS.CUSTITEM_AUI
--
-- $Id$
--
AFTER INSERT OR UPDATE 
ON ALPS.CUSTITEM
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW 
declare
stat integer;
begin
  stat := zqm.send('tms','ITEM',rpad(:new.custid,10)||rpad(:new.item,20),1, null);
end;
/

CREATE OR REPLACE TRIGGER ALPS.CUSTITEM_AU
--
-- $Id$
--
AFTER UPDATE 
ON ALPS.CUSTITEM
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW 
declare
l_msg varchar2(255);
begin
	if (trim(zci.default_value('PALLETSUOM')) is not null)
	then
    if ((nvl(trim(:old.sara_cas_number1),'x') <> nvl(trim(:new.sara_cas_number1),'x')) and
        (trim(:new.sara_cas_number1) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number1)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number1) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number2),'x') <> nvl(trim(:new.sara_cas_number2),'x')) and
        (trim(:new.sara_cas_number2) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number2)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number2) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number3),'x') <> nvl(trim(:new.sara_cas_number3),'x')) and
        (trim(:new.sara_cas_number3) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number3)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number3) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number4),'x') <> nvl(trim(:new.sara_cas_number4),'x')) and
        (trim(:new.sara_cas_number4) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number4)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number4) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number5),'x') <> nvl(trim(:new.sara_cas_number5),'x')) and
        (trim(:new.sara_cas_number5) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number5)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number5) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number6),'x') <> nvl(trim(:new.sara_cas_number6),'x')) and
        (trim(:new.sara_cas_number6) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number6)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number6) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number7),'x') <> nvl(trim(:new.sara_cas_number7),'x')) and
        (trim(:new.sara_cas_number7) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number7)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number7) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number8),'x') <> nvl(trim(:new.sara_cas_number8),'x')) and
        (trim(:new.sara_cas_number8) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number8)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number8) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number9),'x') <> nvl(trim(:new.sara_cas_number9),'x')) and
        (trim(:new.sara_cas_number9) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number9)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number9) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number10),'x') <> nvl(trim(:new.sara_cas_number10),'x')) and
        (trim(:new.sara_cas_number10) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number10)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number10) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number11),'x') <> nvl(trim(:new.sara_cas_number11),'x')) and
        (trim(:new.sara_cas_number11) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number11)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number11) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number12),'x') <> nvl(trim(:new.sara_cas_number12),'x')) and
        (trim(:new.sara_cas_number12) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number12)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number12) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number13),'x') <> nvl(trim(:new.sara_cas_number13),'x')) and
        (trim(:new.sara_cas_number13) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number13)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number13) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number14),'x') <> nvl(trim(:new.sara_cas_number14),'x')) and
        (trim(:new.sara_cas_number14) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number14)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number14) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number15),'x') <> nvl(trim(:new.sara_cas_number15),'x')) and
        (trim(:new.sara_cas_number15) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number15)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number15) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number16),'x') <> nvl(trim(:new.sara_cas_number16),'x')) and
        (trim(:new.sara_cas_number16) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number16)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number16) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number17),'x') <> nvl(trim(:new.sara_cas_number17),'x')) and
        (trim(:new.sara_cas_number17) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number17)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number17) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number18),'x') <> nvl(trim(:new.sara_cas_number18),'x')) and
        (trim(:new.sara_cas_number18) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number18)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number18) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number19),'x') <> nvl(trim(:new.sara_cas_number19),'x')) and
        (trim(:new.sara_cas_number19) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number19)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number19) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  
    if ((nvl(trim(:old.sara_cas_number20),'x') <> nvl(trim(:new.sara_cas_number20),'x')) and
        (trim(:new.sara_cas_number20) is not null) and
        (nvl(zci.is_valid_cas_threshold(trim(:new.sara_cas_number20)),'N') = 'Y'))
    then
      zms.log_msg('CASALERT', '', :new.custid, 'CAS Number ' || trim(:new.sara_cas_number20) ||
        ' set up for Customer ' || trim(:new.custid) || ' Item ' || trim(:new.item),
        'I', 'CASALERT', l_msg);
    end if;
  end if;

end;
/
