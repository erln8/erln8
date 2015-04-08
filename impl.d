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

  abstract void processArgs(string args[]);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();
  string getInstallBase() {
    string home = defaultHome();
    string p = expandTilde(buildNormalizedPath(getConfigDir(), name ~ "s")); // make it plural ;-)
    log_debug(name, " install base = ", p);
    return p;
  }
}


class Erln8Impl : Impl {
  this() {
    name = "erln8";
    commands = ["erlc"];
  }

  override void processArgs(string args[]) {

  }

  override string getInstallBase() {
    string home = defaultHome();
    string p = expandTilde(buildNormalizedPath(getConfigDir(), "otps"));
    log_debug("erln8 install base = ", p);
    return p;
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
      getInstallBase();
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


//class ReoImpl : Impl {
//  override void processArgs(string args[]) {
//  }
//
//  override void runImpl() {
//
//  }
//
//  override void configImpl() {
//
//  }
//}
//
//
//class Reo3Impl : Impl {
//  override void processArgs(string args[]) {
//  }
//
//  override void runImpl() {
//
//  }
//
//  override void configImpl() {
//
//  }
//}
//
