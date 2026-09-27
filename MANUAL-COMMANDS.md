# Manual Build & Release Commands — Maven Driven

The objective is to behave like a Build & Release engineer: use Maven as the single Java build/test controller, produce one qualified versioned JAR, collect test evidence, and hand that exact artifact to SQA.

Run commands from the repository root.

## 1. Identify the source revision

```bash
git status
git rev-parse HEAD
git log -1 --oneline
```

If you downloaded a ZIP and want to practice traceability:

```bash
git init
git add .
git commit -m "Initial VAT Build and Release training source"
```

## 2. Verify the toolchain

```bash
java -version
javac -version
mvn -version
git --version
```

For this project, do not manually call `javac`, `java` for tests, or `jar` to produce the release artifact. Maven owns those lifecycle steps.

## 3. Inspect the Maven project before building

```bash
mvn help:effective-pom > target-effective-pom.xml
```

Useful things to understand in `pom.xml`:

- `maven-compiler-plugin` compiles Java 8-compatible code;
- `maven-surefire-plugin` runs `*Test.java` unit tests;
- `maven-jar-plugin` creates the executable product JAR;
- `maven-failsafe-plugin` runs `*IT.java` after the JAR has been packaged.

## 4. Clean and compile with Maven

```bash
mvn clean compile
```

Inspect the generated classes:

```bash
find target/classes -type f -name '*.class' | sort
```

## 5. Run the unit / engineering test phase through Maven

```bash
mvn test
```

This runs the JUnit unit tests through Maven Surefire.

Inspect the reports:

```bash
find target/surefire-reports -type f -maxdepth 1 -print | sort
```

Typical unit scope:

- standard/reduced/zero VAT rules;
- reverse charge;
- unsupported-country validation;
- invalid amount validation;
- batch aggregation logic.

This is not the full tax QA suite.

## 6. Optional SonarQube gate through Maven

When your SonarQube lab is ready, use Maven rather than a separate scanner command:

```bash
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.projectKey=vat-processing-service
```

In a real organization the token would come from credential storage, not from source code.

## 7. Package the official JAR through Maven

```bash
mvn package
```

Because Maven `package` includes earlier lifecycle phases, the unit tests run again unless intentionally skipped.

Official artifact:

```text
target/vat-processing-service-1.0.0.jar
```

Inspect it:

```bash
ls -lh target/vat-processing-service-1.0.0.jar
jar tf target/vat-processing-service-1.0.0.jar | head -30
unzip -p target/vat-processing-service-1.0.0.jar META-INF/MANIFEST.MF
```

Do not recreate the JAR manually after this point. The Maven-built artifact is the candidate that must be qualified and handed to SQA.

## 8. Run the complete packaged-artifact qualification through Maven

```bash
mvn verify
```

`verify` runs the Maven lifecycle in this order:

```text
compile
  ↓
test-compile
  ↓
test                  Surefire unit tests
  ↓
package               executable JAR created
  ↓
integration-test      Failsafe packaged-JAR tests
  ↓
verify                 build fails if an IT failed
```

The two post-package test types are intentionally different.

### JAR smoke test

Class:

```text
VatJarSmokeIT
```

Maven Failsafe launches:

```text
java -jar target/vat-processing-service-1.0.0.jar calculate ...
```

and asserts that the packaged artifact returns the expected representative VAT result.

### Batch integration test

Class:

```text
VatBatchIntegrationIT
```

Maven Failsafe launches the packaged JAR in batch mode against:

```text
samples/invoices.csv
```

and compares its output with:

```text
samples/expected-vat-return.json
```

Inspect the reports:

```bash
find target/failsafe-reports -type f -maxdepth 1 -print | sort
```

Inspect the integration output:

```bash
cat target/integration-vat-return.json
```

## 9. The one-command Build & Release gate

From a clean checkout, the main qualification command is:

```bash
mvn clean verify
```

If this returns non-zero, do **not** hand the JAR to SQA.

If it passes, you have evidence for:

- clean compile;
- unit tests;
- executable JAR packaging;
- packaged-JAR smoke test;
- packaged-JAR integration test.

## 10. Configure JFrog Artifactory for Maven deploy

Read the complete explanation in:

```text
docs/JFROG-INTEGRATION.md
```

You need two Maven **local** Artifactory repositories (names are examples):

```text
libs-release-local
libs-snapshot-local
```

Export your JFrog configuration:

```bash
export JFROG_URL='https://your-company.jfrog.io'
export JFROG_RELEASE_REPO='libs-release-local'
export JFROG_SNAPSHOT_REPO='libs-snapshot-local'
export JFROG_USERNAME='your-artifactory-user'
export JFROG_TOKEN='your-access-or-identity-token'
```

