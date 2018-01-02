var aws = require('aws-sdk');
var codecommit = new aws.CodeCommit({ apiVersion: '2015-04-13' });
var codebuild = new aws.CodeBuild({apiVersion: '2016-10-06'});

exports.handler = function(event, context) {
    
    //Log the updated references from the event
    var references = event.Records[0].codecommit.references.map(function(reference) {return reference.ref;});
    console.log('References:', references);
    console.log('CodeCommit:', JSON.stringify(event.Records[0].codecommit));
    
    //Get the repository from the event and show its git clone URL
    var repository = event.Records[0].eventSourceARN.split(":")[5];
    var params = {
        repositoryName: repository
    };
    codecommit.getRepository(params, function(err, data) {
        if (err) {
            console.log(err);
            var message = "Error getting repository metadata for repository " + repository;
            console.log(message);
            context.fail(message);
        } else {
            console.log('Clone URL:', data.repositoryMetadata.cloneUrlHttp);
            //context.succeed(data.repositoryMetadata.cloneUrlHttp);
            const build = {
              'projectName': `codebuild-project-${data.repositoryName}`,
              // 'sourceVersion': event['Records'][0]['codecommit']['references'][0]['commit']
            }
            console.log('Build', build);
            //console('Starting build for project {0} from commit ID {1}'.format(build['projectName'], build['sourceVersion']))
            // codebuild.start_build(**build)
        }
    });


};
