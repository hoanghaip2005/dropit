#!/usr/bin/env python3
import datetime, pathlib, subprocess, tempfile, boto3
bucket='dropit-backups-303278700480-sg'
root=pathlib.Path('/etc/dropit');key=root/'backup.key'
if not key.exists():
 import secrets
 key.write_text(secrets.token_hex(32));key.chmod(0o600)
with tempfile.TemporaryDirectory(prefix='dropit-backup-') as work:
 work=pathlib.Path(work)
 with (work/'database.dump').open('wb') as out:
  subprocess.run(['sudo','-u','postgres','pg_dump','-Fc','dropit'],stdout=out,check=True)
 # pg_restore validation of archive catalog; full restore test remains required.
 subprocess.run(['pg_restore','-l',str(work/'database.dump')],stdout=subprocess.DEVNULL,check=True)
 subprocess.run(['tar','-czf',str(work/'snapshot.tar.gz'),'-C',str(work),'database.dump','-C','/opt/dropit/shared','uploads','-C','/etc/dropit','backend.env'],check=True)
 encrypted=work/'snapshot.enc'
 subprocess.run(['openssl','enc','-aes-256-cbc','-salt','-pbkdf2','-iter','200000','-in',str(work/'snapshot.tar.gz'),'-out',str(encrypted),'-pass','file:'+str(key)],check=True)
 s3=boto3.client('s3',region_name='ap-southeast-1')
 now=datetime.datetime.now(datetime.timezone.utc)
 name=now.strftime('%Y-%m-%dT%H%M%SZ')+'.enc'
 s3.upload_file(str(encrypted),bucket,'daily/'+name)
 if now.weekday()==6:s3.upload_file(str(encrypted),bucket,'weekly/'+name)
 for prefix,keep in [('daily/',7),('weekly/',2)]:
  objects=[]
  for page in s3.get_paginator('list_objects_v2').paginate(Bucket=bucket,Prefix=prefix):objects.extend(page.get('Contents',[]))
  for item in sorted(objects,key=lambda x:x['Key'],reverse=True)[keep:]:s3.delete_object(Bucket=bucket,Key=item['Key'])
 print('Encrypted backup uploaded; archive catalog valid; full restore not yet verified')
