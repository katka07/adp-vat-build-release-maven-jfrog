# Validation status

## Source/build structure validated

The repository has been checked for:

- Java 8-compatible source structure
- Maven Surefire `*Test` unit-test separation
- Maven Failsafe `*IT` smoke/integration-test separation
- executable-JAR manifest configuration
- Maven `distributionManagement` release and snapshot targets
- matching JFrog Maven server IDs in `pom.xml` and `config/settings-jfrog.xml.example`
- no real JFrog credentials in source
- valid XML for `pom.xml` and Maven settings example
- Graphviz release-flow rendering

## JFrog deployment validation limitation

This packaging environment does not have Maven installed and has no authenticated JFrog Artifactory instance, so a real `mvn clean deploy` upload could not be executed here.

The deployment configuration follows the standard Maven Artifactory model:

```text
pom.xml distributionManagement
+
Maven settings.xml server credentials
+
mvn clean deploy
```

Run the exact commands in `docs/JFROG-INTEGRATION.md` against your own Artifactory lab. If the Maven tests fail, deployment should stop before upload; if authentication/repository configuration is incorrect, the failure will occur in Maven's deploy phase.
