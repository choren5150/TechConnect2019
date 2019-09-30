pipeline {
    agent any
    
    stages {
        stage('Update Prod from Test Repo') {
            steps {
                    powershell '''
                        Set-Location (Join-Path -Path $env:SystemDrive -ChildPath 'Scripts')
                        .\\Update-ProdRepoFromTest.ps1 `
                        -ProdRepo $env:P_PROD_REPO_URL `
                        -ProdRepoApiKey $env:P_PROD_REPO_API_KEY `
                        -TestRepo $env:P_TEST_REPO_URL `
                        -Verbose
                    '''
            }
        }
    }
    post {
        failure {
            emailext attachLog: true, body:"${currentBuild.currentResult}: ${BUILD_URL}", from: 'RSSAutomation@cuanschutz.edu', subject: "Build Notification ${JOB_NAME}-Build# ${BUILD_NUMBER} ${currentBuild.currentResult}", to: 'OIT-RSS-Systems@ucdenver.edu'
        }
    }
}