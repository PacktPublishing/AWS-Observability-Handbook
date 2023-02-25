# Instructions
- CloudFormation template `chapter11/cf-templates/root_stack.json` needs rest of the resources in this repository.
- Launch it either in CloudFormation designer or console.
- You will need a key pair to the account you are launching this workshop in.
- On successful completion goto CloudFormation console > Stack name> Outputs
- Login to OpenSearch at `OpenSearchProxyURL` by accepting self signed certificate presented with 
- `username: aosadmin` 
- `password: Passw0rd1!`
- Go to the sample app console at `SampleAppURL` (takes ~10 mins after stack `CREATE_COMPLETE`) and click the buttons to mimick interaction in a shopping application
- Goto Trace Analytics app in OpenSearch Dashboard sidebar, explore options
- Create index pattern called sample_app_logs under Stack Management in the sidebar and observe logs as they come in
# Architecture
![architecture](/chapter11/assets/arch.png)