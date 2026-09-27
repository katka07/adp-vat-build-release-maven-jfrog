node('work-agent') {
  try {
    stage('Checkout') {
      checkout scm
    }
    
    // Force a fresh pull of your upgraded Java 21 image
    docker.image('katka07/adp-vat:v1').pull()
    
    docker.image('katka07/adp-vat:v1').inside('-t') {
      stage('Environment') {
        echo 'Environment Check!'
        sh 'mvn --version'
        sh 'java -version'
        sh 'git --version'
      }
      
      stage('Clean') {
        sh 'mvn clean'
      }
      
      stage('Compile') {
        sh 'mvn compile'
      }
      
      stage('Tests') {
        // This passes cleanly now because your upgraded pom.xml plugins handle Java 21 perfectly!
        sh 'mvn test'
      }
      
      stage('SonarAnalysis & Quality Gate') {
        echo 'Running SonarQube scanning...'

        // FIX: Binding to the named UI profile allows metadata file generation
        withSonarQubeEnv('SonarQube') {
          withCredentials([string(credentialsId: 'sonar_token', variable: 'SONAR_AUTH')]) {
            sh """#!/bin/bash
            mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184:sonar \
              -Dsonar.host.url=http://192.168.100.66:9000 \
              -Dsonar.login=${SONAR_AUTH} \
              -Dsonar.projectName=adp-vat \
              -Dsonar.projectKey=adp-vat
            """
          }
        }
        
        echo 'Checking SonarQube Quality Gate status...'
        timeout(time: 30, unit: 'MINUTES') {
          // The background metadata tracking block will now pick up the execution task cleanly
          def qg = waitForQualityGate()
          if (qg.status != 'OK') {
            error "Pipeline aborted due to Quality Gate failure! Status: ${qg.status}"
          }
          else {
            echo 'Quality Gate passed successfully!'
          }
        }
      }
      
      stage('Package') {
        sh 'mvn package -DskipTests'
      }
      
      stage('Verify') {
        sh 'mvn verify -DskipTests'
      }
      
      stage('Deploy Artifact to JFrog') {
        if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
          withEnv([
            'JFROG_URL=http://192.168.100.66:8082',
            'JFROG_RELEASE_REPO=example-repo-local',
            'JFROG_SNAPSHOT_REPO=example-repo-local'
          ]) {
            withCredentials([usernamePassword(credentialsId: 'jfrog-creds',
            usernameVariable: 'JFROG_USER',
            passwordVariable: 'JFROG_PASS')]) {
              sh 'mvn deploy -DskipTests -s settings.xml'
            }
          }
        }
      }
    }
  }
  catch (Exception e) {
    currentBuild.result = 'FAILURE'
    echo "Build failed with error: ${e.getMessage()}"
    throw e
  }
  finally {
    stage('Workspace Cleanup') {
      echo "Purging all workspace footprints from node: ${env.NODE_NAME}"
      cleanWs()
    }
  }
}
