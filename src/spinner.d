import std.stdio;
import core.thread;
import colorize : fg, color, cwrite;

class SlowSpinner : Spinner {
  this() {
    super(500);
  }
}

class FastSpinner : Spinner {
  this() {
    super(50);
  }
}

class Spinner : Thread
{
  this() {
    super(&run);
  }

  this(int d) {
    delay = d;
    super(&run);
  }

  void stop() {
    running = false;
  }

private:
  void run() {
    running = true;
    auto chars = "|/-\\";
    int i = 0;
    while(running) {
      if(i == chars.length)
        i=0;
        write(chars[i]);
        Thread.sleep(dur!("msecs")(delay));
        write("\b");
        stdout.flush();
      i++;
    }
    write(" ");
    stdout.flush();
  }
  bool running = false;
  int delay = 100;
}


class Kit : Thread
{
  this() {
    super(&run);
  }

  this(int d) {
    delay = d;
    super(&run);
  }

  void stop() {
    running = false;
  }

private:
  void run() {
    running = true;
    auto chars = "|/-\\";
    string[] lines = ["  [*       ]",
                      "  [ *      ]",
                      "  [  *     ]",
                      "  [   *    ]",
                      "  [    *   ]",
                      "  [     *  ]",
                      "  [      * ]",
                      "  [       *]"];

    int i = 0;
    int inc = 1;
    while(running) {
        write(lines[i]);
        Thread.sleep(dur!("msecs")(delay));
        write("\b\b\b\b\b\b\b\b\b\b\b\b");
        stdout.flush();
        if(i == 7) {
          inc = -1;
        } else if(i == 0) {
          inc = 1;
        }
        i += inc;
    }
    write("            ");
    stdout.flush();
  }
  bool running = false;
  int delay = 100;
}

