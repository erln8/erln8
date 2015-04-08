import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;

import config;
import dirconfig;
import dini;
import log;

class Impl {
  string name;
  string[] commands;
  string installbasedir;
  string repodir;

  //abstract void initOnce(Ini initialIni);

  abstract void processArgs(string args[]);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();

  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }
}


class Erln8Impl : Impl {
  this() {
    name = "erln8";
    commands = ["erlc"];
    installbasedir = getConfigSubdir("otps");
    repodir = getConfigSubdir("repos");
  }

  override void processArgs(string args[]) {

  }

  override void runCommand(string[] cmdline) {
    Ini cfg = getAppConfig();
    log_debug("Config:", cfg);
    writeln("Running ", cmdline);
    Nullable!Ini dirini = getConfigFromCWD();
    if(!dirini.isNull) {
      log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
      string erlid = dirini["Config"].getKey("Erlang");
      if(!isValidErlang(cfg, erlid)) {
        log_fatal("Unknown Erlang id: ", erlid);
        exit(-1);
      }
      log_debug("installbasedir = ", installbasedir);
      log_debug("repodir = ", repodir);
    } else {
      log_fatal("Can't find a configured version of Erlang");
      exit(-1);
    }
  }

  override void runConfig() {

  }

  bool isValidErlang(Ini ini, string id) {
    return ini["Erlangs"].hasKey(id);
  }
}



