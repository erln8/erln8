import std.process;
import std.stdio;
import std.format;

import colorize : fg, color, cwrite, cwriteln;

import spinner;
import log;

class BuildCommand {
  this(string description, string command) {
    desc = description;
    cmd = command;
  }
  string desc;
  string cmd;
}

class Builder {

  bool run() {
    int i = 0;
    foreach(bc;cmds) {
      SlowSpinner spinner = new SlowSpinner();
      log_debug("Running: ", bc.cmd);

      //write(format("[%d] %s ", i, bc.desc));
      cwrite(format("[".color(fg.white) ~ "%d".color(fg.yellow) ~ "]".color(fg.white) ~ " %s ".color(fg.light_blue), i, bc.desc));
      spinner.start();
      auto p = executeShell(bc.cmd);
      spinner.stop();
      spinner.join();
      if(p.status != 0) {
        writeln("Build error, please check the build logs for more details");
        return false;
      }
      writeln("");
      i++;
    }
    return true;
  }

  void addCommand(string desc, string cmd) {
    cmds = cmds ~ new BuildCommand(desc, cmd);
  }

  private:
  BuildCommand[] cmds = [];
}
