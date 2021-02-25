/**
 * Copyright © 2018 Mayo Clinic (RSTKNOWLEDGEMGMT@mayo.edu)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.omg.spec.api4kp.idl;

import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.idSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.inferSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.karSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.kasSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.kbconstrSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.langSource;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.loadSchemas;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.readBytes;
import static org.omg.spec.api4kp.idl.SwaggerLoaderHelper.repoSource;

import edu.mayo.kmdp.SwaggerToIDLTranslator;
import edu.mayo.kmdp.util.NameUtils;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.omg.spec.api4kp.DistUtil;

public class SwaggerToIDL {

  private Path tgtPath;

  public SwaggerToIDL(Path tgtPath) {
    this.tgtPath = tgtPath;
  }

  public static void main(String... args) {
    Path tgtPath = DistUtil.getDistPath(args);

    SwaggerToIDL s2i = new SwaggerToIDL(tgtPath);
    s2i.translateArtifactAPI();
    s2i.translateAssetAPI();
    s2i.translateLangAPI();
    s2i.translateKBaseAPI();
    s2i.translateReasonAPI();
  }

  public void translateArtifactAPI() {
    List<byte[]> sources = Stream.of(
        readBytes(tgtPath, karSource),
        readBytes(tgtPath, idSource),
        readBytes(tgtPath, repoSource)).collect(Collectors.toList());
    toIDL("Knowledge Artifact Repository", sources);
  }

  public void translateAssetAPI() {
    String title = "Knowledge Asset Repository";
    List<byte[]> sources = loadSchemas(tgtPath);
    sources.add(0, readBytes(tgtPath, kasSource));
    toIDL(title, sources);
  }

  public void translateLangAPI() {
    String title = "Knowledge Asset Transrepresentation";
    List<byte[]> sources = loadSchemas(tgtPath);
    sources.add(0, readBytes(tgtPath, langSource));
    toIDL(title, sources);
  }

  public void translateKBaseAPI() {
    String title = "Knowledge Base Construction";
    List<byte[]> sources = loadSchemas(tgtPath);
    sources.add(0, readBytes(tgtPath, kbconstrSource));
    toIDL(title, sources);
  }

  public void translateReasonAPI() {
    String title = "Knowledge Reasoning";
    List<byte[]> sources = loadSchemas(tgtPath);
    sources.add(0, readBytes(tgtPath, inferSource));
    toIDL(title, sources);
  }


  private void toIDL(String title, List<byte[]> sources) {
    
    List<String> target = new SwaggerToIDLTranslator()
        .translate(sources);

    target.forEach(s ->
    {
      try {
        Path out = getTargetPath(title);
        Files.createDirectories(out.getParent());
        Files.write(getTargetPath(title), s.getBytes());
      } catch (IOException e) {
        e.printStackTrace();
      }
    });
  }

  private Path getTargetPath(String title) {
    return tgtPath.resolve("idl-gen").resolve(NameUtils.camelCase(title) + ".idl");
  }

}
