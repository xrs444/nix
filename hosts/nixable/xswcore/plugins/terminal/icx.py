from __future__ import absolute_import, division, print_function
__metaclass__ = type

import re
from ansible.plugins.terminal import TerminalBase
from ansible.errors import AnsibleConnectionFailure


class TerminalModule(TerminalBase):
    """Terminal plugin for Ruckus/Brocade ICX switches (FastIron 09.x).

    Handles prompt detection, paging disable, and enable/disable transitions
    so ansible.netcommon.cli_config can manage the device without depending on
    the deprecated community.network collection.
    """

    # Matches: SSH@xswcore#  SSH@xswcore(config)#  xswcore>
    terminal_stdout_re = [
        re.compile(rb"[\r\n]?[\w+\-.:\/\[\]]+(?:\([^\)]+\))?[>#]\s*$"),
    ]

    terminal_stderr_re = [
        re.compile(rb"% ?Error", re.IGNORECASE),
        re.compile(rb"(?:invalid input)", re.IGNORECASE),
        re.compile(rb"ERROR:"),
    ]

    def on_open_shell(self):
        try:
            self._exec_cli_command(b"skip-page-display")
        except AnsibleConnectionFailure:
            raise AnsibleConnectionFailure("unable to set terminal parameters")

    def on_become(self, passwd=None):
        prompt = self._get_prompt()
        if prompt and prompt.strip().endswith(b"#"):
            return
        if passwd:
            # _exec_cli_command does not forward prompt/answer; call send directly
            passwd_bytes = passwd.encode() if isinstance(passwd, str) else passwd
            self._connection.send(
                b"enable",
                prompt=rb"(?i)[\r\n]?password:\s*$",
                answer=passwd_bytes,
            )
        else:
            self._exec_cli_command(b"enable")

    def on_unbecome(self):
        prompt = self._get_prompt()
        if prompt is None:
            return
        if b"(config" in prompt:
            self._exec_cli_command(b"end")
        if prompt and prompt.strip().endswith(b"#"):
            self._exec_cli_command(b"disable")
