import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;
import std.file;
import std.format;
import std.string;
import std.algorithm.iteration;

import config;
import dirconfig;
import dini;
import log;
import builder;
import impl;

struct ErlangBuildOptions {
  string repo;
  string tag;
  string id;
  string configname;
}

// executables to symlink to after a build is complete

string[] bins = [
  "bin/ct_run",
  "bin/dialyzer",
  "bin/epmd",
  "bin/erl",
  "bin/erlc",
  "bin/escript",
  "bin/run_erl",
  "bin/run_test",
  "bin/to_erl",
  "bin/typer",
  "lib/erlang/lib/diameter-*/bin/diameterc",
  "lib/erlang/lib/edoc-*/priv/edoc_generate",
  "lib/erlang/lib/erl_interface-*/bin/erl_call",
  "lib/erlang/lib/inets-*/priv/bin/runcgi.sh",
  "lib/erlang/lib/observer-*/priv/bin/cdv",
  "lib/erlang/lib/observer-*/priv/bin/etop",
  "lib/erlang/lib/odbc-*/priv/bin/odbcserver",
  "lib/erlang/lib/os_mon-*/priv/bin/memsup",
  "lib/erlang/lib/snmp-*/bin/snmpc",
  "lib/erlang/lib/tools-*/bin/emem",
  "lib/erlang/lib/webtool-*/priv/bin/start_webtool"
  ];

  class Erln8Impl : Impl {

    this() {
      name = "erln8";
      commands = [];
      foreach(b;bins) {
        commands ~= baseName(b);
      }

      installbasedir = getConfigSubdir("otps");
      repodir = getConfigSubdir("repos");
      appConfigName = "config";
      IdKey = "Erlangs";
    }

    override void initOnce() {
      if(exists(buildNormalizedPath(getConfigDir(), "bin", "erl"))) {
        log_debug("Erln8 has already been initialized");
        return;
      }

      log_debug("Erln8 init once");
      writeln("First time initialization of erln8");
      mkdirSafe(getConfigDir());
      mkdirSafe(buildNormalizedPath(getConfigDir(), "otps"));
      mkdirSafe(buildNormalizedPath(getConfigDir(), "repos"));
      // create ~/.erln8.d
      // create ~/.erln8.d/otps/
      // create ~/.erln8.d/repos/

      // create ~/.erln8.d/config file
      File config = File(buildNormalizedPath(getConfigDir(), "config"), "w");

      // none must be left in!
      //https://github.com/erlang/otp.git
string cfgfileout = format("
[Erln8]
default_config=default
system_default=
color=true
log_level=error

[Repos]
default=%s

[Erlangs]
none=

[Configs]
default=
osx_gcc=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit
osx_llvm=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit
osx_llvm_dtrace=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit --enable-vm-probes --with-dynamic-trace=dtrace
osx_gcc_env=CC=gcc-4.2 CPPFLAGS='-DNDEBUG' MAKEFLAGS='-j 3'k
", getDefaultOTPUrl());

      config.writeln(cfgfileout);
      config.close();

      setupBins();

      Ini cfg = getAppConfig();
      doClone(cfg, "default");
    }



    override void processArgs(string[] args, bool showHelp) {
      CommandLineOptions opts;
      try {
        auto rslt = getopt(
            args,
            std.getopt.config.passThrough,
            "use",           "Setup the current directory to use a specific verion of Erlang", &opts.opt_use,
            "list",          "List available Erlang installations",      &opts.opt_list,
            "remote",        "add/delete/show remotes", &opts.opt_remote,
            "clone",         "Clone an Erlang source repository",  &opts.opt_clone,
            "fetch",         "Update source repos",  &opts.opt_fetch,
            "build",         "Build a specific version of OTP from source",  &opts.opt_build,
            "build-latest",   "Build the latest tagged version of OTP from source",  &opts.opt_build_latest,
            "repo",          "Specifies repo name to build from",  &opts.opt_repo,
            //"tag",         "Specifies repo branch/tag to build fro,",  &opts.opt_tag,
            "id",            "A user assigned name for a version of Erlang",  &opts.opt_id,
            "config",        "Build configuration",  &opts.opt_config,
            "show",          "Show the configured version of Erlang in the current working directory",  &opts.opt_show,
            "prompt",        "Display the version of Erlang configured for this part of the directory tree",  &opts.opt_prompt,
            "configs",       "List build configs",  &opts.opt_configs,
            "repos",         "List build repos",  &opts.opt_repos,
            "set-default",   "Set the system-wide Erlang default", &opts.opt_set_default,
            "get-default",   "Display the system-wide Erlang default",  &opts.opt_get_default,
            "link",          "Link a non-erln8 build of Erlang to erln8",  &opts.opt_link,
            "unlink",        "Unlink a non-erln8 build of Erlang from erln8",  &opts.opt_unlink,
            "force",         "Overwrite an erln8.config in the current directory",  &opts.opt_force,
            "buildable",     "List tags to build from configured source repos", &opts.opt_buildable,
            "version",       "Show the installed version of erln8", &opts.opt_version,
            "setup-bins",    "Regenerate erln8-managed OTP application links", &opts.opt_setup_bins,
            "debug",         "Show debug output", &opts.opt_debug
              );
        if(showHelp && rslt.helpWanted) {
          // it's an Arrested Development joke
          auto bannerMichael = "Usage: " ~ name ~ " [--use <id> --force] [--list] [--remote add|delete|show]\n";
          bannerMichael ~= "       [--clone <remotename>] [--fetch <remotename>] [--show] [--prompt]\n";
          bannerMichael ~= "       [--build --id <someid> --repo <remotename> --config <configname>]\n";
          bannerMichael ~= "       [--buildable] [--configs] [--link <path>] [--unline <id>]\n";
          defaultGetoptPrinter(bannerMichael.color(fg.yellow), rslt.options);
          exit(0);
        }
        log_debug(opts);
        opts.allargs = args;
        currentOpts = opts;
      } catch (Exception e) {
        writeln(e.msg);
        exit(-1);
      }
    }


    override string[] getSymlinkedExecutables() {
      string[] all = [];
      foreach(bin;bins) {
        all = all ~ baseName(bin);
      }
      return all;
    }

    void doShow(Ini cfg) {
      DirconfigResult dcr = getConfigFromCWD();
      auto dirini = dcr.ini;
      if(dirini.isNull) {
        log_info("Can't find a configured version of Erlang, system default will be used");
        writeln("Erln8 system default:");
        getSystemDefault("Erln8");
        exit(-1);
      }

      log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
      string erlid = dirini["Config"].getKey("Erlang");
      if(!isValidErlang(cfg, erlid)) {
        log_fatal("Unknown Erlang id: ", erlid);
        exit(-1);
      }
      if(currentOpts.opt_show) {
        auto path = cfg["Erlangs"].getKey(erlid);
        writeln(erlid, " @ ", path);
      } else {
        write(erlid);
      }
    }

    void doUse(Ini cfg) {
      auto keys = cfg["Erlangs"].keys();
      log_debug("Trying to use ", currentOpts.opt_use);
      string erlangId = currentOpts.opt_use;
      if(!(erlangId in keys)) {
        writeln(erlangId, " is not a configured version of Erlang");
        exit(-1);
      }
      string fileName = "erln8.config";
      if(exists(fileName)) {
        if(!currentOpts.opt_force) {
          writeln("Config already exists in this directory. Override with --force.");
          exit(-1);
        }
      }
      if(currentOpts.opt_force) {
        // update the existing file
        DirconfigResult dcr = getConfigFromCWD();
        auto dircfg = dcr.ini;
        IniSection inicfg = dircfg.get().getSection("Config");
        inicfg.setKey("Erlang", erlangId);
        saveDirConfig(dcr.path, dcr.ini);
      } else {
        // write a new file
        File file = File("erln8.config", "w");
        file.writeln("[Config]");
        file.writeln("Erlang=", erlangId);
      }
    }

    bool isValidErlang(Ini ini, string id) {
      return ini["Erlangs"].hasKey(id);
    }


    ErlangBuildOptions getBuildOptions(Ini cfg, string repo, string tag, string id, string configname) {
      ErlangBuildOptions opts;
      opts.repo = (repo == null ? "default" : repo);
      opts.tag = tag;
      if(id == null) {
        opts.id  = tag;
      } else {
        opts.id  = id;
      }
      if(configname == null || configname == "") {
        if(cfg["Erln8"].hasKey("default_config")) {
          opts.configname = cfg["Erln8"].getKey("default_config");
        } else {
          opts.configname = "default";
        }
      } else {
        opts.configname = configname;
      }

      return opts;
    }

    void verifyInputs(Ini cfg, ErlangBuildOptions build_options) {
      auto erlangs = cfg["Erlangs"].keys();
      if(build_options.id in erlangs) {
        writeln("A version of Erlang already exists with the id ", build_options.id);
        exit(-1);
      }

      auto repos = cfg["Repos"].keys();
      if(!(build_options.repo in repos)) {
        writeln("Unconfigured repo: ", build_options.repo);
        exit(-1);
      }

      string repoURL = cfg["Repos"].getKey(build_options.repo);
      string repoPath = buildNormalizedPath(getConfigSubdir("repos"),build_options.repo);

      if(!exists(repoPath)) {
        writeln("Missing repo for " ~ currentOpts.opt_fetch
            ~ ", which should be in " ~ repoPath ~ ". Maybe you forgot to erln8 --clone <repo_name>");
        exit(-1);
      }

      auto configs = cfg["Configs"].keys();
      if(build_options.configname == null || build_options.configname == "") {
        // default
        log_debug("Using default config");
      } else if(!(build_options.configname in configs)) {
        writeln("Unknown build config: ", build_options.configname);
        exit(-1);
       }

    }

    void checkObject(ErlangBuildOptions opts, string sourcePath) {
      string checkObj = "cd " ~ sourcePath ~ " && git show-ref " ~ opts.tag ~ " > /dev/null";
      log_debug(checkObj);
      auto shell = executeShell(checkObj);
      if(shell.status != 0) {
        writeln("branch or tag " ~ opts.tag ~ " does not exist in " ~ opts.repo ~ " Git repo");
        log_debug("Git object missing");
        exit(-1);
      } else {
        log_debug("Git object exists");
      }
    }



    void setupLinks(string root) {
      foreach(bin;bins) {
        string base = baseName(bin);
        if(bin.indexOf('*') >= 0) {
          // paths that include a *
          string p = buildNormalizedPath(root, "dist", bin);
          log_debug("Getting full path of ", p);
          log_debug("  basename = ", base);
          auto ls = executeShell("ls " ~ p);
          if (ls.status != 0) {
            writeln("Failed to find file while creating symlink: ", p);
            writeln("Most likely an outdated Erlang command. Moving on.");
            // keep going, most likely a command that doesn't exist in a
            // newer version of Erlang
          } else {
            if(splitLines(ls.output).length > 1) {
              log_fatal("Found more than 1 executable for ", p , " while creating symlinks");
              exit(-1);
            }
            string fullpath = strip(splitLines(ls.output)[0]);
            string linkTo = buildNormalizedPath(root, base);
            log_debug("Found ", fullpath);
            log_debug("symlink ", fullpath, " to ", linkTo);
            symlink(fullpath, linkTo);
          }
        } else {
          // paths that do not include a *
          string fullpath = buildNormalizedPath(root, "dist", bin);
          string linkTo = buildNormalizedPath(root, base);
          log_debug("symlink ", fullpath, " to ", linkTo);
          symlink(fullpath, linkTo);
        }
      }
    }


    override void doBuild(Ini cfg, string tag) {
      ErlangBuildOptions opts =
        getBuildOptions(cfg,
          currentOpts.opt_repo,
          tag,
          currentOpts.opt_id,
          currentOpts.opt_config);

      verifyInputs(cfg, opts);

      string outputRoot = buildNormalizedPath(getConfigSubdir("otps"),opts.id);
      string outputPath = buildNormalizedPath(outputRoot, "dist");
      string sourcePath = buildNormalizedPath(getConfigSubdir("repos"), opts.repo);

      checkObject(opts, sourcePath);
      string makeBin = getMakeBin();

      string configenvname = opts.configname ~ "_env";
      string env = "";
      if(cfg["Configs"].hasKey(configenvname)) {
        env = cfg["Configs"].getKey(configenvname);
      }

      log_debug("Output root = ", outputRoot);
      log_debug("Output path = ", outputPath);
      log_debug("Source path = ", sourcePath);
      log_debug("Config      = ", opts.configname);
      log_debug("Config env  = ", env);

      string tmp = buildNormalizedPath(tempDir(), getTimestampedFilename());
      log_debug("tmp dir = ", tmp);
      string logFile = buildNormalizedPath(tmp, "build_log");
      log_debug("log = ", tmp);

      writeln("Building Erlang ", opts.tag);
      mkdirRecurse(tmp);

      string cmd0 = format("%s cd %s && git archive %s | (cd %s; tar -f - -x)",
          env,  sourcePath,     opts.tag, tmp);

      string cmd1 = format("%s cd %s && ./otp_build autoconf > ./build_log 2>&1",
          env, tmp);
      string cmd2 = format("%s cd %s && ./configure --prefix=%s %s >> ./build_log 2>&1",
          env, tmp, outputPath, ""); // TODO buildconfig

      // TODO: configurable parallelism
      string cmd3 = format("%s cd %s && %s -j4 >> ./build_log 2>&1",
          env, tmp, makeBin);

      string cmd4 = format("%s cd %s && %s install >> ./build_log 2>&1",
          env, tmp, makeBin);

      string cmd5 = format("%s cd %s && %s install-docs >> ./build_log 2>&1",
          env, tmp, makeBin);

      Builder b = new Builder();
      b.addCommand("Copy source          ", cmd0);
      b.addCommand("opt_build            ", cmd1);
      b.addCommand("configure            ", cmd2);
      b.addCommand("make                 ", cmd3);
      b.addCommand("make install         ", cmd4);
      b.addCommand("make install-docs    ", cmd4);
      if(!b.run()) {
        writeln("*** Build failed ***");
        writeln("Here are the last 10 lines of " ~ logFile);
        auto pid = spawnShell("tail -10 " ~ logFile);
        wait(pid);
        return;
      }
      log_debug("Adding Erlang id to ~/.erln8/config");
      cfg["Erlangs"].setKey(opts.id, outputPath);
      saveAppConfig(cfg);
      setupLinks(outputRoot);
      setSystemDefaultIfFirst("Erln8", opts.id);
      writeln("Done!");
    }

    override void runConfig() {
      Ini cfg = getAppConfig();
      if(currentOpts.opt_buildable) {
        doBuildable(cfg);
      } else if(currentOpts.opt_list) {
        doList(cfg);
      } else if(currentOpts.opt_repos) {
        doRepos(cfg);
      } else if(currentOpts.opt_show || currentOpts.opt_prompt) {
        doShow(cfg);
      } else if(currentOpts.opt_configs) {
        doConfigs(cfg);
      } else if(currentOpts.opt_use) {
        doUse(cfg);
      } else if(currentOpts.opt_clone) {
        doClone(cfg);
      } else if(currentOpts.opt_fetch) {
        doFetch(cfg);
      } else if(currentOpts.opt_build) {
          foreach(b;currentOpts.opt_build) {
            doBuild(cfg, b);
          }
      } else if(currentOpts.opt_build_latest) {
        doBuildLatest(cfg);
      } else if(currentOpts.opt_remote != RemoteOption.none) {
        doRemote(cfg);
      } else if(currentOpts.opt_get_default) {
        getSystemDefault("Erln8");
      } else if(currentOpts.opt_set_default) {
        setSystemDefault("Erln8", "Erlangs", currentOpts.opt_set_default);
      } else if(currentOpts.opt_version) {
        writeln(name, " ", erln8_version);
      } else if(currentOpts.opt_setup_bins) {
        doSetupBins(cfg); 
      } else {
        log_debug("Nothing to do");
      }
    }

    override void runCommand(string[] cmdline) {
      Ini cfg = getAppConfig();
      log_debug("Config:", cfg);
      log_debug("Running: ", cmdline);
      string bin = baseName(cmdline[0]);

      DirconfigResult dcr = getConfigFromCWD("Erlang");
      auto dirini = dcr.ini;
      string erlid;
      if(dirini.isNull) {
        IniSection e8cfg = cfg.getSection("Erln8");
        if(e8cfg.hasKey("system_default") && e8cfg.getKey("system_default") != null ) {
          log_debug("Using system_default ", e8cfg.getKey("system_default"));
          erlid = e8cfg.getKey("system_default");
        } else {
          log_fatal("Can't find a configured version of Erlang, system default unavailable");
          exit(-1);
        }
      } else {
        erlid = dirini["Config"].getKey("Erlang");
        log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
      }

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

  }
