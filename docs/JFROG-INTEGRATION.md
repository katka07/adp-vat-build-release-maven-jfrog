# JFrog Artifactory integration

This project uses the traditional Maven deployment model:

```text
pom.xml distributionManagement
        +
Maven settings.xml credentials
        ↓
mvn clean deploy
        ↓
JFrog Artifactory Maven local repository
```

The official release artifact remains the Maven-built JAR. Artifactory is the system of record used to publish and hand the qualified artifact to SQA.

## 1. Artifactory repositories required

Ask your Artifactory administrator to provide Maven **local** repositories similar to:

```text
libs-release-local
libs-snapshot-local
```

The exact names can be different.

A version such as:

```text
1.0.0
```

is deployed to the release repository.

A version such as:

```text
1.0.1-SNAPSHOT
```

is deployed to the snapshot repository.

## 2. Artifactory information you need

Collect:

```text
JFrog base URL
Maven release repository name
Maven snapshot repository name
Your Artifactory username
An access/identity token with deploy permission
```

Example values used throughout this guide:

```text
JFROG_URL=https://acme.jfrog.io
JFROG_RELEASE_REPO=libs-release-local
JFROG_SNAPSHOT_REPO=libs-snapshot-local
```

Do not commit a real token to Git.

## 3. Export the environment variables

```bash
export JFROG_URL='https://acme.jfrog.io'
export JFROG_RELEASE_REPO='libs-release-local'
export JFROG_SNAPSHOT_REPO='libs-snapshot-local'
export JFROG_USERNAME='your-artifactory-user'
export JFROG_TOKEN='replace-with-your-access-or-identity-token'
```

Confirm only non-secret variables:

```bash
printf 'JFROG_URL=%s\n' "$JFROG_URL"
printf 'JFROG_RELEASE_REPO=%s\n' "$JFROG_RELEASE_REPO"
printf 'JFROG_SNAPSHOT_REPO=%s\n' "$JFROG_SNAPSHOT_REPO"
printf 'JFROG_USERNAME=%s\n' "$JFROG_USERNAME"
```

Do not echo `JFROG_TOKEN` into logs.

## 4. Maven credential mapping

The repository contains:

```text
config/settings-jfrog.xml.example
```

It deliberately contains no credentials. Maven reads them from the environment:

```xml
<server>
  <id>jfrog-releases</id>
  <username>${env.JFROG_USERNAME}</username>
  <password>${env.JFROG_TOKEN}</password>
</server>
```

The `<id>` must match the repository ID in `pom.xml`:

```xml
<distributionManagement>
  <repository>
    <id>jfrog-releases</id>
    ...
  </repository>
</distributionManagement>
```

That ID match is how Maven associates credentials with the deployment repository.

## 5. Verify the repository URL Maven will use

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
https://acme.jfrog.io/artifactory/libs-release-local
```

For snapshots:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  help:evaluate \
  -Dexpression=project.distributionManagement.snapshotRepository.url \
  -q \
  -DforceStdout
```

## 6. Optional Artifactory connectivity check

If your token permits API access:

```bash
curl \
  --fail \
  --silent \
  --show-error \
  -H "Authorization: Bearer $JFROG_TOKEN" \
  "$JFROG_URL/artifactory/api/system/ping"
```

A healthy Artifactory instance normally responds with:

```text
OK
```

If your organization uses a different authentication policy, use the method provided by your Artifactory administrator.

## 7. Deploy the release artifact

From a clean checkout:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  clean deploy
```

This is the important point: `deploy` is a Maven lifecycle phase. Before Maven reaches `deploy`, it runs the earlier phases including unit tests, packaging, Failsafe smoke/integration tests, and `verify`.

Conceptually:

```text
clean
  ↓
compile
  ↓
test
  ↓
package
  ↓
integration-test
  ↓
verify
  ↓
install
  ↓
deploy
```

If a unit, smoke, or integration test fails, Maven never reaches the Artifactory upload step.

For version `1.0.0`, Maven publishes artifacts under a Maven path similar to:

```text
com/example/vat/vat-processing-service/1.0.0/
```

The deployed content normally includes at least:

```text
vat-processing-service-1.0.0.jar
vat-processing-service-1.0.0.pom
Maven metadata/checksum information
```

## 8. Confirm the deployed artifact

In the JFrog UI, browse:

```text
Artifacts
  → libs-release-local
  → com
  → example
  → vat
  → vat-processing-service
  → 1.0.0
```

Confirm that the JAR is present and record the artifact URL/build reference for SQA.

## 9. Snapshot deployment

Maven chooses the snapshot repository automatically when the project version ends in `-SNAPSHOT`.

For example, change the project version to:

```text
1.0.1-SNAPSHOT
```

then run:

```bash
mvn \
  -s config/settings-jfrog.xml.example \
  clean deploy
```

It will use `jfrog-snapshots` instead of `jfrog-releases`.

## 10. Recommended Build & Release flow

For this training project:

```text
Developer commit
      ↓
mvn clean deploy
      ↓
Surefire unit tests
      ↓
Executable JAR package
      ↓
Failsafe packaged-JAR smoke/integration tests
      ↓
Maven verify
      ↓
Maven deploy
      ↓
JFrog Artifactory
      ↓
Build metadata + test reports
      ↓
SQA receives exact published artifact
```

The key release-engineering principle is that SQA should test the **same immutable artifact** that Build & Release published. Do not rebuild the JAR after SQA approves it; promote or release the already-tested artifact according to your repository process.

## 11. Common deployment failures

### `401 Unauthorized`

Check:

```text
JFROG_USERNAME
JFROG_TOKEN
repository permissions
server IDs in settings.xml vs pom.xml
```

### `403 Forbidden`

Authentication may be valid, but the user/token may not have deploy permission to the target local repository.

### `405 Method Not Allowed` or deployment to the wrong repository

Make sure the target is a deployable Maven **local** repository, not simply a remote-cache repository.

### Maven tries to deploy to a literal `${env.JFROG_URL}` path

The environment variable was not exported in the shell launching Maven.

Verify:

```bash
printf '%s\n' "$JFROG_URL"
```

### Tests fail before upload

This is expected Maven behavior. `deploy` runs after `verify`; fix the failed unit/smoke/integration test first.

## 12. Optional modern JFrog CLI path

For this 2017-style project, native Maven deployment is the primary learning path.

In a modern environment, JFrog CLI can also configure Maven resolution/deployment and collect JFrog Build Info. That is useful later when you automate the project in Jenkins, but it is intentionally not required for the historical manual workflow.
