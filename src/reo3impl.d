import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;
import std.file;
import std.format;
import std.string;

import config;
import dirconfig;
import dini;
import log;
import builder;
import impl;

struct RebarBuildOptions {
  string repo;
  string tag;
  string id;
  string configname;
}

// executables to symlink to after a build is complete

string[] bins = [
  "rebar3"
];


class Reo3Impl : Impl {
    string reosectionname; // [Reo] or [Reo3] in the reo_config file

    this() {
      IdKey = "Rebar3s";
      name = "reo3";
      commands = ["rebar3"];
      installbasedir = getConfigSubdir("rebar3s");
      repodir = getConfigSubdir("rebar3_repos");
      appConfigName = "reo3_config";
      reosectionname = "Reo3";
    }

    override void initOnce() {
      log_debug("reo3 init once");

      if(exists(buildNormalizedPath(getConfigDir(), appConfigName))) {
        log_debug("reo3 has already been initialized");
        return;
      }

      mkdirSafe(getConfigDir());
      mkdirSafe(buildNormalizedPath(getConfigDir(), "rebar3s"));
      mkdirSafe(buildNormalizedPath(getConfigDir(), "rebar3_repos"));
      // create ~/.erln8.d
      // create ~/.erln8.d/otps/
      // create ~/.erln8.d/repos/

      // create ~/.erln8.d/config file
      File config = File(buildNormalizedPath(getConfigDir(), "reo3_config"), "w");
      // "none" must be left in, otherwise the section will be empty
      config.writeln(q"EOS
[Reo3]
default_config=default
system_default=
color=true

[Repos]
default=git@github.com:rebar/rebar3.git

[Rebar3s]
none =

[Configs]
EOS"
);
      config.close();

      setupBins();

      Ini cfg = getAppConfig();
      doClone(cfg, "default");
    }

