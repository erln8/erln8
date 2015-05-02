import std.path;
import std.file;
import std.stdio;
import std.regex;
import std.c.stdlib; // exit()
import std.process;
import std.format;
import std.string;
import std.getopt;

import config;
import dini;
import log;
import utils;

struct CommandLineOptions {
  string opt_use       = null;
  bool   opt_list      = false;
  string opt_clone     = null;
  string opt_fetch     = null;
  bool   opt_build     = false;
  string opt_repo      = null;
  string opt_tag       = null;
  string opt_id        = null;
  string opt_config    = null;
  bool   opt_show      = false;
  bool   opt_prompt    = false;
  bool   opt_configs   = false;
  bool   opt_repos     = false;
  bool   opt_link      = false;
  bool   opt_unlink    = false;
  bool   opt_force     = false;
  bool   opt_nocolor   = false;
  bool   opt_buildable = false;
  bool   opt_debug     = false;
}

class Impl {
  CommandLineOptions currentOpts;
  string name;
  string[] commands;

  string IdKey;           // cfg["Erlangs"], cfg["Rebars"] etc
  string installbasedir;  // where the compiled packages live
  string repodir;         // where erln8/reo keeps this impls git repo
  string appConfigName;   // ~/.erln8.d/foo_config

  abstract void initOnce();

  abstract void runCommand(string[] cmdline);
  abstract void runConfig();
  abstract string[] getSymlinkedExecutables();

  void processArgs(string[] args) {
      CommandLineOptions opts;
      auto rslt = getopt(
          args,
          "use",       &opts.opt_use,
          "list",      &opts.opt_list,
          "clone",     &opts.opt_clone,
          "fetch",     &opts.opt_fetch,
          "build",     &opts.opt_build,
          "repo",      &opts.opt_repo,
          "tag",       &opts.opt_tag,
          "id",        &opts.opt_id,
          "config",    &opts.opt_config,
          "show",      &opts.opt_show,
          "prompt",    &opts.opt_prompt,
          "configs",   &opts.opt_configs,
          "repos",     &opts.opt_repos,
          "link",      &opts.opt_link,
          "unlink",    &opts.opt_unlink,
          "force",     &opts.opt_force,
          "nocolor",   &opts.opt_nocolor,
          "buildable", &opts.opt_buildable,
          "debug",     &opts.opt_debug
            );

      if(rslt.helpWanted) {
        defaultGetoptPrinter(name, rslt.options);
      }
      log_debug(opts);
      currentOpts = opts;
    }



  Ini getAppConfig() {
    string cfgFileName = buildNormalizedPath(getConfigDir(), appConfigName);
    log_debug("Attempting to load ", cfgFileName);
    if(!exists(cfgFileName)) {
      log_fatal(name ~ "has not been initialized");
      exit(-1);
    }
    Ini ini = Ini.Parse(cfgFileName);
    return ini;
  }

  void saveAppConfig(Ini cfg) {
    string cfgFileName = buildNormalizedPath(getConfigDir(), appConfigName);
    log_debug("Attempting to save ", cfgFileName);
    if(!exists(cfgFileName)) {
      log_fatal("erln8 has not been initialized");
      exit(-1);
    }

    File output = File(cfgFileName, "w");
    foreach(section;cfg.sections) {
      auto keys = cfg[section.name].keys();
      output.writeln("[" ~ section.name ~ "]");
      foreach(k,v;keys) {
        output.writeln(k, "=", v);
      }
      output.writeln("");
    }
  }


  void mkdirSafe(string d) {
    try {
      mkdir(d);
    } catch(FileException fe) {
      auto ctr = ctRegex!(`File exists`);
      auto c2 = matchFirst(fe.msg, ctr);
      if(c2.empty) {
        writeln(fe.msg);
        throw fe;
      } else {
        log_debug("File already exists: ", d);
      }
    }
  }

  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }

  void doBuildable(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      log_debug("Listing buildable in repo ", k, " @ ", v);

      string currentRepoDir = buildNormalizedPath(repodir, k);
      log_debug(currentRepoDir);
      string cmd = "cd " ~ currentRepoDir ~ " && git tag | sort";
      log_debug(cmd);
      auto pid = spawnShell(cmd);
      wait(pid);
    }
  }

  void doList(Ini cfg) {
    auto keys = cfg[IdKey].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      writeln(k, " -> ", v);
    }
  }

  void doRepos(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    foreach(k,v;keys) {
      writeln(k," -> ", v);
    }
  }

  void doConfigs(Ini cfg) {
    auto keys = cfg["Configs"].keys();
    foreach(k,v;keys) {
      writeln(k," -> ", v);
    }
  }

  void doClone(Ini cfg) {
    doClone(cfg, currentOpts.opt_clone);
  }

  void doClone(Ini cfg, string name) {
      auto keys = cfg["Repos"].keys();
      if(!(name in keys)) {
        writeln("Unknown repo:", name);
        exit(-1);
      }
      string repoURL = cfg["Repos"].getKey(name);
      string dest = buildNormalizedPath(getConfigSubdir(repodir),name);
      string command = "git clone " ~ repoURL ~ " " ~ dest;
      log_debug(command);
      auto pid = spawnShell(command);
      wait(pid);
  }

  void doFetch(Ini cfg) {
      auto keys = cfg["Repos"].keys();
      if(!(currentOpts.opt_fetch in keys)) {
        writeln("Unknown repo:", currentOpts.opt_fetch);
        exit(-1);
      }
      string repoURL = cfg["Repos"].getKey(currentOpts.opt_fetch);
      string dest = buildNormalizedPath(getConfigSubdir(repodir),currentOpts.opt_fetch);

      if(!exists(dest)) {
        writeln("Missing repo for " ~ currentOpts.opt_fetch
            ~ ", which should be in " ~ dest ~ ". Maybe you forgot to reo --clone <repo_name>");
        exit(-1);
      }
      string command = "cd " ~ dest ~ "  && git fetch --all";
      log_debug(command);
      auto pid = spawnShell(command);
      wait(pid);
  }

}

