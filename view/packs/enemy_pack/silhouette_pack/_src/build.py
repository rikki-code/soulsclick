import os
import sys

from rigkit import PACK

which = sys.argv[1:] or ["grunt", "knight", "warden", "hound", "dancer", "bulwark"]
for name in which:
    mod = __import__(name)
    mod.build(os.path.join(PACK, name))
    print("built", name)
