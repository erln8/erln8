import std.file;
import std.path;
import std.c.stdlib; // exit()
import std.process;
import std.stdio;

import dini;
import log;

const erln8_version = "2.0beta0";

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

string getMakeBin() {
  try {
    string make_bin = environment["MAKE_BIN"];
    log_debug("Using MAKE_BIN env var:", make_bin);
    return make_bin;
  } catch (Exception e) {
    log_debug("Using make");
    return "make";
  }
}

string getConfigDir() {
  // should be already expandTilde'd
  return buildNormalizedPath(defaultHome(), ".erln8.d");
}

// used in testing
string getDefaultOTPUrl() {
  try {
      string defaultUrl = environment["ERLN8_OTP_DEFAULT_URL"];
      log_debug("Using ERLN8_OTP_DEFAULT_URL env var:", defaultUrl);
      return defaultUrl;
    } catch (Exception e) {
      return "https://github.com/erlang/otp.git";
    }
}

