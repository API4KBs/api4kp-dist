package org.omg.spec.api4kp.idl;

import edu.mayo.kmdp.util.FileUtil;
import edu.mayo.kmdp.util.StreamUtil;
import java.io.IOException;
import java.io.InputStream;
import java.net.JarURLConnection;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Stream;

public class SwaggerLoaderHelper {

  static final String VERSION = "v20210201";

  public final static String karSource =
      "/openapi/v2/org/omg/spec/api4kp/" + VERSION + "/knowledgeArtifactRepository.swagger.yaml";
  public final static String kasSource =
      "/openapi/v2/org/omg/spec/api4kp/" + VERSION + "/knowledgeAssetRepository.swagger.yaml";
  public final static String langSource =
      "/openapi/v2/org/omg/spec/api4kp/" + VERSION + "/knowledgeAssetTransrepresentation.swagger.yaml";
  public final static String kbconstrSource =
      "/openapi/v2/org/omg/spec/api4kp/" + VERSION + "/knowledgeBaseConstruction.swagger.yaml";
  public final static String inferSource =
      "/openapi/v2/org/omg/spec/api4kp/" + VERSION + "/knowledgeReasoning.swagger.yaml";

  public final static String idSource = "/yaml/API4KP/api4kp/id/id.yaml";
  public final static String dataTypeSource = "/yaml/API4KP/api4kp/datatypes/datatypes.yaml";
  public final static String serviceSource = "/yaml/API4KP/api4kp/services/services.yaml";
  public final static String repoSource = "/yaml/API4KP/api4kp/services/repository/repository.yaml";
  public final static String infSource = "/yaml/API4KP/api4kp/services/inference/inference.yaml";
  public final static String tranxSource = "/yaml/API4KP/api4kp/services/transrepresentation/transrepresentation.yaml";

  public final static String metadata = "/yaml/API4KP/surrogate/surrogate.yaml";


  public static List<byte[]> loadSchemas(Path root) {
    List<String> files = new ArrayList<>();

    files.add(idSource);
    files.add(dataTypeSource);
    files.add(serviceSource);
    files.add(repoSource);
    files.add(infSource);
    files.add(tranxSource);
    files.add(metadata);

    List<byte[]> inputBinaries = new ArrayList<>();
    files.stream().map(f -> SwaggerLoaderHelper.readBytes(root, f)).forEach(inputBinaries::add);

    try {
      URL resRoot = SwaggerLoaderHelper.class.getResource("/yaml");

      JarURLConnection jarEntryConn = (JarURLConnection) resRoot.openConnection();
      String entryName = jarEntryConn.getEntryName();
      try (FileSystem jfs = FileSystems.newFileSystem(resRoot.toURI(), new HashMap<>())) {
        Path path = jfs.getPath(entryName);
        try (Stream<Path> filePaths = Files.walk(path)) {
          filePaths.filter(Files::isRegularFile)
              .filter(f -> f.toString().endsWith(".yaml"))
              .map(SwaggerLoaderHelper::openStream)
              .map(FileUtil::readBytes)
              .flatMap(StreamUtil::trimStream)
              .forEach(inputBinaries::add);
        }
      }

    } catch (IOException | URISyntaxException e) {
      e.printStackTrace();
    }
    return inputBinaries;
  }


  public static byte[] readBytes(Path tgtPath, String source) {
    if (source.startsWith("/")) {
      source = source.substring(1);
    }
    return FileUtil.readBytes(openStream(tgtPath.resolve(source)))
        .orElseThrow();
  }

  public static InputStream openStream(String filePath) {
    try {
      return openStream(Path.of(SwaggerLoaderHelper.class.getResource(filePath).toURI()));
    } catch (URISyntaxException e) {
      e.printStackTrace();
    }
    System.exit(-1);
    return null;
  }

  public static InputStream openStream(Path filePath) {
    try {
      return Files.newInputStream(filePath);
    } catch (IOException e) {
      e.printStackTrace();
    }
    System.exit(-1);
    return null;
  }
}
