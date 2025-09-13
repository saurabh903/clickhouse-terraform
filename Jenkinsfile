pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/saurabh903/clickhouse-terraform.git', branch: 'main'
            }
        }

        stage('Set Public IP') {
            steps {
                script {
                    env.MY_IP = sh(script: "curl -s https://checkip.amazonaws.com", returnStdout: true).trim()
                    echo "Detected Public IP: ${env.MY_IP}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'aws-credential-id', region: "${AWS_REGION}") {
                    dir('clickhouse-terraform') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withAWS(credentials: 'aws-credential-id', region: "${AWS_REGION}") {
                    dir('clickhouse-terraform') {
                        sh """
                            terraform plan -out=tfplan \
                            -var "my_ip=${MY_IP}" \
                            -var "key_name=my-key"
                        """
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withAWS(credentials: 'aws-credential-id', region: "${AWS_REGION}") {
                    dir('clickhouse-terraform') {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'clickhouse-key', keyFileVariable: 'SSH_KEY')]) {
                    dir('ansible') {
                        // Use dynamic inventory
                        sh 'ansible-playbook -i inventory/inventory_aws_ec2.yml playbook.yml --private-key $SSH_KEY'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        failure {
            echo 'Pipeline failed. Check logs.'
        }
    }
}
