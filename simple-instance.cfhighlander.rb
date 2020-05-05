CfhighlanderTemplate do

  Parameters do

    ComponentParam :InstanceType, 't3.small', description: 'Instance type, determining its hardware properties'
    ComponentParam :SubnetId, type: 'AWS::EC2::Subnet::Id', description: 'Subnet Id for instance to run in '
    ComponentParam :Ami, description: 'Amazon Machine Image (AMI) id'
    ComponentParam :Name, 'MyEc2Server', description: 'Name tag for the instance'
    ComponentParam :TerminationProtection, 'false', allowedValues: %w[false true], description: 'Allow instance termination by default'
    ComponentParam :KeyName, description: 'EC2 KeyPair, can be left blank'
    ComponentParam :RootVolumeSize, 15, type: 'Number', description: 'Size of the root volume, encrypted by default'
    ComponentParam :InstanceProfile, type: String, description: 'Instance profile NAME to pass to EC2 instance'
  end


end