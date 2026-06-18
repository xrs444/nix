from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible_collections.community.network.plugins.cliconf.icx import Cliconf as IcxCliconfBase


class Cliconf(IcxCliconfBase):
    """Cliconf plugin for Ruckus/Brocade ICX switches (FastIron 09.x).

    Inherits the full ICX implementation from community.network but fixes
    get() to accept the 'newline' parameter added in newer ansible.netcommon,
    which the community.network version is missing.
    """

    def get(self, command=None, prompt=None, answer=None, sendonly=False,
            newline=True, output=None, check_all=False):
        return super(Cliconf, self).get(
            command=command,
            prompt=prompt,
            answer=answer,
            sendonly=sendonly,
            output=output,
            check_all=check_all,
        )
