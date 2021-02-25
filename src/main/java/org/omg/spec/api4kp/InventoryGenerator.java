package org.omg.spec.api4kp;

import static java.util.Collections.emptyList;
import static org.omg.spec.api4kp.DistUtil.getDistPath;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Stream;
import org.apache.poi.xwpf.usermodel.ParagraphAlignment;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;

public class InventoryGenerator {

  static final String SPEC_DOCUMENT_NUMBER = "ad/2021-02-01";
  static final String INVENTORY_DOCUMENT_NUMBER = "ad/2021-02-02";
  static final String DOCS_DOCUMENT_NUMBER = "ad/2021-02-03";
  static final String XMIS_DOCUMENT_NUMBER = "ad/2021-02-04";
  static final String OPENAPIS_DOCUMENT_NUMBER = "ad/2021-02-05";
  static final String OWL_DOCUMENT_NUMBER = "ad/2021-02-06";
  static final String IDL_DOCUMENT_NUMBER = "ad/2021-02-07";
  static final String XSD_DOCUMENT_NUMBER = "ad/2021-02-08";
  static final String YML_DOCUMENT_NUMBER = "ad/2021-02-09";
  static final String SKOS_DOCUMENT_NUMBER = "ad/2021-02-010";

  static final String UML_DOCUMENT_NUMBER = "ad/2021-02-012";
  static final String IMG_DOCUMENT_NUMBER = "ad/2021-02-013";


  static final String API4KP_BASE_URI = "https://www.omg.org/spec/API4KP/1.0/";
  static final String API4KP_RELEASE_DATE = Integer.toString(20210201);
  static final String API4KP_SPEC_URI = "https://www.omg.org/spec/API4KP/" + API4KP_RELEASE_DATE + "/";
  static final String API4KP_SPEC_SERIES_URI = "https://www.omg.org/spec/API4KP/";

