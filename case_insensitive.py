import os

def exists_nocase(path):
    if os.path.exists(path):
        return True
    path = os.path.normpath(os.path.realpath(os.path.abspath(unicode(path)))).upper()
    parts = path.split(os.sep)
    path = unicode(os.path.join(unicode(os.path.splitdrive(path)[0]), os.sep))
    for name in parts:
        if not name:
            continue
        # this is a naive and insane way to do case-insensitive string comparisons:
        entries = dict((entry.upper(), entry) for entry in os.listdir(path))
        if name in entries:
            path = os.path.join(path, entries[name])
        else:
            return False
    return True

print exists_nocase("/ETC/ANYTHING")
print exists_nocase("/ETC/PASSWD")
