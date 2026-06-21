import os
import tempfile


def save_upload_file(upload_file):
    suffix = os.path.splitext(upload_file.filename)[1] or '.wav'
    fd, path = tempfile.mkstemp(suffix=suffix)
    with os.fdopen(fd, 'wb') as destination:
        destination.write(upload_file.file.read())
    return path