  public static void main(String[] args) throws Exception {

    Path basePath = getDistPath(args);

    DocumentBuilder db = new DocumentBuilder()
        .withTitle("Inventory of Files for the API4KP Revised Submission")
        .withFormat("c")
        .withParagraph("Document Number: " + INVENTORY_DOCUMENT_NUMBER)
        .clearFormat();

    db.withParagraph("Name of Submission/RFC/RTF/FTF Process: "
        + "Application Programming Interfaces (APIs) to Knowledge Bases (KB) RFP");

    db.withParagraph("Primary Contact for this Submission: "
        + "Elisa Kendall, Thematix Partners LLC");

    db.withParagraph("Primary Specification:", "\n\tAssigned Acronym: API4KP");

    db.withFile("Application Programming Interfaces for Knowledge Platforms (API4KP)",
        SPEC_DOCUMENT_NUMBER,
        "Primary specification document for API4KPs (MSWord)",
        true,
        API4KP_BASE_URI + "Alpha2/");

    db.withParagraph("Report from RTF/FTFs: N/A",
        "\n\tTitle: ",
        "\n\tDoc Number: ");

    db.withPageBreak();

    db.withParagraph("Additional Documents:");

    visitTreePath(
        basePath.resolve("html"),
        file -> emptyList(),
        file -> db.withFile("OpenAPI Documentation",
            file.getFileName().toString(),
            XMIS_DOCUMENT_NUMBER,
            file.getFileName().toString() + " API and SDK Documentation",
            true,
            API4KP_BASE_URI + file.getFileName().toString())
    );

    db.withNoteToStaff(
        "Each of these documents is, itself, an HTML document that should be deployed on "
        + "the OMG server as navigable reference in section 7.2 of the specification document.");
    db.clearFormat();

    db.withFile("API4KP Inventory File",
        INVENTORY_DOCUMENT_NUMBER,
        "Inventory",
        false,
        "none");

    db.withPageBreak();

    db.withParagraph("Machine consumable file(s):",
        "\n\tVersion: " + API4KP_RELEASE_DATE);

    db.withFormat("c").withParagraph("UML Models").clearFormat();

    visitTreePath(
        basePath.resolve("uml"),
        f -> f.getFileName().toString().endsWith(".xmi"),
        InventoryGenerator::getUMLDependencies,
        file -> db.withMachineFile("API4KP UML models for the APIs (.xmi)",
            DOCS_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            InventoryGenerator::getUMLDependencies,
            API4KP_SPEC_URI + file.getFileName().toString())
    );

    db.withFormat("c").withParagraph("OpenAPI Specs").clearFormat();

    visitTreePath(
        basePath.resolve("openapi").resolve("v3"),
        path -> emptyList(),
        file -> db.withMachineFile("API4KP OpenAPI 3.x API Spec Files (.yaml)",
            OPENAPIS_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            path -> emptyList(),
            API4KP_SPEC_URI + file.getFileName().toString())
    );

    db.withFormat("c").withParagraph("OWL Ontologies").clearFormat();

    db.withNoteToStaff("The .rdf files listed below as a part of "
        + OWL_DOCUMENT_NUMBER + " are OWL ontologies and should be posted to both the versioned "
        + "and non-versioned URLs to facilitate ‘follow-your-nose’ style loading in ontology tools.");

    visitTreePath(
        basePath.resolve("ontologies").resolve("API4KP"),
        file -> isOntology(file),
        InventoryGenerator::getOWLDependencies,
        file -> db.withMachineFile("API4KP RDF/XML-serialized OWL ontologies (.rdf)",
            OWL_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            isNormative(file),
            InventoryGenerator::getOWLDependencies,
            API4KP_SPEC_URI + file.getFileName().toString(),
                 API4KP_SPEC_SERIES_URI + file.getFileName().toString())
    );

    db.withPageBreak();

    db.withFormat("c").withParagraph("Datatype Schemas").clearFormat();

    Path xsdBase = basePath.resolve("xsd").resolve("API4KP").resolve("api4kp");
    visitTreePath(
        xsdBase,
//        file -> isNormativeOntology(file),
        InventoryGenerator::getXSDDependencies,
        file -> db.withMachineFile("API4KP XML Schemas derived from the UML model files (.xsd)",
            XSD_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            InventoryGenerator::getXSDDependencies,
            API4KP_SPEC_URI + xsdBase.relativize(file).toString().replace(File.separatorChar,'/')));

    Path yamlBase = basePath.resolve("yaml").resolve("API4KP").resolve("api4kp");
    visitTreePath(
        yamlBase,
//        file -> isNormativeOntology(file),
        InventoryGenerator::getYMLDependencies,
        file -> db.withMachineFile("API4KP YML Schemas derived from the UML model files (.yaml)",
            YML_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            InventoryGenerator::getYMLDependencies,
            API4KP_SPEC_URI + yamlBase.relativize(file).toString().replace(File.separatorChar,'/')));


    db.withPageBreak();

    db.withFormat("c").withParagraph("Controlled Vocabularies (Valuesets)").clearFormat();

    visitTreePath(
        basePath.resolve("skos"),
//        file -> isNormativeOntology(file),
        s -> emptyList(),
        file -> db.withMachineFile("API4KP SKOS vocabularies derived from the OWL ontologies (.skos.rdf)",
            SKOS_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            s -> emptyList(),
            API4KP_SPEC_URI + "taxonomy/" + file.getFileName()));

    db.withFormat("c").withParagraph("Controlled Vocabularies (XSD Variant)").clearFormat();

    visitTreePath(
        basePath.resolve("xsd").resolve("org"),
//        file -> isNormativeOntology(file),
        s -> emptyList(),
        file -> db.withMachineFile("API4KP Vocabularies derived from the OWL ontologies (.xsd)",
            XSD_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            s -> emptyList(),
            API4KP_SPEC_URI + file.getFileName()));

    db.withFormat("c").withParagraph("Controlled Vocabularies (YAML Variant)").clearFormat();

    visitTreePath(
        basePath.resolve("yaml").resolve("org"),
//        file -> isNormativeOntology(file),
        s -> emptyList(),
        file -> db.withMachineFile("API4KP YML Schemas derived from the UML model files (.yaml)",
            YML_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            s -> emptyList(),
            API4KP_SPEC_URI + file.getFileName()));

    db.withPageBreak();

    db.withFormat("c").withParagraph("IDL Files").clearFormat();

    // IDLs

    visitTreePath(
        basePath.resolve("idl"),
        s -> emptyList(),
        file -> db.withMachineFile("API4KP IDL files (.idl)",
            IDL_DOCUMENT_NUMBER,
            file.getFileName().toString(),
            true,
            s -> emptyList(),
            API4KP_SPEC_URI + file.getFileName()));

    db.withPageBreak();

    db.withFormat("c").withParagraph("Additional Documentation").clearFormat();

    db.withMachineFileTextual("API4KP Ancillary UMLDesigner UML model files (ancillary)",
        UML_DOCUMENT_NUMBER,
        "API4KP UMLDesigner Model Files.zip",
        false,
        s -> emptyList(),
        "none");

    db.withMachineFileTextual("API4KP .svg images (ancillary)",
        IMG_DOCUMENT_NUMBER,
        "API4KP Image Files.zip",
        false,
        s -> emptyList(),
        "none");

    save(basePath, db.get());
  }

