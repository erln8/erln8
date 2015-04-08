import std.stdio;

class Impl {
  string name;
  string[] commands;

  abstract void processArgs(string args[]);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();
}


class Erln8Impl : Impl {
  this() {
    name = "erln8";
    commands = ["erlc"];
  }

  override void processArgs(string args[]) {

  }

  override void runCommand(string[] cmdline) {
    writeln("Running ", cmdline);
  }

  override void runConfig() {

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
