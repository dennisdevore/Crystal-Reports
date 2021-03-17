update appmsgs
set msgtype='T'
where author='WAVERELEASE'
and msgtype='D';

update appmsgs
set msgtype='I'
where author='LOADCLOSE'
and msgtype='D';

update appmsgs
set msgtype='W'
where author='REGENPICK'
and msgtype='D';

update appmsgs
set msgtype='I'
where author='BATCHALLOC'
and msgtype='D';

