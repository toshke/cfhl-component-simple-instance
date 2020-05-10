CloudFormation do

  user_data = external_parameters.fetch(:user_data, 'echo "Hello World!!"')
  create_role = external_parameters.fetch(:create_role, false)
  name = external_parameters.fetch(:name, 'EC2Server')
  public_ip = external_parameters.fetch(:public_ip, false)
  device_mappings = external_parameters.fetch(:device_mappings, nil)

  Condition(:KeyGiven, FnNot(FnEquals(Ref(:KeyName), '')))
  Condition(:InstanceProfileGiven, FnNot(FnEquals(Ref(:InstanceProfile), ''))) unless create_role

  ingress_rules = []
  allow_incoming.each do |it|
    rule = { CidrIp: it['range'], IpProtocol: it.fetch('protocol', 'tcp') }
    if it['port'].to_s.include? '-'
      rule[:FromPort] = it['port'].split('-')[0].to_i
      rule[:ToPort] = it['port'].split('-')[1].to_i
    else
      rule[:FromPort] = it['port'].to_i
      rule[:ToPort] = it['port'].to_i
    end
    ingress_rules << rule
  end

  device_mappings = [
      {
          DeviceName: '/dev/xvda', Ebs:
          {
              Encrypted: true,
              KmsKeyId: 'alias/aws/ebs',
              VolumeSize: Ref(:RootVolumeSpace),
              DeleteOnTermination: true,
          }
      }
  ] if device_mappings.nil?
  begin
    IAM_Role(:Role) do
      Path '/'
      AssumeRolePolicyDocument service_assume_role_policy('ec2')
      ManagedPolicyArns managed_policies unless managed_policies.empty?
      Policies policies unless policies.empty?
    end

    IAM_InstanceProfile(:InstanceProfile) do
      Path '/'
      Roles [Ref(:Role)]
    end
  end if create_role


  EC2_Instance(:Instance) do
    ImageId Ref(:Ami)
    Tags [{ Key: 'Name', Value: Ref(:Name) }]
    InstanceType Ref(:InstanceType)
    KeyName FnIf(:KeyGiven, Ref(:KeyName), Ref('AWS::NoValue'))
    DisableApiTermination Ref(:TerminationProtection)
    BlockDeviceMappings device_mappings
    IamInstanceProfile FnIf(:InstanceProfileGiven, Ref(:InstanceProfile), Ref('AWS::NoValue')) unless create_role
    IamInstanceProfile Ref(:InstanceProfile) if create_role
    UserData FnBase64(FnSub(File.read "#{template_dir}/user_data.sh")) if File.exist? "#{template_dir}/user_data.sh"
    UserData FnBase64(FnSub((user_data))) unless user_data.nil?
    if public_ip
      NetworkInterfaces([{
          "AssociatePublicIpAddress": "true",
          "DeviceIndex": "0",
          "GroupSet": [Ref(:InstanceSecurityGroup)],
          "SubnetId": Ref(:SubnetId)
      }])
    else
      SecurityGroupIds [Ref(:InstanceSecurityGroup)]
      SubnetId Ref(:SubnetId)
    end
  end

  EC2_SecurityGroup(:InstanceSecurityGroup) do
    VpcId Ref('VpcId')
    GroupDescription "#{name} - ASG SG"
    SecurityGroupIngress ingress_rules unless ingress_rules.empty?
  end

  Output(:SecurityGroup) do
    Value(Ref(:InstanceSecurityGroup))
  end
  Output(:InstanceId) do
    Value(Ref(:Instance))
  end
end
