CloudFormation do

  Condition(:KeyGiven, FnNot(FnEquals(Ref(:KeyName), '')))
  Condition(:InstanceProfileGiven, FnNot(FnEquals(Ref(:InstanceProfile), '')))
  bdmappings = [
      {
          DeviceName: '/dev/xvda', Ebs:
          {
              Encrypted: true,
              KmsKeyId: 'alias/aws/ebs',
              VolumeSize: Ref(:RootVolumeSize),
              DeleteOnTermination: true,
          }
      }
  ]

  EC2_Instance(:Instance) do
    ImageId Ref(:Ami)
    SubnetId Ref(:SubnetId)
    Tags [{Key: 'Name', Value: Ref(:Name)}]
    InstanceType Ref(:InstanceType)
    KeyName FnIf(:KeyGiven, Ref(:KeyName), Ref('AWS::NoValue'))
    DisableApiTermination Ref(:TerminationProtection)
    BlockDeviceMappings bdmappings
    IamInstanceProfile FnIf(:InstanceProfileGiven, Ref(:InstanceProfile), Ref('AWS::NoValue'))
    UserData FnBase64(File.read "#{template_dir}/user_data.sh") if File.exist? "#{template_dir}/user_data.sh"
  end


end
