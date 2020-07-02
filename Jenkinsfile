String credentialsId = 'awsCredentials'

try {
	stage('checkout') {
		node {
			cleanWs()
			checkout scm
		}
	}
// Run terraform init
	stage('init') {
		node {
			withCredentials([[
				$class: 'AmazonWebServicesCredentialsBinding',
				credentialsId: 'awsCredentials',
			]]) {
				sh '/usr/local/bin/terraform init'
			}
		}
	}

// Run terraform validate
	stage('validate') {
		node {
			withCredentials([[
				$class: 'AmazonWebServicesCredentialsBinding',
				credentialsId: 'awsCredentials',
			]]) {
				sh '/usr/local/bin/terraform validate'
			}
		}
	}


// Run terraform plan
	stage('plan') {
		node {
			withCredentials([[
				$class: 'AmazonWebServicesCredentialsBinding',
				credentialsId: 'awsCredentials',
			]]) {
				sh '/usr/local/bin/terraform plan'
			}
		}
	}

// Run terraform apply
	stage('apply') {
		node {
			withCredentials([[
				$class: 'AmazonWebServicesCredentialsBinding',
				credentialsId: 'awsCredentials',
			]]) {
				sh '/usr/local/bin/terraform apply -auto-approve'
			}
		}
	}
// Run terraform show
	stage('show') {
		node {
			withCredentials([[
				$class: 'AmazonWebServicesCredentialsBinding',
				credentialsId: 'awsCredentials',
			 ]]) {
				sh '/usr/local/bin/terraform show'
			}
		}
	}


currentBuild.result = 'Success'
}
catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException flowError) {
	currentBuild.result = 'Aborted'
}
catch (error) {
	currentBuild.result = 'Failure'
	throw error
}
finally {
	if (currentBuild.result == 'Success') {
	   currentBuild.result = 'Success'
	}
}
