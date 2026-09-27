# Project 2 — VAT Processing Build & Release with JFrog Artifactory

This is an original training project for a **2017–2018 enterprise Build & Release workflow**. The official product artifact is a **versioned executable Java JAR**. Maven compiles it, runs engineering qualification, and publishes the qualified artifact to **JFrog Artifactory** before SQA handover.

It is not employer source code and does not reproduce any proprietary ADP implementation.

## Build & Release boundary

```text
Developer commit
    ↓
mvn clean deploy
    ↓
Maven compile
    ↓
Surefire unit tests
    ↓
Maven package
    ↓
Versioned executable JAR
    ↓
Failsafe packaged-JAR smoke test
    ↓
Failsafe batch integration test
    ↓
Maven verify
    ↓
Maven deploy
    ↓
JFrog Artifactory
    ↓
Build metadata + Maven test evidence
    ↓
SQA handover
    ↓
SQA full functional/regression testing
```

There is **no HTTP test surface, Docker Compose, or Docker Swarm** in this project. Docker remains optional and is not part of the official release flow.

## Official release coordinates

```text
Group ID:    com.example.vat
Artifact ID: vat-processing-service
Version:     1.0.0
Packaging:   jar
```

Local build artifact:

```text
target/vat-processing-service-1.0.0.jar
```

After `mvn deploy`, Artifactory stores it under Maven coordinates similar to:

```text
com/example/vat/vat-processing-service/1.0.0/
```

## JAR business modes

```bash
java -jar target/vat-processing-service-1.0.0.jar calculate INV-1 GB STANDARD 1000.00
```

```bash
java -jar target/vat-processing-service-1.0.0.jar batch samples/invoices.csv target/vat-return.json
```

## Tests are Maven-driven

### Unit tests — Maven Surefire

```bash
mvn clean test
```

### Complete local qualification

```bash
mvn clean verify
```

This runs unit tests, creates the JAR, and executes the packaged-JAR smoke and integration tests through Maven Failsafe.

### Complete qualification + Artifactory publish

After JFrog is configured:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  clean deploy
```

`deploy` is the Maven repository-publishing lifecycle phase; it does **not** deploy the application to an application server.

If any unit, smoke, or integration test fails before `deploy`, Maven does not upload the artifact.

## JFrog configuration

Read:

```text
docs/JFROG-INTEGRATION.md
```

The repository contains:

```text
config/settings-jfrog.xml.example
```

It uses environment variables for the Artifactory username/token. No real credentials belong in Git.

## Repository layout

```text
.
├── src/main/java/                         production VAT code
├── src/test/java/
│   ├── .../*Test.java                     unit tests (Surefire)
│   ├── .../smoke/*SmokeIT.java            packaged-JAR smoke tests (Failsafe)
│   └── .../integration/*IntegrationIT.java packaged-JAR integration tests (Failsafe)
├── samples/                               approved sample input/output
├── config/
│   └── settings-jfrog.xml.example         Maven/JFrog credential mapping
├── docs/
│   ├── JFROG-INTEGRATION.md
│   └── architecture/release diagrams
├── sqa-template/                          release-note handover template
├── automation/                            future Jenkins-stage suggestions only
├── pom.xml                                Maven lifecycle + distributionManagement
├── Dockerfile                             optional JAR image packaging only
├── MANUAL-COMMANDS.md
└── TOOLS-AND-INSTALLATION.md
```

## Recommended learning order

1. `mvn clean test`
2. `mvn clean verify`
3. Inspect Surefire/Failsafe reports and the JAR
4. Configure a JFrog Maven local repository
5. Configure `JFROG_*` environment variables
6. Run `mvn clean deploy`
7. Find the exact JAR in Artifactory
8. Assemble the SQA handover referencing that published artifact
9. Only then automate the same flow in Jenkins
