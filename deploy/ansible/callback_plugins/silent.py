from ansible import constants as C
from ansible.plugins.callback.default import (
    CallbackModule as DefaultCallback,
    DOCUMENTATION as DEFAULT_DOCUMENTATION,
)

# Reuse default callback's documentation so get_option() works
DOCUMENTATION = DEFAULT_DOCUMENTATION

#
# Silent Output Control Tags
#
#   silent_v[N]
#
# Example:
#
#   tags:
#     - silent_v1
#
# The use of a silent tag suppresses normal task output up to and including
# the verbosity level specified in the tag. To render the default Ansible
# output, the verbosity level must be set at least one level higher than
# the silent tag.
#
# For example:
#   silent_v1 requires a verbosity of 2 (-vv) or higher to display
#   the normal task output.
#
# Loop Behavior:
#
# When applied to a task that includes a loop, the loop detail level is
# automatically set to task_level + 1.
#
# Verbosity interaction (e.g. silent_v1):
#
#   verbosity <= 1 (task level):
#       loop summary is displayed (ok/changed/skipped counts)
#
#   verbosity == 2 (task level + 1):
#       per-item loop status headers are displayed
#
#   verbosity >= 3 (above loop level):
#       full default Ansible output is displayed
#
#
#                   Verbosity levels (e.g. silent_v1):
#                   0       1       2       3
#   Task summary    x       x       -       -
#   Loop Header     -       -       x       -
#   Details         -       -       -       x
#
#   if verbosity <= task:          show task summary only
#   if verbosity = task + 1:       show loop header only
#   if verbosity > task + 1:       show everything as normal
#   if no silent tags:             show everything as normal
#




