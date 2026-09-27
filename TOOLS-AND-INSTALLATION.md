# Tools and installation

This project represents a 2017–2018 enterprise Java Build & Release workflow. Maven owns compilation, testing, packaging, verification, and repository deployment.

## Required local tools

| Tool | Purpose |
|---|---|
| Git | source/release traceability |
| JDK 8 or newer | compile/run Java 8-compatible application |
| Maven | compile, unit test, package, smoke/integration test, deploy |
| `sha256sum` | release integrity evidence |
| `tar` / `gzip` | optional SQA transport bundle |
| `unzip` | inspect JAR content |
| Graphviz | regenerate diagrams only |

No HTTP/curl test flow is required by the application test suite.

## Maven-managed tooling

`pom.xml` defines:

- JUnit 4.12
- Maven Compiler Plugin 3.7.0
- Maven Surefire Plugin 2.20.1
- Maven JAR Plugin 3.0.2
- Maven Failsafe Plugin 2.20.1
- Maven Deploy Plugin 2.8.2

The versions are intentionally aligned with the historical Java 8 / 2017-era learning goal.

## Ubuntu lab setup

```bash
sudo apt-get update
sudo apt-get install -y git default-jdk maven unzip zip tar gzip graphviz
```

Verify:

```bash
git --version
java -version
javac -version
mvn -version
sha256sum --version | head -1
dot -V
```

A modern JDK can compile this source with Java 8 source/target compatibility. For closer historical runtime behavior, use a maintained JDK 8 distribution in an isolated lab.

## JFrog Artifactory requirements

You need access to a JFrog Artifactory instance and deploy permission to Maven **local** repositories.

Typical repository layout:

```text
libs-release-local
libs-snapshot-local
```

You also need:

```text
JFrog base URL
Artifactory username
Access/identity token
Release repository name
Snapshot repository name
```

The project includes:

```text
config/settings-jfrog.xml.example
docs/JFROG-INTEGRATION.md
```

No Artifactory password/token is stored in source control.

## Optional tools

| Tool | Purpose |
|---|---|
| SonarQube | Maven quality gate |
| Jenkins | automate the Maven/JFrog flow after manual learning |
| Docker Engine | optional image packaging only |
| JFrog CLI | modern build-info/Xray integration, optional later exercise |

For this project, learn native `mvn deploy` first. JFrog CLI can be added later when you move to a modern CI implementation.
