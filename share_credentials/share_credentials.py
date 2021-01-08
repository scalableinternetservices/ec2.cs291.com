#!/usr/bin/env python3
import os
import sys

from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} CREDENTIALS_PATH")
        return 1

    auth = GoogleAuth()
    auth.LocalWebserverAuth()
    drive = GoogleDrive(auth)

    directory = drive.CreateFile(
        {
            "title": "CS291A Credentials",
            "mimeType": "application/vnd.google-apps.folder",
        }
    )
    directory.Upload()

    users_file = os.path.join(sys.argv[1], "usernames.txt")
    with open(users_file) as fp:
        for line in fp:
            username = line.strip()
            email = f"{username}@ucsb.edu"
            print(email)
            pem_filename = os.path.join(
                sys.argv[1], f"{username.replace('_', '-')}.pem"
            )

            pem_file = drive.CreateFile(
                {
                    "parents": [{"id": directory["id"]}],
                    "title": os.path.basename(pem_filename),
                }
            )
            pem_file.SetContentFile(pem_filename)
            pem_file.Upload()
            pem_file.InsertPermission(
                {"role": "reader", "type": "user", "value": email}
            )


if __name__ == "__main__":
    sys.exit(main())
