from __future__ import absolute_import, division, print_function
__metaclass__ = type

import json

from ansible_collections.ansible.netcommon.plugins.plugin_utils.cliconf_base import CliconfBase


class Cliconf(CliconfBase):
    """Cliconf plugin for Ruckus/Brocade ICX switches (FastIron 09.x).

    Thin wrapper over CliconfBase so ansible_network_os=icx resolves to this
    plugin rather than community.network.icx (which has an outdated get()
    signature missing the newline parameter).
    """

    def get_device_info(self):
        return {"network_os": "icx"}

    def get_capabilities(self):
        result = super(Cliconf, self).get_capabilities()
        result["device_operations"] = self.get_device_operations()
        return json.dumps(result)

    def get_device_operations(self):
        return {
            "supports_diff_replace": False,
            "supports_commit": False,
            "supports_rollback": False,
            "supports_defaults": False,
            "supports_onbox_diff": False,
            "supports_commit_comment": False,
            "supports_multiline_delimiter": False,
            "supports_diff_match": False,
            "supports_diff_ignore_lines": False,
            "supports_generate_diff": False,
            "supports_replace": False,
        }
