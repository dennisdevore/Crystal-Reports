create or replace trigger multishiphdrhist_aiu
after insert or update or delete
on multishiphdr
for each row
begin
   if deleting then
	   insert into multishiphdrhistory
		   (whenoccurred, rid, orderid, shipid, custid, shiptoname, shiptocontact, shiptoaddr1,
		      shiptoaddr2, shiptocity, shiptostate, shiptopostalcode, shiptocountrycode,
		      shiptophone, carrier, carriercode, specialservice1, specialservice2,
		      specialservice3, specialservice4, terms, satdelivery, orderstatus, orderpriority,
		      ordercomments, reference, cod, amtcod, hdrpassthruchar20, hdrpassthruchar19,
		      shipdate, po, hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03,
		      hdrpassthruchar04, hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07,
		      hdrpassthruchar08, hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11,
		      hdrpassthruchar12, hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15,
		      hdrpassthruchar16, hdrpassthruchar17, hdrpassthruchar18, hdrpassthrunum01,
		      hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04, hdrpassthrunum05,
		      hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08, hdrpassthrunum09,
		      hdrpassthrunum10, hdrpassthrudate01, hdrpassthrudate02, hdrpassthrudate03,
		      hdrpassthrudate04, hdrpassthrudoll01, hdrpassthrudoll02, hdrpassthruchar21,
		      hdrpassthruchar22, hdrpassthruchar23, hdrpassthruchar24, hdrpassthruchar25,
		      hdrpassthruchar26, hdrpassthruchar27, hdrpassthruchar28, hdrpassthruchar29,
		      hdrpassthruchar30, hdrpassthruchar31, hdrpassthruchar32, hdrpassthruchar33,
		      hdrpassthruchar34, hdrpassthruchar35, hdrpassthruchar36, hdrpassthruchar37,
		      hdrpassthruchar38, hdrpassthruchar39, hdrpassthruchar40)
	   values
		   (systimestamp, :old.rowid, :old.orderid, :old.shipid, :old.custid, :old.shiptoname, :old.shiptocontact, :old.shiptoaddr1,
		      :old.shiptoaddr2, :old.shiptocity, :old.shiptostate, :old.shiptopostalcode, :old.shiptocountrycode,
		      :old.shiptophone, :old.carrier, :old.carriercode, :old.specialservice1, :old.specialservice2,
		      :old.specialservice3, :old.specialservice4, :old.terms, :old.satdelivery, :old.orderstatus, :old.orderpriority,
		      :old.ordercomments, :old.reference, :old.cod, :old.amtcod, :old.hdrpassthruchar20, :old.hdrpassthruchar19,
		      :old.shipdate, :old.po, :old.hdrpassthruchar01, :old.hdrpassthruchar02, :old.hdrpassthruchar03,
		      :old.hdrpassthruchar04, :old.hdrpassthruchar05, :old.hdrpassthruchar06, :old.hdrpassthruchar07,
		      :old.hdrpassthruchar08, :old.hdrpassthruchar09, :old.hdrpassthruchar10, :old.hdrpassthruchar11,
		      :old.hdrpassthruchar12, :old.hdrpassthruchar13, :old.hdrpassthruchar14, :old.hdrpassthruchar15,
		      :old.hdrpassthruchar16, :old.hdrpassthruchar17, :old.hdrpassthruchar18, :old.hdrpassthrunum01,
		      :old.hdrpassthrunum02, :old.hdrpassthrunum03, :old.hdrpassthrunum04, :old.hdrpassthrunum05,
		      :old.hdrpassthrunum06, :old.hdrpassthrunum07, :old.hdrpassthrunum08, :old.hdrpassthrunum09,
		      :old.hdrpassthrunum10, :old.hdrpassthrudate01, :old.hdrpassthrudate02, :old.hdrpassthrudate03,
		      :old.hdrpassthrudate04, :old.hdrpassthrudoll01, :old.hdrpassthrudoll02, :old.hdrpassthruchar21,
		      :old.hdrpassthruchar22, :old.hdrpassthruchar23, :old.hdrpassthruchar24, :old.hdrpassthruchar25,
		      :old.hdrpassthruchar26, :old.hdrpassthruchar27, :old.hdrpassthruchar28, :old.hdrpassthruchar29,
		      :old.hdrpassthruchar30, :old.hdrpassthruchar31, :old.hdrpassthruchar32, :old.hdrpassthruchar33,
		      :old.hdrpassthruchar34, :old.hdrpassthruchar35, :old.hdrpassthruchar36, :old.hdrpassthruchar37,
		      :old.hdrpassthruchar38, :old.hdrpassthruchar39, :old.hdrpassthruchar40);
   else
	   insert into multishiphdrhistory
		   (whenoccurred, rid, orderid, shipid, custid, shiptoname, shiptocontact, shiptoaddr1,
		      shiptoaddr2, shiptocity, shiptostate, shiptopostalcode, shiptocountrycode,
		      shiptophone, carrier, carriercode, specialservice1, specialservice2,
		      specialservice3, specialservice4, terms, satdelivery, orderstatus, orderpriority,
		      ordercomments, reference, cod, amtcod, hdrpassthruchar20, hdrpassthruchar19,
		      shipdate, po, hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03,
		      hdrpassthruchar04, hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07,
		      hdrpassthruchar08, hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11,
		      hdrpassthruchar12, hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15,
		      hdrpassthruchar16, hdrpassthruchar17, hdrpassthruchar18, hdrpassthrunum01,
		      hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04, hdrpassthrunum05,
		      hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08, hdrpassthrunum09,
		      hdrpassthrunum10, hdrpassthrudate01, hdrpassthrudate02, hdrpassthrudate03,
		      hdrpassthrudate04, hdrpassthrudoll01, hdrpassthrudoll02, hdrpassthruchar21,
		      hdrpassthruchar22, hdrpassthruchar23, hdrpassthruchar24, hdrpassthruchar25,
		      hdrpassthruchar26, hdrpassthruchar27, hdrpassthruchar28, hdrpassthruchar29,
		      hdrpassthruchar30, hdrpassthruchar31, hdrpassthruchar32, hdrpassthruchar33,
		      hdrpassthruchar34, hdrpassthruchar35, hdrpassthruchar36, hdrpassthruchar37,
		      hdrpassthruchar38, hdrpassthruchar39, hdrpassthruchar40)
	   values
		   (systimestamp, :new.rowid, :new.orderid, :new.shipid, :new.custid, :new.shiptoname, :new.shiptocontact, :new.shiptoaddr1,
		      :new.shiptoaddr2, :new.shiptocity, :new.shiptostate, :new.shiptopostalcode, :new.shiptocountrycode,
		      :new.shiptophone, :new.carrier, :new.carriercode, :new.specialservice1, :new.specialservice2,
		      :new.specialservice3, :new.specialservice4, :new.terms, :new.satdelivery, :new.orderstatus, :new.orderpriority,
		      :new.ordercomments, :new.reference, :new.cod, :new.amtcod, :new.hdrpassthruchar20, :new.hdrpassthruchar19,
		      :new.shipdate, :new.po, :new.hdrpassthruchar01, :new.hdrpassthruchar02, :new.hdrpassthruchar03,
		      :new.hdrpassthruchar04, :new.hdrpassthruchar05, :new.hdrpassthruchar06, :new.hdrpassthruchar07,
		      :new.hdrpassthruchar08, :new.hdrpassthruchar09, :new.hdrpassthruchar10, :new.hdrpassthruchar11,
		      :new.hdrpassthruchar12, :new.hdrpassthruchar13, :new.hdrpassthruchar14, :new.hdrpassthruchar15,
		      :new.hdrpassthruchar16, :new.hdrpassthruchar17, :new.hdrpassthruchar18, :new.hdrpassthrunum01,
		      :new.hdrpassthrunum02, :new.hdrpassthrunum03, :new.hdrpassthrunum04, :new.hdrpassthrunum05,
		      :new.hdrpassthrunum06, :new.hdrpassthrunum07, :new.hdrpassthrunum08, :new.hdrpassthrunum09,
		      :new.hdrpassthrunum10, :new.hdrpassthrudate01, :new.hdrpassthrudate02, :new.hdrpassthrudate03,
		      :new.hdrpassthrudate04, :new.hdrpassthrudoll01, :new.hdrpassthrudoll02, :new.hdrpassthruchar21,
		      :new.hdrpassthruchar22, :new.hdrpassthruchar23, :new.hdrpassthruchar24, :new.hdrpassthruchar25,
		      :new.hdrpassthruchar26, :new.hdrpassthruchar27, :new.hdrpassthruchar28, :new.hdrpassthruchar29,
		      :new.hdrpassthruchar30, :new.hdrpassthruchar31, :new.hdrpassthruchar32, :new.hdrpassthruchar33,
		      :new.hdrpassthruchar34, :new.hdrpassthruchar35, :new.hdrpassthruchar36, :new.hdrpassthruchar37,
		      :new.hdrpassthruchar38, :new.hdrpassthruchar39, :new.hdrpassthruchar40);
   end if;
end;
/
show error trigger multishiphdrhist_aiu;

exit;
