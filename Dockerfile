# Optional packaging exercise only. The official SQA handoff artifact is the JAR.
FROM eclipse-temurin:8-jre
WORKDIR /opt/vat
ARG JAR_FILE=target/vat-processing-service-1.0.0.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java", "-jar", "/opt/vat/app.jar"]
