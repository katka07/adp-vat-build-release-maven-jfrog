# Future Jenkins automation exercise

Do not start here. First run `MANUAL-COMMANDS.md` manually, including a successful JFrog deployment.

For this project, a realistic automated Build & Release flow is:

1. Checkout
2. Set build version / release candidate identity
3. `mvn clean deploy` using a Jenkins-managed Maven `settings.xml`
4. Maven Surefire unit reports
5. Maven Failsafe packaged-JAR smoke/integration reports
6. SonarQube analysis / quality gate
7. SHA-256 + build metadata
8. Archive test reports
9. Record the Artifactory artifact URL/build coordinates
10. Notify or hand over to SQA

`mvn clean deploy` already executes all Maven lifecycle phases through `verify` before the deploy phase. If any Maven test gate fails, the artifact is not uploaded.

In Jenkins, never hard-code Artifactory tokens in the Jenkinsfile or `pom.xml`. Use Jenkins credentials and expose the token only to the Maven step.

SQA's deep regression suite is downstream and is not implemented in this repository.
