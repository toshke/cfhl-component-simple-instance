def param_value_if_given(cfndsl, param_name)
  cfndsl.Condition("#{param_namea}Given", FnNot(FnEquals(Ref(param_name), '')))
  return
end