    override void processArgs(string[] args) {
      CommandLineOptions opts;
      try {
        auto rslt = getopt(
            args,
            std.getopt.config.passThrough,
            "use",       "Setup the current directory to use a specific verion of Rebar3", &opts.opt_use,
            "list",      "List installed versions of Rebar3",      &opts.opt_list,
            "remote",    "add/delete/show remotes", &opts.opt_remote,
            "clone",     "Clone a Rebar3 source repository",  &opts.opt_clone,
            "fetch",     "Update source repos",  &opts.opt_fetch,
            "build",     "Build a specific version of Rebar3 from source",  &opts.opt_build,
            "repo",      "Specifies repo name to build from",  &opts.opt_repo,
            //"tag",       "Specifies repo branch/tag to build fro,",  &opts.opt_tag,
            "id",        "A user assigned name for a version of Rebar3",  &opts.opt_id,
            "config",    "Build configuration",  &opts.opt_config,
            "show",      "Show the configured version of Rebar3 in the current working directory",  &opts.opt_show,
            "prompt",    "Same as above without a newline, suitable to use in a prompt",  &opts.opt_prompt,
            "configs",   "List build configs",  &opts.opt_configs,
            "repos",     "List build repos",  &opts.opt_repos,
            "link",      "Link a non-reo3 build of Rebar3 to reo3",  &opts.opt_link,
            "unlink",    "Unlink a non-reo3 build of Rebar3 from reo3",  &opts.opt_unlink,
            "force",     "Overwrite an erln8.config in the current directory",  &opts.opt_force,
            "buildable", "List tags to build from configured source repos", &opts.opt_buildable,
            "debug",     "Show debug output", &opts.opt_debug
              );
        if(rslt.helpWanted) {
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
      DirconfigResult dcr = getConfigFromCWD("Rebar3");
      auto dirini = dcr.ini;
      if(dirini.isNull) {
        log_fatal("Can't find a configured version of Rebar3");
        exit(-1);
      }

      log_debug("Rebar3 id:", dirini["Config"].getKey("Rebar3"));
      string rebarid = dirini["Config"].getKey("Rebar3");
      if(!isValidRebar(cfg, rebarid)) {
        log_fatal("Unknown Rebar3 id: ", rebarid);
        exit(-1);
      }
      if(currentOpts.opt_show) {
        writeln(rebarid);
      } else {
        write(rebarid);
      }
    }

    void doUse(Ini cfg) {
      auto keys = cfg[IdKey].keys();
      log_debug("Trying to use ", currentOpts.opt_use);
      string rebarId = currentOpts.opt_use;
      if(!(rebarId in keys)) {
        writeln(rebarId, " is not a configured version of Rebar3");
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
        inicfg.setKey("Rebar3", rebarId);
        saveDirConfig(dcr.path, dcr.ini);
      } else {
        // write a new file
        File file = File("erln8.config", "w");
        file.writeln("[Config]");
        file.writeln("Rebar3=", rebarId);
      }

    }


    bool isValidRebar(Ini ini, string id) {
      return ini[IdKey].hasKey(id);
    }

    RebarBuildOptions getBuildOptions(string repo, string tag, string id, string configname) {
      RebarBuildOptions opts;
      opts.repo = (repo == null ? "default" : repo);
      opts.tag = tag;

      if(opts.id == null) {
        opts.id  = tag;
      } else {
        opts.id  = id;
      }

      // TODO: use Rebar.default_config value here
      //opts.configname = (configname == null ? "default_config" : configname);
      opts.configname = configname;
      return opts;
    }

    void verifyInputs(Ini cfg, RebarBuildOptions build_options) {
      auto rebars = cfg[IdKey].keys();
      if(build_options.id in rebars) {
        writeln("A version of Rebar3 already exists with the id ", build_options.id);
        exit(-1);
      }

      auto repos = cfg["Repos"].keys();
      if(!(build_options.repo in repos)) {
        writeln("Unconfigured repo: ", build_options.repo);
        exit(-1);
      }

      string repoURL = cfg["Repos"].getKey(build_options.repo);
      string repoPath = buildNormalizedPath(getConfigSubdir(repodir),build_options.repo);

      if(!exists(repoPath)) {
        writeln("Missing repo for " ~ currentOpts.opt_fetch
            ~ ", which should be in " ~ repoPath ~ ". Maybe you forgot to reo3 --clone <repo_name>");
        exit(-1);
      }

      // TODO
      //auto configs = cfg["Configs"].keys();
      //if(!(build_options.configname in configs)) {
      //  writeln("Unknown build config: ", build_options.configname);
      //  exit(-1);
      // }

    }

    void checkObject(RebarBuildOptions opts, string sourcePath) {
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
            // keep going, maybe a command has been removed?
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


    // TODO: NEEDS A SYSTEM DEFAULT IF ONE ISN'T SET
    void doBuild(Ini cfg) {
      RebarBuildOptions opts = getBuildOptions(currentOpts.opt_repo,
          currentOpts.opt_build,
          currentOpts.opt_id,
          currentOpts.opt_config);

      verifyInputs(cfg, opts);

      string outputRoot = buildNormalizedPath(getConfigSubdir(installbasedir),opts.id);
      string outputPath = buildNormalizedPath(outputRoot);
      string sourcePath = buildNormalizedPath(getConfigSubdir(repodir), opts.repo);

      checkObject(opts, sourcePath);
      string makeBin = getMakeBin();

      // TODO: build config _env
      string env = "";

      log_debug("Output root = ", outputRoot);
      log_debug("Output path = ", outputPath);
      log_debug("Source path = ", sourcePath);

      string tmp = buildNormalizedPath(tempDir(), getTimestampedFilename());
      log_debug("tmp dir = ", tmp);
      string logFile = buildNormalizedPath(tmp, "build_log");
      log_debug("log = ", tmp);

      mkdirRecurse(tmp);
      mkdirRecurse(outputPath);
      string cmd0 = format("%s cd %s && git archive %s | (cd %s; tar -f - -x)",
          env,  sourcePath,     opts.tag, tmp);

      string cmd1 = format("%s cd %s && ./bootstrap > ./build_log 2>&1",
          env, tmp);

      string cmd2 = format("%s cd %s && cp ./rebar3 %s/rebar3 > ./build_log 2>&1",
          env, tmp, outputPath);

      Builder b = new Builder();
      b.addCommand("Copy source          ", cmd0);
      b.addCommand("Bootstrap            ", cmd1);
      b.addCommand("Install              ", cmd2);

      // TODO: build plt
      if(!b.run()) {
        writeln("*** Build failed ***");
        writeln("Here are the last 10 lines of " ~ logFile);
        auto pid = spawnShell("tail -10 " ~ logFile);
        wait(pid);
        return;
      }
      log_debug("Adding Rebar3 id to ~/.erln8/reo3_config");
      cfg[IdKey].setKey(opts.id, outputPath);
      saveAppConfig(cfg);
      setSystemDefaultIfFirst("Reo3", opts.id);
      writeln("Done!");
    }

    override void runConfig() {
      // TODO: this has to go after init
      // TODO: don't pass cfg everywhere?
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
        doBuild(cfg);
      } else {
        log_debug("Nothing to do");
      }
    }

    override void runCommand(string[] cmdline) {
      Ini cfg = getAppConfig();
      log_debug("Config:", cfg);
      log_debug("Running: ", cmdline);
      string bin = baseName(cmdline[0]);

      DirconfigResult dcr = getConfigFromCWD();
      auto dirini = dcr.ini;
      string rebarId;

      if(dirini.isNull) {
        IniSection e8cfg = cfg.getSection(reosectionname);
        if(e8cfg.hasKey("system_default") && e8cfg.getKey("system_default") != null ) {
          log_debug("Using system_default ", e8cfg.getKey("system_default"));
          rebarId = e8cfg.getKey("system_default");
        } else {
          log_fatal("Can't find a configured version of Rebar");
          exit(-1);
        }
      } else {
         rebarId = dirini["Config"].getKey("Rebar3");
         log_debug("Rebar id:", dirini["Config"].getKey("Rebar3"));
      }

      if(!isValidRebar(cfg, rebarId)) {
        log_fatal("Unknown Rebar3 id: ", rebarId);
        exit(-1);
      }
      log_debug("installbasedir = ", installbasedir);
      log_debug("repodir = ", repodir);

      string binFullPath = buildNormalizedPath(installbasedir, rebarId, bin);
      log_debug("mapped cmd to execute = ", binFullPath);
      auto argsPassthrough = [bin] ~ cmdline[1 .. $];
      log_debug("Args = ", argsPassthrough);
      execv(binFullPath, argsPassthrough);
    }

}



