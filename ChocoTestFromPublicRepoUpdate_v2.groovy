pipeline {
    agent any
    
    stages {
        stage('Update Test from Community Repo') {
            steps {
                    powershell '''
                        Set-Location (Join-Path -Path $env:SystemDrive -ChildPath 'Scripts')
                        .\\Get-UpdatedPackage.ps1 -LocalRepo $env:P_LOCAL_REPO_URL `
                        -LocalRepoApiKey $env:P_LOCAL_REPO_API_KEY `
                        -RemoteRepo $env:P_REMOTE_REPO_URL `
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