  private static boolean isOntology(Path file) {
    return file.getFileName().toString().endsWith(".rdf");
  }

  public static boolean isNormative(Path file) {
    return ! file.toString().contains("informative");
  }

  private static List<String> getOWLDependencies(String file) {
    switch (file) {
      case "api4kp.rdf" : return emptyList();
      case "api4kp-kao.rdf" :
      case "api4kp-kmdo.rdf" :
      case "api4kp-rel.rdf" :
      case "api4kp-registry.rdf" :
      case "api4kp-series.rdf" :
      case "api4kp-kp.rdf" : return Collections.singletonList("api4kp.rdf");
      case "api4kp-krr.rdf" : return Arrays.asList("api4kp.rdf", "api4kp-lang.rdf", "api4kp-series.rdf");
      case "api4kp-lang.rdf" : return Arrays.asList("api4kp.rdf", "api4kp-series.rdf");
      case "api4kp-ops.rdf" : return Arrays.asList("api4kp.rdf", "api4kp-krr.rdf", "api4kp-lang.rdf", "api4kp-rel.rdf", "api4kp-series.rdf");
      case "api4kp-ckao.rdf" : return Arrays.asList("api4kp.rdf", "api4kp-kao.rdf");
      case "api4kp-kpc.rdf" : return Arrays.asList("api4kp.rdf", "api4kp-kp.rdf");
      default:
        throw new IllegalStateException("Unrecognized OWL file " + file);
    }
  }

  private static List<String> getUMLDependencies(String file) {
    switch (file) {
      case "api4kp.xmi" : return emptyList();
      case "api4kp_uml_profiles.xmi" : return Collections.singletonList("api4kp.xmi");
      case "vocabs.xmi" : return Arrays.asList("api4kp_uml_profiles.xmi", "api4kp.xmi");
      case "API4KP-VOMModelFiles-20210201.zip" : return emptyList();
      default:
        throw new IllegalStateException("Unrecognized UML file " + file);
    }
  }
  
  private static List<String> getXSDDependencies(String file) {
    switch (file) {
      case "datatypes.xsd" :
      case "api4kp.xsd" : return emptyList();

      case "id.xsd" : return Collections.singletonList("api4kp.xsd");

      case "services.xsd" : return Collections.singletonList("id.xsd");

      case "inference.xsd" :
      case "transrepresentation.xsd" :
      case "repository.xsd" : return Collections.singletonList("services.xsd");

      case "surrogate.xsd" : return Arrays.asList("id.xsd", "services.xsd");
      default:
        throw new IllegalStateException("Unrecognized XSD file " + file);
    }
  }

  private static List<String> getYMLDependencies(String file) {
    switch (file) {
      case "datatypes.yaml" :
      case "api4kp.yaml" : return emptyList();

      case "id.yaml" : return Collections.singletonList("api4kp.yaml");

      case "services.yaml" : return Collections.singletonList("id.yaml");

      case "inference.yaml" :
      case "transrepresentation.yaml" :
      case "repository.yaml" : return Collections.singletonList("services.yaml");

      case "surrogate.yaml" : return Arrays.asList("id.yaml", "services.yaml");
      default:
        throw new IllegalStateException("Unrecognized YML file " + file);
    }
  }

  private static void visitTreePath(
      Path root, Function<String,List<String>> deps, Consumer<Path> fun) throws IOException {
    visitTreePath(root, path -> true, deps, fun);
  }

