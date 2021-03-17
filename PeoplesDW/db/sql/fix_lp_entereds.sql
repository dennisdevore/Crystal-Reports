--
-- $Id$
--
alter trigger plate_bu disable;
alter trigger plate_aiud disable;

update plate
	set qtyentered = quantity,
   	 uomentered = unitofmeasure
	where type = 'PA'
     and (nvl(qtyentered, 0) = 0 or uomentered is null);

commit;

alter trigger plate_bu enable;
alter trigger plate_aiud enable;

exit;
