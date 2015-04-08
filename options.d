import std.getopt;
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

Erln8Options getOptions(string[] args) {
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
  return opts;
}
