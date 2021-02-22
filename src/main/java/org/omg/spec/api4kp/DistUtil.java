package org.omg.spec.api4kp;

import java.nio.file.Path;

public class DistUtil {

  private DistUtil() {
    //
  }

  public static Path getDistPath(String[] args) {
    String path = args.length > 0
        ? args[0]
        : "C:\\Users\\M123110\\Projects\\API4KP\\api4kp-dist\\dist\\";
    return Path.of(path);
  }

}
