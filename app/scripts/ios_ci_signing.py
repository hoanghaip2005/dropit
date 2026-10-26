"""Install CI-only Apple signing material; never print credentials."""
import base64
import datetime
import json
import os
from pathlib import Path
import plistlib
import secrets
import shutil
import subprocess
import sys


ROOT = Path(os.environ['RUNNER_TEMP']) / 'dropit-signing'
BUNDLE = 'com.bakhi.dropit.dropit'
TEAM = '5MNN7PQYBD'


def command(*args, output=False):
    result = subprocess.run(args, capture_output=True)
    if result.returncode:
        # Commands can contain passwords; do not include argv/stdout in errors.
        raise RuntimeError(f'{args[0]} failed (exit {result.returncode})')
    return result.stdout if output else None


def install():
    os.umask(0o077)
    ROOT.mkdir(mode=0o700)
    keychain = ROOT / 'build.keychain-db'
    p12 = ROOT / 'distribution.p12'
    profile = ROOT / 'DropIt.mobileprovision'
    p12.write_bytes(base64.b64decode(os.environ['IOS_DISTRIBUTION_P12_BASE64'], validate=True))
    profile.write_bytes(base64.b64decode(os.environ['IOS_PROFILE_BASE64'], validate=True))
    data = plistlib.loads(command('security', 'cms', '-D', '-i', str(profile), output=True))
    entitlements = data['Entitlements']
    if data['TeamIdentifier'] != [TEAM] or entitlements['application-identifier'] != TEAM + '.' + BUNDLE:
        raise RuntimeError('Provisioning profile belongs to another team/application')
    if entitlements.get('aps-environment') != 'production' or entitlements.get('get-task-allow', False):
        raise RuntimeError('Expected production push/distribution profile')
    if data['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise RuntimeError('Provisioning profile expired')
    (ROOT / 'profile.json').write_text(json.dumps({'name': data['Name'], 'team': TEAM, 'uuid': data['UUID']}))
    original = command('security', 'list-keychains', '-d', 'user', output=True).decode()
    import shlex
    original = shlex.split(original)
    (ROOT / 'original-keychains.json').write_text(json.dumps(original))
    password = secrets.token_urlsafe(32)
    command('security', 'create-keychain', '-p', password, str(keychain))
    command('security', 'set-keychain-settings', '-lut', '21600', str(keychain))
    command('security', 'unlock-keychain', '-p', password, str(keychain))
    command('security', 'import', str(p12), '-P', os.environ['IOS_P12_PASSWORD'], '-A', '-t', 'cert', '-f', 'pkcs12', '-k', str(keychain))
    command('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, str(keychain))
    command('security', 'list-keychains', '-d', 'user', '-s', str(keychain), *original)
    locations = [Path.home() / 'Library/MobileDevice/Provisioning Profiles', Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles']
    installed = []
    for directory in locations:
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / (data['UUID'] + '.mobileprovision')
        shutil.copyfile(profile, target)
        installed.append(str(target))
    (ROOT / 'installed-profiles.json').write_text(json.dumps(installed))
    keys = ROOT / 'private_keys'
    keys.mkdir(mode=0o700)
    (keys / ('AuthKey_' + os.environ['ASC_KEY_ID'] + '.p8')).write_text(os.environ['ASC_API_KEY_P8'])
    export = {'method': 'app-store-connect', 'teamID': TEAM, 'signingStyle': 'manual', 'signingCertificate': 'Apple Distribution', 'provisioningProfiles': {BUNDLE: data['Name']}, 'uploadSymbols': True, 'manageAppVersionAndBuildNumber': False}
    (ROOT / 'ExportOptions.plist').write_bytes(plistlib.dumps(export))
    print('Installed isolated distribution signing identity and production push profile')


def cleanup():
    original = ROOT / 'original-keychains.json'
    if original.exists():
        command('security', 'list-keychains', '-d', 'user', '-s', *json.loads(original.read_text()))
    keychain = ROOT / 'build.keychain-db'
    if keychain.exists():
        command('security', 'delete-keychain', str(keychain))
    profiles = ROOT / 'installed-profiles.json'
    if profiles.exists():
        for path in json.loads(profiles.read_text()):
            Path(path).unlink(missing_ok=True)
    if ROOT.exists():
        shutil.rmtree(ROOT)


if __name__ == '__main__':
    {'install': install, 'cleanup': cleanup}[sys.argv[1]]()
