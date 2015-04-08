import std.file;
import std.path;
import std.c.stdlib; // exit()
import std.process;

import dini;
import log;

string defaultHome() {
  try {
    string home = environment["ERLN8_HOME"];
    log_debug("Using ERLN8_HOME env var:", home);
    return expandTilde(home);
  } catch (Exception e) {
    try {
      string home = environment["HOME"];
      log_debug("Using HOME env var:", home);
      return expandTilde(home);
    } catch (Exception e) {
      log_fatal("Unable to detect HOME or ERLN8_HOME, you're weird!");
      exit(-1);
      return "";
    }
  }

}

string getConfigDir() {
  // should be already expandTilde'd
  return buildNormalizedPath(defaultHome(), ".erln8.d");
}

Ini getAppConfig() {
  string cfgFileName = buildNormalizedPath(getConfigDir(), "config");
  log_debug("Attempting to load ", cfgFileName);
  if(!exists(cfgFileName)) {
    log_fatal("erln8 has not been initialized");
    exit(-1);
  }
  Ini ini = Ini.Parse(cfgFileName);
  return ini;
}


