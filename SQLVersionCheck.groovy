pipeline {
    agent any
    
    stages {
        stage('Verify version') {
            steps {
                withCredentials([usernamePassword(credentialsId: '7a8e77b6-d081-4ed7-9bb5-32e3f5bd0b4b', passwordVariable: 'srvPassword', usernameVariable: 'srvUser')]) {
                    powershell '''
                        Set-Location (Join-Path -Path $env:SystemDrive -ChildPath 'Scripts')
                        .\\JenkinsSQLVersions.ps1 `
                        -Pass $env:srvPassword `
                        -User $env:srvUser `
                        -Verbose
                    '''
                }
            }
        }
    }
    post {
        success {
            emailext attachmentsPattern: '**/SQLServerVersions.csv', body:"${currentBuild.currentResult}: ${BUILD_URL}", from: 'RSSAutomation@cuanschutz.edu', subject: "Build Notification ${JOB_NAME}-Build# ${BUILD_NUMBER} ${currentBuild.currentResult}", to: 'OIT-RSS-Systems@ucdenver.edu'
        }
    }
}