class CallbackModule(DefaultCallback):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'silent'


    # ----------------------------------+---------------------------------------
    def __init__(self):
        super().__init__()
        self._loop_summary = {}
        self._silent_task_prefix = "silent_v"


    # ----------------------------------+---------------------------------------
    @staticmethod
    def _verbosity_hint(level):
        """Return a -v string for the given verbosity level (e.g. 2 -> '-vv')."""
        return '-' + 'v' * level if level > 0 else '(default)'


    # ----------------------------------+---------------------------------------
    def _display_ok_header_only(self, result, changed: bool = False, required_verbosity: int = 1):
        # Use the same host labeling as default (includes delegation like "x -> localhost")
        host_label = self.host_label(result)

        hint = self._verbosity_hint(required_verbosity)
        suppressed = f"Output suppressed by silent tag, use {hint} to see details"
        msg = ("changed: [%s] => [%s]" if changed else "ok: [%s] => [%s]") % (host_label, suppressed)
        color = C.COLOR_CHANGED if changed else C.COLOR_OK

        self._display.display(msg, color=color)


    # ----------------------------------+---------------------------------------
    def _display_item_ok_header_only(self, result, changed: bool = False, required_verbosity: int = 1):
        host_label = self.host_label(result)
        status = "changed" if changed else "ok"
        color = C.COLOR_CHANGED if changed else C.COLOR_OK

        hint = self._verbosity_hint(required_verbosity)

        # Default callback uses _get_item_label() for "(item=...)" formatting
        try:
            item_label = self._get_item_label(result._result)
        except Exception:
            item_label = result._result.get("item", None)

        if item_label is None:
            self._display.display(f"{status}: [{host_label}] => use {hint} to see details", color=color)
        else:
            self._display.display(f"{status}: [{host_label}] => (item={item_label}) => use {hint} to see details", color=color)


    # ----------------------------------+---------------------------------------
    def _silent_level(self, tags):
        """Return the min verbosity threshold from matching silent_v tags, or -1 if none match."""
        levels = []
        for tag in tags:
            if tag.startswith(self._silent_task_prefix):
                try:
                    levels.append(int(tag[len(self._silent_task_prefix):]))
                except ValueError:
                    pass
        return min(levels) if levels else -1


    # ----------------------------------+---------------------------------------
    def v2_playbook_on_task_start(self, task, is_conditional):
        # Let DefaultCallback do its normal caching/state
        super().v2_playbook_on_task_start(task, is_conditional)

        # Force the TASK [...] banner to be shown even if results are silenced
        # Avoid duplicate banners
        if self._last_task_banner != task._uuid:
            self._print_task_banner(task)


    # ----------------------------------+---------------------------------------
    def v2_runner_on_ok(self, result, **kwargs):
        """Called when a task succeeds."""

        tags = set(getattr(result._task, "tags", []) or [])
        verbosity = getattr(self._display, "verbosity", 0)
        required_task_level = self._silent_level(tags)  # Find which silent tags apply (if any)

        # Check for a loop summary accumulated by v2_runner_item_on_ok/skipped
        task_id = result._task._uuid
        host_name = result._host.get_name()
        summary_key = (task_id, host_name)
        if required_task_level >= 0 and getattr(result._task, "loop", None) and summary_key in self._loop_summary:
            summary = self._loop_summary.pop(summary_key)                       # remove so it doesn't leak into future tasks
            host_label = self.host_label(result)

            # choose color: changed wins
            color = C.COLOR_CHANGED if summary["changed"] > 0 else C.COLOR_OK

            # minimal one-line summary
            loop_hint = self._verbosity_hint(required_task_level + 2)
            header_hint = self._verbosity_hint(required_task_level + 1)
            msg = f"ok: [{host_label}] => {summary['ok']} ok, {summary['changed']} changed, {summary['skipped']} skipped => use {header_hint} for loop headers, {loop_hint} for details"
            self._display.display(msg, color=color)
            return None

        # If no silent tags, behave exactly like default
        if required_task_level < 0:
            return super().v2_runner_on_ok(result, **kwargs)

        if verbosity > required_task_level:
            return super().v2_runner_on_ok(result, **kwargs)

        # Otherwise: print ONLY the header line
        changed = bool(result._result.get("changed", False))
        self._display_ok_header_only(result, changed=changed, required_verbosity=required_task_level + 1)

        # else: suppress output by doing nothing
        return None


    # ----------------------------------+---------------------------------------
    def v2_runner_item_on_ok(self, result, **kwargs):
        tags = set(getattr(result._task, "tags", []) or [])
        verbosity = getattr(self._display, "verbosity", 0)
        required_task_level = self._silent_level(tags)
        required_loop_level = required_task_level + 1 if required_task_level >= 0 else -1

        # No silent tags => default behavior
        if required_task_level < 0 and required_loop_level < 0:
            return super().v2_runner_item_on_ok(result, **kwargs)

        # If verbosity is high enough to show details, show everything as normal
        if verbosity > required_task_level and verbosity > required_loop_level:
            return super().v2_runner_item_on_ok(result, **kwargs)

        # Silent at this verbosity => header-only per loop item
        if verbosity > required_task_level and verbosity <= required_loop_level:
            changed = bool(result._result.get("changed", False))
            self._display_item_ok_header_only(result, changed=changed, required_verbosity=required_loop_level + 1)
            return None

        # Task Summary
        task_id = result._task._uuid
        host_name = result._host.get_name()
        summary_key = (task_id, host_name)
        r = result._result
        if summary_key not in self._loop_summary:
            self._loop_summary[summary_key] = {
                "ok": 0,
                "changed": 0,
                "skipped": 0,
            }
        if r.get("skipped", False):   self._loop_summary[summary_key]["skipped"] += 1
        elif r.get("changed", False): self._loop_summary[summary_key]["changed"] += 1
        else:                         self._loop_summary[summary_key]["ok"]      += 1

        # suppress per‑item output entirely
        return None


    # ----------------------------------+---------------------------------------
    def v2_runner_item_on_skipped(self, result, **kwargs):
        tags = set(getattr(result._task, "tags", []) or [])
        verbosity = getattr(self._display, "verbosity", 0)
        required_task_level = self._silent_level(tags)
        required_loop_level = required_task_level + 1 if required_task_level >= 0 else -1

        if required_loop_level < 0:
            return super().v2_runner_item_on_skipped(result, **kwargs)

        if verbosity > required_task_level and verbosity > required_loop_level:
            return super().v2_runner_item_on_skipped(result, **kwargs)

        # If verbosity is in the "silent loop" range, show header-only for each loop item
        if verbosity > required_task_level and verbosity <= required_loop_level:
            return super().v2_runner_item_on_skipped(result, **kwargs)

        # Task Summary
        task_id = result._task._uuid
        host_name = result._host.get_name()
        summary_key = (task_id, host_name)
        r = result._result
        if summary_key not in self._loop_summary:
            self._loop_summary[summary_key] = {
                "ok": 0,
                "changed": 0,
                "skipped": 0,
            }
        if r.get("skipped", False):   self._loop_summary[summary_key]["skipped"] += 1
        elif r.get("changed", False): self._loop_summary[summary_key]["changed"] += 1
        else:                         self._loop_summary[summary_key]["ok"]      += 1

        # Silent => suppress item-skipped output
        return None


    # ----------------------------------+---------------------------------------
    def v2_runner_on_failed(self, result, ignore_errors=False, **kwargs):
        """Clean up any accumulated loop summary before delegating to default."""
        task_id = result._task._uuid
        host_name = result._host.get_name()
        self._loop_summary.pop((task_id, host_name), None)
        return super().v2_runner_on_failed(result, ignore_errors=ignore_errors, **kwargs)


    # ----------------------------------+---------------------------------------
    def v2_runner_on_unreachable(self, result, **kwargs):
        """Clean up any accumulated loop summary before delegating to default."""
        task_id = result._task._uuid
        host_name = result._host.get_name()
        self._loop_summary.pop((task_id, host_name), None)
        return super().v2_runner_on_unreachable(result, **kwargs)

