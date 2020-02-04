pipeline {
  agent any
  stages {
    stage('Run Unit Tests') {
      parallel {
        stage('DMD') {
          steps {
            sh 'dub test --compiler=dmd'
          }
        }

        stage('LDC') {
          steps {
            sh 'dub test --compiler=ldc'
          }
        }

      }
    }

    stage('Build') {
      parallel {
        stage('DMD') {
          steps {
            sh 'dub build --compiler=dmd'
          }
        }

        stage('LDC') {
          steps {
            sh 'dub build --compiler=ldc'
          }
        }

      }
    }

  }
}