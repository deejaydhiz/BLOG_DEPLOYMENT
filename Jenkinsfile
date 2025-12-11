pipeline {
  agent any

  parameters {
    credentials credentialType: 'com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl', defaultValue: 'stack_prog_aut', name: 'AWS', required: false
    booleanParam(name: 'BUILD_AMI', defaultValue: true)
    booleanParam(name: 'DESTROY', defaultValue: false)
    string defaultValue: 'DEJI', name: 'RUNNER'
  }

  environment {
    PATH = "${PATH}:${getTerraformPath()}"
  }

  stages {
    stage('Packer AMI Build'){
      when {
        expression { params.BUILD_PACKER_IMG }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          slackSend (color: '#ffae00ff', message: "STARTING PACKER IMAGE BUILD: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}). Initiated by ${params.RUNNER}")
          sh '''
          packer init -upgrade .
          packer validate golden_img.pkr.hcl
          sed -i "s/deji-blog-ami-'[0-9]*$'/deji-blog-ami-'${BUILD_NUMBER}'/" ./golden_img.pkr.hcl
          export PACKER_LOG=1
          export PACKER_LOG_PATH=$WORKSPACE/packer.log
          /usr/bin/packer build -force golden_img.pkr.hcl 
          '''    
        }
      }
    }

    stage('terraform init') {
      steps {
        slackSend (color: '#d0ff00ff', message: "${params.RUNNER} STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        sh 'terraform init'
      }
    }

    stage('terraform plan and apply'){
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          slackSend (color: '#15ff00ff', message: "GENERATING PLAN: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
          sh 'terraform plan -out=tfplan -input=false'
          sh "terraform apply -input=false tfplan" 
          slackSend (color: '#0400ffff', message: "FINISHED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        } 
      }
    }

    stage('terraform destroy'){
      when {
        expression { params.DESTROY }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS, accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        ]) {
          sh "terraform destroy -auto-approve"
          slackSend (color: '#ff000dff', message: "DESTROYED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}). Initiated by ${params.RUNNER}")
        }
      }
    }
  }
}

def getTerraformPath() {
  def tfHome = tool name: 'terraform-14', type: 'terraform'
  return tfHome
}