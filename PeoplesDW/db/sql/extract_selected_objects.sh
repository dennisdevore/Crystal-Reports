#!/bin/bash

SYN_PKGS="DRE_ASOFINVACTLOTPKG \
DRE_ASOFINVACTLOT2PKG"

SYN_PROCS="DRE_ASOFINVACTLOT2PROC_TEST \
DRE_ASOFINVACTLOT2PROCWS"

SYN_VIEWS="DRE_RECEIVERDTLVIEWWOZERO \
DRE_PALLETS_RECEIVED_BY_MONTH \
DRE_RECEIVERDTLVIEW_SCHRIC \
DRE_RECEIVERDTLVIEW_S \
DRE_FIFOCHECKEXP \
DRE_FIFOCHECKMFG \
DRE_FIFOCHECK \
DRE_BOLRPT_PRELIM \
DRE_BOLRPT_PRELIM2 \
DRE_BOLRPT_PRELIM2_WALIAS \
DRE_BOLRPT_PRELIM2_FRAMAN \
DRE_CUSTITEMTOTALLVIEW2_3 \
DRE_BOLRPT_PRELIM2_RAYILL \
DRE_AGGRPICKLISTVIEW \
DRE_AGGRPICKLISTVIEW_SARBAK \
DRE_CROSSDOCKSHIPPINGVIEW \
DRE_USERITEMVIEW_RAYBERN \
DRE_CUSTITEMTOTALLVIEW3 \
DRE_AGGRPICKLISTVIEW2 \
DRE_AGGRPICKLISTVIEW2_UI \
DRE_BOLRPT_PRELIM_RAYILL \
DRE_BOLRPTV_WALIAS \
DRE_BOLRPT_WALIAS \
DRE_BOLRPTV \
DRE_INVITEMRPT_DOLPAC \
DRE_CROSSDOCKRECEIPTDATEVIEW \
DRE_BURLEWVIEW_SA \
DRE_BURLEWVIEW \
DRE_ALLPLATEVIEW \
DRE_ALLPLATEVIEW_RAYBERN \
DRE_RECEIVERDTLVIEW_NESTLE \
DRE_CUSTITEMTOTVIEW3 \
DRE_AGGRPICKLISTVIEW_UI \
DRE_RECEIVERDTLVIEW_KERING \
DRE_RECEIVERDTLVIEWWOZERO_IAB \
DRE_RECEIVERDTLVIEW_FREPAH \
DRE_RECDTLVIEWWOZEROCROSS"

for SYN_PKG in ${SYN_PKGS};
do
  . ./expkg_no_syn.sh ${SYN_PKG}
done;

for SYN_PROC in ${SYN_PROCS};
do
  . ./exproc.sh ${SYN_PROC}
done;

for SYN_VIEW in ${SYN_VIEWS};
do
  . ./exview.sh ${SYN_VIEW}
done;