  private static void visitTreePath(
      Path root, Predicate<Path> filter, Function<String, List<String>> deps, Consumer<Path> fun) throws IOException {
    Set<Path> pathSet = new HashSet<>();
    Files.walkFileTree(root, new SimpleFileVisitor<>() {
      @Override
      public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
        if (!filter.test(file)) {
          return FileVisitResult.CONTINUE;
        }
        pathSet.add(file);
        return FileVisitResult.CONTINUE;
      }
    });
    pathSet.stream()
        .sorted((p1, p2) -> {
          String f1 = p1.getFileName().toString();
          String f2 = p2.getFileName().toString();
          if (deps.apply(f1).contains(f2)) {
            return 1;
          } else if (deps.apply(f2).contains(f1)) {
            return -1;
          }
          if (isNormative(p1) && !isNormative(p2)) {
            return -1;
          } else if (isNormative(p2) && !isNormative(p1)) {
            return 1;
          }
          return 0;
        })
        .forEach(fun);

  }


  private static void save(Path basePath, XWPFDocument document) throws Exception {
    Path path = basePath.resolve("API4KP Inventory.docx");
    OutputStream out = Files.newOutputStream(path);
    document.write(out);
    out.close();
  }

  public static class DocumentBuilder {

    XWPFDocument document = new XWPFDocument();
    String format = "";

    public DocumentBuilder withTitle(String titleText) {
      XWPFParagraph title = document.createParagraph();
      title.setAlignment(ParagraphAlignment.CENTER);
      XWPFRun run = title.createRun();
      run.setBold(true);
      run.setFontFamily("Arial");
      run.setFontSize(16);
      run.setText(titleText);
      return this;
    }

    public DocumentBuilder withParagraph(String run) {
      return withParagraph(Stream.of(run));
    }

    public DocumentBuilder withParagraph(String... runs) {
      return withParagraph(Arrays.stream(runs));
    }

    public DocumentBuilder withParagraph(Stream<String> runs) {
      XWPFParagraph para = document.createParagraph();
      if (format.contains("c")) {
        para.setAlignment(ParagraphAlignment.CENTER);
      }

      runs
          .forEach(text -> {
            if ("" .equals(text)) {
              return;
            }

            String txt = text;
            XWPFRun run = para.createRun();
            run.setFontFamily("Times");
            run.setFontSize(12);
            run.setBold(format.contains("b"));
            run.setItalic(format.contains("i"));

            boolean flag = txt.length() > 0;
            while (flag || txt.charAt(0) == '\t' || txt.charAt(0) == '\n') {
              if (txt.charAt(0) == '\t') {
                run.addTab();
                txt = txt.substring(1);
              } else if (txt.charAt(0) == '\n') {
                run.addCarriageReturn();
                txt = txt.substring(1);
              } else {
                flag = false;
              }
            }
            run.setText(txt);
          });

      return this;
    }

    public DocumentBuilder withFormat(String fmt) {
      this.format = fmt;
      return this;
    }

    public DocumentBuilder clearFormat() {
      return withFormat("");
    }

    public XWPFDocument get() {
      return document;
    }

    public DocumentBuilder withFile(
        String title, String docNum, String descr, boolean norm, String url) {
      return withFileTextual(title, null, docNum, descr, norm, url);
    }

    public DocumentBuilder withFile(
        String title, String subTitle, String docNum, String descr, boolean norm, String url) {
      return withFileTextual(title, subTitle, docNum, descr, norm, url);
    }

    private DocumentBuilder withFileTextual(
        String title, String subTitle, String docNum, String descr, boolean norm, String url) {

      List<String> l = new ArrayList<>();
      l.add("\n\tTitle:");
      l.add("\t\t" + title);
      if (subTitle != null) {
        l.add("\n\tSubitle:");
        l.add("\t" + subTitle);
      }
      l.add("\n\tDoc Number:");
      l.add("\t" + docNum);
      l.add("\n\tDescription:");
      l.add("\t" + descr);
      l.add("\n\tNormative:");
      l.add("\t" + (norm ? "Yes" : "No (ancillary)"));
      l.add("\n\tURL:");
      l.add("\t\t" + url);

      return withParagraph(l.stream());
    }

    public DocumentBuilder withMachineFile(
        String descr, String docNum, String fileName, boolean norm,
        Function<String, List<String>> deps, String... url) {
      return withMachineFileTextual(descr, docNum, fileName, norm, deps, url);
    }

    private DocumentBuilder withMachineFileTextual(
        String descr, String docNum, String fileName, boolean norm,
        Function<String, List<String>> deps, String... url) {

      List<String> depNames = deps.apply(fileName);

      List<String> l = new ArrayList<>();
      l.add("\n\tDescription:");
      l.add("\t" + descr);
      l.add("\n\tDoc Number:");
      l.add("\t" + docNum);
      l.add("\n\tFilename:");
      l.add("\t" + fileName);
      l.add("\n\tNormative:");
      l.add("\t" + (norm ? "Yes" : "No (ancillary)"));
      l.add("\n\tDependencies:");
      l.add("\t" + (depNames.isEmpty() ? "none" : String.join(", ",depNames)) );
      Arrays.stream(url).forEach(u -> {
        l.add("\n\tURL:");
        l.add("\t\t" + u);
      });

      return withParagraph(l.stream());
    }


    public void withPageBreak() {
      XWPFParagraph paragraph = document.createParagraph();
      paragraph.setPageBreak(true);
    }

    public void withNoteToStaff(String note) {
      this.withFormat("i")
          .withParagraph("\tNote to OMG Staff: " + note)
          .clearFormat();
    }
  }
}
