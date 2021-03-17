alter table carrier
add(
notifyonreceiptclose            CHAR(1) DEFAULT 'N',
notifyonreceiptcloseBODY        CLOB DEFAULT empty_clob(),
notifyonreceiptcloseFROM        VARCHAR2(255),
notifyonreceiptcloseTO          VARCHAR2(255),
notifyonshipclose           CHAR(1) DEFAULT 'N',
notifyonshipcloseBODY       CLOB DEFAULT empty_clob(),
notifyonshipcloseFROM       VARCHAR2(255),
notifyonshipcloseTO         VARCHAR2(255)
);

exit;