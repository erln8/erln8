import std.path;
import std.file;
import std.typecons; // Nullable
import colorize : fg, color, cwriteln, cwritefln;

import dini;
import log;

class DirconfigResult {
  Nullable!Ini ini;
  string path;
  this(Nullable!Ini ini, string path) {
    this.path = path;
    this.ini = ini;
  }
}

DirconfigResult getConfigFromCWD() {
  string cwd = getcwd();
  return getDirConfig(cwd);
}

DirconfigResult getDirConfig(string path) {
  if(path == rootName(path)) {
    log_debug("Got to root dir");
    Nullable!Ini result;
    return new DirconfigResult(result, "/");
  }
  string cfgFileName = buildNormalizedPath(path, "erln8.config");
  log_debug("Looking for config ", cfgFileName);
  if(exists(cfgFileName)) {
    cwriteln("erln8 directory config ".color(fg.yellow), cfgFileName.color(fg.yellow));
    Ini ini = Ini.Parse(cfgFileName);
    Nullable!Ini result;
    result = ini;
    return new DirconfigResult(result, cfgFileName);
  } else {
    string parent = buildNormalizedPath(path ~ dirSeparator ~ "..");
    return getDirConfig(parent);
  }
}

DirconfigResult getConfigFromCWD(string key) {
  string cwd = getcwd();
  return getDirConfig(key, cwd);
}

DirconfigResult getDirConfig(string key, string path) {
  if(path == rootName(path)) {
    log_debug("Got to root dir");
    Nullable!Ini result;
    return new DirconfigResult(result, path);
  }
  string cfgFileName = buildNormalizedPath(path, "erln8.config");
  log_debug("Looking for config ", cfgFileName);
  if(exists(cfgFileName)) {
    Ini ini = Ini.Parse(cfgFileName);
    IniSection cfgini = ini.getSection("Config");
    if(cfgini.hasKey(key)) {
      cwriteln("erln8 directory config ".color(fg.yellow), cfgFileName.color(fg.yellow));
      Nullable!Ini result;
      result = ini;
      return new DirconfigResult(result, cfgFileName);
    } else {
      log_debug("Found a erln8.config, but not with ", key);
      string parent = buildNormalizedPath(path ~ dirSeparator ~ "..");
      return getDirConfig(key, parent);
    }
  } else {
    string parent = buildNormalizedPath(path ~ dirSeparator ~ "..");
    return getDirConfig(key, parent);
  }
}
