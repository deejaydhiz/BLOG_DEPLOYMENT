pipeline {
  agent any

  parameters {
    credentials credentialType: 'com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl', defaultValue: 'stack_prog_aut', name: 'AWS', required: false
    booleanParam(name: 'DESTROY', defaultValue: false)
  }

  environment {
    PATH = "${PATH}:${getTerraformPath()}"
  }

  stages {
    stage('Initial Deployment Approval') {
      steps {
        script {
          input(message: 'Start Pipeline?')
        }
      }
    }

    stage('terraform init') {
      steps {
        slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        sh 'terraform init'
      }
    }

    stage('terraform plan'){
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          sh 'terraform plan -out=tfplan -input=false'
        }
      }
    }

    stage('Final Deployment Approval') { 
      steps { 
        script { 
          input(message: 'Apply Terraform?')
        } 
      } 
    }

    stage('Terraform Apply'){ 
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          sh "terraform apply -input=false tfplan" 
          slackSend (color: '#FFFF00', message: "FINISHED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        } 
      }
    }

    stage('Terraform Destroy'){
      when {
        expression { params.DESTROY }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          sh "terraform destroy -auto-approve"
        }
      }
    }
  }
}

def getTerraformPath() {
  def tfHome = tool name: 'terraform-14', type: 'terraform'
  return tfHome
}