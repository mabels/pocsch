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
            console.log('repositoryMetadata:', data.repositoryMetadata);
            const build = {
              'projectName': `codebuild-project-${data.repositoryMetadata.repositoryName}`,
              'sourceVersion': event.Records[0].codecommit.references[0].commit
            }
            console.log('Build', build);
            codebuild.startBuild(build, function(err, data) {
              if (err) console.log(err, err.stack); // an error occurred
              else     console.log(data);           // successful response
              context.succeed('codebuild-triggered:', build);
            });
        }
    });


};
