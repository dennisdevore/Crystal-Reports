update custitem
   set lotrequired = 'C'
 where lotrequired is null;
update custitem
   set serialrequired = 'C'
 where serialrequired is null;
update custitem
   set user1required = 'C'
 where user1required is null;
update custitem
   set user2required = 'C'
 where user2required is null;
update custitem
   set user3required = 'C'
 where user3required is null;
update custitem
   set mfgdaterequired = 'C'
 where mfgdaterequired is null;
 update custitem
    set expdaterequired = 'C'
  where expdaterequired is null;
update custitem
   set countryrequired = 'C'
 where countryrequired is null;
update custitem
   set allowsub = 'C'
 where allowsub is null;
update custitem
   set backorder = 'C'
 where backorder is null;
update custitem
   set hazardous = 'N'
 where hazardous is null;
update custitem
   set invstatusind = 'C'
 where invstatusind is null;
update custitem
   set invclassind = 'C'
 where invclassind is null;
update custitem
   set qtytype = 'C'
 where qtytype is null;
update custitem
   set velocity = 'C'
 where velocity is null;
update custitem
   set recvinvstatus = 'AV'
 where recvinvstatus is null;
update custitem
   set weightcheckrequired = 'C'
 where weightcheckrequired is null;
update custitem
   set ordercheckrequired = 'C'
 where ordercheckrequired is null;
update custitem
   set fifowindowdays = 0
 where fifowindowdays is null;
update custitem
   set putawayconfirmation = 'C'
 where putawayconfirmation is null;
update custitem
   set nodamaged = 'C'
 where nodamaged is null;
update custitem
   set iskit = 'N'
 where iskit is null;
update custitem
   set picktotype = 'PAL'
 where picktotype is null;
update custitem
   set subslprsnrequired = 'C'
 where subslprsnrequired is null;
update custitem
   set lotsumreceipt = 'N'
 where lotsumreceipt is null;
update custitem
   set lotsumrenewal = 'N'
 where lotsumrenewal is null;
update custitem
   set lotsumbol = 'N'
 where lotsumbol is null;
update custitem
   set lotsumaccess = 'N'
 where lotsumaccess is null;
update custitem
   set lotfmtaction = 'C'
 where lotfmtaction is null;
update custitem
   set serialfmtaction = 'C'
 where serialfmtaction is null;
update custitem
   set user1fmtaction = 'C'
 where user1fmtaction is null;
update custitem
   set user2fmtaction = 'C'
 where user2fmtaction is null;
update custitem
   set user3fmtaction = 'C'
 where user3fmtaction is null;
update custitem
   set maxqtyof1 = 'C'
 where maxqtyof1 is null;
update custitem
   set rategroup = 'C'
 where rategroup is null;
update custitem
   set serialasncapture = 'C'
 where serailasncapture is null;
update custitem
   set user1asncapture = 'C'
 where user1asncapture is null;
update custitem
   set user2asncapture = 'C'
 where user2asncapture is null;
update custitem
   set user3asncapture = 'C'
 where user3asncapture is null;
update custitem
   set needs_review_yn = 'N'
 where needs_review_yn is null;
update custitem
   set use_fifo = 'C'
 where use_fifo is null;
update custitem
   set printmsds = 'N'
 where printmsds is null;
update custitem
   set allow_uom_chgs = 'N'
 where allow_uom_chgs is null;
update custitem
   set require_cyclecount_item = 'N'
 where require_cyclecount_item is null;
update custitem
   set variancepct_use_default = 'Y'
 where variancepct_use_default is null;
update custitem
   set use_min_units_qty = 'C'
 where use_min_units_qty is null;
update custitem
   set use_multiple_units_qty = 'C'
 where use_multiple_units_qty is null;
update custitem
   set prtlps_on_load_arrival = 'C'
 where prtlps_on_load_arrival is null;
update custitem
   set system_generated_lps = 'C'
 where system_generated_lps is null;
update custitem
   set allow_component_overpicking = 'N'
 where allow_component_overpicking is null;
update custitem
   set require_phyinv_item = 'N'
 where require_phyinv_item is null;
update custitem
   set treat_labeluom_separate = 'N'
 where treat_labeluom_separate is null;
update custitem
   set require_cyclecount_lot = 'Y'
 where require_cyclecount_lot is null;
update custitem
   set require_phyinv_lot = 'Y'
 where require_phyinv_lot is null;
