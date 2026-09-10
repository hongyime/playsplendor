package com.splendor.test;

import static org.junit.jupiter.api.Assertions.*;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import javax.tools.DocumentationTool;
import javax.tools.ToolProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import org.junit.jupiter.api.io.TempDir;

/** Builds real API documentation and verifies the preserved project diagrams. */
@DisplayName("Documentation generation and archive checks")
public class DocumentationTest {
    @TempDir static Path temporary;
    private static Path api;
    private static List<Path> sources;

    @BeforeAll
    @Timeout(60)
    static void generateDocumentation() throws Exception {
        try (var files = Files.walk(Path.of("src"))) {
            sources = files.filter(path -> path.toString().endsWith(".java")).sorted().collect(Collectors.toList());
        }
        assertFalse(sources.isEmpty(), "Java source files must be available");
        api = temporary.resolve("javadoc");
        DocumentationTool tool = ToolProvider.getSystemDocumentationTool();
        assertNotNull(tool, "Run with a JDK, not a JRE");
        ByteArrayOutputStream diagnostics = new ByteArrayOutputStream();
        int result = tool.run(null, diagnostics, diagnostics, "-d", api.toString(),
                "-sourcepath", "src", "-subpackages", "com.splendor", "--release", "17",
                "-encoding", "UTF-8", "-docencoding", "UTF-8", "-charset", "UTF-8",
                "-Xdoclint:all,-missing", "-quiet", "-notimestamp");
        assertEquals(0, result, diagnostics.toString(StandardCharsets.UTF_8));
    }

    @Test
    @DisplayName("Generated API indexes are present and readable")
    void generatedIndexes() throws Exception {
        for (String name : List.of("index.html", "allclasses-index.html", "allpackages-index.html")) {
            String html = Files.readString(api.resolve(name), StandardCharsets.UTF_8);
            assertTrue(html.toLowerCase().contains("<!doctype html>"), name);
            assertTrue(html.contains("com.splendor"), name);
        }
    }

    @Test
    @DisplayName("Every Java source type has an API page")
    void everySourceHasDocumentation() {
        for (Path source : sources) {
            if (source.getFileName().toString().equals("package-info.java")) continue;
            String page = Path.of("src").relativize(source).toString().replaceAll("\\.java$", ".html");
            assertTrue(Files.isRegularFile(api.resolve(page)), "Missing API page for " + source);
        }
    }

    @Test
    @DisplayName("Every source package has a generated summary")
    void everyPackageHasSummary() {
        Set<Path> packages = sources.stream().map(path -> Path.of("src").relativize(path.getParent())).collect(Collectors.toSet());
        for (Path path : packages) assertTrue(Files.isRegularFile(api.resolve(path).resolve("package-summary.html")), path.toString());
    }

    @Test
    @DisplayName("Archived diagrams retain real PNG data and PlantUML sources")
    void archivedDiagramsAreUsable() throws Exception {
        byte[] signature = {(byte)137, 80, 78, 71, 13, 10, 26, 10};
        for (String name : List.of("splendor", "splendor-class-light", "splendor-dependency", "splendor-functional", "splendor-inheritance")) {
            Path directory = Path.of("site", "diagrams");
            byte[] image = Files.readAllBytes(directory.resolve(name + ".png"));
            assertTrue(image.length > signature.length, name);
            assertArrayEquals(signature, java.util.Arrays.copyOf(image, signature.length), name);
            String source = Files.readString(directory.resolve(name + ".puml"), StandardCharsets.UTF_8);
            assertTrue(source.contains("@startuml") && source.contains("@enduml"), name);
        }
    }
}
