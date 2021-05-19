#!/usr/bin/env python3
"""
This script removes volumes created by cinder csi that are
* older than 3 hours
* not attached to any node
"""
import openstack
import logging
import sys
from datetime import datetime, timedelta

def main():

    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    log = logging.getLogger(__name__)
    log.info("cleaning up orphaned volumes")

    con = openstack.connect()
    volumes = con.block_storage.volumes(details=True, status="available")

    for v in filter(filter_volumes, volumes):
        log.info("deleting volume %s", v.id)
        try:
            con.block_storage.delete_volume(v, ignore_missing=True)
        except:
            log.exception("unable to delete volume %s... skipping", v.id)
            pass

def filter_volumes(vol):
    """
    filter_volumes takes care to only clean up volumes created by cinder csi
    """
    try:
        if not vol.name.startswith("pvc-"):
            return False
        if vol.attachments:
            return False

        created = datetime.fromisoformat(vol.created_at)
        age = datetime.now() - created
        if age < timedelta(hours=3):
            return False

        cluster_name = vol.metadata.get("cinder.csi.openstack.org/cluster", "")
        if not cluster_name.startswith("kubernetes"):
            return False
    except:
        return False
    return True

if __name__ == "__main__":
    main()
