import sublime
import sublime_plugin


class CloseWithoutSaving(sublime_plugin.WindowCommand):
    def run(self):
        window = self.window

        for v in window.views():
            if v.is_dirty():
                v.set_scratch(True)

        window.run_command("close")
