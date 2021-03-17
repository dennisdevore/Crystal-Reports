update systemdefaults
set defaultvalue = '9999',
    lastuser = 'SYNAPSE',
    lastupdate = sysdate
where defaultid = 'MIN0QTYSUSPENSEWEIGHT'
and defaultvalue != '9999';
exit;
