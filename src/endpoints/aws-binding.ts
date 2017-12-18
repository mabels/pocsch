
interface AwsSignature {
  (event: any, context: any, callback: any): void;
}

export default function AwsBinding(handler: any): AwsSignature {
  return (event: any, context: any, callback: any) => {
    const response: any = {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*', // Required for CORS support to work
      },
    };
    handler.handle({}, {
      end: (str: string) => { response.body = str; }
    });
    callback(null, response);
  };
}
