import std.stdio;
//import std.string;
//import std.file;
//import std.process;
import core.thread;

class Spinner : Thread
{
  this() {
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
        Thread.sleep(dur!("msecs")(100));
        write("\b");
        stdout.flush();
      i++;
    }
  }
  bool running = false;
}

