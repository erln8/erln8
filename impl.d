import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;

import config;
import dirconfig;
import dini;
import log;

class Impl {
  string name;
  string[] commands;
  string installbasedir;  // where the compiled package lives in erln8
  string repodir;         // where erln8/reo keeps this impls git repo

  //abstract void initOnce(Ini initialIni);

  abstract void processArgs(string args[]);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();

  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }
}


struct Erln8Options {
  bool   opt_init = false;
  string opt_use;
  bool   opt_list = false;
  string opt_clone;
  string opt_fetch;
  bool   opt_build = false;
  string opt_repo;
  string opt_tag;
  string opt_id;
  string opt_config;
  bool   opt_show = false;
  bool   opt_prompt = false;
  bool   opt_configs = false;
  bool   opt_repos = false;
  bool   opt_link  = false;
  bool   opt_unlink = false;
  bool   opt_force = false;
  bool   opt_nocolor = false;
  bool   opt_buildable = false;
  bool   opt_debug = false;
}


class Erln8Impl : Impl {
  Erln8Options currentOpts;

  this() {
    name = "erln8";
    commands = ["erlc"];
    installbasedir = getConfigSubdir("otps");
    repodir = getConfigSubdir("repos");
  }

  override void processArgs(string args[]) {
    Erln8Options opts;
    auto rslt = getopt(
            args,
            "init",      &opts.opt_init,
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
        defaultGetoptPrinter("erln8", rslt.options);
      }
    log_debug(opts);
    currentOpts = opts;
  }

  override void runConfig() {
    // TODO: this has to go after init
    Ini cfg = getAppConfig();
    if(currentOpts.opt_buildable) {
      auto keys = cfg["Repos"].keys();
      log_debug(keys);

      foreach(k,v;keys) {
        log_debug("Listing buildable in repo ", k, " @ ", v);

        string currentRepoDir = buildNormalizedPath(repodir, k);
        log_debug(currentRepoDir);
        string cmd = "cd " ~ currentRepoDir ~ " && git tag | sort";
        log_debug(cmd);
        auto result = executeShell(cmd);
        // TODO: check result.status
        writeln(result.output);
      }
    } else if(currentOpts.opt_list) {
      auto keys = cfg["Erlangs"].keys();
      log_debug(keys);

      foreach(k,v;keys) {
        writeln(k, " -> ", v);
      }
    } else {
      log_debug("Nothing to do");
    }
  }

  override void runCommand(string[] cmdline) {
    Ini cfg = getAppConfig();
    log_debug("Config:", cfg);
    log_debug("Running: ", cmdline);
    string bin = baseName(cmdline[0]);

    Nullable!Ini dirini = getConfigFromCWD();
    if(dirini.isNull) {
      log_fatal("Can't find a configured version of Erlang");
      exit(-1);
    }

    log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
    string erlid = dirini["Config"].getKey("Erlang");
    if(!isValidErlang(cfg, erlid)) {
      log_fatal("Unknown Erlang id: ", erlid);
      exit(-1);
    }
    log_debug("installbasedir = ", installbasedir);
    log_debug("repodir = ", repodir);

    string binFullPath = buildNormalizedPath(installbasedir, erlid, bin);
    log_debug("mapped cmd to execute = ", binFullPath);
    auto argsPassthrough = [bin] ~ cmdline[1 .. $];
    log_debug("Args = ", argsPassthrough);
    execv(binFullPath, argsPassthrough);
  }


  bool isValidErlang(Ini ini, string id) {
    return ini["Erlangs"].hasKey(id);
  }
}