Do not print `JFROG_TOKEN` in build logs.

The Maven credential file is:

```text
config/settings-jfrog.xml.example
```

It references the username/token through environment variables. The `server/id` values match the IDs in the `distributionManagement` section of `pom.xml`.

Inspect the release repository URL Maven resolved:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  help:evaluate \
  -Dexpression=project.distributionManagement.repository.url \
  -q \
  -DforceStdout
```

Expected shape:

```text
https://your-company.jfrog.io/artifactory/libs-release-local
```

## 11. Run the complete release build and deploy it to JFrog

The primary Build & Release command is now:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  clean deploy
```

Maven executes the lifecycle in order:

```text
clean
  ↓
compile
  ↓
test                  Surefire unit tests
  ↓
package               JAR created
  ↓
integration-test      Failsafe smoke/integration tests
  ↓
verify                 qualification must pass
  ↓
install                local ~/.m2 repository
  ↓
deploy                 upload to JFrog Artifactory
```

If a unit test or Failsafe test fails, Maven exits before the `deploy` upload.

For the current `1.0.0` release version, Maven uses:

```text
jfrog-releases
```

and publishes to the repository defined by:

```text
JFROG_RELEASE_REPO
```

A `*-SNAPSHOT` project version would use `jfrog-snapshots` instead.

## 12. Confirm the artifact in Artifactory

In the JFrog UI browse to the configured release repository and locate:

```text
com/
└── example/
    └── vat/
        └── vat-processing-service/
            └── 1.0.0/
                ├── vat-processing-service-1.0.0.jar
                └── vat-processing-service-1.0.0.pom
```

Record the repository name, Maven coordinates, and artifact path for the SQA handover.

The coordinates are:

```text
com.example.vat:vat-processing-service:1.0.0
```

## 13. Generate local release integrity information

Artifactory maintains repository metadata/checksums, but Build & Release can also create a local SHA-256 file for the handover packet:

```bash
sha256sum \
  target/vat-processing-service-1.0.0.jar \
  > target/vat-processing-service-1.0.0.jar.sha256
```

Verify it:

```bash
sha256sum -c target/vat-processing-service-1.0.0.jar.sha256
```

## 14. Create build metadata

```bash
mkdir -p sqa-handover
```

```bash
{
  echo 'product=vat-processing-service'
  echo 'version=1.0.0'
  echo 'maven_coordinates=com.example.vat:vat-processing-service:1.0.0'
  echo "jfrog_repository=${JFROG_RELEASE_REPO}"
  echo "git_commit=$(git rev-parse HEAD 2>/dev/null || echo source-zip)"
  echo "build_time_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "builder=$(whoami)"
  echo "host=$(hostname)"
  echo "java_version=$(java -version 2>&1 | head -1)"
  echo "maven_version=$(mvn -version | head -1)"
} > sqa-handover/build-info.properties
```

Do not put the JFrog token in build metadata.

## 15. Assemble SQA handover evidence

```bash
rm -rf sqa-handover/test-results
mkdir -p sqa-handover/test-results/unit
mkdir -p sqa-handover/test-results/integration
```

```bash
cp target/vat-processing-service-1.0.0.jar sqa-handover/
cp target/vat-processing-service-1.0.0.jar.sha256 sqa-handover/
cp sqa-template/RELEASE-NOTES.md sqa-handover/RELEASE-NOTES.md
cp target/integration-vat-return.json sqa-handover/sample-vat-return.json
cp target/surefire-reports/* sqa-handover/test-results/unit/
cp target/failsafe-reports/* sqa-handover/test-results/integration/
```

The JAR in this local handover directory should have the same checksum as the version published to Artifactory.

## 16. What is handed to SQA

Build & Release provides SQA with:

```text
Maven coordinates:
com.example.vat:vat-processing-service:1.0.0

Artifactory repository:
libs-release-local (or your configured repository)

Evidence:
- Surefire reports
- Failsafe reports
- build-info.properties
- release notes
- SHA-256
- approved sample VAT output
```

SQA then owns the deeper functional/regression/business-rule testing.

## 17. Release-candidate principle

A useful future extension is to use an RC version, for example:

```text
1.1.0-rc1
```

or your organization's equivalent versioning convention.

The important release-engineering principle is:

```text
Build once
   ↓
Qualify
   ↓
Publish exact artifact to Artifactory
   ↓
SQA tests exact artifact
   ↓
Promote/release that artifact
```

Do not rebuild a different JAR after SQA approves the candidate.

## 18. Optional Docker image exercise

Docker is not the official product path for this project. If you want container-packaging practice after the JAR is already qualified, you may build the supplied `Dockerfile`, but it is outside the Build & Release/SQA handover requirement.
