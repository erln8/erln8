import std.path;
import std.file;

import dini;
import log;

void getConfigFromCWD() {
  string cwd = getcwd();
  getDirConfig(cwd);
  //auto ini = Ini.Parse("/Users/dparfitt/.erln8.d/config");
  //writeln(ini["Repos"].getKey["default"]);
  //writeln(ini["Repos"].getKey("default"));
}

void getDirConfig(string path) {
  if(path == rootName(path)) {
    log_debug("Got to root dir");
    return;
  }
  string cfgFileName = buildNormalizedPath(path, "erln8.config");
  log_debug("Looking for ", cfgFileName);

  auto segments = pathSplitter(path);
  log_debug("FOO:", segments.stringof);
  //auto parent  = segments[0 .. $ - 1];
  //getDirConfig(parent);
}
